import 'package:fitflow/core/app_state.dart';
import 'package:fitflow/data/models.dart';
import 'package:fitflow/data/planner.dart';
import 'package:fitflow/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Planner', () {
    const planner = Planner();

    test('respects injuries (R03)', () {
      final p = Profile(equipment: Equipment.gym, injuries: {Injury.knee, Injury.shoulder});
      final plan = planner.generate(profile: p, energy: Energy.normal);
      for (final item in plan.items) {
        expect(item.exercise.avoidFor.intersection(p.injuries), isEmpty, reason: item.exercise.name);
      }
    });

    test('only uses available equipment', () {
      final plan = planner.generate(profile: Profile(equipment: Equipment.none), energy: Energy.normal);
      expect(plan.items.every((i) => i.exercise.equipment == Equipment.none), isTrue);
    });

    test('always explains itself, strongest reason first (R04)', () {
      final plan = planner.generate(profile: Profile(goal: Goal.strength), energy: Energy.low);
      expect(plan.reasons.first, contains('strength'));
      expect(plan.reasons.any((r) => r.contains('energy is low')), isTrue);
    });

    test('low energy reduces volume', () {
      final p = Profile(level: Level.advanced);
      final normal = planner.generate(profile: p, energy: Energy.normal);
      final low = planner.generate(profile: p, energy: Energy.low);
      expect(low.items.first.sets, lessThan(normal.items.first.sets));
    });
  });

  testWidgets('first launch shows welcome, then three skippable steps (R02)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.create();
    await tester.pumpWidget(FitFlowApp(state: state));
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Skip'), findsNothing, reason: 'consent step cannot be skipped');
  });
}
