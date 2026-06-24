import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kidcost_mobile/src/app.dart';
import 'package:kidcost_mobile/src/features/auth/auth_repository.dart';

void main() {
  testWidgets('opens the KidCost shell after email sign in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      KidCostApp(authRepository: InMemoryAuthRepository()),
    );
    await tester.pump();

    expect(find.text('KidCost'), findsOneWidget);
    expect(find.text('Zaloguj'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'parent@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret1');
    await tester.tap(find.byIcon(Icons.login));
    await tester.pumpAndSettle();

    expect(find.text('Podsumowanie miesiaca'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('bottom navigation exposes the MVP demo sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      KidCostApp(authRepository: InMemoryAuthRepository()),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'parent@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret1');
    await tester.tap(find.byIcon(Icons.login));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dodaj'));
    await tester.pump();

    expect(find.text('Nowy koszt'), findsOneWidget);
    expect(find.text('Zapisz koszt'), findsOneWidget);
  });

  testWidgets('registration validates weak passwords', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      KidCostApp(authRepository: InMemoryAuthRepository()),
    );
    await tester.pump();

    await tester.tap(find.text('Nie masz konta? Utworz konto'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'parent@example.com');
    await tester.enterText(find.byType(TextField).last, '123');
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();

    expect(
      find.text('Haslo jest za slabe. Uzyj co najmniej 6 znakow.'),
      findsOneWidget,
    );
  });

  testWidgets('registration opens the shell for a new email session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      KidCostApp(authRepository: InMemoryAuthRepository()),
    );
    await tester.pump();

    await tester.tap(find.text('Nie masz konta? Utworz konto'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'new@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret1');
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();

    expect(find.text('Podsumowanie miesiaca'), findsOneWidget);
  });

  testWidgets('logout clears the user session', (WidgetTester tester) async {
    await tester.pumpWidget(
      KidCostApp(authRepository: InMemoryAuthRepository()),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'parent@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret1');
    await tester.tap(find.byIcon(Icons.login));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ustawienia'));
    await tester.pumpAndSettle();
    expect(find.text('parent@example.com'), findsOneWidget);

    await tester.tap(find.text('Wyloguj'));
    await tester.pumpAndSettle();

    expect(find.text('Zaloguj'), findsOneWidget);
  });
}
