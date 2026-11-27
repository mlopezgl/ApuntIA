// Runnable without Flutter's network-based test runner:
// dart run tool/domain_check.dart
import 'dart:convert';
import 'dart:io';
import 'package:apuntia/domain/models.dart';
import 'package:apuntia/services/generator.dart';

void check(bool value, String description) {
  if (!value) throw StateError(description);
}

Future<void> main() async {
  final now = DateTime(2026, 11, 19, 10);
  final sample = StudyData.example(now);
  check(sample.decks.single.cards.length == 8, 'Example deck');
  var card = sample.decks.single.cards.first;
  for (final interval in [1, 3, 7, 14, 30, 60, 60]) {
    final start = card.due;
    card = card.reviewed(easy: true, now: start);
    check(
      calendarDay(card.due).difference(calendarDay(start)).inDays == interval,
      'Easy interval $interval',
    );
  }
  final hard = card.reviewed(easy: false, now: card.due);
  check(
    hard.stage == 0 && hard.due.difference(card.due).inMinutes == 10,
    'Hard reset',
  );
  check(!hard.isDue(card.due) && hard.isDue(hard.due), 'Due boundary');
  check(!hard.copyWith(reported: true).isDue(hard.due), 'Reported exclusion');
  final data = StudyData(
    decks: [],
    events: [
      ReviewEvent('1', DateTime(2026, 10, 31, 10), true),
      ReviewEvent('1', DateTime(2026, 11, 1, 10), true),
      ReviewEvent('2', DateTime(2026, 11, 1, 11), false),
    ],
  );
  check(data.streak(DateTime(2026, 11, 2, 12)) == 2, 'Streak across month');
  check(data.streak(DateTime(2026, 11, 3, 12)) == 0, 'Broken streak');
  check(
    StudyData.fromJson(
          jsonDecode(jsonEncode(sample.toJson())) as Map<String, dynamic>,
        ).decks.length ==
        1,
    'JSON roundtrip',
  );
  var rejected = false;
  try {
    StudyData.fromJson({'version': 2});
  } on FormatException {
    rejected = true;
  }
  check(rejected, 'Reject incompatible backup');
  final generator = CardGenerator();
  final drafts = generator.local(
    'Modelo: representa los datos.\nModelo: representa los datos.\nVista: muestra la interfaz.',
  );
  check(
    drafts.length == 2 && drafts.first.answer == 'representa los datos.',
    'Source-only local generation',
  );
  check(
    generator
            .local(
              List.generate(
                20,
                (i) => 'Concepto $i: definición del concepto $i',
              ).join('\n'),
            )
            .length ==
        12,
    'Draft cap',
  );
  check(generator.local('hola').isEmpty, 'Reject insufficient notes');
  var calls = 0;
  final remote = CardGenerator(
    engine: (text, subject) async {
      calls++;
      check(text.startsWith('Modelo') && subject == 'Software', 'Engine input');
      return jsonEncode({
        'cards': [
          {'question': '¿Qué es un modelo?', 'answer': 'Representa datos.'},
        ],
      });
    },
  );
  final generated = await remote.ai('Modelo: representa datos.', 'Software');
  check(
    calls == 1 && generated.single.question == '¿Qué es un modelo?',
    'AI response parsing',
  );
  var offlineRejected = false;
  try {
    await CardGenerator().ai('notes', 'subject');
  } on FormatException {
    offlineRejected = true;
  }
  check(offlineRejected, 'Reject AI when no engine is configured');
  var invalidRejected = false;
  try {
    await CardGenerator(engine: (_, _) async => '{"cards":[]}').ai('n', 's');
  } on FormatException {
    invalidRejected = true;
  }
  check(invalidRejected, 'Reject empty AI response');
  var failureHandled = false;
  try {
    await CardGenerator(
      engine: (_, _) async => throw StateError('offline'),
    ).ai('n', 's');
  } on FormatException {
    failureHandled = true;
  }
  check(failureHandled, 'Handle AI transport failure');
  final local = StudyData.example(DateTime(2026, 11, 19, 10));
  final remoteData = StudyData.fromJson(local.toJson());
  final merged = mergeStudyData(local, remoteData);
  check(
    merged.decks.length == local.decks.length &&
        merged.events.length == local.events.length,
    'Merge is idempotent',
  );
  stdout.writeln(
    'Domain checks passed: scheduling, due dates, reports, streak, JSON, local drafts, AI response validation, cloud merge.',
  );
}
