// Store screenshots. Drives the real app with demo data and captures each key
// screen. Run through scripts/capture_screenshots.sh, which sets the device and
// output folder:
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart -d <device>

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:fitflow/core/app_state.dart';
import 'package:fitflow/data/catalogue.dart';
import 'package:fitflow/data/models.dart';
import 'package:fitflow/features/nutrition/nutrition_screen.dart';
import 'package:fitflow/features/shell.dart';
import 'package:fitflow/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_plate.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store screenshots', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.create();
    await tester.pumpWidget(FitFlowApp(state: state));
    await tester.pumpAndSettle();

    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      // On Android the captured surface can lag the last frame; give the
      // engine time to present it before taking the picture.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    Future<void> tab(String label) async {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
      await tester.pumpAndSettle();
    }

    await shot('00_welcome');

    _seedDemo(state);
    await tester.pumpAndSettle();
    expect(find.text('Start workout'), findsOneWidget, reason: 'demo profile should land on Home');
    await shot('01_home');

    await tab('Plan');
    await tester.tap(find.text('Why this workout?'));
    await shot('02_plan');

    await tab('Home');
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Log set 1'));
    await tester.pump(const Duration(seconds: 3)); // let the rest timer tick
    await binding.takeScreenshot('03_logger');
    await tester.tap(find.byTooltip('Undo last set'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pageBack();
    await tester.pumpAndSettle();

    final plate = recognisedPlates.first;
    final photo = MemoryImage(base64Decode(demoPlateJpegBase64));
    // Decode the photo up front so it is on screen when the shot is taken.
    await tester.runAsync(() => precacheImage(photo, tester.element(find.byType(Shell))));
    Navigator.of(tester.element(find.byType(Shell))).push(MaterialPageRoute(
      builder: (_) => MealReviewScreen(
        image: photo,
        items: [
          for (final (name, conf) in plate)
            FoodItem(food: foodByName(name), grams: foodByName(name).typicalGrams, confidence: conf),
        ],
      ),
    ));
    // The "analysing" spinner never settles, so wait past it with plain pumps.
    await tester.pump(const Duration(seconds: 2));
    await shot('04_meal_review');
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tab('Nutrition');
    await shot('05_nutrition');

    await tab('Circles');
    await shot('06_circles');

    await tab('Progress');
    await shot('07_progress');

    await tab('Home');
    await tester.tap(find.byTooltip('Profile and settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete all my data'), 200);
    await shot('08_privacy');
  });
}

/// Three weeks of realistic history so Home, Progress and the logger look like
/// an app in use rather than a fresh install.
void _seedDemo(AppState s) {
  s.completeOnboarding(Profile(
    name: 'Amaya',
    goal: Goal.strength,
    level: Level.intermediate,
    minutes: 30,
    equipment: Equipment.dumbbells,
    weeklyGoal: 4,
    healthConsent: true,
  ));

  final weekStart = s.weekStart;
  final today = DateTime.now();
  var n = 0;
  void session(DateTime day, String title, List<(String, int, double)> lifts, {int minutes = 32}) {
    if (day.isAfter(today)) return;
    s.sessions.add(Session(
      id: 'demo${n++}',
      date: DateTime(day.year, day.month, day.day, 7, 10),
      title: title,
      minutes: minutes,
      sets: [
        for (final (id, reps, kg) in lifts)
          for (var i = 0; i < 3; i++) SetLog(exerciseId: id, reps: reps, weightKg: kg),
      ],
    ));
  }

  for (var w = 3; w >= 0; w--) {
    final start = weekStart.subtract(Duration(days: 7 * w));
    final bump = (3 - w) * 2.0; // progressive overload across the weeks
    session(start, 'Lower-body strength', [('goblet_squat', 10, 10 + bump), ('db_rdl', 10, 12 + bump), ('plank', 30, 0)]);
    session(start.add(const Duration(days: 2)), 'Upper-body strength',
        [('db_press', 10, 10 + bump), ('db_row', 10, 12 + bump), ('pushup', 10, 0)], minutes: 28);
    if (w > 0) {
      session(start.add(const Duration(days: 4)), 'Full-body strength',
          [('goblet_squat', 10, 10 + bump), ('db_press', 10, 10 + bump), ('dead_bug', 12, 0)], minutes: 35);
      if (w.isOdd) {
        session(start.add(const Duration(days: 5)), 'Full-body flow', [('glute_bridge', 15, 0), ('incline_pushup', 12, 0)],
            minutes: 20);
      }
    }
  }
  s.sessions.sort((a, b) => a.date.compareTo(b.date));

  s.addMeal(MealSlot.breakfast, [
    FoodItem(food: foodByName('Oats (cooked)'), grams: 220),
    FoodItem(food: foodByName('Banana'), grams: 120),
    FoodItem(food: foodByName('Milk tea'), grams: 200),
  ], fromPhoto: false);
  s.addMeal(MealSlot.lunch, [
    FoodItem(food: foodByName('Rice (boiled)'), grams: 200, confidence: 0.94),
    FoodItem(food: foodByName('Dhal curry'), grams: 120, confidence: 0.88),
    FoodItem(food: foodByName('Fish curry'), grams: 110, confidence: 0.81),
  ], fromPhoto: true);

  s.addPost('Four weeks in and my goblet squat is up 6 kg. The "why this workout" notes keep me honest.', 'partners');
}
