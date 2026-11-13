# FitTrack — Fitness Tracker App

A Flutter mobile app for tracking daily fitness — built by Raju K B for the **CodeAlpha App Development Internship (Task 3)**.

Log your workouts, steps and calories, and see your progress for today and for the week on the dashboard, with goal bars and a 7-day chart.

## Features

- Track daily fitness activities: **steps, workouts, calories burned**
- **Log fitness data manually** — date, exercise type, workout time in minutes, steps and calories
- **Edit** a log entry (it loads back into the form) and **delete** a log entry, with confirmation
- **Dashboard** with totals for **today** — steps, calories, active minutes, workouts
- **Weekly summary** — totals for **this week (Monday–Sunday)**, worked out from your logs, plus your daily average steps
- **Daily goals with progress bars:** 10,000 steps, 500 calories, 60 active minutes
- **7-day bar chart**, switchable between Steps, Calories and Minutes
- Data is saved on the device, so your logs survive closing the app
- 8 sample logs are included on first run so the dashboard and chart are not empty — use **Reset sample data** to bring them back, or **Clear all logs** to start fresh

## Tech stack

- **Flutter** (Dart) with Material 3
- `shared_preferences` for on-device storage — no account, no server needed

## Project structure

```
fitness-tracker-app/
├── pubspec.yaml            # name: fitness_tracker_app
├── lib/
│   ├── main.dart           # the app and the home screen
│   ├── models.dart         # FitnessLog, totals, daily goals, exercise types
│   ├── data.dart           # sample logs and the storage layer
│   └── widgets.dart        # stat cards, goal progress bars, 7-day chart
├── test/
│   └── widget_test.dart    # smoke test: open the app, check the dashboard
├── android/                # Android app (applicationId com.codealpha.fitnesstrackerapp)
├── ios/Runner/             # iOS app metadata
└── README.md
```

## Getting started

You need the Flutter SDK (3.22 or newer) installed.

```bash
flutter pub get
flutter run
```

Run it on an Android emulator, a connected phone, or in Chrome with `flutter run -d chrome`.

## Tests

```bash
flutter test
```

## Build an APK (Android)

```bash
flutter build apk --release
```

The APK is produced at `build/app/outputs/flutter-apk/app-release.apk`.

## About this project

This is Task 3 of the CodeAlpha App Development Internship — [codealpha.tech](https://www.codealpha.tech).
