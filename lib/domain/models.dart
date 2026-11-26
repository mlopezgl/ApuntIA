import 'dart:math';

String dayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime calendarDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);
String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';

class StudyCard {
  const StudyCard({
    required this.id,
    required this.question,
    required this.answer,
    required this.due,
    this.stage = 0,
    this.reviews = 0,
    this.reported = false,
  });
  final String id, question, answer;
  final DateTime due;
  final int stage, reviews;
  final bool reported;
  bool isDue(DateTime now) => !reported && !due.isAfter(now);
  StudyCard copyWith({
    String? question,
    String? answer,
    DateTime? due,
    int? stage,
    int? reviews,
    bool? reported,
  }) => StudyCard(
    id: id,
    question: question ?? this.question,
    answer: answer ?? this.answer,
    due: due ?? this.due,
    stage: stage ?? this.stage,
    reviews: reviews ?? this.reviews,
    reported: reported ?? this.reported,
  );

  // A simple, explainable schedule; not an implementation of SM-2 or FSRS.
  StudyCard reviewed({required bool easy, required DateTime now}) {
    const days = [1, 3, 7, 14, 30, 60];
    final index = stage.clamp(0, days.length - 1);
    return copyWith(
      stage: easy ? min(index + 1, days.length - 1) : 0,
      reviews: reviews + 1,
      due: easy
          ? DateTime(
              now.year,
              now.month,
              now.day + days[index],
              now.hour,
              now.minute,
            )
          : now.add(const Duration(minutes: 10)),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'answer': answer,
    'due': due.toIso8601String(),
    'stage': stage,
    'reviews': reviews,
    'reported': reported,
  };
  factory StudyCard.fromJson(Map<String, dynamic> j) {
    final question = j['question'] as String;
    final answer = j['answer'] as String;
    final stage = j['stage'] as int;
    final reviews = j['reviews'] as int;
    if (question.trim().isEmpty ||
        question.length > 500 ||
        answer.trim().isEmpty ||
        answer.length > 2000 ||
        stage < 0 ||
        stage > 5 ||
        reviews < 0) {
      throw const FormatException('Tarjeta inválida.');
    }
    return StudyCard(
      id: j['id'] as String,
      question: question,
      answer: answer,
      due: DateTime.parse(j['due'] as String).toLocal(),
      stage: stage,
      reviews: reviews,
      reported: j['reported'] as bool,
    );
  }
}

class Deck {
  Deck({
    required this.id,
    required this.title,
    required this.subject,
    required this.created,
    required this.source,
    required this.origin,
    required this.cards,
  });
  final String id, title, subject, source, origin;
  final DateTime created;
  final List<StudyCard> cards;
  int dueCount(DateTime now) => cards.where((c) => c.isDue(now)).length;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'created': created.toIso8601String(),
    'source': source,
    'origin': origin,
    'cards': cards.map((c) => c.toJson()).toList(),
  };
  factory Deck.fromJson(Map<String, dynamic> j) {
    final cards = (j['cards'] as List)
        .map((c) => StudyCard.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();
    if (cards.isEmpty ||
        cards.length > 100 ||
        (j['title'] as String).trim().isEmpty ||
        (j['title'] as String).length > 80 ||
        (j['subject'] as String).length > 60 ||
        (j['source'] as String).length > 12000 ||
        cards.map((c) => c.id).toSet().length != cards.length) {
      throw const FormatException('Mazo inválido.');
    }
    return Deck(
      id: j['id'] as String,
      title: j['title'] as String,
      subject: j['subject'] as String,
      source: j['source'] as String,
      origin: j['origin'] as String,
      created: DateTime.parse(j['created'] as String).toLocal(),
      cards: cards,
    );
  }
}

class ReviewEvent {
  const ReviewEvent(this.cardId, this.when, this.easy);
  final String cardId;
  final DateTime when;
  final bool easy;
  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'when': when.toIso8601String(),
    'easy': easy,
  };
  factory ReviewEvent.fromJson(Map<String, dynamic> j) => ReviewEvent(
    j['cardId'] as String,
    DateTime.parse(j['when'] as String).toLocal(),
    j['easy'] as bool,
  );
}

class StudyData {
  StudyData({required this.decks, required this.events});
  final List<Deck> decks;
  final List<ReviewEvent> events;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'decks': decks.map((d) => d.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
  };
  factory StudyData.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1) {
      throw const FormatException('Versión de respaldo no compatible.');
    }
    final decks = (j['decks'] as List)
        .map((d) => Deck.fromJson(Map<String, dynamic>.from(d as Map)))
        .toList();
    final events = (j['events'] as List)
        .map((e) => ReviewEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final ids = decks.expand((d) => d.cards).map((c) => c.id).toList();
    if (decks.length > 200 ||
        events.length > 50000 ||
        decks.map((d) => d.id).toSet().length != decks.length ||
        ids.toSet().length != ids.length) {
      throw const FormatException('Respaldo inválido o demasiado grande.');
    }
    return StudyData(decks: decks, events: events);
  }
  int streak(DateTime now) {
    final dates = events
        .where((e) => !e.when.isAfter(now))
        .map((e) => calendarDay(e.when))
        .toSet();
    var day = calendarDay(now);
    if (!dates.contains(day)) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while (dates.contains(day)) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  factory StudyData.example(DateTime now) => StudyData(
    decks: [
      Deck(
        id: 'example-deck',
        title: 'Arquitectura de software',
        subject: 'Ingeniería de software',
        created: now,
        source: 'Mazo de ejemplo. Puedes editarlo o eliminarlo.',
        origin: 'Ejemplo',
        cards:
            [
                  (
                    '¿Qué separa MVVM de MVC?',
                    'MVVM incorpora un ViewModel que expone el estado y las acciones de la vista. MVC organiza la interacción mediante un controlador.',
                  ),
                  (
                    '¿Cuál es la responsabilidad del modelo?',
                    'Representar los datos y las reglas del dominio, independientemente de la interfaz.',
                  ),
                  (
                    '¿Qué hace la vista?',
                    'Muestra el estado al usuario y recoge sus interacciones.',
                  ),
                  (
                    '¿Qué es la separación de responsabilidades?',
                    'Asignar a cada componente una función definida para reducir el acoplamiento y facilitar mantenimiento y pruebas.',
                  ),
                  (
                    '¿Qué es una API?',
                    'Una interfaz que define cómo un componente puede comunicarse con otro.',
                  ),
                  (
                    '¿Para qué sirve la inyección de dependencias?',
                    'Para proporcionar a un objeto sus dependencias desde fuera y permitir sustituirlas, por ejemplo en pruebas.',
                  ),
                  (
                    '¿Qué es el estado de una aplicación?',
                    'La información que determina lo que la aplicación muestra y cómo responde en un momento dado.',
                  ),
                  (
                    '¿Qué valida una prueba unitaria?',
                    'El comportamiento de una unidad pequeña de lógica, normalmente aislada de servicios externos.',
                  ),
                ].indexed
                .map(
                  (entry) => StudyCard(
                    id: 'example-${entry.$1}',
                    question: entry.$2.$1,
                    answer: entry.$2.$2,
                    due: now,
                  ),
                )
                .toList(),
      ),
    ],
    events: [],
  );
}
