import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models.dart';

class CardDraft {
  const CardDraft(this.question, this.answer);
  final String question, answer;
  StudyCard toCard(DateTime now) =>
      StudyCard(id: newId(), question: question, answer: answer, due: now);
}

class CardGenerator {
  CardGenerator({String? apiEndpoint}) : _apiEndpoint = apiEndpoint ?? endpoint;
  final String _apiEndpoint;
  static const endpoint = String.fromEnvironment('AI_ENDPOINT');
  static bool _validEndpoint(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty;
  }

  static bool get aiAvailable => _validEndpoint(endpoint);

  // Local templates extract source verbatim. This method does not use AI.
  List<CardDraft> local(String text) {
    final lines = text
        .split(RegExp(r'\n+|(?<=[.!?])\s+'))
        .map((s) => s.replaceFirst(RegExp(r'^\s*[-•*]\s*'), '').trim())
        .where((s) => s.length >= 12)
        .toSet();
    return lines.take(12).indexed.map((entry) {
      final line = entry.$2;
      final colon = line.indexOf(':');
      if (colon > 1 && colon < 90 && colon < line.length - 5) {
        final answer = line.substring(colon + 1).trim();
        return CardDraft(
          '¿Cómo se define ${line.substring(0, colon).trim()}?',
          answer.substring(0, answer.length.clamp(0, 2000)),
        );
      }
      return CardDraft(
        'Explica la idea ${entry.$1 + 1} de tus apuntes.',
        line.substring(0, line.length.clamp(0, 2000)),
      );
    }).toList();
  }

  Future<List<CardDraft>> ai(
    String text,
    String subject, {
    required String accessToken,
    http.Client? client,
  }) async {
    if (!_validEndpoint(_apiEndpoint)) {
      throw const FormatException('La IA todavía no está configurada.');
    }
    final ownClient = client == null;
    final transport = client ?? http.Client();
    try {
      final response = await transport
          .post(
            Uri.parse(_apiEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'text': text,
              'subject': subject,
              'consent': true,
            }),
          )
          .timeout(const Duration(seconds: 55));
      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          throw const FormatException(
            'El código de acceso a la IA no es correcto.',
          );
        }
        throw const FormatException(
          'La IA no está disponible. Intenta de nuevo o usa el modo sin conexión.',
        );
      }
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final cards = json['cards'] as List;
      if (cards.isEmpty || cards.length > 12) {
        throw const FormatException('Respuesta de IA inválida.');
      }
      return cards.map((item) {
        final j = Map<String, dynamic>.from(item as Map);
        final q = (j['question'] as String).trim();
        final a = (j['answer'] as String).trim();
        if (q.isEmpty || q.length > 500 || a.isEmpty || a.length > 2000) {
          throw const FormatException('La IA devolvió una tarjeta incompleta.');
        }
        return CardDraft(q, a);
      }).toList();
    } finally {
      if (ownClient) transport.close();
    }
  }
}
