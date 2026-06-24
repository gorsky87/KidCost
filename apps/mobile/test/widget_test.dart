import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kidcost_mobile/src/app.dart';

void main() {
  testWidgets('opens the KidCost demo shell after demo sign in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KidCostApp());

    expect(find.text('KidCost'), findsOneWidget);
    expect(find.text('Wejdz do demo'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.login));
    await tester.pump();

    expect(find.text('Podsumowanie miesiaca'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('bottom navigation exposes the MVP demo sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KidCostApp());
    await tester.tap(find.byIcon(Icons.login));
    await tester.pump();

    await tester.tap(find.text('Dodaj'));
    await tester.pump();

    expect(find.text('Nowy koszt'), findsOneWidget);
    expect(find.text('Zapisz koszt'), findsOneWidget);
  });
}
