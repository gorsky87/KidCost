import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kidcost_mobile/src/app.dart';
import 'package:kidcost_mobile/src/features/auth/auth_repository.dart';
import 'package:kidcost_mobile/src/features/expenses/attachment_storage.dart';

void main() {
  testWidgets('opens the KidCost shell after email sign in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      KidCostApp(
        authRepository: InMemoryAuthRepository(),
        attachmentStorage: InMemoryAttachmentStorage(),
      ),
    );
    await tester.pump();

    expect(find.text('KidCost'), findsOneWidget);
    expect(find.text('Zaloguj'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'parent@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret1');
    await tester.tap(find.byIcon(Icons.login));
    await tester.pumpAndSettle();
    await completeOnboarding(tester);

    expect(find.text('Podsumowanie miesiaca'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('bottom navigation exposes the MVP demo sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      KidCostApp(
        authRepository: InMemoryAuthRepository(),
        attachmentStorage: InMemoryAttachmentStorage(),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'parent@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret1');
    await tester.tap(find.byIcon(Icons.login));
    await tester.pumpAndSettle();
    await completeOnboarding(tester);

    await tester.tap(find.text('Dodaj'));
    await tester.pump();

    expect(find.text('Nowy koszt'), findsOneWidget);
    await tester.ensureVisible(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();
    expect(find.text('Zapisz koszt'), findsOneWidget);
  });

  testWidgets('registration validates weak passwords', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      KidCostApp(
        authRepository: InMemoryAuthRepository(),
        attachmentStorage: InMemoryAttachmentStorage(),
      ),
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
      KidCostApp(
        authRepository: InMemoryAuthRepository(),
        attachmentStorage: InMemoryAttachmentStorage(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Nie masz konta? Utworz konto'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'new@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret1');
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();
    await completeOnboarding(tester, childName: 'Ola');

    expect(find.text('Podsumowanie miesiaca'), findsOneWidget);
  });

  testWidgets('onboarding can create an invitation code', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      KidCostApp(
        authRepository: InMemoryAuthRepository(),
        attachmentStorage: InMemoryAttachmentStorage(),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'parent@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret1');
    await tester.tap(find.byIcon(Icons.login));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zakladam rodzine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Ola');
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'coparent@example.com',
    );
    await tester.tap(find.text('Wygeneruj kod'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kod zaproszenia: KC-'), findsOneWidget);
    expect(
      find.text('Kod nie ujawnia kosztow ani danych dziecka.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Zakoncz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rodzina'));
    await tester.pumpAndSettle();

    expect(find.text('coparent@example.com'), findsOneWidget);
    expect(
      find.textContaining('nie ujawnia danych rodzinnych'),
      findsOneWidget,
    );
  });

  testWidgets('logout clears the user session', (WidgetTester tester) async {
    await tester.pumpWidget(
      KidCostApp(
        authRepository: InMemoryAuthRepository(),
        attachmentStorage: InMemoryAttachmentStorage(),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'parent@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret1');
    await tester.tap(find.byIcon(Icons.login));
    await tester.pumpAndSettle();
    await completeOnboarding(tester);

    await tester.tap(find.text('Ustawienia'));
    await tester.pumpAndSettle();
    expect(find.text('parent@example.com'), findsOneWidget);

    await tester.tap(find.text('Wyloguj'));
    await tester.pumpAndSettle();

    expect(find.text('Zaloguj'), findsOneWidget);
  });

  testWidgets('add expense validates amount and date', (
    WidgetTester tester,
  ) async {
    await pumpSignedInOnboardedApp(tester);
    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();

    expect(find.text('Podaj kwote wieksza od 0.'), findsOneWidget);
    expect(find.text('Podaj date kosztu.'), findsOneWidget);
  });

  testWidgets('saved expense appears on list and changes balance', (
    WidgetTester tester,
  ) async {
    await pumpSignedInOnboardedApp(tester);
    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '12,50');
    await tester.enterText(find.byType(TextField).at(1), '2026-06-24');
    await tester.enterText(find.byType(TextField).at(2), 'Obiad');
    await tester.ensureVisible(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();

    expect(find.text('Koszt zapisany.'), findsOneWidget);

    await tester.tap(find.text('Koszty'));
    await tester.pumpAndSettle();

    expect(find.text('Obiad'), findsOneWidget);
    expect(find.text('12,50 zl'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('Wydatki razem'), findsOneWidget);
    expect(find.text('12,50 zl'), findsOneWidget);
    expect(find.text('Drugi rodzic oddaje 6,25 zl'), findsOneWidget);
  });

  testWidgets('optional PDF attachment is saved with the expense', (
    WidgetTester tester,
  ) async {
    await pumpSignedInOnboardedApp(tester);
    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '40');
    await tester.enterText(find.byType(TextField).at(1), '2026-06-24');
    await tester.enterText(find.byType(TextField).at(2), 'Faktura');
    await tester.ensureVisible(find.text('Dodaj paragon lub PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dodaj paragon lub PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();
    expect(find.text('rachunek.pdf'), findsOneWidget);

    await tester.tap(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koszty'));
    await tester.pumpAndSettle();

    expect(find.text('Faktura'), findsOneWidget);
    expect(find.textContaining('Zalacznik: rachunek.pdf'), findsOneWidget);
  });
}

Future<void> pumpSignedInOnboardedApp(WidgetTester tester) async {
  await tester.pumpWidget(
    KidCostApp(
      authRepository: InMemoryAuthRepository(),
      attachmentStorage: InMemoryAttachmentStorage(),
    ),
  );
  await tester.pump();
  await tester.enterText(find.byType(TextField).first, 'parent@example.com');
  await tester.enterText(find.byType(TextField).last, 'secret1');
  await tester.tap(find.byIcon(Icons.login));
  await tester.pumpAndSettle();
  await completeOnboarding(tester);
}

Future<void> completeOnboarding(
  WidgetTester tester, {
  String childName = 'Antek',
}) async {
  expect(find.text('Jak zaczynamy?'), findsOneWidget);

  await tester.tap(find.text('Zakladam rodzine'));
  await tester.pumpAndSettle();
  expect(find.text('Nazwij rodzine'), findsOneWidget);

  await tester.tap(find.text('Dalej'));
  await tester.pumpAndSettle();
  expect(find.text('Dodaj dziecko'), findsOneWidget);

  await tester.enterText(find.byType(TextField).first, childName);
  await tester.tap(find.text('Dalej'));
  await tester.pumpAndSettle();
  expect(find.text('Zapros rodzica'), findsOneWidget);

  await tester.tap(find.text('Pomin zaproszenie'));
  await tester.pumpAndSettle();
}
