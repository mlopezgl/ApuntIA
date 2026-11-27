import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/store.dart';
import '../domain/models.dart';
import '../firebase_options.dart';
import 'auth_config.dart';

/// Cuenta del alumno (Firebase Authentication) y copia en la nube de sus mazos
/// (Cloud Firestore, documento `users/{uid}`).
///
/// El teléfono sigue siendo la fuente principal: la app funciona sin conexión
/// y, con sesión iniciada, cada cambio se sube a la nube unos segundos después.
/// Al iniciar sesión se combinan los datos locales con los de la nube.
class CloudSync extends ChangeNotifier {
  CloudSync(this.store, {FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final StudyStore store;
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  StreamSubscription<User?>? _authSub;
  Timer? _debounce;
  bool _applyingRemote = false;

  bool syncing = false;
  DateTime? lastSync;
  String? lastError;

  /// La persona eligió "Continuar sin cuenta" en la pantalla de acceso.
  bool loginSkipped = false;
  static const _skipKey = 'apuntia.login_skipped';

  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      loginSkipped = prefs.getBool(_skipKey) ?? false;
    } catch (_) {}
  }

  Future<void> _setSkipped(bool value) async {
    loginSkipped = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_skipKey, value);
    } catch (_) {}
  }

  /// Usar la app sin cuenta (solo en este teléfono).
  Future<void> skipLogin() => _setSkipped(true);

  User? get user => _auth.currentUser;
  bool get signedIn => user != null;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  void start() {
    _authSub = _auth.authStateChanges().listen((u) {
      notifyListeners();
      if (u != null) unawaited(syncNow());
    });
    store.addListener(_onLocalChange);
  }

  void _onLocalChange() {
    if (_applyingRemote || !signedIn) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () => unawaited(_push()));
  }

  Future<void> _push() async {
    final u = user;
    if (u == null) return;
    try {
      await _doc(u.uid).set({
        'schema': 1,
        'data': jsonEncode(store.data.toJson()),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      lastSync = DateTime.now();
      lastError = null;
    } catch (e) {
      lastError =
          'No se pudo subir a la nube. Se reintentará con el próximo cambio.';
    }
    notifyListeners();
  }

  /// Descarga la copia de la nube, la combina con la local y sube el resultado.
  Future<void> syncNow() async {
    final u = user;
    if (u == null || syncing) return;
    syncing = true;
    lastError = null;
    notifyListeners();
    try {
      final snap = await _doc(u.uid).get();
      final raw = snap.data()?['data'];
      if (raw is String) {
        final remote = StudyData.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        final merged = isPristine(store.data)
            ? remote
            : mergeStudyData(store.data, remote);
        _applyingRemote = true;
        try {
          await store.replaceAll(merged);
        } finally {
          _applyingRemote = false;
        }
      }
      await _push();
    } on FirebaseException catch (e) {
      lastError = e.code == 'unavailable'
          ? 'Sin conexión. Tus datos siguen guardados en el teléfono.'
          : 'No se pudo sincronizar (${e.code}).';
    } catch (_) {
      lastError =
          'La copia de la nube no es válida; no se modificaron tus datos.';
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) => _guard(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  Future<void> register(String email, String password) => _guard(
    () => _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  bool _googleReady = false;

  Future<void> _initGoogle() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? DefaultFirebaseOptions.currentPlatform.iosClientId
          : null,
      // Android toma el cliente web (default_web_client_id) de
      // google-services.json automáticamente.
    );
    _googleReady = true;
  }

  /// Inicia sesión con Google. Devuelve `false` si la persona canceló.
  Future<bool> signInWithGoogle() async {
    try {
      await _initGoogle();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const FormatException('Google no devolvió la identidad.');
      }
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      throw FormatException(
        'No se pudo iniciar sesión con Google (${e.code.name}).',
      );
    } on FirebaseAuthException catch (e) {
      throw FormatException(authMessage(e.code));
    }
  }

  /// Inicia sesión con Apple (iCloud). Devuelve `false` si se canceló.
  Future<bool> signInWithApple() async {
    if (!AuthConfig.appleEnabled) {
      throw const FormatException(
        'El acceso con Apple se activará cuando la app use una cuenta de Apple Developer.',
      );
    }
    try {
      await _auth.signInWithProvider(
        AppleAuthProvider()
          ..addScope('email')
          ..addScope('name'),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' || e.code == 'web-context-canceled') {
        return false;
      }
      throw FormatException(authMessage(e.code));
    }
  }

  /// Inicia sesión con Facebook. Para activarlo: agrega `flutter_facebook_auth`,
  /// obtén el token con `FacebookAuth.instance.login()` y llama a
  /// `_auth.signInWithCredential(FacebookAuthProvider.credential(token))`.
  Future<bool> signInWithFacebook() async {
    throw const FormatException(
      'El acceso con Facebook se activará cuando se registre la app en Meta.',
    );
  }

  Future<void> resetPassword(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  Future<void> signOut() async {
    _debounce?.cancel();
    await _push();
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
    lastSync = null;
    await _setSkipped(false);
  }

  Future<void> _guard(Future<Object?> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw FormatException(authMessage(e.code));
    }
  }

  @visibleForTesting
  static String authMessage(String code) => switch (code) {
    'invalid-email' => 'El correo no tiene un formato válido.',
    'user-disabled' => 'Esta cuenta fue deshabilitada.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Correo o contraseña incorrectos.',
    'email-already-in-use' =>
      'Ya existe una cuenta con ese correo. Inicia sesión.',
    'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
    'network-request-failed' => 'Sin conexión. Intenta de nuevo con internet.',
    'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
    'account-exists-with-different-credential' =>
      'Ese correo ya está registrado con otro método. Entra con el método que usaste antes.',
    'operation-not-allowed' => 'Este método de acceso no está habilitado.',
    _ => 'No se pudo completar el acceso ($code).',
  };

  @override
  void dispose() {
    _debounce?.cancel();
    _authSub?.cancel();
    store.removeListener(_onLocalChange);
    super.dispose();
  }
}
