import 'package:flutter_test/flutter_test.dart';
import 'package:kidcost_mobile/src/features/scenarios/kidcost_user_scenarios.dart';

void main() {
  group('KidCost user scenario catalog', () {
    test('covers every declared product area', () {
      final coveredAreas = kidCostUserScenarios
          .map((scenario) => scenario.area)
          .toSet();

      expect(coveredAreas, containsAll(kidCostScenarioAreas));
    });

    test('uses unique stable scenario IDs', () {
      final ids = kidCostUserScenarios.map((scenario) => scenario.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id, matches(RegExp(r'^[A-Z]+-[0-9]{2}$')));
      }
    });

    test('keeps the catalog broad enough to describe the current app', () {
      expect(kidCostUserScenarios.length, greaterThanOrEqualTo(45));
    });

    test('links each scenario to an automated or source coverage note', () {
      for (final scenario in kidCostUserScenarios) {
        expect(
          scenario.coverage,
          isNotEmpty,
          reason: '${scenario.id} must point at a test or source check.',
        );
        for (final coverage in scenario.coverage) {
          expect(
            coverage.trim(),
            isNotEmpty,
            reason: '${scenario.id} has an empty coverage note.',
          );
        }
      }
    });

    for (final scenario in kidCostUserScenarios) {
      test('${scenario.id} describes who, what, and when', () {
        expect(
          scenario.actor.trim(),
          isNotEmpty,
          reason: '${scenario.id} must say who can act.',
        );
        expect(
          scenario.action.trim(),
          isNotEmpty,
          reason: '${scenario.id} must say what they can do.',
        );
        expect(
          scenario.timing.trim(),
          isNotEmpty,
          reason: '${scenario.id} must say when the action applies.',
        );
        expect(
          scenario.expectedOutcome.trim(),
          isNotEmpty,
          reason: '${scenario.id} must say what should happen.',
        );
        expect(
          scenario.whoWhatWhen.split('|'),
          hasLength(3),
          reason: '${scenario.id} must stay in who / what / when form.',
        );
      });
    }
  });
}
