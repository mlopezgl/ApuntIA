import 'dart:convert';
import '../domain/models.dart';

class CardDraft {
  const CardDraft(this.question, this.answer);
  final String question, answer;
  StudyCard toCard(DateTime now) =>
      StudyCard(id: newId(), question: question, answer: answer, due: now);
}

/// Motor de IA: recibe el texto y la materia y devuelve el JSON crudo
/// `{"cards":[{"question":"…","answer":"…"}]}`. En la app es Gemini vía
/// Firebase AI Logic (ver `gemini.dart`); en las pruebas, una función falsa.
typedef CardEngine = Future<String?> Function(String text, String subject);

class CardGenerator {
  CardGenerator({this.engine});
  final CardEngine? engine;

  bool get aiAvailable => engine != null;

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

  Future<List<CardDraft>> ai(String text, String subject) async {
    final run = engine;
    if (run == null) {
      throw const FormatException('La IA todavía no está configurada.');
    }
    final String? raw;
    try {
      raw = await run(text, subject).timeout(const Duration(seconds: 60));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'La IA no está disponible. Revisa tu conexión o usa el modo sin conexión.',
      );
    }
    return parseCards(raw);
  }

  /// Valida la respuesta de la IA antes de mostrarla como borradores.
  static List<CardDraft> parseCards(String? raw) {
    try {
      final json = jsonDecode(raw ?? '') as Map<String, dynamic>;
      final cards = json['cards'] as List;
      if (cards.isEmpty) throw const FormatException('vacía');
      return cards.take(12).map((item) {
        final j = Map<String, dynamic>.from(item as Map);
        final q = (j['question'] as String).trim();
        final a = (j['answer'] as String).trim();
        if (q.isEmpty || q.length > 500 || a.isEmpty || a.length > 2000) {
          throw const FormatException('incompleta');
        }
        return CardDraft(q, a);
      }).toList();
    } catch (_) {
      throw const FormatException(
        'La IA devolvió una respuesta incompleta. Intenta de nuevo.',
      );
    }
  }
}
