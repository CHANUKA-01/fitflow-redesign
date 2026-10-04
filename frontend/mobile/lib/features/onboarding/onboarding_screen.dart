import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/links.dart';
import '../../core/theme.dart';
import '../../data/models.dart';

/// Three skippable steps (R02). Health-data consent is explicit and separate,
/// because fitness data is special-category data under GDPR Art. 9.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.editing = false});

  /// True when opened from Settings to change answers.
  final bool editing;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final Profile _p;
  late int _step; // -1 = welcome screen
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Work on a copy so backing out of an edit leaves the saved profile untouched.
    _p = Profile.fromJson(AppScope.read(context).profile.toJson());
    _name.text = _p.name;
    _step = widget.editing ? 0 : -1;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _finish() {
    _p.name = _name.text.trim();
    AppScope.read(context).completeOnboarding(_p);
    if (widget.editing) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_step == -1) return _Welcome(onStart: () => setState(() => _step = 0));
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: _step > 0 || widget.editing
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _step > 0 ? setState(() => _step--) : Navigator.of(context).pop(),
              )
            : null,
        title: Text('Step ${_step + 1} of 3', style: t.textTheme.titleSmall),
        actions: [
          if (_step < 2) TextButton(onPressed: _next, child: const Text('Skip')),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_step + 1) / 3, minHeight: 4),
        ),
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.all(20), children: switch (_step) {
              0 => _goalStep(t),
              1 => _abilityStep(t),
              _ => _setupStep(t),
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _step == 2 && !_p.healthConsent ? null : _next,
                child: Text(_step == 2 ? (widget.editing ? 'Save changes' : 'Build my first plan') : 'Continue'),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _goalStep(ThemeData t) => [
        Text('What brings you to FitFlow?', style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Pick one. You can change it any time.', style: t.textTheme.bodyMedium),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'First name (optional)', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 16),
        for (final g in Goal.values)
          _OptionTile(
            icon: switch (g) {
              Goal.strength => Icons.fitness_center,
              Goal.endurance => Icons.directions_run,
              Goal.weightLoss => Icons.local_fire_department_outlined,
              Goal.general => Icons.self_improvement,
            },
            title: g.label,
            selected: _p.goal == g,
            onTap: () => setState(() => _p.goal = g),
          ),
      ];

  List<Widget> _abilityStep(ThemeData t) => [
        Text('How much do you train now?', style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        for (final l in Level.values)
          _OptionTile(
            icon: Icons.signal_cellular_alt,
            title: l.label,
            subtitle: switch (l) {
              Level.beginner => 'New to training or coming back after a break',
              Level.intermediate => 'Training 1–3 times a week',
              Level.advanced => 'Training 4+ times a week',
            },
            selected: _p.level == l,
            onTap: () => setState(() => _p.level = l),
          ),
        const SizedBox(height: 16),
        Text('Time per session', style: t.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final m in const [15, 20, 30, 45, 60])
            ChoiceChip(label: Text('$m min'), selected: _p.minutes == m, onSelected: (_) => setState(() => _p.minutes = m)),
        ]),
        const SizedBox(height: 16),
        Text('Sessions per week', style: t.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final n in const [2, 3, 4, 5])
            ChoiceChip(label: Text('$n'), selected: _p.weeklyGoal == n, onSelected: (_) => setState(() => _p.weeklyGoal = n)),
        ]),
      ];

  List<Widget> _setupStep(ThemeData t) => [
        Text('What do you have to work with?', style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        for (final e in Equipment.values)
          _OptionTile(
            icon: switch (e) {
              Equipment.none => Icons.accessibility_new,
              Equipment.dumbbells => Icons.fitness_center,
              Equipment.gym => Icons.store_mall_directory_outlined,
            },
            title: e.label,
            selected: _p.equipment == e,
            onTap: () => setState(() => _p.equipment = e),
          ),
        const SizedBox(height: 16),
        Text('Any injuries we should work around?', style: t.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final i in Injury.values)
            FilterChip(
              label: Text(i.label),
              selected: _p.injuries.contains(i),
              onSelected: (on) => setState(() => on ? _p.injuries.add(i) : _p.injuries.remove(i)),
            ),
        ]),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(
                value: _p.healthConsent,
                onChanged: (v) => setState(() => _p.healthConsent = v ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      'I agree that FitFlow may store my fitness, workout and nutrition information on this device to personalise my plans.',
                      style: t.textTheme.bodyMedium,
                    ),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => openPrivacyPolicy(context),
                      child: const Text('Read the privacy policy'),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'FitFlow gives general fitness guidance. It is not a medical service. Check with a doctor before starting if you have a health condition.',
          style: t.textTheme.bodySmall,
        ),
      ];
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.icon, required this.title, required this.selected, required this.onTap, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? c.primaryContainer : c.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? c.primary : Colors.transparent, width: 2),
        ),
        child: ListTile(
          minVerticalPadding: 14,
          leading: Icon(icon, color: c.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: subtitle == null ? null : Text(subtitle!),
          trailing: selected ? Icon(Icons.check_circle, color: c.primary) : null,
          onTap: onTap,
          selected: selected,
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [FF.indigo, Color(0xFF312E81), Color(0xFF1E1B4B)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                child: const Icon(Icons.bolt_rounded, color: FF.coral, size: 48),
              ),
              const SizedBox(height: 24),
              Text('FitFlow',
                  style: t.textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('One clear workout a day.\nPlanned for you, explained to you.',
                  style: t.textTheme.titleMedium?.copyWith(color: Colors.white70, height: 1.4)),
              const SizedBox(height: 32),
              for (final (icon, text) in const [
                (Icons.auto_awesome, 'Plans that adapt to your time and energy'),
                (Icons.lock_outline, 'Private circles by default'),
                (Icons.photo_camera_outlined, 'Snap a meal — analysed on your phone'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Icon(icon, color: FF.coral, size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15))),
                  ]),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: FF.coral, foregroundColor: Colors.white),
                  onPressed: onStart,
                  child: const Text('Get started'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Takes under a minute · 3 steps',
                    style: t.textTheme.bodySmall?.copyWith(color: Colors.white60)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
