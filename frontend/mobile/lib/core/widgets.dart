import 'package:flutter/material.dart';

import 'theme.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
        child: Row(children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          ?trailing,
        ]),
      );
}

/// Small rounded label, e.g. difficulty or audience.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.icon, this.color});

  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: c), const SizedBox(width: 4)],
        Flexible(
          child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ),
      ]),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 20, color: t.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: t.textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }
}

/// Explains what an AI feature reads and where it runs (R15).
class AiNotice extends StatelessWidget {
  const AiNotice(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.phonelink_lock_outlined, size: 18, color: t.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: t.textTheme.bodySmall)),
      ]),
    );
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: size + 8,
          height: size + 8,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [FF.indigo, Color(0xFF6D28D9)]),
            borderRadius: BorderRadius.circular(size / 2.5),
          ),
          child: Icon(Icons.bolt_rounded, color: FF.coral, size: size),
        ),
        const SizedBox(width: 8),
        Text('FitFlow',
            style: TextStyle(fontSize: size * 0.9, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      ]);
}

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} h ago';
  if (diff.inDays == 1) return 'yesterday';
  return '${diff.inDays} days ago';
}

String kg(double w) => w == w.roundToDouble() ? '${w.toInt()} kg' : '${w.toStringAsFixed(1)} kg';

/// Page padding that keeps content at a readable width on tablets: 16 dp
/// gutters on phones, centred 720 dp column on wider screens.
EdgeInsets pagePadding(BuildContext context, double top, double bottom) {
  final width = MediaQuery.sizeOf(context).width;
  final side = width > 752 ? (width - 720) / 2 : 16.0;
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}
