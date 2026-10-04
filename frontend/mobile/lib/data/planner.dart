import 'dart:math';

import 'catalogue.dart';
import 'models.dart';

/// On-device, rule-based stand-in for the AI planning service (Flow A in
/// docs/04-architecture.md). It reads the same inputs the service would (R03)
/// and returns ranked reasons with every plan (R04).
class Planner {
  const Planner();

  static const _secondsPerSet = 150; // work + rest, used to fit the time budget

  WorkoutPlan generate({
    required Profile profile,
    required Energy energy,
    String? lastArea,
    int seed = 0,
    int? minutesOverride,
    Level? levelOverride,
  }) {
    final rng = Random(seed);
    final minutes = minutesOverride ?? profile.minutes;
    final level = levelOverride ?? profile.level;
    final reasons = <String>[];

    final allowedEquipment = switch (profile.equipment) {
      Equipment.none => {Equipment.none},
      Equipment.dumbbells => {Equipment.none, Equipment.dumbbells},
      Equipment.gym => {Equipment.none, Equipment.dumbbells, Equipment.gym},
    };

    var pool = exercises
        .where((e) => allowedEquipment.contains(e.equipment))
        .where((e) => e.avoidFor.intersection(profile.injuries).isEmpty)
        .toList();

    // Alternate focus so consecutive sessions don't load the same area.
    final focus = switch (lastArea) {
      'upper' => 'lower',
      'lower' => 'upper',
      _ => 'full',
    };

    final goalReason = switch (profile.goal) {
      Goal.strength => 'Your goal is to build strength, so compound lifts come first.',
      Goal.endurance => 'Your goal is endurance, so the session mixes cardio with higher reps.',
      Goal.weightLoss => 'Your goal is weight loss, so the session keeps your heart rate up with circuits.',
      Goal.general => 'Your goal is to stay active, so the session balances the whole body.',
    };
    reasons.add(goalReason);

    var setsPerExercise = switch (level) {
      Level.beginner => 2,
      Level.intermediate => 3,
      Level.advanced => 4,
    };
    if (energy == Energy.low) {
      setsPerExercise = max(2, setsPerExercise - 1);
      reasons.add('You said your energy is low today, so each exercise has one set fewer.');
    } else if (energy == Energy.high && level != Level.beginner) {
      setsPerExercise += 1;
      reasons.add('Your energy is high today, so each exercise has one extra set.');
    }

    final exerciseCount = max(3, (minutes * 60 / _secondsPerSet / setsPerExercise).floor()).clamp(3, 7);
    reasons.add('You have $minutes minutes, which fits $exerciseCount exercises of $setsPerExercise sets.');

    if (lastArea == 'upper' || lastArea == 'lower') {
      reasons.add('Your last session worked your $lastArea body, so today focuses on your $focus body.');
    }
    if (profile.injuries.isNotEmpty) {
      final names = profile.injuries.map((i) => i.label.toLowerCase()).join(' and ');
      reasons.add('Exercises that load your $names are left out because you flagged an injury.');
    }

    int score(Exercise e) {
      var s = 0;
      if (focus == 'full' || e.area == focus) s += 3;
      if (e.area == 'core') s += 1;
      if (profile.goal == Goal.strength && e.compound) s += 3;
      if ((profile.goal == Goal.endurance || profile.goal == Goal.weightLoss) && e.cardio) s += 3;
      if (e.equipment == profile.equipment) s += 2; // use the kit they actually have
      return s * 10 + rng.nextInt(10); // the seed varies ties so "regenerate" gives a fresh plan
    }

    pool.sort((a, b) => score(b).compareTo(score(a)));
    pool = pool.take(exerciseCount).toList();

    final repScale = switch (profile.goal) {
      Goal.strength => 0.8,
      Goal.endurance || Goal.weightLoss => 1.25,
      Goal.general => 1.0,
    };
    final weightScale = switch (level) {
      Level.beginner => 0.7,
      Level.intermediate => 1.0,
      Level.advanced => 1.3,
    };

    final items = [
      for (final e in pool)
        PlanItem(
          exercise: e,
          sets: setsPerExercise,
          reps: max(4, (e.reps * repScale).round()),
          weightKg: (e.weightKg * weightScale / 2).round() * 2.0,
        ),
    ];

    final title = switch ((profile.goal, focus)) {
      (Goal.strength, 'upper') => 'Upper-body strength',
      (Goal.strength, 'lower') => 'Lower-body strength',
      (Goal.strength, _) => 'Full-body strength',
      (Goal.endurance, _) => 'Endurance builder',
      (Goal.weightLoss, _) => 'Fat-burn circuit',
      (Goal.general, 'upper') => 'Upper-body flow',
      (Goal.general, 'lower') => 'Lower-body flow',
      (Goal.general, _) => 'Full-body flow',
    };

    return WorkoutPlan(title: title, minutes: minutes, level: level, items: items, reasons: reasons);
  }

  /// Replacement for one exercise: same area, not already in the plan (R05).
  Exercise? swapFor(WorkoutPlan plan, PlanItem item, Profile profile) {
    final used = plan.items.map((i) => i.exercise.id).toSet();
    final allowed = switch (profile.equipment) {
      Equipment.none => {Equipment.none},
      Equipment.dumbbells => {Equipment.none, Equipment.dumbbells},
      Equipment.gym => Equipment.values.toSet(),
    };
    final options = exercises
        .where((e) => !used.contains(e.id))
        .where((e) => allowed.contains(e.equipment))
        .where((e) => e.avoidFor.intersection(profile.injuries).isEmpty)
        .toList();
    if (options.isEmpty) return null;
    final sameArea = options.where((e) => e.area == item.exercise.area).toList();
    return (sameArea.isNotEmpty ? sameArea : options).first;
  }
}
