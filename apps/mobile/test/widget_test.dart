import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kidcost_mobile/src/app.dart';
import 'package:kidcost_mobile/src/features/auth/auth_repository.dart';
import 'package:kidcost_mobile/src/features/expenses/attachment_storage.dart';
import 'package:kidcost_mobile/src/features/expenses/expense_models.dart';
import 'package:kidcost_mobile/src/features/onboarding/onboarding_profile.dart';
import 'package:kidcost_mobile/src/features/shell/screens/dashboard_screen.dart';
import 'package:kidcost_mobile/src/features/shell/screens/expenses_screen.dart';
import 'package:kidcost_mobile/src/features/shell/screens/reports_screen.dart';

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

    expect(find.text('Wydatki w tym miesiacu'), findsOneWidget);
    expect(find.text('12,50 zl'), findsOneWidget);
    expect(
      find.textContaining('Drugi rodzic oddaje Tobie 6,25 zl'),
      findsOneWidget,
    );
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

  testWidgets('expenses list exposes loading and error states', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ExpensesScreen(expenses: [], isLoading: true)),
      ),
    );

    expect(find.text('Ladowanie kosztow'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExpensesScreen(
            expenses: [],
            errorMessage: 'Brak polaczenia z API.',
          ),
        ),
      ),
    );

    expect(find.text('Nie udalo sie pobrac kosztow'), findsOneWidget);
    expect(find.text('Brak polaczenia z API.'), findsOneWidget);
  });

  testWidgets('expenses list filters costs and can clear filters', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpensesScreen(
            expenses: [
              testExpense(id: '1', title: 'Obiad', amountCents: 1250),
              testExpense(
                id: '2',
                title: 'Lekarz',
                amountCents: 9000,
                expenseDate: '2026-05-03',
                category: expenseCategories[3],
                status: ExpenseStatus.accepted,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Obiad'), findsOneWidget);
    expect(find.text('Lekarz'), findsOneWidget);

    await tester.tap(find.text('Pokaz filtry i sortowanie'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lekarze i leki').last);
    await tester.pumpAndSettle();

    expect(find.text('Lekarz'), findsOneWidget);
    expect(find.text('Obiad'), findsNothing);

    await tester.tap(find.text('Wyczysc'));
    await tester.pumpAndSettle();

    expect(find.text('Obiad'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Lekarz'), 120);
    expect(find.text('Lekarz'), findsOneWidget);
  });

  testWidgets('expense details show attachment preview and edit lock', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpensesScreen(
            expenses: [
              testExpense(
                id: '1',
                title: 'Faktura',
                attachment: const ExpenseAttachment(
                  fileName: 'rachunek.pdf',
                  contentType: 'application/pdf',
                  status: AttachmentStatus.uploaded,
                  storagePath: 'expenses/rachunek.pdf',
                ),
              ),
              testExpense(
                id: '2',
                title: 'Sporne leki',
                category: expenseCategories[3],
                status: ExpenseStatus.disputed,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Faktura'));
    await tester.pumpAndSettle();

    expect(find.text('Szczegoly kosztu'), findsOneWidget);
    expect(find.text('Podglad PDF: rachunek.pdf'), findsOneWidget);
    expect(find.text('Edytuj koszt'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sporne leki'));
    await tester.pumpAndSettle();

    expect(find.text('Brak zalacznika'), findsOneWidget);
    expect(find.text('Edycja zablokowana przez status'), findsOneWidget);
  });

  testWidgets('dashboard shows empty state and CTA opens add expense', (
    WidgetTester tester,
  ) async {
    await pumpSignedInOnboardedApp(tester);

    expect(find.text('Brak kosztow w tym miesiacu'), findsOneWidget);

    await tester.tap(find.text('Dodaj koszt'));
    await tester.pumpAndSettle();

    expect(find.text('Nowy koszt'), findsOneWidget);
  });

  testWidgets('dashboard CTA opens monthly reports', (
    WidgetTester tester,
  ) async {
    await pumpSignedInOnboardedApp(tester);

    await tester.tap(find.text('Raport miesiaca'));
    await tester.pumpAndSettle();

    expect(find.text('Raport miesieczny'), findsOneWidget);
    expect(find.text('Eksport'), findsOneWidget);
  });

  testWidgets('dashboard summarizes current month balance and recent costs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardScreen(
            profile: testProfile(),
            currentDate: DateTime.utc(2026, 6, 24),
            expenses: [
              testExpense(id: '1', title: 'Obiad', amountCents: 12000),
              testExpense(
                id: '2',
                title: 'Lekarz',
                amountCents: 6000,
                expenseDate: '2026-06-20',
                category: expenseCategories[3],
                paidBy: const ExpensePayer(
                  id: 'co-parent',
                  label: 'Drugi rodzic',
                  isCurrentUser: false,
                ),
              ),
              testExpense(
                id: '3',
                title: 'Majowy koszt',
                amountCents: 9900,
                expenseDate: '2026-05-20',
              ),
            ],
            onAddExpense: () {},
            onOpenReports: () {},
          ),
        ),
      ),
    );

    expect(find.text('Wydatki w tym miesiacu'), findsOneWidget);
    expect(find.text('180,00 zl\n2026-06'), findsOneWidget);
    expect(find.text('Ty zaplaciles'), findsOneWidget);
    expect(find.text('120,00 zl'), findsWidgets);
    expect(find.text('Drugi rodzic zaplacil'), findsOneWidget);
    expect(find.text('60,00 zl'), findsWidgets);
    expect(
      find.textContaining('Drugi rodzic oddaje Tobie 30,00 zl'),
      findsOneWidget,
    );
    expect(find.text('Ostatnie koszty'), findsOneWidget);
    expect(find.text('Lekarz'), findsOneWidget);
    expect(find.text('Obiad'), findsOneWidget);
    expect(find.text('Majowy koszt'), findsNothing);
  });

  testWidgets('dashboard explains when only co-parent paid this month', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardScreen(
            profile: testProfile(),
            currentDate: DateTime.utc(2026, 6, 24),
            expenses: [
              testExpense(
                id: '1',
                title: 'Dentysta',
                amountCents: 8000,
                paidBy: const ExpensePayer(
                  id: 'co-parent',
                  label: 'Drugi rodzic',
                  isCurrentUser: false,
                ),
              ),
            ],
            onAddExpense: () {},
            onOpenReports: () {},
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Ty oddajesz drugiemu rodzicowi 40,00 zl'),
      findsOneWidget,
    );
    expect(find.text('Drugi rodzic zaplacil'), findsOneWidget);
    expect(find.text('80,00 zl'), findsWidgets);
  });

  testWidgets('monthly reports summarize costs and expose CSV export', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportsScreen(
            currentDate: DateTime.utc(2026, 6, 24),
            expenses: [
              testExpense(id: '1', title: 'Obiad', amountCents: 12000),
              testExpense(
                id: '2',
                title: 'Lekarz',
                amountCents: 6000,
                expenseDate: '2026-06-20',
                category: expenseCategories[3],
                paidBy: const ExpensePayer(
                  id: 'co-parent',
                  label: 'Drugi rodzic',
                  isCurrentUser: false,
                ),
                status: ExpenseStatus.disputed,
              ),
              testExpense(
                id: '3',
                title: 'Majowy koszt',
                amountCents: 9900,
                expenseDate: '2026-05-20',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Raport miesieczny'), findsOneWidget);
    expect(find.text('Suma kosztow'), findsOneWidget);
    expect(find.text('180,00 zl'), findsWidgets);
    expect(find.text('Koszty sporne'), findsOneWidget);
    expect(find.text('60,00 zl'), findsWidgets);
    expect(find.text('Koszty nierozliczone'), findsOneWidget);
    expect(find.text('120,00 zl'), findsWidgets);
    expect(find.text('Suma per rodzic'), findsOneWidget);
    expect(find.text('parent@example.com'), findsOneWidget);
    expect(find.text('Drugi rodzic'), findsOneWidget);
    expect(find.text('Suma per dziecko'), findsOneWidget);
    expect(find.text('Antek'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Suma per kategoria'), 180);
    expect(find.text('Suma per kategoria'), findsOneWidget);
    expect(find.text('Jedzenie'), findsOneWidget);
    expect(find.text('Lekarze i leki'), findsOneWidget);
    expect(find.text('Majowy koszt'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('CSV: kidcost-report-2026-06.csv'),
      180,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSV: kidcost-report-2026-06.csv'));
    await tester.pumpAndSettle();

    expect(find.text('Eksport CSV'), findsOneWidget);
    expect(find.text('kidcost-report-2026-06.csv'), findsOneWidget);
    expect(find.textContaining('"data","tytul","dziecko"'), findsOneWidget);
    expect(find.textContaining('"2026-06-20","Lekarz"'), findsOneWidget);
  });

  testWidgets('monthly reports handle empty selected month', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportsScreen(
            currentDate: DateTime.utc(2026, 6, 24),
            expenses: [
              testExpense(
                id: '1',
                title: 'Majowy koszt',
                amountCents: 9900,
                expenseDate: '2026-05-20',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Brak kosztow w tym miesiacu'), findsOneWidget);
    expect(find.text('0,00 zl'), findsWidgets);
    expect(find.text('CSV: kidcost-report-2026-06.csv'), findsOneWidget);
    expect(find.text('PDF wymaga generatora'), findsOneWidget);
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

ExpenseEntry testExpense({
  required String id,
  required String title,
  int amountCents = 1000,
  String expenseDate = '2026-06-24',
  ExpenseCategory? category,
  ExpensePayer paidBy = const ExpensePayer(
    id: 'self',
    label: 'parent@example.com',
    isCurrentUser: true,
  ),
  ExpenseStatus status = ExpenseStatus.pending,
  ExpenseAttachment? attachment,
}) {
  return ExpenseEntry(
    id: id,
    amountCents: amountCents,
    expenseDate: expenseDate,
    childName: 'Antek',
    category: category ?? expenseCategories.first,
    paidBy: paidBy,
    title: title,
    status: status,
    createdAt: DateTime.utc(2026, 6, 24),
    attachment: attachment,
  );
}

OnboardingProfile testProfile() {
  return const OnboardingProfile(
    familyName: 'Rodzina Testowa',
    childName: 'Antek',
    invitationSkipped: true,
  );
}
