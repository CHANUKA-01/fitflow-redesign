import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../logging/session_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../planner/plan_screen.dart';
import '../settings/settings_screen.dart';
import '../shell.dart';

/// Focus Flow home: one recommended workout, startable with no configuration
/// (R01), its two strongest reasons visible (U04), and quick-log (R14).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context);
    final plan = s.plan;
    final name = s.profile.name;
    final todayKcal = s.mealsOn(DateTime.now()).fold<double>(0, (a, m) => a + m.kcal);

    return Scaffold(
      appBar: AppBar(
        title: const Brand(),
        actions: [
          IconButton(
            tooltip: 'Profile and settings',
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: t.colorScheme.primaryContainer,
              child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: TextStyle(color: t.colorScheme.primary, fontWeight: FontWeight.w700)),
            ),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(padding: pagePadding(context, 4, 24), children: [
        Text(name.isEmpty ? '${_greeting()} 👋' : '${_greeting()}, $name 👋',
            style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Here is today\'s focus.', style: t.textTheme.bodyMedium),
        if (s.missedYesterday) ...[
          const SizedBox(height: 12),
          _RecoveryBanner(goal: s.profile.weeklyGoal, done: s.sessionsThisWeek),
        ],
        const SizedBox(height: 16),
        _EnergyCheck(value: s.energy, onChanged: s.setEnergy),
        const SizedBox(height: 12),
        _FocusCard(plan: plan),
        const SectionTitle('Quick log'),
        Row(children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.photo_camera_outlined,
              label: 'Snap a meal',
              color: FF.teal,
              onTap: () => startMealCapture(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickAction(
              icon: Icons.edit_note,
              label: 'Log a meal',
              color: FF.amber,
              onTap: () => showManualEntry(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickAction(
              icon: Icons.groups_outlined,
              label: 'Post update',
              color: FF.indigo,
              onTap: () => ShellState.of(context)?.go(3),
            ),
          ),
        ]),
        const SectionTitle('This week'),
        Row(children: [
          StatTile(label: 'Sessions', value: '${s.sessionsThisWeek}/${s.profile.weeklyGoal}', icon: Icons.event_available),
          const SizedBox(width: 12),
          StatTile(label: 'Week streak', value: '${s.weekStreak}', icon: Icons.local_fire_department_outlined),
          const SizedBox(width: 12),
          StatTile(label: 'kcal today', value: todayKcal.round().toString(), icon: Icons.restaurant),
        ]),
      ]),
    );
  }
}

class _EnergyCheck extends StatelessWidget {
  const _EnergyCheck({required this.value, required this.onChanged});

  final Energy value;
  final ValueChanged<Energy> onChanged;

  @override
  Widget build(BuildContext context) => Row(children: [
        Text('Energy today', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(width: 12),
        Expanded(
          child: SegmentedButton<Energy>(
            showSelectedIcon: false,
            segments: [for (final e in Energy.values) ButtonSegment(value: e, label: Text(e.label))],
            selected: {value},
            onSelectionChanged: (v) => onChanged(v.first),
          ),
        ),
      ]);
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.plan});

  final WorkoutPlan plan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FF.radius + 4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FF.indigo, Color(0xFF6D28D9)],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.auto_awesome, color: FF.coral, size: 18),
          const SizedBox(width: 6),
          Text('TODAY\'S FOCUS', style: t.textTheme.labelMedium?.copyWith(color: Colors.white70, letterSpacing: 1.2)),
        ]),
        const SizedBox(height: 10),
        Text(plan.title, style: t.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('${plan.minutes} min · ${plan.items.length} exercises · ${plan.level.label}',
            style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 14),
        for (final r in plan.reasons.take(2))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.check_circle_outline, color: Colors.white70, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(r, style: const TextStyle(color: Colors.white, height: 1.3))),
            ]),
          ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: FF.coral, foregroundColor: Colors.white),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start workout'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionScreen(plan: plan))),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlanScreen(standalone: true))),
            child: const Text('Adjust'),
          ),
        ]),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}

class _RecoveryBanner extends StatelessWidget {
  const _RecoveryBanner({required this.goal, required this.done});

  final int goal;
  final int done;

  @override
  Widget build(BuildContext context) {
    final left = (goal - done).clamp(0, goal);
    return Card(
      color: FF.teal.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const Icon(Icons.favorite_outline, color: FF.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              left == 0
                  ? 'Welcome back. Your weekly goal is already met — today is a bonus.'
                  : 'Welcome back. Missing a few days doesn\'t reset your progress — $left more this week keeps your streak.',
            ),
          ),
        ]),
      ),
    );
  }
}
