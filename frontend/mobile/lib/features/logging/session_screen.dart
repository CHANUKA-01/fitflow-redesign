import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';

/// Set logger. Values are pre-filled from the last matching set (R07) so
/// logging is a single tap (R06, NFR1); the rest timer starts automatically.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.plan});

  final WorkoutPlan plan;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _Draft {
  _Draft(this.item, this.reps, this.weight);

  final PlanItem item;
  int reps;
  double weight;
  final List<SetLog> done = [];
}

class _SessionScreenState extends State<SessionScreen> {
  late final List<_Draft> _drafts;
  late final DateTime _started;
  Timer? _timer;
  int _restLeft = 0;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _started = DateTime.now();
    final s = AppScope.read(context);
    _drafts = [
      for (final item in widget.plan.items)
        () {
          final last = s.lastSetFor(item.exercise.id);
          return _Draft(item, last?.reps ?? item.reps, last?.weightKg ?? item.weightKg);
        }(),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _setsDone => _drafts.fold(0, (a, d) => a + d.done.length);
  int get _setsTotal => _drafts.fold(0, (a, d) => a + d.item.sets);

  void _logSet(_Draft d) {
    HapticFeedback.mediumImpact();
    setState(() {
      d.done.add(SetLog(exerciseId: d.item.exercise.id, reps: d.reps, weightKg: d.weight));
      if (d.done.length >= d.item.sets && _current < _drafts.length - 1) _current = _drafts.indexOf(d) + 1;
    });
    if (_setsDone < _setsTotal) _startRest();
  }

  void _undo(_Draft d) => setState(() => d.done.removeLast());

  void _startRest() {
    _timer?.cancel();
    setState(() => _restLeft = AppScope.read(context).profile.restSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _restLeft--);
      if (_restLeft <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
      }
    });
  }

  Future<void> _finish() async {
    final sets = [for (final d in _drafts) ...d.done];
    if (sets.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final s = AppScope.read(context);
    final minutes = DateTime.now().difference(_started).inMinutes.clamp(1, 240);
    final session = Session(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      date: DateTime.now(),
      title: widget.plan.title,
      minutes: minutes,
      sets: sets,
    );
    final pbs = s.finishSession(session);
    _timer?.cancel();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (_) => _Summary(
        sets: sets.length,
        minutes: minutes,
        pbs: pbs,
        weekDone: s.sessionsThisWeek,
        weekGoal: s.profile.weeklyGoal,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmLeave() async {
    if (_setsDone == 0) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Leave this workout?'),
        content: const Text('Sets you have logged will be saved as a shorter session.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep going')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save and leave')),
        ],
      ),
    );
    if (leave == true) await _finish();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _setsDone == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.plan.title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: _setsTotal == 0 ? 0 : _setsDone / _setsTotal, minHeight: 4),
          ),
        ),
        body: Column(children: [
          if (_restLeft > 0) _RestBar(seconds: _restLeft, onSkip: () {
            _timer?.cancel();
            setState(() => _restLeft = 0);
          }),
          Expanded(
            child: ListView.builder(
              padding: pagePadding(context, 12, 16),
              itemCount: _drafts.length,
              itemBuilder: (_, i) => _ExerciseCard(
                draft: _drafts[i],
                active: i == _current,
                onTap: () => setState(() => _current = i),
                onLog: () => _logSet(_drafts[i]),
                onUndo: () => _undo(_drafts[i]),
                onChanged: () => setState(() {}),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: pagePadding(context, 0, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: _setsDone == _setsTotal
                      ? FilledButton.styleFrom(backgroundColor: FF.coral, foregroundColor: Colors.white)
                      : null,
                  onPressed: _finish,
                  child: Text(_setsDone == _setsTotal ? 'Finish workout' : 'Finish early ($_setsDone/$_setsTotal sets)'),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.draft,
    required this.active,
    required this.onTap,
    required this.onLog,
    required this.onUndo,
    required this.onChanged,
  });

  final _Draft draft;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onLog;
  final VoidCallback onUndo;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final complete = draft.done.length >= draft.item.sets;
    final ex = draft.item.exercise;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FF.radius),
          side: BorderSide(color: active ? t.colorScheme.primary : Colors.transparent, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(FF.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(ex.name, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (complete)
                  const Pill('Done', icon: Icons.check, color: FF.teal)
                else
                  Text('${draft.done.length}/${draft.item.sets} sets', style: t.textTheme.labelLarge),
              ]),
              if (draft.done.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final (i, d) in draft.done.indexed)
                    Pill('Set ${i + 1}: ${d.reps}${d.weightKg > 0 ? ' × ${kg(d.weightKg)}' : ''}', color: FF.teal),
                ]),
              ],
              if (active && !complete) ...[
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: _Stepper(
                      label: 'Reps',
                      value: '${draft.reps}',
                      onMinus: () {
                        if (draft.reps > 1) draft.reps--;
                        onChanged();
                      },
                      onPlus: () {
                        draft.reps++;
                        onChanged();
                      },
                    ),
                  ),
                  if (ex.weightKg > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Stepper(
                        label: 'Weight',
                        value: kg(draft.weight),
                        onMinus: () {
                          if (draft.weight >= 2) draft.weight -= 2;
                          onChanged();
                        },
                        onPlus: () {
                          draft.weight += 2;
                          onChanged();
                        },
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: Text('Log set ${draft.done.length + 1}'),
                      onPressed: onLog,
                    ),
                  ),
                  if (draft.done.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton.outlined(tooltip: 'Undo last set', onPressed: onUndo, icon: const Icon(Icons.undo)),
                  ],
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.onMinus, required this.onPlus});

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        IconButton(tooltip: 'Decrease $label', onPressed: onMinus, icon: const Icon(Icons.remove)),
        Expanded(
          child: Column(children: [
            Text(label, style: t.textTheme.labelSmall),
            Text(value, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ]),
        ),
        IconButton(tooltip: 'Increase $label', onPressed: onPlus, icon: const Icon(Icons.add)),
      ]),
    );
  }
}

class _RestBar extends StatelessWidget {
  const _RestBar({required this.seconds, required this.onSkip});

  final int seconds;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return Semantics(
      liveRegion: true,
      label: 'Rest, $seconds seconds left',
      child: Container(
        width: double.infinity,
        color: FF.indigo,
        padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
        child: Row(children: [
          const Icon(Icons.timer_outlined, color: Colors.white),
          const SizedBox(width: 10),
          Text('Rest  $m:$s',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, fontFeatures: [FontFeature.tabularFigures()])),
          const Spacer(),
          TextButton(onPressed: onSkip, child: const Text('Skip', style: TextStyle(color: Colors.white))),
        ]),
      ),
    );
  }
}

/// End-of-session recognition: personal bests and weekly goal (R12).
class _Summary extends StatelessWidget {
  const _Summary({required this.sets, required this.minutes, required this.pbs, required this.weekDone, required this.weekGoal});

  final int sets;
  final int minutes;
  final List<String> pbs;
  final int weekDone;
  final int weekGoal;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final goalMet = weekDone >= weekGoal;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.emoji_events, color: FF.coral, size: 40),
          const SizedBox(height: 8),
          Text('Workout complete', style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('$sets sets in $minutes min'),
          const SizedBox(height: 16),
          if (pbs.isNotEmpty)
            for (final p in pbs)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Pill('New personal best: $p', icon: Icons.trending_up, color: FF.coral),
              ),
          Pill(
            goalMet ? 'Weekly goal reached — $weekDone of $weekGoal' : '$weekDone of $weekGoal sessions this week',
            icon: goalMet ? Icons.verified : Icons.event_available,
            color: goalMet ? FF.teal : FF.indigo,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ),
        ]),
      ),
    );
  }
}
