import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public URLs referenced from the app and both store listings. The privacy
/// policy is served by GitHub Pages from /site in the repository.
class Links {
  static const privacyPolicy = 'https://chanuka-01.github.io/fitflow-redesign/privacy-policy/';
  static const releaseNotes = 'https://chanuka-01.github.io/fitflow-redesign/release-notes/';
  // Placeholder until the team chooses a public support address.
  static const supportEmail = 'support@fitflow.example';
}

Future<void> openPrivacyPolicy(BuildContext context) => openUrl(context, Links.privacyPolicy);

Future<void> openUrl(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok) messenger?.showSnackBar(SnackBar(content: Text('Could not open $url')));
}
