import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/catalogue.dart';

enum _Period { week, month }

/// One headline metric and a plain-language sentence (R10) that follow the
/// period toggle (U06); detail sits below.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  _Period _period = _Period.week;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context);
    final now = DateTime.now();
    final from = _period == _Period.week ? s.weekStart : DateTime(now.year, now.month, 1);
    final inPeriod = s.sessionsSince(from);
    final minutes = inPeriod.fold<int>(0, (a, x) => a + x.minutes);
    final sets = inPeriod.fold<int>(0, (a, x) => a + x.sets.length);

    final goal = _period == _Period.week ? s.profile.weeklyGoal : s.profile.weeklyGoal * 4;
    final left = goal - inPeriod.length;
    final periodWord = _period == _Period.week ? 'this week' : 'this month';
    final sentence = inPeriod.isEmpty
        ? 'No sessions $periodWord yet. Today\'s plan takes ${s.plan.minutes} minutes.'
        : left > 0
            ? 'You trained ${inPeriod.length} ${inPeriod.length == 1 ? 'time' : 'times'} $periodWord — '
                '$left more reaches your goal.'
            : 'You trained ${inPeriod.length} times $periodWord and reached your goal. Nice work.';

    // Bars: minutes per day (week) or per week (month).
    final List<(String, int)> bars;
    if (_period == _Period.week) {
      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      bars = [
        for (var i = 0; i < 7; i++)
          (
            days[i],
            inPeriod
                .where((x) => x.date.difference(s.weekStart).inDays == i)
                .fold<int>(0, (a, x) => a + x.minutes),
          ),
      ];
    } else {
      bars = [
        for (var w = 0; w < 5; w++)
          (
            'W${w + 1}',
            inPeriod.where((x) => (x.date.day - 1) ~/ 7 == w).fold<int>(0, (a, x) => a + x.minutes),
          ),
      ];
    }

    final pbs = <(String, String)>[];
    for (final id in {for (final x in s.sessions) ...x.sets.map((e) => e.exerciseId)}) {
      final ex = exerciseById(id);
      pbs.add((ex.name, ex.weightKg > 0 ? kg(s.bestWeightFor(id)) : '${s.bestRepsFor(id)} reps'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(padding: pagePadding(context, 0, 24), children: [
        SegmentedButton<_Period>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _Period.week, label: Text('This week')),
            ButtonSegment(value: _Period.month, label: Text('This month')),
          ],
          selected: {_period},
          onSelectionChanged: (v) => setState(() => _period = v.first),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sessions $periodWord', style: t.textTheme.labelLarge),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${inPeriod.length}',
                    style: t.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, color: FF.indigo)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 6),
                  child: Text('/ $goal', style: t.textTheme.titleLarge),
                ),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: goal == 0 ? 0 : (inPeriod.length / goal).clamp(0, 1).toDouble(),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 12),
              Text(sentence, style: t.textTheme.bodyLarge),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          StatTile(label: 'Minutes', value: '$minutes', icon: Icons.schedule),
          const SizedBox(width: 12),
          StatTile(label: 'Sets logged', value: '$sets', icon: Icons.fitness_center),
          const SizedBox(width: 12),
          StatTile(label: 'Week streak', value: '${s.weekStreak}', icon: Icons.local_fire_department_outlined),
        ]),
        const SectionTitle('Minutes trained'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: _Bars(bars: bars),
          ),
        ),
        const SectionTitle('Personal bests'),
        if (pbs.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.emoji_events_outlined),
              title: Text('Finish a workout to start tracking personal bests.'),
            ),
          )
        else
          Card(
            child: Column(children: [
              for (final (name, best) in pbs)
                ListTile(
                  leading: const Icon(Icons.emoji_events_outlined, color: FF.coral),
                  title: Text(name),
                  trailing: Text(best, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
        const SectionTitle('Recent sessions'),
        if (s.sessions.isEmpty)
          const Card(child: ListTile(title: Text('No sessions yet.')))
        else
          Card(
            child: Column(children: [
              for (final x in s.sessions.reversed.take(10))
                ListTile(
                  leading: const Icon(Icons.check_circle, color: FF.teal),
                  title: Text(x.title),
                  subtitle: Text('${x.sets.length} sets · ${x.minutes} min'),
                  trailing: Text(timeAgo(x.date)),
                ),
            ]),
          ),
      ]),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.bars});

  final List<(String, int)> bars;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final peak = bars.fold<int>(0, (m, b) => b.$2 > m ? b.$2 : m);
    return Semantics(
      label: 'Minutes trained: ${bars.map((b) => '${b.$1} ${b.$2}').join(', ')}',
      excludeSemantics: true,
      child: SizedBox(
        height: 140,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final (label, value) in bars)
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (value > 0) Text('$value', style: t.textTheme.labelSmall),
                const SizedBox(height: 4),
                Container(
                  height: peak == 0 ? 4 : 4 + 90 * value / peak,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: value > 0 ? FF.indigo : t.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(label, style: t.textTheme.labelMedium),
              ]),
            ),
        ]),
      ),
    );
  }
}
