import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:apuntia/data/store.dart';
import 'package:apuntia/domain/models.dart';
import 'package:apuntia/services/generator.dart';

class MemoryStorage implements StudyStorage {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    if (fail) throw StateError('disk full');
    this.value = value;
  }
}

void main() {
  final now = DateTime(2026, 11, 19, 10);
  test(
    'Easy expands intervals; hard returns in ten minutes and resets stage',
    () {
      final card = StudyCard(id: 'a', question: 'Q', answer: 'A', due: now);
      final first = card.reviewed(easy: true, now: now);
      expect(first.due, DateTime(2026, 11, 20, 10));
      final second = first.reviewed(easy: true, now: first.due);
      expect(second.due, DateTime(2026, 11, 23, 10));
      final hard = second.reviewed(easy: false, now: second.due);
      expect(hard.due.difference(second.due), const Duration(minutes: 10));
      expect(hard.stage, 0);
      expect(hard.reviews, 3);
      expect(hard.isDue(second.due), false);
      expect(hard.isDue(hard.due), true);
    },
  );

  test(
    'Streak handles repeated same-day reviews, yesterday, gaps and month changes',
    () {
      final data = StudyData(
        decks: [],
        events: [
          ReviewEvent('a', DateTime(2026, 10, 31, 8), true),
          ReviewEvent('a', DateTime(2026, 11, 1, 8), true),
          ReviewEvent('b', DateTime(2026, 11, 1, 9), false),
        ],
      );
      expect(data.streak(DateTime(2026, 11, 1, 10)), 2);
      expect(data.streak(DateTime(2026, 11, 2, 10)), 2);
      expect(data.streak(DateTime(2026, 11, 3, 10)), 0);
    },
  );

  test(
    'Failed persistence does not change cards or history; retry works',
    () async {
      final disk = MemoryStorage();
      final store = StudyStore(disk, clock: () => now);
      await store.load();
      disk.fail = true;
      await expectLater(store.review('example-0', true), throwsStateError);
      expect(store.dueCards().length, 8);
      expect(store.data.events, isEmpty);
      disk.fail = false;
      await store.review('example-0', true);
      expect(store.dueCards().length, 7);
      expect(store.todayReviews, 1);
      final restored = StudyStore(disk, clock: () => now);
      await restored.load();
      expect(restored.dueCards().length, 7);
      expect(restored.data.streak(now), 1);
    },
  );

  test('Concurrent duplicate reviews record once', () async {
    final store = StudyStore(MemoryStorage(), clock: () => now);
    await store.load();
    final first = store.review('example-0', true);
    final second = store.review('example-0', false);
    await first;
    await expectLater(second, throwsStateError);
    expect(store.data.events.length, 1);
  });

  test('Reported cards stay out of study until edited', () async {
    final store = StudyStore(MemoryStorage(), clock: () => now);
    await store.load();
    await store.reportCard('example-0');
    expect(store.dueCards().length, 7);
    await store.editCard(
      'example-0',
      'Pregunta corregida',
      'Respuesta corregida',
    );
    expect(store.dueCards().length, 8);
  });

  test(
    'Invalid restore preserves current storage; export roundtrips',
    () async {
      final disk = MemoryStorage();
      final store = StudyStore(disk, clock: () => now);
      await store.load();
      final before = disk.value;
      await expectLater(
        store.importJson('{"version":99}'),
        throwsFormatException,
      );
      expect(disk.value, before);
      await store.importJson(store.exportJson());
      expect(store.totalCards, 8);
      final duplicate = jsonDecode(store.exportJson()) as Map<String, dynamic>;
      duplicate['decks'].add(duplicate['decks'][0]);
      await expectLater(
        store.importJson(jsonEncode(duplicate)),
        throwsFormatException,
      );
      expect(store.totalCards, 8);
    },
  );

  test('Local drafts use only provided notes, deduplicate and cap at twelve', () {
    final generator = CardGenerator();
    final cards = generator.local(
      'Modelo: representa los datos.\nModelo: representa los datos.\nVista: muestra la interfaz.',
    );
    expect(cards.length, 2);
    expect(cards.first.question, '¿Cómo se define Modelo?');
    expect(cards.first.answer, 'representa los datos.');
    expect(
      generator
          .local(
            List.generate(
              20,
              (i) => 'Concepto $i: definición del concepto $i',
            ).join('\n'),
          )
          .length,
      12,
    );
    expect(generator.local('hola'), isEmpty);
  });
}
