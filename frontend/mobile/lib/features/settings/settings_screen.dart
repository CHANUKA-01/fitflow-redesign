import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/app_state.dart';
import '../../core/links.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../onboarding/onboarding_screen.dart';

/// Profile, privacy and legal. Export and delete implement the GDPR rights of
/// access/portability and erasure for data held on the device.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.profile;
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & settings')),
      body: ListView(padding: pagePadding(context, 0, 32), children: [
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: t.colorScheme.primaryContainer,
              child: Text(p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                  style: TextStyle(fontSize: 22, color: t.colorScheme.primary, fontWeight: FontWeight.w800)),
            ),
            title: Text(p.name.isEmpty ? 'FitFlow member' : p.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            subtitle: Text('${p.goal.label} · ${p.level.label} · ${p.minutes} min · ${p.equipment.label}'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const OnboardingScreen(editing: true))),
          ),
        ),
        const SectionTitle('Training'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Weekly goal'),
              trailing: DropdownButton<int>(
                value: p.weeklyGoal,
                underline: const SizedBox(),
                items: [for (final n in const [2, 3, 4, 5, 6]) DropdownMenuItem(value: n, child: Text('$n sessions'))],
                onChanged: (v) => s.updateProfile((x) => x.weeklyGoal = v!),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Rest between sets'),
              trailing: DropdownButton<int>(
                value: p.restSeconds,
                underline: const SizedBox(),
                items: [for (final n in const [30, 60, 90, 120, 180]) DropdownMenuItem(value: n, child: Text('$n s'))],
                onChanged: (v) => s.updateProfile((x) => x.restSeconds = v!),
              ),
            ),
          ]),
        ),
        const SectionTitle('Privacy & data'),
        Card(
          child: Column(children: [
            const ListTile(
              leading: Icon(Icons.phonelink_lock_outlined),
              title: Text('Where your data lives'),
              subtitle: Text(
                'This version stores everything on this phone only. Workout planning and food recognition '
                'run on the device. Nothing is sent to FitFlow servers.',
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.health_and_safety_outlined),
              title: const Text('Health data consent'),
              subtitle: const Text('Needed to personalise plans. Turning it off deletes your data.'),
              value: p.healthConsent,
              onChanged: (on) async {
                if (on) return s.updateProfile((x) => x.healthConsent = true);
                await _confirmDelete(context, withdrawing: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export my data'),
              subtitle: const Text('Copy everything FitFlow holds about you as JSON'),
              onTap: () => _export(context, s),
            ),
            ListTile(
              leading: const Icon(Icons.policy_outlined),
              title: const Text('Privacy policy'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openPrivacyPolicy(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: FF.coral),
              title: const Text('Delete all my data', style: TextStyle(color: FF.coral)),
              onTap: () => _confirmDelete(context),
            ),
          ]),
        ),
        const SectionTitle('About'),
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.new_releases_outlined),
              title: const Text('What\'s new'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openUrl(context, Links.releaseNotes),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Help & support'),
              subtitle: const Text(Links.supportEmail),
              onTap: () => openUrl(context, 'mailto:${Links.supportEmail}?subject=FitFlow%20support'),
            ),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (_, snap) => ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                trailing: Text(snap.hasData ? '${snap.data!.version} (${snap.data!.buildNumber})' : '…'),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text(
          'FitFlow provides general fitness and nutrition information. It is not a medical device and does not '
          'diagnose, treat or prevent any condition. Talk to a qualified professional before changing your '
          'exercise or diet if you have a health condition.',
          style: t.textTheme.bodySmall,
        ),
      ]),
    );
  }

  static Future<void> _export(BuildContext context, AppState s) async {
    final json = const JsonEncoder.withIndent('  ').convert(s.exportJson());
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Your data'),
        content: SizedBox(
          width: double.maxFinite,
          height: 360,
          child: SingleChildScrollView(
            child: SelectableText(json, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
          FilledButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: json));
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
            },
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmDelete(BuildContext context, {bool withdrawing = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(withdrawing ? 'Withdraw consent?' : 'Delete all data?'),
        content: const Text(
          'This permanently removes your profile, workouts, meals and posts from this phone. It cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: FF.coral),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    await AppScope.read(context).deleteAllData();
  }
}
