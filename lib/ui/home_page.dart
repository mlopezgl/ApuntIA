import 'package:flutter/material.dart';
import '../data/store.dart';
import 'deck_page.dart';
import 'review_page.dart';
import 'theme.dart';
import 'widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.store,
    required this.onCapture,
    required this.onLibrary,
  });
  final StudyStore store;
  final VoidCallback onCapture, onLibrary;
  @override
  Widget build(BuildContext context) {
    final pending = store.dueCards().length;
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final hero = ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        color: InkColors.navy,
        child: Stack(
          children: [
            Positioned(
              right: -90,
              top: -110,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  color: Color(0xFF262063),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(wide ? 34 : 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Tag(
                    'UN POCO CADA DÍA',
                    color: InkColors.orange,
                    background: Color(0xFF302A3E),
                    icon: Icons.auto_awesome_outlined,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Lo que viste en clase,\ncontigo.',
                    style: TextStyle(
                      fontSize: wide ? 43 : 34,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                      letterSpacing: -1.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Convierte tus apuntes en tarjetas.\nRepasa 10 minutos y sigue con tu día.',
                    style: TextStyle(
                      color: Color(0xFFC2C0DA),
                      fontSize: 16,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onCapture,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                    label: const Text('Nueva captura'),
                    style: FilledButton.styleFrom(
                      backgroundColor: InkColors.orange,
                      foregroundColor: InkColors.navy,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Tu foto se queda en tu teléfono.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFC2C0DA)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    final review = Panel(
      color: InkColors.lavender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: InkColors.purple),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'TU REPASO DE HOY',
                  style: TextStyle(
                    color: InkColors.purple,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '$pending',
            style: const TextStyle(
              fontSize: 66,
              height: 1.1,
              color: InkColors.purple,
              fontWeight: FontWeight.w800,
              letterSpacing: -3,
            ),
          ),
          Text(
            pending == 1 ? 'tarjeta te espera' : 'tarjetas te esperan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            pending == 0
                ? 'Todo al día. Vuelve más tarde o captura nuevos apuntes.'
                : 'No necesitas aprenderlo todo hoy.\nSolo dar el siguiente paso.',
            style: const TextStyle(color: InkColors.muted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: pending == 0 ? null : () => openReview(context, store),
              label: const Text('Repasar ahora'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MENOS ACUMULAR. MÁS RECORDAR.',
          style: TextStyle(
            color: InkColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: hero),
              const SizedBox(width: 22),
              Expanded(flex: 4, child: review),
            ],
          )
        else ...[
          hero,
          const SizedBox(height: 18),
          review,
        ],
        const SizedBox(height: 28),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _Metric(
              icon: Icons.local_fire_department_outlined,
              color: const Color(0xFFC37C14),
              value: '${store.data.streak(store.clock())}',
              label: 'días de racha',
            ),
            _Metric(
              icon: Icons.check_circle_outline,
              color: InkColors.green,
              value: '${store.todayReviews}',
              label: 'repasos hoy',
            ),
            _Metric(
              icon: Icons.style_outlined,
              color: InkColors.purple,
              value: '${store.totalCards}',
              label: 'tarjetas guardadas',
            ),
          ],
        ),
        const SizedBox(height: 32),
        SectionTitle(
          'Tus apuntes',
          trailing: TextButton(
            onPressed: onLibrary,
            child: const Text('Ver todos'),
          ),
        ),
        if (store.data.decks.isEmpty)
          EmptyMessage(
            title: 'Todo empieza con una idea',
            message:
                'Captura tus apuntes o escribe un concepto para crear tu primer mazo.',
            action: FilledButton(
              onPressed: onCapture,
              child: const Text('Crear mi primer mazo'),
            ),
          )
        else
          ...store.data.decks
              .take(3)
              .map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DeckTile(
                    deck: d,
                    now: store.clock(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => DeckPage(store: store, deckId: d.id),
                      ),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 20),
        const SectionTitle('De la foto a la memoria'),
        LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 680;
            final steps = [
              const _Step(
                number: '1',
                icon: Icons.photo_camera_outlined,
                title: 'Captura tus apuntes',
                description:
                    'El texto se lee en tu teléfono. También puedes escribirlo.',
              ),
              const _Step(
                number: '2',
                icon: Icons.auto_awesome_outlined,
                title: 'Crea tus tarjetas',
                description:
                    'Revisa las preguntas y respuestas. Tú tienes el control.',
              ),
              const _Step(
                number: '3',
                icon: Icons.psychology_outlined,
                title: 'Repasa a tu ritmo',
                description:
                    'Marca Fácil o Difícil. Tu próximo repaso queda agendado.',
              ),
            ];
            return horizontal
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: steps
                        .map(
                          (s) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: s,
                            ),
                          ),
                        )
                        .toList(),
                  )
                : Column(
                    children: steps
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: s,
                          ),
                        )
                        .toList(),
                  );
          },
        ),
        const SizedBox(height: 24),
        const InfoNote(
          'Captura y repaso sin conexión. La generación con IA requiere internet y tu autorización.',
          icon: Icons.wifi_off_outlined,
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value, label;
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(color: InkColors.muted, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });
  final String number, title, description;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 18,
        backgroundColor: InkColors.orange,
        child: Text(
          number,
          style: const TextStyle(
            color: InkColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 5),
            Text(
              description,
              style: const TextStyle(color: InkColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    ],
  );
}
