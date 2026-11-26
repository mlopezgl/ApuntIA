import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/store.dart';
import '../domain/models.dart';
import 'theme.dart';
import 'widgets.dart';

void openReview(BuildContext context, StudyStore store, {String? deckId}) {
  final cards = store.dueCards(deckId: deckId);
  if (cards.isEmpty) return;
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ReviewPage(store: store, cards: cards),
    ),
  );
}

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.store, required this.cards});
  final StudyStore store;
  final List<StudyCard> cards;
  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> with WidgetsBindingObserver {
  int index = 0, easyCount = 0, hardCount = 0;
  bool revealed = false, busy = false;
  final watch = Stopwatch();
  Timer? ticker;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    watch.start();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && index < widget.cards.length) {
      watch.start();
    } else {
      watch.stop();
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    watch.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> rate(bool easy) async {
    if (busy || !revealed) return;
    setState(() => busy = true);
    try {
      await widget.store.review(widget.cards[index].id, easy);
      if (mounted) {
        setState(() {
          easy ? easyCount++ : hardCount++;
          index++;
          revealed = false;
          if (index == widget.cards.length) {
            watch.stop();
            ticker?.cancel();
          }
        });
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finished = index >= widget.cards.length;
    final left = max(0, 600 - watch.elapsed.inSeconds);
    final minutes = left ~/ 60;
    final seconds = (left % 60).toString().padLeft(2, '0');
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tu momento de repaso'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Tag(
                  left == 0 ? 'Meta cumplida' : '$minutes:$seconds',
                  icon: Icons.timer_outlined,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: finished
                  ? _summary(context)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tarjeta ${index + 1} de ${widget.cards.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '$index completadas',
                              style: const TextStyle(
                                color: InkColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: index / widget.cards.length,
                            minHeight: 8,
                            backgroundColor: InkColors.line,
                            color: InkColors.purple,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Semantics(
                          button: !revealed,
                          label: revealed ? 'Respuesta' : 'Mostrar respuesta',
                          child: Material(
                            color: InkColors.lavender,
                            borderRadius: BorderRadius.circular(28),
                            child: InkWell(
                              onTap: revealed
                                  ? null
                                  : () => setState(() => revealed = true),
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(
                                  minHeight: 370,
                                ),
                                padding: const EdgeInsets.all(30),
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 180),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Tag(
                                        revealed ? 'RESPUESTA' : 'PREGUNTA',
                                        background: Colors.white.withValues(
                                          alpha: .65,
                                        ),
                                        icon: revealed
                                            ? Icons.lightbulb_outline
                                            : Icons.psychology_outlined,
                                      ),
                                      const SizedBox(height: 28),
                                      Text(
                                        widget.cards[index].question,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineMedium,
                                      ),
                                      const SizedBox(height: 24),
                                      if (revealed) ...[
                                        const Divider(),
                                        const SizedBox(height: 16),
                                        Text(
                                          widget.cards[index].answer,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            height: 1.6,
                                          ),
                                        ),
                                      ] else
                                        const Text(
                                          'Piensa en la respuesta.\nDespués, toca la tarjeta para comprobarla.',
                                          style: TextStyle(
                                            color: InkColors.muted,
                                            height: 1.6,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!revealed)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => setState(() => revealed = true),
                              child: const Text('Ver respuesta'),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFE3D7),
                                    foregroundColor: const Color(0xFFA13C17),
                                  ),
                                  onPressed: busy ? null : () => rate(false),
                                  icon: const Icon(Icons.replay_rounded),
                                  label: const Text('Difícil'),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: busy ? null : () => rate(true),
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text('Fácil'),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 18),
                        const InfoNote(
                          'Difícil: otro repaso en 10 minutos. Fácil: ampliamos el intervalo. Puedes salir cuando quieras; cada valoración se guarda.',
                          icon: Icons.schedule_outlined,
                        ),
                        if (busy) ...[
                          const SizedBox(height: 16),
                          const LinearProgressIndicator(),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(BuildContext context) => Column(
    children: [
      const SizedBox(height: 38),
      Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: InkColors.lavender,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.task_alt_rounded,
          color: InkColors.purple,
          size: 62,
        ),
      ),
      const SizedBox(height: 28),
      Text(
        'Un paso más.\nBien recordado.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 16),
      Text(
        'Repasaste ${easyCount + hardCount} tarjetas en ${watch.elapsed.inMinutes} min ${watch.elapsed.inSeconds % 60} s.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: InkColors.muted),
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          Tag('$easyCount fáciles'),
          Tag(
            '$hardCount difíciles',
            color: const Color(0xFFA13C17),
            background: const Color(0xFFFFE3D7),
          ),
        ],
      ),
      const SizedBox(height: 26),
      const Text(
        'Tus próximos repasos ya están programados.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Volver a mis apuntes'),
      ),
    ],
  );
}
