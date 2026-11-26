import 'package:flutter/material.dart';
import '../data/store.dart';
import 'deck_page.dart';
import 'theme.dart';
import 'widgets.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.store, required this.onCapture});
  final StudyStore store;
  final VoidCallback onCapture;
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String query = '';
  bool pendingOnly = false;
  @override
  Widget build(BuildContext context) {
    final decks = widget.store.data.decks
        .where(
          (d) =>
              '${d.title} ${d.subject}'.toLowerCase().contains(
                query.toLowerCase(),
              ) &&
              (!pendingOnly || d.dueCount(widget.store.clock()) > 0),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tus ideas, organizadas.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        const Text(
          'Un mazo por tema. Un pequeño repaso cada día.',
          style: TextStyle(color: InkColors.muted),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: widget.onCapture,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nuevo mazo'),
        ),
        const SizedBox(height: 22),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Buscar tema o materia',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        FilterChip(
          selected: pendingOnly,
          onSelected: (v) => setState(() => pendingOnly = v),
          label: const Text('Con repasos pendientes'),
        ),
        const SizedBox(height: 22),
        if (decks.isEmpty)
          const EmptyMessage(
            title: 'No hay mazos aquí todavía',
            message: 'Crea uno nuevo o cambia tu búsqueda.',
          )
        else
          ...decks.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DeckTile(
                deck: d,
                now: widget.store.clock(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DeckPage(store: widget.store, deckId: d.id),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
