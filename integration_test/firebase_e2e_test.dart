// Prueba de punta a punta contra el proyecto Firebase real.
// Ejecutar en un simulador o teléfono:
//   flutter test integration_test --dart-define-from-file=config/dev.json -d <dispositivo>
// Crea una cuenta temporal, genera tarjetas con Gemini, sincroniza con
// Firestore, comprueba las reglas de seguridad y borra todo al terminar.
import 'package:apuntia/data/store.dart';
import 'package:apuntia/domain/models.dart';
import 'package:apuntia/services/app_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class _MemoryStorage implements StudyStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String v) async => value = v;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Cuenta, Gemini y Firestore funcionan de punta a punta', (
    tester,
  ) async {
    final store = StudyStore(_MemoryStorage());
    await store.load();
    final services = await AppServices.initialize(store);
    expect(services.cloud, isNotNull, reason: 'Firebase no se inicializó');
    expect(services.generator.aiAvailable, isTrue);
    final cloud = services.cloud!;
    final email =
        'prueba-e2e-${DateTime.now().millisecondsSinceEpoch}@apuntia.test';
    await cloud.register(email, 'Prueba-E2E-2026!');
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = FirebaseFirestore.instance.collection('users').doc(uid);
    try {
      // 1. Gemini (Firebase AI Logic + App Check).
      final drafts = await services.generator.ai(
        'Modelo: representa los datos y las reglas del dominio.\n'
            'Vista: muestra el estado al usuario.\n'
            'Controlador: recibe las acciones del usuario y actualiza el modelo.',
        'Ingeniería de software',
      );
      expect(drafts, isNotEmpty);
      // ignore: avoid_print
      print(
        'Gemini generó ${drafts.length} tarjetas. Primera: ${drafts.first.question}',
      );

      // 2. Guardar un mazo y sincronizar con Firestore.
      final now = DateTime.now();
      final deck = Deck(
        id: newId(),
        title: 'Prueba E2E',
        subject: 'Ingeniería de software',
        created: now,
        source: 'MVC',
        origin: 'IA (Gemini)',
        cards: drafts.map((d) => d.toCard(now)).toList(),
      );
      await store.addDeck(deck);
      while (cloud.syncing) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      await cloud.syncNow();
      expect(cloud.lastError, isNull, reason: cloud.lastError);
      final snap = await doc.get(const GetOptions(source: Source.server));
      expect(snap.data()?['data'] as String?, contains(deck.id));

      // 3. Reglas: no se puede leer el documento de otra persona.
      Object? denied;
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc('otro-usuario')
            .get(const GetOptions(source: Source.server));
      } catch (e) {
        denied = e;
      }
      expect(denied, isA<FirebaseException>());
      expect((denied as FirebaseException).code, 'permission-denied');
      // ignore: avoid_print
      print('E2E OK: cuenta, Gemini, Firestore y reglas de seguridad.');
    } finally {
      await doc.delete();
      await FirebaseAuth.instance.currentUser?.delete();
    }
  });
}
