// Runnable without Flutter's network-based test runner:
// dart run tool/domain_check.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
  var requests = 0;
  final client = MockClient((request) async {
    requests++;
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    check(
      body['consent'] == true && !body.containsKey('photo'),
      'Text-only authorized request',
    );
    check(
      request.headers['Authorization'] == 'Bearer test-access-token',
      'Runtime access token',
    );
    return http.Response(
      jsonEncode({
        'cards': [
          {'question': '¿Qué es un modelo?', 'answer': 'Representa datos.'},
        ],
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
  final remote = CardGenerator(apiEndpoint: 'https://example.test/cards');
  final generated = await remote.ai(
    'Modelo: representa datos.',
    'Software',
    accessToken: 'test-access-token',
    client: client,
  );
  check(
    requests == 1 && generated.single.question == '¿Qué es un modelo?',
    'AI response parsing',
  );
  var insecureRejected = false;
  try {
    await CardGenerator(
      apiEndpoint: 'http://example.test/cards',
    ).ai('notes', 'subject', accessToken: 'token', client: client);
  } on FormatException {
    insecureRejected = true;
  }
  check(
    insecureRejected && requests == 1,
    'Reject insecure endpoint before sending',
  );
  var unauthorizedRejected = false;
  final unauthorized = MockClient((_) async => http.Response('{}', 401));
  try {
    await remote.ai(
      'notes',
      'subject',
      accessToken: 'wrong',
      client: unauthorized,
    );
  } on FormatException {
    unauthorizedRejected = true;
  }
  check(unauthorizedRejected, 'Handle rejected access code');
  client.close();
  unauthorized.close();
  stdout.writeln(
    'Domain checks passed: scheduling, due dates, reports, streak, JSON, local drafts, AI transport validation.',
  );
}
