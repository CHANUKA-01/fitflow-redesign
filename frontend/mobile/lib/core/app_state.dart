import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalogue.dart';
import '../data/models.dart';
import '../data/planner.dart';

/// Single source of truth for the prototype. All data stays on the device
/// (shared_preferences); nothing is sent to a server.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _load();
  }

  static const _key = 'fitflow_state_v1';
  final SharedPreferences _prefs;
  final _planner = const Planner();

  Profile profile = Profile();
  final List<Session> sessions = [];
  final List<Meal> meals = [];
  final List<Post> posts = [];
  Energy energy = Energy.normal;
  WorkoutPlan? _plan;
  int _seed = 0;
  int? _minutesOverride;
  Level? _levelOverride;

  static Future<AppState> create() async => AppState(await SharedPreferences.getInstance());

  // ---------- persistence ----------

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      posts.addAll(_seedPosts());
      return;
    }
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      profile = Profile.fromJson(j['profile'] as Map<String, dynamic>);
      energy = Energy.values.firstWhere((e) => e.name == j['energy'], orElse: () => Energy.normal);
      sessions.addAll([for (final s in j['sessions'] as List) Session.fromJson(s as Map<String, dynamic>)]);
      meals.addAll([for (final m in j['meals'] as List) _mealFromJson(m as Map<String, dynamic>)]);
      posts.addAll([for (final p in j['posts'] as List) Post.fromJson(p as Map<String, dynamic>)]);
    } catch (_) {
      // Corrupt or older format: start clean rather than crash on launch.
      profile = Profile();
      posts
        ..clear()
        ..addAll(_seedPosts());
    }
  }

  Meal _mealFromJson(Map<String, dynamic> j) => Meal(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        slot: MealSlot.values.firstWhere((s) => s.name == j['slot'], orElse: () => MealSlot.snack),
        fromPhoto: j['fromPhoto'] as bool? ?? false,
        items: [
          for (final i in j['items'] as List)
            FoodItem(
              food: foodByName(i['food'] as String),
              grams: i['g'] as int,
              confidence: (i['c'] as num?)?.toDouble(),
            ),
        ],
      );

  Map<String, dynamic> exportJson() => {
        'exportedAt': DateTime.now().toIso8601String(),
        'profile': profile.toJson(),
        'energy': energy.name,
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'meals': meals.map((m) => m.toJson()).toList(),
        'posts': posts.map((p) => p.toJson()).toList(),
      };

  Future<void> _save() => _prefs.setString(_key, jsonEncode(exportJson()));

  void _changed() {
    notifyListeners();
    _save();
  }

  /// Right to erasure: wipes everything stored on this device.
  Future<void> deleteAllData() async {
    await _prefs.remove(_key);
    profile = Profile();
    sessions.clear();
    meals.clear();
    posts
      ..clear()
      ..addAll(_seedPosts());
    energy = Energy.normal;
    _resetPlan();
    notifyListeners();
  }

  // ---------- profile ----------

  void completeOnboarding(Profile p) {
    profile = p..onboarded = true;
    _resetPlan();
    _changed();
  }

  void updateProfile(void Function(Profile p) edit) {
    edit(profile);
    _resetPlan();
    _changed();
  }

  // ---------- planning (R01, R03–R05) ----------

  String? get _lastArea {
    if (sessions.isEmpty) return null;
    final ids = sessions.last.sets.map((s) => s.exerciseId).toSet();
    final areas = ids.map((id) => exerciseById(id).area).toList();
    final upper = areas.where((a) => a == 'upper').length;
    final lower = areas.where((a) => a == 'lower').length;
    if (upper == lower) return 'full';
    return upper > lower ? 'upper' : 'lower';
  }

  WorkoutPlan get plan => _plan ??= _planner.generate(
        profile: profile,
        energy: energy,
        lastArea: _lastArea,
        seed: _seed,
        minutesOverride: _minutesOverride,
        levelOverride: _levelOverride,
      );

  void _resetPlan() {
    _plan = null;
    _minutesOverride = null;
    _levelOverride = null;
  }

  void setEnergy(Energy e) {
    energy = e;
    _plan = null;
    _changed();
  }

  void regenerate() {
    _seed++;
    _plan = null;
    notifyListeners();
  }

  void adjustPlan({int? minutes, Level? level}) {
    if (minutes != null) _minutesOverride = minutes;
    if (level != null) _levelOverride = level;
    _plan = null;
    notifyListeners();
  }

  /// Returns the replacement's name, or null when nothing suitable is left.
  String? swap(PlanItem item) {
    final replacement = _planner.swapFor(plan, item, profile);
    if (replacement == null) return null;
    final i = plan.items.indexOf(item);
    plan.items[i] = PlanItem(
      exercise: replacement,
      sets: item.sets,
      reps: replacement.reps,
      weightKg: replacement.weightKg,
    );
    notifyListeners();
    return replacement.name;
  }

  // ---------- logging (R06, R07, R12) ----------

  /// Most recent logged set for this exercise, used to pre-fill the logger (R07).
  SetLog? lastSetFor(String exerciseId) {
    for (final s in sessions.reversed) {
      for (final set in s.sets.reversed) {
        if (set.exerciseId == exerciseId) return set;
      }
    }
    return null;
  }

  double bestWeightFor(String exerciseId, {Session? excluding}) {
    var best = 0.0;
    for (final s in sessions) {
      if (identical(s, excluding)) continue;
      for (final set in s.sets) {
        if (set.exerciseId == exerciseId && set.weightKg > best) best = set.weightKg;
      }
    }
    return best;
  }

  int bestRepsFor(String exerciseId, {Session? excluding}) {
    var best = 0;
    for (final s in sessions) {
      if (identical(s, excluding)) continue;
      for (final set in s.sets) {
        if (set.exerciseId == exerciseId && set.reps > best) best = set.reps;
      }
    }
    return best;
  }

  /// Saves a finished session and returns the exercises that set a personal best.
  List<String> finishSession(Session session) {
    final pbs = <String>[];
    for (final id in session.sets.map((s) => s.exerciseId).toSet()) {
      final hadHistory = sessions.any((s) => s.sets.any((x) => x.exerciseId == id));
      if (!hadHistory) continue;
      final ex = exerciseById(id);
      final mine = session.sets.where((s) => s.exerciseId == id);
      final topW = mine.fold<double>(0, (m, s) => s.weightKg > m ? s.weightKg : m);
      final topR = mine.fold<int>(0, (m, s) => s.reps > m ? s.reps : m);
      if (ex.weightKg > 0 ? topW > bestWeightFor(id) : topR > bestRepsFor(id)) pbs.add(ex.name);
    }
    sessions.add(session);
    _seed++;
    _resetPlan();
    _changed();
    return pbs;
  }

  // ---------- progress (R10, R13) ----------

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get weekStart {
    final today = _day(DateTime.now());
    return today.subtract(Duration(days: today.weekday - 1));
  }

  List<Session> sessionsSince(DateTime from) => sessions.where((s) => !s.date.isBefore(from)).toList();

  int get sessionsThisWeek => sessionsSince(weekStart).length;

  /// Consecutive weeks (including this one if goal already met) that hit the
  /// weekly goal. One short week is forgiven so a missed session doesn't wipe
  /// progress (R13).
  int get weekStreak {
    var streak = 0;
    var forgiven = false;
    var start = weekStart;
    if (sessionsThisWeek >= profile.weeklyGoal) streak++;
    while (true) {
      start = start.subtract(const Duration(days: 7));
      final end = start.add(const Duration(days: 7));
      final count = sessions.where((s) => !s.date.isBefore(start) && s.date.isBefore(end)).length;
      if (count >= profile.weeklyGoal) {
        streak++;
      } else if (!forgiven && count > 0) {
        forgiven = true;
      } else {
        break;
      }
      if (streak > 52) break;
    }
    return streak;
  }

  bool get missedYesterday {
    if (sessions.isEmpty) return false;
    final last = _day(sessions.last.date);
    return _day(DateTime.now()).difference(last).inDays >= 3;
  }

  // ---------- nutrition (R08, R09) ----------

  int get kcalTarget => switch (profile.goal) {
        Goal.weightLoss => 1800,
        Goal.strength => 2400,
        Goal.endurance => 2300,
        Goal.general => 2100,
      };

  List<Meal> mealsOn(DateTime day) => meals.where((m) => _day(m.date) == _day(day)).toList();

  void addMeal(MealSlot slot, List<FoodItem> items, {required bool fromPhoto}) {
    meals.add(Meal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime.now(),
      slot: slot,
      items: items,
      fromPhoto: fromPhoto,
    ));
    _changed();
  }

  void removeMeal(Meal m) {
    meals.remove(m);
    _changed();
  }

  // ---------- community (R11) ----------

  List<Post> postsIn(String circleId) =>
      posts.where((p) => p.circleId == circleId).toList()..sort((a, b) => b.date.compareTo(a.date));

  void addPost(String text, String circleId) {
    posts.add(Post(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      author: profile.name.isEmpty ? 'You' : profile.name,
      text: text,
      date: DateTime.now(),
      circleId: circleId,
      mine: true,
    ));
    _changed();
  }

  void toggleLike(Post p) {
    p.liked = !p.liked;
    p.likes += p.liked ? 1 : -1;
    _changed();
  }

  void deletePost(Post p) {
    posts.remove(p);
    _changed();
  }

  static List<Post> _seedPosts() {
    final now = DateTime.now();
    Post p(String id, String author, String text, int hoursAgo, String circle, int likes) =>
        Post(id: id, author: author, text: text, date: now.subtract(Duration(hours: hoursAgo)), circleId: circle, likes: likes);
    return [
      p('s1', 'Nimal', 'Hit 3 sessions this week for the first time since January. The 20-minute plans really help.', 2, 'partners', 4),
      p('s2', 'Ayesha', 'Anyone up for a Saturday morning walk around the lake? 7am start.', 6, 'partners', 2),
      p('s3', 'Kavindu', 'New personal best on goblet squat — 16 kg for 10. Knee felt fine.', 20, 'partners', 5),
      p('s4', 'Tharushi', 'Campus gym is quiet after 4pm on Fridays if anyone wants the squat rack.', 3, 'sliit', 9),
      p('s5', 'Dilan', 'Weekly challenge: 10,000 steps every day until Sunday. Who is in?', 26, 'sliit', 14),
      p('s6', 'FitFlow team', 'Tip: tap "Why this workout?" on your plan to see exactly what the planner used.', 30, 'public', 41),
    ];
  }
}

/// Makes [AppState] available to the widget tree and rebuilds on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing — for callbacks.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
