import 'package:flutter/material.dart';

/// One logged fitness activity.
///
/// A single fitness log entry (date, exercise type, minutes,
/// steps, calories) so the two versions behave identically.
class FitnessLog {
  const FitnessLog({
    required this.id,
    required this.date,
    required this.type,
    required this.minutes,
    required this.steps,
    required this.calories,
  });

  final String id;

  /// Calendar date of the workout (time part is ignored).
  final DateTime date;
  final String type;
  final int minutes;
  final int steps;
  final int calories;

  FitnessLog copyWith({
    String? id,
    DateTime? date,
    String? type,
    int? minutes,
    int? steps,
    int? calories,
  }) {
    return FitnessLog(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      minutes: minutes ?? this.minutes,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'date': _dateKey(date),
        'type': type,
        'minutes': minutes,
        'steps': steps,
        'calories': calories,
      };

  factory FitnessLog.fromJson(Map<String, dynamic> json) {
    final parts = (json['date'] as String).split('-');
    return FitnessLog(
      id: json['id'] as String,
      date: DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      ),
      type: json['type'] as String,
      minutes: (json['minutes'] as num).toInt(),
      steps: (json['steps'] as num).toInt(),
      calories: (json['calories'] as num).toInt(),
    );
  }

  /// 'yyyy-MM-dd' key, used for storage and for date comparisons.
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get dateKey => _dateKey(date);
}

/// Summed totals over a set of logs.
class Totals {
  const Totals({
    this.steps = 0,
    this.calories = 0,
    this.minutes = 0,
    this.workouts = 0,
  });

  final int steps;
  final int calories;
  final int minutes;
  final int workouts;

  Totals operator +(Totals other) => Totals(
        steps: steps + other.steps,
        calories: calories + other.calories,
        minutes: minutes + other.minutes,
        workouts: workouts + other.workouts,
      );

  static Totals sum(Iterable<FitnessLog> logs) {
    var total = const Totals();
    for (final log in logs) {
      total += Totals(
        steps: log.steps,
        calories: log.calories,
        minutes: log.minutes,
        workouts: 1,
      );
    }
    return total;
  }
}

/// Daily goals.
class DailyGoals {
  const DailyGoals._();

  static const int steps = 10000;
  static const int calories = 500;
  static const int minutes = 60;
}

/// Exercise types offered in the log form.
const List<String> exerciseTypes = <String>[
  'Walking',
  'Running',
  'Cycling',
  'Gym / Strength',
  'Yoga',
  'Swimming',
  'Dance',
  'Sports',
  'Other',
];

/// Icon shown for each exercise type in the history list.
IconData exerciseIcon(String type) {
  switch (type) {
    case 'Walking':
      return Icons.directions_walk;
    case 'Running':
      return Icons.directions_run;
    case 'Cycling':
      return Icons.directions_bike;
    case 'Gym / Strength':
      return Icons.fitness_center;
    case 'Yoga':
      return Icons.self_improvement;
    case 'Swimming':
      return Icons.pool;
    case 'Dance':
      return Icons.music_note;
    case 'Sports':
      return Icons.sports_soccer;
    default:
      return Icons.fitness_center;
  }
}

/// Format an integer with thousands separators, e.g. 9900 -> "9,900".
String formatNumber(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return value < 0 ? '-${buffer.toString()}' : buffer.toString();
}

/// Monday of the week containing [date].
DateTime weekStart(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  // DateTime.weekday: Monday = 1 ... Sunday = 7.
  return day.subtract(Duration(days: day.weekday - 1));
}

/// The date only (midnight), for day-level comparisons.
DateTime dateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);
