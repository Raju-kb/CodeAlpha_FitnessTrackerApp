import 'package:fitness_tracker_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('FitTrack pumps and shows the dashboard',
      (WidgetTester tester) async {
    // shared_preferences needs mock values in tests.
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const FitnessTrackerApp());
    // Let the async log load (and the seeded sample data) finish.
    await tester.pumpAndSettle();

    // App bar and the main dashboard sections are visible.
    expect(find.text('FitTrack — Fitness Tracker'), findsOneWidget);
    expect(find.text("Today's summary"), findsOneWidget);
    expect(find.text('Daily goals'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Log fitness data'), findsOneWidget);
    expect(find.text('Activity history'), findsOneWidget);

    // The seeded sample logs (8 across the last 7 days) mean today
    // has 2 workouts: Running + Walking = 9,900 steps.
    expect(find.text('9,900'), findsWidgets);

    // The log form is present.
    expect(find.text('Save log'), findsOneWidget);
    expect(find.text('Workout time (minutes)'), findsOneWidget);
  });
}
