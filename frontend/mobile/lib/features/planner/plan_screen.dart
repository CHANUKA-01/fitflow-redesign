import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../logging/session_screen.dart';

/// AI planner: full reasons on demand (R04), adjust duration and difficulty,
/// swap an exercise, regenerate (R05), and what the planner reads (R15).
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key, this.standalone = false});

  /// True when pushed from Home rather than shown as a tab.
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context);
    final plan = s.plan;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: standalone,
        title: const Text('Your plan'),
        actions: [
          IconButton(
            tooltip: 'Generate a different plan',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              s.regenerate();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('New plan generated with the same settings')));
            },
          ),
        ],
      ),
      body: ListView(padding: pagePadding(context, 0, 24), children: [
        Text(plan.title, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('${plan.minutes} min · ${plan.items.length} exercises · ${plan.level.label}'),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: Icon(Icons.lightbulb_outline, color: t.colorScheme.primary),
            title: const Text('Why this workout?', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(plan.reasons.first, maxLines: 1, overflow: TextOverflow.ellipsis),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, r) in plan.reasons.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleAvatar(radius: 11, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r)),
                  ]),
                ),
              const SizedBox(height: 4),
              const AiNotice(
                'This plan is made by a rule-based planner that runs on your phone. It reads your goal, '
                'level, session length, today\'s energy, equipment, injuries and your last session. '
                'Nothing is sent to a server.',
              ),
            ],
          ),
        ),
        const SectionTitle('Adjust'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Duration', style: t.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final m in const [15, 20, 30, 45, 60])
                  ChoiceChip(
                    label: Text('$m min'),
                    selected: plan.minutes == m,
                    onSelected: (_) => s.adjustPlan(minutes: m),
                  ),
              ]),
              const SizedBox(height: 16),
              Text('Difficulty', style: t.textTheme.labelLarge),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<Level>(
                  showSelectedIcon: false,
                  segments: [for (final l in Level.values) ButtonSegment(value: l, label: Text(l.label))],
                  selected: {plan.level},
                  onSelectionChanged: (v) => s.adjustPlan(level: v.first),
                ),
              ),
            ]),
          ),
        ),
        const SectionTitle('Exercises'),
        for (final item in plan.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                leading: CircleAvatar(
                  backgroundColor: t.colorScheme.primaryContainer,
                  child: Icon(_areaIcon(item.exercise), color: t.colorScheme.primary),
                ),
                title: Text(item.exercise.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${item.sets} × ${item.reps}${item.weightKg > 0 ? ' · ${kg(item.weightKg)}' : ''}',
                ),
                trailing: IconButton(
                  tooltip: 'Swap ${item.exercise.name}',
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () {
                    final name = s.swap(item);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text(name == null ? 'No other suitable exercise for your setup' : 'Swapped in $name'),
                      ));
                  },
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start this workout'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionScreen(plan: plan))),
        ),
      ]),
    );
  }

  static IconData _areaIcon(Exercise e) {
    if (e.cardio) return Icons.directions_run;
    return switch (e.area) {
      'upper' => Icons.fitness_center,
      'lower' => Icons.directions_walk,
      'core' => Icons.accessibility_new,
      _ => Icons.bolt,
    };
  }
}
