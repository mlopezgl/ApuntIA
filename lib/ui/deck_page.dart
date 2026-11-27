import 'package:flutter/material.dart';
import '../data/store.dart';
import '../services/generator.dart';
import 'card_editor.dart';
import 'review_page.dart';
import 'theme.dart';
import 'widgets.dart';

class DeckPage extends StatelessWidget {
  const DeckPage({super.key, required this.store, required this.deckId});
  final StudyStore store;
  final String deckId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final deck = store.data.decks.where((d) => d.id == deckId).firstOrNull;
      if (deck == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Este mazo ya no existe.')),
        );
      }
      final due = deck.dueCount(store.clock());
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis apuntes'),
          actions: [
            IconButton(
              tooltip: 'Eliminar mazo',
              onPressed: () async {
                final yes = await confirm(
                  context,
                  title: '¿Eliminar este mazo?',
                  message:
                      'Se eliminarán «${deck.title}» y sus tarjetas de este dispositivo. El historial de repasos se conserva.',
                );
                if (yes && context.mounted) {
                  try {
                    await store.deleteDeck(deck.id);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) showError(context, e);
                  }
                }
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Tag(deck.subject),
                        Tag(
                          deck.origin,
                          color: InkColors.muted,
                          background: InkColors.line,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      deck.title,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${deck.cards.length} tarjetas · $due para repasar ahora',
                      style: const TextStyle(color: InkColors.muted),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: due == 0
                          ? null
                          : () => openReview(context, store, deckId: deckId),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Repasar este mazo'),
                    ),
                    const SizedBox(height: 24),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Ver texto original'),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            deck.source,
                            style: const TextStyle(color: InkColors.muted),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const SectionTitle('Preguntas y respuestas'),
                    ...deck.cards.map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Panel(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      card.reported
                                          ? 'Pausada · corrige para reactivar'
                                          : card.isDue(store.clock())
                                          ? 'Lista para repasar'
                                          : 'Próximo: ${dueLabel(card.due, context)}',
                                      style: TextStyle(
                                        color: card.reported
                                            ? const Color(0xFFAE4C2B)
                                            : InkColors.purple,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Editar tarjeta',
                                    onPressed: () async {
                                      final edited = await editDraft(
                                        context,
                                        CardDraft(card.question, card.answer),
                                      );
                                      if (edited != null) {
                                        try {
                                          await store.editCard(
                                            card.id,
                                            edited.question,
                                            edited.answer,
                                          );
                                        } catch (e) {
                                          if (context.mounted) {
                                            showError(context, e);
                                          }
                                        }
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Reportar error y pausar',
                                    onPressed: card.reported
                                        ? null
                                        : () async {
                                            final yes = await confirm(
                                              context,
                                              title:
                                                  '¿Hay un error en esta tarjeta?',
                                              message:
                                                  'La marcaremos para revisión en este dispositivo y la quitaremos de tus repasos hasta que la edites. No se enviará ningún reporte.',
                                              action: 'Marcar y pausar',
                                            );
                                            if (yes) {
                                              try {
                                                await store.reportCard(card.id);
                                              } catch (e) {
                                                if (context.mounted) {
                                                  showError(context, e);
                                                }
                                              }
                                            }
                                          },
                                    icon: const Icon(
                                      Icons.flag_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                card.question,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                card.answer,
                                style: const TextStyle(color: InkColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

String dueLabel(DateTime d, BuildContext context) =>
    '${MaterialLocalizations.of(context).formatShortDate(d)} · ${TimeOfDay.fromDateTime(d).format(context)}';
