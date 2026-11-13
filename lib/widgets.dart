import 'package:flutter/material.dart';

import 'models.dart';

/// A single stat tile, e.g. "9,900 steps".
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: color ?? theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// One daily goal with a progress bar, e.g. "Steps — 9,900 / 10,000".
class GoalBar extends StatelessWidget {
  const GoalBar({
    super.key,
    required this.icon,
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int current;
  final int goal;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction =
        goal <= 0 ? 0.0 : (current / goal).clamp(0.0, 1.0);
    final reached = current >= goal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 6),
                  Text(label, style: theme.textTheme.bodyMedium),
                  if (reached) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check_circle,
                        size: 16, color: theme.colorScheme.primary),
                  ],
                ],
              ),
              Text(
                '${formatNumber(current)} / ${formatNumber(goal)} $unit',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Metric the 7-day chart can show.
enum ChartMetric { steps, calories, minutes }

extension ChartMetricLabel on ChartMetric {
  String get label {
    switch (this) {
      case ChartMetric.steps:
        return 'Steps';
      case ChartMetric.calories:
        return 'Calories';
      case ChartMetric.minutes:
        return 'Minutes';
    }
  }

  String get unit {
    switch (this) {
      case ChartMetric.steps:
        return 'steps';
      case ChartMetric.calories:
        return 'kcal';
      case ChartMetric.minutes:
        return 'min';
    }
  }
}

/// Simple 7-day bar chart built from plain widgets — no chart library.
///
/// [dailyTotals] must hold one [Totals] per day, oldest first, with
/// [days] the matching dates in the same order.
class WeekChart extends StatelessWidget {
  const WeekChart({
    super.key,
    required this.days,
    required this.dailyTotals,
    required this.metric,
  });

  final List<DateTime> days;
  final List<Totals> dailyTotals;
  final ChartMetric metric;

  static const List<String> _weekdayShort = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = dateOnly(DateTime.now());
    final values = <int>[
      for (final total in dailyTotals)
        switch (metric) {
          ChartMetric.steps => total.steps,
          ChartMetric.calories => total.calories,
          ChartMetric.minutes => total.minutes,
        },
    ];
    final maxValue = values.fold<int>(1, (a, b) => a > b ? a : b);

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: _ChartColumn(
                    value: values[i],
                    maxValue: maxValue,
                    label: formatNumber(values[i]),
                    dayLabel:
                        '${_weekdayShort[days[i].weekday - 1]}\n${days[i].day}/${days[i].month}',
                    isToday: dateOnly(days[i]) == today,
                    color: dateOnly(days[i]) == today
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Showing ${metric.unit} for the last 7 days. '
          'Highest day: ${formatNumber(maxValue)} ${metric.unit}.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ChartColumn extends StatelessWidget {
  const _ChartColumn({
    required this.value,
    required this.maxValue,
    required this.label,
    required this.dayLabel,
    required this.isToday,
    required this.color,
  });

  final int value;
  final int maxValue;
  final String label;
  final String dayLabel;
  final bool isToday;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Keep a visible sliver even for a zero day.
    final heightFraction =
        maxValue <= 0 ? 0.03 : (value / maxValue).clamp(0.03, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 130,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: 130 * heightFraction,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dayLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isToday
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
