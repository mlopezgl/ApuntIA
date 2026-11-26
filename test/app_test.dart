import 'package:apuntia/app.dart';
import 'package:apuntia/data/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'study_test.dart' show MemoryStorage;

void main() {
  testWidgets('Dashboard, reveal, rating and reload preserve a real review', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = StudyStore(
      MemoryStorage(),
      clock: () => DateTime(2026, 11, 19, 10),
    );
    await store.load();
    await tester.pumpWidget(ApuntiaApp(store: store));
    await tester.pumpAndSettle();
    final button = find.text('Repasar ahora');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Ver respuesta'), findsOneWidget);
    expect(find.text('Fácil'), findsNothing);
    await tester.ensureVisible(find.text('Ver respuesta'));
    await tester.tap(find.text('Ver respuesta'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Fácil'));
    await tester.tap(find.text('Fácil'));
    await tester.pumpAndSettle();
    expect(store.todayReviews, 1);
    expect(store.dueCards().length, 7);
    expect(find.text('Tarjeta 2 de 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Create a local deck from notes and edit its draft before saving',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = StudyStore(MemoryStorage());
      await store.load();
      await tester.pumpWidget(ApuntiaApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nueva captura'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del mazo'),
        'Conceptos SQL',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Materia'),
        'Bases de datos',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Texto de tus apuntes'),
        'SQL: lenguaje para consultar bases de datos relacionales.',
      );
      final generate = find.text('Crear borradores sin conexión');
      await tester.ensureVisible(generate);
      await tester.tap(generate);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar borrador'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Pregunta'),
        '¿Qué es SQL?',
      );
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Guardar mi mazo'));
      await tester.tap(find.text('Guardar mi mazo'));
      await tester.pumpAndSettle();
      expect(store.data.decks.first.title, 'Conceptos SQL');
      expect(store.data.decks.first.cards.first.question, '¿Qué es SQL?');
      expect(store.data.decks.first.origin, 'Plantillas locales');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final width in [320.0, 1440.0]) {
    testWidgets('Layout does not overflow at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = StudyStore(MemoryStorage());
      await store.load();
      await tester.pumpWidget(ApuntiaApp(store: store));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
