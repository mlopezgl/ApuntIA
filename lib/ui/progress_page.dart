import 'dart:math';
import 'package:flutter/material.dart';
import '../data/store.dart';
import '../domain/models.dart';
import 'theme.dart';
import 'widgets.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, required this.store});
  final StudyStore store;
  @override
  Widget build(BuildContext context) {
    final now = store.clock();
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - 6 + i),
    );
    final counts = days
        .map(
          (d) => store.data.events
              .where((e) => dayKey(e.when) == dayKey(d))
              .length,
        )
        .toList();
    final total = counts.fold(0, (a, b) => a + b);
    final easy = store.data.events.where((e) => e.easy).length;
    final all = store.data.events.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cada repaso cuenta.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        const Text(
          'La constancia se construye de a poco.',
          style: TextStyle(color: InkColors.muted),
        ),
        const SizedBox(height: 28),
        Panel(
          color: InkColors.navy,
          child: Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: InkColors.orange,
                size: 48,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${store.data.streak(now)} días de racha',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Un día cuenta cuando repasas al menos una tarjeta.',
                      style: TextStyle(color: Color(0xFFC2C0DA)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Últimos 7 días'),
              Text(
                '$total repasos esta semana',
                style: const TextStyle(color: InkColors.muted),
              ),
              const SizedBox(height: 24),
              WeekChart(days: days, counts: counts),
            ],
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, c) {
            final children = [
              _ProgressStat(
                '${store.todayReviews}',
                'repasos hoy',
                Icons.check_circle_outline,
              ),
              _ProgressStat('$all', 'repasos en total', Icons.history_rounded),
              _ProgressStat(
                all == 0 ? '—' : '${(100 * easy / all).round()}%',
                'marcados como Fácil',
                Icons.thumb_up_outlined,
              ),
            ];
            return c.maxWidth >= 700
                ? Row(
                    children: children
                        .map(
                          (w) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: w,
                            ),
                          ),
                        )
                        .toList(),
                  )
                : Column(
                    children: children
                        .map(
                          (w) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: w,
                          ),
                        )
                        .toList(),
                  );
          },
        ),
        const SizedBox(height: 16),
        const InfoNote(
          'Fácil: vuelve en 1, 3, 7, 14, 30 y hasta 60 días. Difícil: vuelve en 10 minutos. Los intervalos dependen de tus respuestas.',
          icon: Icons.schedule_outlined,
        ),
        const SizedBox(height: 14),
        const InfoNote(
          'Los porcentajes reflejan tus valoraciones, no una medición de aprendizaje. La racha usa la fecha local de tu dispositivo.',
          icon: Icons.insights_outlined,
        ),
      ],
    );
  }
}

class WeekChart extends StatelessWidget {
  const WeekChart({super.key, required this.days, required this.counts});
  final List<DateTime> days;
  final List<int> counts;
  @override
  Widget build(BuildContext context) {
    final peak = max(1, counts.reduce(max));
    const names = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return SizedBox(
      height: 192,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          7,
          (i) => Expanded(
            child: Semantics(
              label: '${days[i].day}/${days[i].month}: ${counts[i]} repasos',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${counts[i]}',
                      style: const TextStyle(
                        color: InkColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: max(6, 122.0 * counts[i] / peak),
                      constraints: const BoxConstraints(maxWidth: 45),
                      decoration: BoxDecoration(
                        color: i == 6
                            ? InkColors.purple
                            : const Color(0xFFC7BCFF),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      names[days[i].weekday - 1],
                      style: TextStyle(
                        color: i == 6 ? InkColors.purple : InkColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat(this.value, this.label, this.icon);
  final String value, label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Panel(
    child: Row(
      children: [
        Icon(icon, color: InkColors.purple),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, style: const TextStyle(color: InkColors.muted)),
            ],
          ),
        ),
      ],
    ),
  );
}
