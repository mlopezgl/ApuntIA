import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../data/store.dart';
import '../firebase_options.dart';
import 'cloud_sync.dart';
import 'gemini.dart';
import 'generator.dart';

/// Servicios opcionales de la app (solo Android e iOS). Si Firebase no está
/// disponible (pruebas o un error de configuración) la app sigue funcionando
/// sin conexión.
class AppServices {
  AppServices({this.cloud, CardGenerator? generator})
    : generator = generator ?? CardGenerator();

  /// Sin Firebase: solo modo local (pruebas).
  AppServices.offline() : cloud = null, generator = CardGenerator();

  final CloudSync? cloud;
  final CardGenerator generator;

  /// Token de depuración de App Check, se pasa con
  /// `--dart-define-from-file=config/dev.json` (desarrollo) o
  /// `config/testers.json` (APK de prueba). Ambos archivos están fuera de git.
  static const _appCheckDebugToken = String.fromEnvironment(
    'APP_CHECK_DEBUG_TOKEN',
  );

  /// `false` mientras lib/firebase_options.dart sea la plantilla sin llenar.
  static bool get firebaseConfigured {
    try {
      return !DefaultFirebaseOptions.currentPlatform.apiKey.startsWith(
        'AQUI_COLOCA',
      );
    } catch (_) {
      return false;
    }
  }

  static Future<AppServices> initialize(StudyStore store) async {
    final mobile =
        (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
    if (!mobile || !firebaseConfigured) return AppServices.offline();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final debugToken = _appCheckDebugToken.isEmpty
          ? null
          : _appCheckDebugToken;
      // Desarrollo, o APK de prueba compilado con un token de testers:
      // proveedor de depuración. Versión de tienda sin token: Play Integrity
      // y App Attest.
      final useDebugProvider = !kReleaseMode || debugToken != null;
      await FirebaseAppCheck.instance.activate(
        providerAndroid: useDebugProvider
            ? AndroidDebugProvider(debugToken: debugToken)
            : const AndroidPlayIntegrityProvider(),
        providerApple: useDebugProvider
            ? AppleDebugProvider(debugToken: debugToken)
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
      final cloud = CloudSync(store);
      await cloud.loadPreferences();
      cloud.start();
      return AppServices(
        cloud: cloud,
        generator: CardGenerator(engine: geminiEngine()),
      );
    } catch (e) {
      debugPrint('ApuntIA: Firebase no disponible, modo local. $e');
      return AppServices.offline();
    }
  }
}
