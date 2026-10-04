import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.create();
  runApp(FitFlowApp(state: state));
}

class FitFlowApp extends StatelessWidget {
  const FitFlowApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
        state: state,
        child: MaterialApp(
          title: 'FitFlow',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          home: const _Root(),
        ),
      );
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final onboarded = AppScope.of(context).profile.onboarded;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: onboarded ? const Shell(key: ValueKey('shell')) : const OnboardingScreen(key: ValueKey('onb')),
    );
  }
}
