// Domain models for the FitFlow prototype. Everything here is stored locally
// on the device (see AppState), so every model round-trips through JSON.

enum Goal { strength, endurance, weightLoss, general }

enum Level { beginner, intermediate, advanced }

enum Equipment { none, dumbbells, gym }

enum Injury { knee, back, shoulder }

enum Energy { low, normal, high }

enum MealSlot { breakfast, lunch, dinner, snack }

extension GoalLabel on Goal {
  String get label => switch (this) {
        Goal.strength => 'Build strength',
        Goal.endurance => 'Improve endurance',
        Goal.weightLoss => 'Lose weight',
        Goal.general => 'Stay active',
      };
}

extension LevelLabel on Level {
  String get label => switch (this) {
        Level.beginner => 'Beginner',
        Level.intermediate => 'Intermediate',
        Level.advanced => 'Advanced',
      };
}

extension EquipmentLabel on Equipment {
  String get label => switch (this) {
        Equipment.none => 'No equipment',
        Equipment.dumbbells => 'Dumbbells',
        Equipment.gym => 'Full gym',
      };
}

extension InjuryLabel on Injury {
  String get label => switch (this) {
        Injury.knee => 'Knee',
        Injury.back => 'Lower back',
        Injury.shoulder => 'Shoulder',
      };
}

extension EnergyLabel on Energy {
  String get label => switch (this) {
        Energy.low => 'Low',
        Energy.normal => 'Normal',
        Energy.high => 'High',
      };
}

extension MealSlotLabel on MealSlot {
  String get label => switch (this) {
        MealSlot.breakfast => 'Breakfast',
        MealSlot.lunch => 'Lunch',
        MealSlot.dinner => 'Dinner',
        MealSlot.snack => 'Snack',
      };
}

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((v) => v.name == name, orElse: () => fallback);

class Profile {
  Profile({
    this.name = '',
    this.goal = Goal.general,
    this.level = Level.beginner,
    this.minutes = 30,
    this.equipment = Equipment.none,
    Set<Injury>? injuries,
    this.weeklyGoal = 3,
    this.restSeconds = 90,
    this.healthConsent = false,
    this.onboarded = false,
  }) : injuries = injuries ?? {};

  String name;
  Goal goal;
  Level level;
  int minutes;
  Equipment equipment;
  Set<Injury> injuries;
  int weeklyGoal;
  int restSeconds;
  bool healthConsent;
  bool onboarded;

  Map<String, dynamic> toJson() => {
        'name': name,
        'goal': goal.name,
        'level': level.name,
        'minutes': minutes,
        'equipment': equipment.name,
        'injuries': injuries.map((i) => i.name).toList(),
        'weeklyGoal': weeklyGoal,
        'restSeconds': restSeconds,
        'healthConsent': healthConsent,
        'onboarded': onboarded,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: j['name'] as String? ?? '',
        goal: _enum(Goal.values, j['goal'], Goal.general),
        level: _enum(Level.values, j['level'], Level.beginner),
        minutes: j['minutes'] as int? ?? 30,
        equipment: _enum(Equipment.values, j['equipment'], Equipment.none),
        injuries: {
          for (final n in (j['injuries'] as List? ?? const []))
            _enum(Injury.values, n, Injury.knee),
        },
        weeklyGoal: j['weeklyGoal'] as int? ?? 3,
        restSeconds: j['restSeconds'] as int? ?? 90,
        healthConsent: j['healthConsent'] as bool? ?? false,
        onboarded: j['onboarded'] as bool? ?? false,
      );
}

/// A catalogue entry. [avoidFor] lists injuries the planner must respect.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.area,
    required this.equipment,
    required this.reps,
    this.weightKg = 0,
    this.compound = false,
    this.cardio = false,
    this.avoidFor = const {},
  });

  final String id;
  final String name;
  final String area; // 'upper', 'lower', 'core', 'full'
  final Equipment equipment;
  final int reps;
  final double weightKg;
  final bool compound;
  final bool cardio;
  final Set<Injury> avoidFor;
}

class PlanItem {
  PlanItem({required this.exercise, required this.sets, required this.reps, required this.weightKg});

  final Exercise exercise;
  int sets;
  int reps;
  double weightKg;
}

class WorkoutPlan {
  WorkoutPlan({
    required this.title,
    required this.minutes,
    required this.level,
    required this.items,
    required this.reasons,
  });

  final String title;
  final int minutes;
  final Level level;
  final List<PlanItem> items;

  /// Ranked explanation: the strongest reason first (R04, U04).
  final List<String> reasons;
}

class SetLog {
  SetLog({required this.exerciseId, required this.reps, required this.weightKg});

  final String exerciseId;
  final int reps;
  final double weightKg;

  Map<String, dynamic> toJson() => {'e': exerciseId, 'r': reps, 'w': weightKg};

  factory SetLog.fromJson(Map<String, dynamic> j) =>
      SetLog(exerciseId: j['e'] as String, reps: j['r'] as int, weightKg: (j['w'] as num).toDouble());
}

class Session {
  Session({
    required this.id,
    required this.date,
    required this.title,
    required this.minutes,
    required this.sets,
  });

  /// Doubles as the idempotency key a sync queue would send (NFR2).
  final String id;
  final DateTime date;
  final String title;
  final int minutes;
  final List<SetLog> sets;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'minutes': minutes,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        title: j['title'] as String,
        minutes: j['minutes'] as int,
        sets: [for (final s in j['sets'] as List) SetLog.fromJson(s as Map<String, dynamic>)],
      );
}

class Food {
  const Food(this.name, this.kcalPer100, this.protein, this.carbs, this.fat, this.typicalGrams);

  final String name;
  final double kcalPer100;
  final double protein; // grams per 100 g
  final double carbs;
  final double fat;
  final int typicalGrams;
}

class FoodItem {
  FoodItem({required this.food, required this.grams, this.confidence});

  final Food food;
  int grams;

  /// 0–1 when the item came from photo recognition; null for manual entries (R09, U08).
  final double? confidence;

  double get kcal => food.kcalPer100 * grams / 100;
  double get protein => food.protein * grams / 100;
  double get carbs => food.carbs * grams / 100;
  double get fat => food.fat * grams / 100;
}

class Meal {
  Meal({required this.id, required this.date, required this.slot, required this.items, required this.fromPhoto});

  final String id;
  final DateTime date;
  final MealSlot slot;
  final List<FoodItem> items;
  final bool fromPhoto;

  double get kcal => items.fold(0, (s, i) => s + i.kcal);

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'slot': slot.name,
        'fromPhoto': fromPhoto,
        'items': [
          for (final i in items) {'food': i.food.name, 'g': i.grams, 'c': i.confidence},
        ],
      };
}

enum Audience { circle, public }

class Circle {
  const Circle({required this.id, required this.name, required this.members, this.isPrivate = true});

  final String id;
  final String name;
  final int members;
  final bool isPrivate;
}

class Post {
  Post({
    required this.id,
    required this.author,
    required this.text,
    required this.date,
    required this.circleId,
    this.likes = 0,
    this.liked = false,
    this.mine = false,
  });

  final String id;
  final String author;
  final String text;
  final DateTime date;
  final String circleId;
  int likes;
  bool liked;
  final bool mine;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'text': text,
        'date': date.toIso8601String(),
        'circleId': circleId,
        'likes': likes,
        'liked': liked,
        'mine': mine,
      };

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as String,
        author: j['author'] as String,
        text: j['text'] as String,
        date: DateTime.parse(j['date'] as String),
        circleId: j['circleId'] as String,
        likes: j['likes'] as int? ?? 0,
        liked: j['liked'] as bool? ?? false,
        mine: j['mine'] as bool? ?? false,
      );
}
