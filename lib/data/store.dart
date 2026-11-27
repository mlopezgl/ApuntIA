import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'storage_native.dart';
import '../domain/models.dart';

abstract interface class StudyStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class DeviceStorage implements StudyStorage {
  final _device = PlatformStorage();
  @override
  Future<String?> read() => _device.read();
  @override
  Future<void> write(String value) => _device.write(value);
}

class StudyStore extends ChangeNotifier {
  StudyStore(this.storage, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final StudyStorage storage;
  final DateTime Function() clock;
  StudyData data = StudyData(decks: [], events: []);
  bool loaded = false;
  Future<void> _pending = Future.value();
  Future<void> load() async {
    final raw = await storage.read();
    // Surface invalid storage; never silently overwrite it.
    final next = raw == null
        ? StudyData.example(clock())
        : StudyData.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    if (raw == null) await storage.write(jsonEncode(next.toJson()));
    data = next;
    loaded = true;
    notifyListeners();
  }

  Future<void> _commit(void Function(StudyData) update) {
    final operation = _pending.then((_) async {
      final next = StudyData.fromJson(data.toJson());
      update(next);
      StudyData.fromJson(next.toJson());
      await storage.write(jsonEncode(next.toJson()));
      data = next;
      notifyListeners();
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }

  List<StudyCard> dueCards({String? deckId}) =>
      data.decks
          .where((d) => deckId == null || d.id == deckId)
          .expand((d) => d.cards)
          .where((c) => c.isDue(clock()))
          .toList()
        ..sort((a, b) => a.due.compareTo(b.due));
  int get todayReviews =>
      data.events.where((e) => dayKey(e.when) == dayKey(clock())).length;
  int get totalCards => data.decks.fold(0, (sum, d) => sum + d.cards.length);
  Future<void> addDeck(Deck deck) => _commit((d) => d.decks.insert(0, deck));
  Future<void> deleteDeck(String id) =>
      _commit((d) => d.decks.removeWhere((deck) => deck.id == id));
  Future<void> editCard(String id, String question, String answer) =>
      _commit((data) {
        for (final deck in data.decks) {
          final index = deck.cards.indexWhere((c) => c.id == id);
          if (index >= 0) {
            deck.cards[index] = deck.cards[index].copyWith(
              question: question,
              answer: answer,
              reported: false,
            );
          }
        }
      });
  Future<void> reportCard(String id) => _commit((data) {
    for (final deck in data.decks) {
      final index = deck.cards.indexWhere((c) => c.id == id);
      if (index >= 0) {
        deck.cards[index] = deck.cards[index].copyWith(reported: true);
      }
    }
  });
  Future<void> review(String id, bool easy) => _commit((data) {
    for (final deck in data.decks) {
      final index = deck.cards.indexWhere((c) => c.id == id);
      if (index >= 0) {
        final card = deck.cards[index];
        if (!card.isDue(clock())) {
          throw StateError('Esta tarjeta ya fue repasada o está pausada.');
        }
        final now = clock();
        deck.cards[index] = card.reviewed(easy: easy, now: now);
        data.events.add(ReviewEvent(id, now, easy));
        return;
      }
    }
    throw StateError('La tarjeta ya no existe.');
  });
  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(data.toJson());

  /// Sustituye todos los mazos y el historial (restauración o sincronización).
  Future<void> replaceAll(StudyData next) => _commit((d) {
    d.decks
      ..clear()
      ..addAll(next.decks);
    d.events
      ..clear()
      ..addAll(next.events);
  });

  Future<void> importJson(String raw) async {
    if (utf8.encode(raw).length > 5000000) {
      throw const FormatException('El respaldo supera 5 MB.');
    }
    final imported = StudyData.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
    await replaceAll(imported);
  }
}
