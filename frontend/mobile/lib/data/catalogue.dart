import 'models.dart';

// Static reference data bundled with the app. In production the exercise
// catalogue and food database come from the API; the prototype ships them.

const exercises = <Exercise>[
  // No equipment
  Exercise(id: 'squat_bw', name: 'Bodyweight squat', area: 'lower', equipment: Equipment.none, reps: 15, compound: true, avoidFor: {Injury.knee}),
  Exercise(id: 'glute_bridge', name: 'Glute bridge', area: 'lower', equipment: Equipment.none, reps: 15),
  Exercise(id: 'reverse_lunge', name: 'Reverse lunge', area: 'lower', equipment: Equipment.none, reps: 10, compound: true, avoidFor: {Injury.knee}),
  Exercise(id: 'pushup', name: 'Push-up', area: 'upper', equipment: Equipment.none, reps: 10, compound: true, avoidFor: {Injury.shoulder}),
  Exercise(id: 'incline_pushup', name: 'Incline push-up', area: 'upper', equipment: Equipment.none, reps: 12),
  Exercise(id: 'superman', name: 'Superman hold', area: 'core', equipment: Equipment.none, reps: 10, avoidFor: {Injury.back}),
  Exercise(id: 'plank', name: 'Plank (seconds)', area: 'core', equipment: Equipment.none, reps: 30),
  Exercise(id: 'dead_bug', name: 'Dead bug', area: 'core', equipment: Equipment.none, reps: 12),
  Exercise(id: 'jumping_jack', name: 'Jumping jacks', area: 'full', equipment: Equipment.none, reps: 30, cardio: true, avoidFor: {Injury.knee}),
  Exercise(id: 'march', name: 'High-knee march', area: 'full', equipment: Equipment.none, reps: 40, cardio: true),
  Exercise(id: 'mountain_climber', name: 'Mountain climbers', area: 'full', equipment: Equipment.none, reps: 20, cardio: true, avoidFor: {Injury.shoulder}),
  // Dumbbells
  Exercise(id: 'goblet_squat', name: 'Goblet squat', area: 'lower', equipment: Equipment.dumbbells, reps: 10, weightKg: 10, compound: true, avoidFor: {Injury.knee}),
  Exercise(id: 'db_rdl', name: 'Dumbbell Romanian deadlift', area: 'lower', equipment: Equipment.dumbbells, reps: 10, weightKg: 12, compound: true, avoidFor: {Injury.back}),
  Exercise(id: 'db_press', name: 'Dumbbell floor press', area: 'upper', equipment: Equipment.dumbbells, reps: 10, weightKg: 10, compound: true),
  Exercise(id: 'db_row', name: 'One-arm dumbbell row', area: 'upper', equipment: Equipment.dumbbells, reps: 10, weightKg: 12, compound: true),
  Exercise(id: 'db_ohp', name: 'Seated shoulder press', area: 'upper', equipment: Equipment.dumbbells, reps: 10, weightKg: 8, avoidFor: {Injury.shoulder}),
  Exercise(id: 'db_thruster', name: 'Dumbbell thruster', area: 'full', equipment: Equipment.dumbbells, reps: 12, weightKg: 6, cardio: true, avoidFor: {Injury.knee, Injury.shoulder}),
  // Gym
  Exercise(id: 'leg_press', name: 'Leg press', area: 'lower', equipment: Equipment.gym, reps: 10, weightKg: 60, compound: true),
  Exercise(id: 'back_squat', name: 'Barbell back squat', area: 'lower', equipment: Equipment.gym, reps: 8, weightKg: 40, compound: true, avoidFor: {Injury.knee, Injury.back}),
  Exercise(id: 'lat_pulldown', name: 'Lat pulldown', area: 'upper', equipment: Equipment.gym, reps: 10, weightKg: 35, compound: true),
  Exercise(id: 'bench', name: 'Bench press', area: 'upper', equipment: Equipment.gym, reps: 8, weightKg: 30, compound: true, avoidFor: {Injury.shoulder}),
  Exercise(id: 'cable_row', name: 'Seated cable row', area: 'upper', equipment: Equipment.gym, reps: 10, weightKg: 30, compound: true),
  Exercise(id: 'rower', name: 'Rowing machine (calories)', area: 'full', equipment: Equipment.gym, reps: 15, cardio: true, avoidFor: {Injury.back}),
  Exercise(id: 'bike', name: 'Bike intervals (minutes)', area: 'full', equipment: Equipment.gym, reps: 4, cardio: true),
];

Exercise exerciseById(String id) => exercises.firstWhere((e) => e.id == id);

const foods = <Food>[
  Food('Rice (boiled)', 130, 2.7, 28, 0.3, 180),
  Food('Dhal curry', 120, 7, 16, 3.5, 120),
  Food('Chicken curry', 165, 18, 4, 9, 120),
  Food('Fish curry', 140, 19, 3, 6, 120),
  Food('Pol sambol', 260, 3, 9, 24, 30),
  Food('String hoppers', 150, 3, 33, 0.5, 120),
  Food('Egg (boiled)', 155, 13, 1, 11, 50),
  Food('Banana', 89, 1.1, 23, 0.3, 120),
  Food('Oats (cooked)', 71, 2.5, 12, 1.5, 200),
  Food('Greek yoghurt', 97, 9, 4, 5, 150),
  Food('Mixed salad', 20, 1.2, 3.5, 0.2, 100),
  Food('Grilled chicken breast', 165, 31, 0, 3.6, 120),
  Food('Bread (wholemeal)', 247, 13, 41, 3.4, 60),
  Food('Peanut butter', 588, 25, 20, 50, 20),
  Food('Milk tea', 60, 1.5, 9, 2, 200),
  Food('Apple', 52, 0.3, 14, 0.2, 150),
];

Food foodByName(String name) => foods.firstWhere((f) => f.name == name, orElse: () => foods.first);

/// Plates the prototype "recognises". The on-device model described in ADR-003
/// would return items with confidences; the prototype picks one of these.
const recognisedPlates = <List<(String, double)>>[
  [('Rice (boiled)', 0.94), ('Dhal curry', 0.88), ('Chicken curry', 0.71), ('Pol sambol', 0.46)],
  [('String hoppers', 0.90), ('Fish curry', 0.67), ('Pol sambol', 0.52)],
  [('Oats (cooked)', 0.92), ('Banana', 0.85), ('Peanut butter', 0.41)],
  [('Grilled chicken breast', 0.89), ('Mixed salad', 0.83), ('Bread (wholemeal)', 0.58)],
];

const circles = <Circle>[
  Circle(id: 'partners', name: 'Training partners', members: 5),
  Circle(id: 'sliit', name: 'Campus lifters', members: 24),
  Circle(id: 'public', name: 'FitFlow community', members: 0, isPrivate: false),
];

Circle circleById(String id) => circles.firstWhere((c) => c.id == id);

/// Plain-language audience statement shown on every post and in the composer (R11, U01).
String audienceLabel(Circle c) =>
    c.isPrivate ? 'Visible to ${c.members} members of ${c.name}' : 'Visible to everyone on FitFlow';
