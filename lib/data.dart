import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Storage key for the log list.
/// Storage key for the saved logs (`codealpha_fitness_logs_v1`).
const String _storageKey = 'codealpha_fitness_logs_v1';

/// The 8 sample logs seeded on first run, relative to
/// "today" so the dashboard and the 7-day chart are never empty:
///   today:      Running 30 min / 6,500 steps / 320 kcal
///   today:      Walking 20 min / 3,400 steps / 140 kcal
///   yesterday:  Gym / Strength 45 min / 4,200 steps / 380 kcal
///   2 days ago: Cycling 40 min / 2,800 steps / 410 kcal
///   3 days ago: Yoga 25 min / 1,800 steps / 120 kcal
///   4 days ago: Running 35 min / 7,200 steps / 360 kcal
///   5 days ago: Walking 30 min / 8,100 steps / 260 kcal
///   6 days ago: Swimming 30 min / 1,500 steps / 300 kcal
List<FitnessLog> seedLogs() {
  final today = dateOnly(DateTime.now());
  final rows = <(int, String, int, int, int)>[
    (0, 'Running', 30, 6500, 320),
    (0, 'Walking', 20, 3400, 140),
    (-1, 'Gym / Strength', 45, 4200, 380),
    (-2, 'Cycling', 40, 2800, 410),
    (-3, 'Yoga', 25, 1800, 120),
    (-4, 'Running', 35, 7200, 360),
    (-5, 'Walking', 30, 8100, 260),
    (-6, 'Swimming', 30, 1500, 300),
  ];
  return <FitnessLog>[
    for (var i = 0; i < rows.length; i++)
      FitnessLog(
        id: 'seed-${i + 1}',
        date: today.add(Duration(days: rows[i].$1)),
        type: rows[i].$2,
        minutes: rows[i].$3,
        steps: rows[i].$4,
        calories: rows[i].$5,
      ),
  ];
}

/// Loads and saves logs with shared_preferences.
class FitnessRepository {
  const FitnessRepository();

  /// Returns the stored logs. On first run (nothing stored) the 8
  /// sample logs are seeded and saved.
  Future<List<FitnessLog>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      final seeded = seedLogs();
      await saveLogs(seeded);
      return seeded;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => FitnessLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt stored data: fall back to the sample logs.
      final seeded = seedLogs();
      await saveLogs(seeded);
      return seeded;
    }
  }

  Future<void> saveLogs(List<FitnessLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(logs.map((log) => log.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  /// Replace all logs with the sample data.
  Future<List<FitnessLog>> resetSampleData() async {
    final seeded = seedLogs();
    await saveLogs(seeded);
    return seeded;
  }

  /// Delete every log.
  Future<List<FitnessLog>> clearAll() async {
    await saveLogs(<FitnessLog>[]);
    return <FitnessLog>[];
  }
}
