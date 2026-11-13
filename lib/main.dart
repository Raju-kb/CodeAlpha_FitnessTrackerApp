import 'package:flutter/material.dart';

import 'data.dart';
import 'models.dart';
import 'widgets.dart';

void main() {
  runApp(const FitnessTrackerApp());
}

/// FitTrack — Fitness Tracker App.
/// CodeAlpha App Development Internship, Task 3.
class FitnessTrackerApp extends StatelessWidget {
  const FitnessTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack — Fitness Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16A34A),
          brightness: Brightness.light,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FitnessRepository _repository = const FitnessRepository();

  List<FitnessLog> _logs = <FitnessLog>[];
  bool _loading = true;
  ChartMetric _chartMetric = ChartMetric.steps;

  // Log form state.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  DateTime _selectedDate = dateOnly(DateTime.now());
  String _selectedType = exerciseTypes.first;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _stepsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final logs = await _repository.loadLogs();
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  Future<void> _persist(List<FitnessLog> logs) async {
    await _repository.saveLogs(logs);
    if (!mounted) return;
    setState(() => _logs = logs);
  }

  // ---- Derived data ----

  Totals get _todayTotals {
    final today = dateOnly(DateTime.now());
    return Totals.sum(_logs.where((l) => dateOnly(l.date) == today));
  }

  Totals get _weekTotals {
    final start = weekStart(DateTime.now());
    final end = start.add(const Duration(days: 6));
    return Totals.sum(_logs.where((l) {
      final d = dateOnly(l.date);
      return !d.isBefore(start) && !d.isAfter(end);
    }));
  }

  /// Last 7 days, oldest first, with one [Totals] per day.
  (List<DateTime>, List<Totals>) get _last7Days {
    final today = dateOnly(DateTime.now());
    final days = <DateTime>[
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final totals = <Totals>[
      for (final day in days)
        Totals.sum(_logs.where((l) => dateOnly(l.date) == day)),
    ];
    return (days, totals);
  }

  List<FitnessLog> get _sortedLogs {
    final sorted = List<FitnessLog>.from(_logs);
    sorted.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.id.compareTo(a.id);
    });
    return sorted;
  }

  // ---- Form actions ----

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = dateOnly(picked));
    }
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final entry = FitnessLog(
      id: _editingId ?? 'log-${DateTime.now().millisecondsSinceEpoch}',
      date: _selectedDate,
      type: _selectedType,
      minutes: int.parse(_minutesController.text),
      steps: int.parse(_stepsController.text),
      calories: int.parse(_caloriesController.text),
    );

    final updated = List<FitnessLog>.from(_logs);
    final wasEditing = _editingId != null;
    if (_editingId != null) {
      final index = updated.indexWhere((l) => l.id == _editingId);
      if (index >= 0) updated[index] = entry;
    } else {
      updated.add(entry);
    }
    await _persist(updated);
    _resetForm();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasEditing ? 'Log updated.' : 'Log saved.'),
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _minutesController.clear();
    _stepsController.clear();
    _caloriesController.clear();
    setState(() {
      _editingId = null;
      _selectedDate = dateOnly(DateTime.now());
      _selectedType = exerciseTypes.first;
    });
  }

  void _startEdit(FitnessLog log) {
    setState(() {
      _editingId = log.id;
      _selectedDate = dateOnly(log.date);
      _selectedType = exerciseTypes.contains(log.type)
          ? log.type
          : exerciseTypes.first;
      _minutesController.text = log.minutes.toString();
      _stepsController.text = log.steps.toString();
      _caloriesController.text = log.calories.toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editing log — change it and tap Update log.')),
    );
  }

  Future<void> _deleteLog(FitnessLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this log?'),
        content: Text('${log.type} on ${_formatDate(log.date)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final updated =
        _logs.where((l) => l.id != log.id).toList();
    await _persist(updated);
  }

  Future<void> _resetSampleData() async {
    final confirmed = await _confirm(
      'Reset sample data?',
      'Your current logs will be replaced with the sample logs.',
    );
    if (confirmed != true) return;
    final seeded = await _repository.resetSampleData();
    if (!mounted) return;
    setState(() => _logs = seeded);
  }

  Future<void> _clearAll() async {
    final confirmed = await _confirm(
      'Delete ALL logs?',
      'This removes every log, including the sample data.',
    );
    if (confirmed != true) return;
    final cleared = await _repository.clearAll();
    if (!mounted) return;
    setState(() => _logs = cleared);
  }

  Future<bool?> _confirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = <String>[
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} '
        '${months[date.month - 1]} ${date.year}';
  }

  String? _validateInt(String? value, String name, int min, int max) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $name';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a whole number';
    if (parsed < min || parsed > max) {
      return '$name must be $min–$max';
    }
    return null;
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('FitTrack')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final today = _todayTotals;
    final week = _weekTotals;
    final (chartDays, chartTotals) = _last7Days;
    final weekStartDate = weekStart(DateTime.now());
    final weekEndDate = weekStartDate.add(const Duration(days: 6));
    final goalsReached = <bool>[
      today.steps >= DailyGoals.steps,
      today.calories >= DailyGoals.calories,
      today.minutes >= DailyGoals.minutes,
    ].where((reached) => reached).length;
    final goalMessage = goalsReached == 3
        ? 'All 3 daily goals reached — great work!'
        : goalsReached == 0
            ? 'Keep going — every step counts.'
            : '$goalsReached of 3 daily goals reached.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitTrack — Fitness Tracker'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Today's summary
            _sectionTitle(context, "Today's summary",
                _formatDate(DateTime.now())),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                StatCard(
                  icon: Icons.directions_walk,
                  value: formatNumber(today.steps),
                  label: 'steps',
                  color: Colors.green,
                ),
                StatCard(
                  icon: Icons.local_fire_department,
                  value: formatNumber(today.calories),
                  label: 'calories burned',
                  color: Colors.orange,
                ),
                StatCard(
                  icon: Icons.timer,
                  value: formatNumber(today.minutes),
                  label: 'active minutes',
                  color: Colors.blue,
                ),
                StatCard(
                  icon: Icons.fitness_center,
                  value: today.workouts.toString(),
                  label: 'workouts',
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Daily goals
            _sectionTitle(context, 'Daily goals',
                'Goals reset every day.'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GoalBar(
                      icon: Icons.directions_walk,
                      label: 'Steps',
                      current: today.steps,
                      goal: DailyGoals.steps,
                      unit: 'steps',
                      color: Colors.green,
                    ),
                    GoalBar(
                      icon: Icons.local_fire_department,
                      label: 'Calories',
                      current: today.calories,
                      goal: DailyGoals.calories,
                      unit: 'kcal',
                      color: Colors.orange,
                    ),
                    GoalBar(
                      icon: Icons.timer,
                      label: 'Active minutes',
                      current: today.minutes,
                      goal: DailyGoals.minutes,
                      unit: 'min',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 6),
                    Text(goalMessage,
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // This week
            _sectionTitle(
              context,
              'This week',
              'Monday ${_formatDate(weekStartDate)} to Sunday '
              '${_formatDate(weekEndDate)}, computed from your logs.',
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _weekStat(context, 'Steps',
                            formatNumber(week.steps)),
                        _weekStat(context, 'Calories',
                            formatNumber(week.calories)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _weekStat(context, 'Active minutes',
                            formatNumber(week.minutes)),
                        _weekStat(context, 'Workouts',
                            week.workouts.toString()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Daily average: '
                      '${formatNumber((week.steps / 7).round())} steps / day',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 7-day chart
            _sectionTitle(context, 'Last 7 days',
                'Tap a metric to switch the chart.'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SegmentedButton<ChartMetric>(
                      segments: <ButtonSegment<ChartMetric>>[
                        for (final metric in ChartMetric.values)
                          ButtonSegment<ChartMetric>(
                            value: metric,
                            label: Text(metric.label),
                          ),
                      ],
                      selected: <ChartMetric>{_chartMetric},
                      onSelectionChanged:
                          (Set<ChartMetric> selected) {
                        setState(() => _chartMetric = selected.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    WeekChart(
                      days: chartDays,
                      dailyTotals: chartTotals,
                      metric: _chartMetric,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Log form
            _sectionTitle(context, 'Log fitness data',
                'Add a workout manually. It is saved on this device.'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Date'),
                        subtitle: Text(_formatDate(_selectedDate)),
                        trailing: TextButton(
                          onPressed: _pickDate,
                          child: const Text('Change'),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Exercise type',
                          border: OutlineInputBorder(),
                        ),
                        items: <DropdownMenuItem<String>>[
                          for (final type in exerciseTypes)
                            DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _minutesController,
                        decoration: const InputDecoration(
                          labelText: 'Workout time (minutes)',
                          hintText: 'e.g. 30',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateInt(
                            value, 'minutes', 1, 1440),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _stepsController,
                        decoration: const InputDecoration(
                          labelText: 'Steps',
                          hintText: 'e.g. 6500',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            _validateInt(value, 'steps', 0, 100000),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _caloriesController,
                        decoration: const InputDecoration(
                          labelText: 'Calories burned (kcal)',
                          hintText: 'e.g. 320',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => _validateInt(
                            value, 'calories', 0, 10000),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _submitForm,
                        child: Text(_editingId == null
                            ? 'Save log'
                            : 'Update log'),
                      ),
                      if (_editingId != null) ...[
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _resetForm,
                          child: const Text('Cancel edit'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: _resetSampleData,
                            child: const Text('Reset sample data'),
                          ),
                          OutlinedButton(
                            onPressed: _clearAll,
                            child: const Text('Clear all logs'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // History
            _sectionTitle(context, 'Activity history',
                'Newest first. Edit loads a log back into the form.'),
            Card(
              child: _sortedLogs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No logs yet. Add your first workout above.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sortedLogs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final log = _sortedLogs[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Icon(exerciseIcon(log.type)),
                          ),
                          title: Text(
                            log.type,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${_formatDate(log.date)} • '
                            '${formatNumber(log.minutes)} min',
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${formatNumber(log.steps)} steps',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${formatNumber(log.calories)} kcal',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Edit',
                                onPressed: () => _startEdit(log),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Delete',
                                onPressed: () => _deleteLog(log),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'FitTrack • CodeAlpha App Development — Task 3: '
              'Fitness Tracker App • Data is stored only on this device.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
      BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
