import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kidcost_mobile/src/app.dart';
import 'package:kidcost_mobile/src/features/auth/auth_repository.dart';
import 'package:kidcost_mobile/src/features/custody/custody_models.dart';
import 'package:kidcost_mobile/src/features/expenses/attachment_storage.dart';
import 'package:kidcost_mobile/src/features/expenses/expense_models.dart';
import 'package:kidcost_mobile/src/features/expenses/expense_visuals.dart';
import 'package:kidcost_mobile/src/features/onboarding/onboarding_profile.dart';
import 'package:kidcost_mobile/src/features/premium/premium_discovery.dart';
import 'package:kidcost_mobile/src/features/shell/screens/add_expense_screen.dart';
import 'package:kidcost_mobile/src/features/shell/screens/dashboard_screen.dart';
import 'package:kidcost_mobile/src/features/shell/screens/custody_calendar_screen.dart';
import 'package:kidcost_mobile/src/features/shell/screens/expenses_screen.dart';
import 'package:kidcost_mobile/src/features/shell/screens/reports_screen.dart';
import 'package:kidcost_mobile/src/features/shell/screens/settings_screen.dart';
import 'package:kidcost_mobile/src/telemetry/app_telemetry.dart';
import 'package:kidcost_mobile/src/theme/kidcost_theme.dart';

Future<void> dragUntilPresent(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
  Offset delta = const Offset(0, -700),
}) async {
  final targetScrollable = scrollable ?? find.byType(ListView).first;
  for (var attempt = 0; attempt < 8 && finder.evaluate().isEmpty; attempt++) {
    await tester.drag(targetScrollable, delta);
    await tester.pumpAndSettle();
  }
  expect(finder, findsOneWidget);
}

Finder editableTextByKey(Key key) {
  return find.descendant(
    of: find.byKey(key),
    matching: find.byType(EditableText),
  );
}

void main() {
  testWidgets('theme exposes the Calm Ledger brand palette', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KidCostTheme.light(),
        home: Builder(
          builder: (context) {
            return const Text('brand theme');
          },
        ),
      ),
    );

    expect(
      Theme.of(tester.element(find.byType(Text))).colorScheme.primary,
      KidCostTheme.primary,
    );
    expect(
      Theme.of(tester.element(find.byType(Text))).colorScheme.secondary,
      KidCostTheme.secondary,
    );
    expect(
      Theme.of(tester.element(find.byType(Text))).scaffoldBackgroundColor,
      KidCostTheme.surface,
    );
  });

  testWidgets('core MVP screens stay usable with large text and tap targets', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: KidCostTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: DashboardScreen(
              profile: testProfile(),
              expenses: [testExpense(id: '1', title: 'Obiad')],
              custodyDays: const [],
              currentDate: DateTime.utc(2026, 6, 24),
              onAddExpense: () {},
              onQuickReceiptDraft: () {},
              onOpenExpenses: () {},
              onOpenReports: () {},
              onOpenFamily: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final addExpenseButton = find.widgetWithText(FilledButton, 'Dodaj koszt');
    expect(addExpenseButton, findsOneWidget);
    expect(tester.getSize(addExpenseButton).height, greaterThanOrEqualTo(48));

    await tester.pumpWidget(
      MaterialApp(
        theme: KidCostTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: AddExpenseScreen(
              profile: testProfile(),
              userEmail: 'parent@example.com',
              attachmentStorage: InMemoryAttachmentStorage(),
              onExpenseSaved: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final saveExpenseButton = find.widgetWithText(FilledButton, 'Zapisz koszt');
    await tester.ensureVisible(saveExpenseButton);
    await tester.pumpAndSettle();

    expect(saveExpenseButton, findsOneWidget);
    expect(tester.getSize(saveExpenseButton).height, greaterThanOrEqualTo(48));
  });

  testWidgets('expense visuals cover MVP categories and statuses', (_) async {
    const expectedCategoryIds = {
      'food',
      'clothes',
      'school',
      'health',
      'activities',
      'holiday',
      'transport',
      'other',
    };

    expect(expenseCategories.map((category) => category.id).toSet(), {
      ...expectedCategoryIds,
    });
    expect(
      expenseCategories.map((category) => category.icon).toSet(),
      hasLength(expenseCategories.length),
    );
    for (final category in expenseCategories) {
      expect(category.accentColor, isA<Color>());
      expect(category.iconAssetPath, endsWith('${category.id}.svg'));
    }

    expect(
      ExpenseStatus.values.map((status) => status.icon).toSet(),
      hasLength(ExpenseStatus.values.length),
    );
    for (final status in ExpenseStatus.values) {
      expect(status.accentColor, isA<Color>());
      expect(status.iconAssetPath, endsWith('.svg'));
      expect(status.label, isNotEmpty);
    }
  });

  testWidgets('telemetry sanitizer removes PII and precise amounts', (_) async {
    final sanitized = sanitizeTelemetryParameters({
      'screen': 'dashboard',
      'category_id': 'school',
      'from_status': 'pending',
      'to_status': 'accepted',
      'actor': 'counterparty',
      'has_status_comment': false,
      'email': 'parent@example.com',
      'child_name': 'Antek',
      'amount': '42.99',
      'content_type': 'application/pdf',
      'release_channel': 'beta',
      'trigger': 'after_first_balance_viewed',
      'surface': 'settings',
      'plan_context': 'family',
      'feature': 'receipt_ocr',
      'reason_code': 'too_early',
      'access_scope': 'selected_report',
      'audit_action': 'report_viewed',
      'expires_in_days': 14,
      'professional_role': 'mediator',
      'report_month': '2026-06',
    });

    expect(sanitized, {
      'screen': 'dashboard',
      'category_id': 'school',
      'from_status': 'pending',
      'to_status': 'accepted',
      'actor': 'counterparty',
      'has_status_comment': false,
      'content_type': 'application/pdf',
      'release_channel': 'beta',
      'trigger': 'after_first_balance_viewed',
      'surface': 'settings',
      'plan_context': 'family',
      'feature': 'receipt_ocr',
      'reason_code': 'too_early',
      'access_scope': 'selected_report',
      'audit_action': 'report_viewed',
      'expires_in_days': 14,
      'professional_role': 'mediator',
      'report_month': '2026-06',
    });
  });

  testWidgets('signup and onboarding emit safe telemetry events', (
    WidgetTester tester,
  ) async {
    final telemetry = RecordingTelemetry();

    await tester.pumpWidget(
      KidCostApp(
        authRepository: InMemoryAuthRepository(),
        attachmentStorage: InMemoryAttachmentStorage(),
        telemetry: telemetry,
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

    expect(telemetry.eventNames, contains('signup_started'));
    expect(telemetry.eventNames, contains('signup_completed'));
    expect(telemetry.eventNames, contains('family_created'));
    expect(telemetry.eventNames, contains('child_added'));
    expect(
      telemetry.events.any((event) => event.parameters.values.contains('Ola')),
      isFalse,
    );
    expect(
      telemetry.events.any(
        (event) => event.parameters.values.contains('new@example.com'),
      ),
      isFalse,
    );
  });

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
      find.byType(TextField).at(1),
      'coparent@example.com',
    );
    await tester.tap(find.text('Wygeneruj kod'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kod zaproszenia: KC-'), findsOneWidget);
    expect(
      find.text('Kod nie ujawnia kosztow ani danych dziecka.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Prywatnosc i zaufanie'));
    await tester.pumpAndSettle();
    expect(find.text('Prywatnosc i zaufanie'), findsWidgets);
    expect(
      find.text(
        'Dane rodziny widza tylko osoby z aktywnym dostepem do tej rodziny.',
      ),
      findsOneWidget,
    );
    expect(find.text('Historia zmian'), findsOneWidget);
    expect(
      find.text(
        'KidCost pomaga dokumentowac koszty, ale nie zastepuje porady prawnej.',
      ),
      findsOneWidget,
    );

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 500));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Zakoncz'));
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
    expect(find.text('Powiadomienia'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Eksport danych rodziny'), 120);
    expect(find.text('Eksport danych rodziny'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Polityka prywatnosci'), 120);
    expect(find.text('Polityka prywatnosci'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Regulamin'), 120);
    expect(find.text('Regulamin'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Kontakt support'), 120);
    expect(find.text('Kontakt support'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Brak porad prawnych'), 120);
    expect(find.text('Brak porad prawnych'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('parent@example.com'), 120);
    expect(find.text('parent@example.com'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Wyloguj'), 120);
    await tester.tap(find.text('Wyloguj'));
    await tester.pumpAndSettle();

    expect(find.text('Zaloguj'), findsOneWidget);
  });

  testWidgets('settings exposes contextual notification controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsScreen(
            userEmail: 'parent@example.com',
            isDemoSession: true,
            onSignOut: () async {},
          ),
        ),
      ),
    );

    expect(find.text('Powiadomienia'), findsOneWidget);
    expect(find.text('Nowy koszt od drugiego rodzica'), findsOneWidget);
    expect(find.text('Zmiana statusu kosztu'), findsOneWidget);
    expect(find.text('Przypomnienie o saldzie'), findsOneWidget);

    await tester.tap(find.text('Przypomnienie o saldzie'));
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNWidgets(3));

    await tester.tap(find.text('Wlacz powiadomienia po pierwszym koszcie'));
    await tester.pumpAndSettle();
    expect(
      find.text('Poprosimy o zgode dopiero w kontekscie wspolnego kosztu.'),
      findsOneWidget,
    );
  });

  testWidgets('settings downgrade flow preserves records and safe telemetry', (
    WidgetTester tester,
  ) async {
    final telemetry = RecordingTelemetry();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsScreen(
            userEmail: 'parent@example.com',
            isDemoSession: true,
            telemetry: telemetry,
            onSignOut: () async {},
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Zobacz opcje anulowania'), 120);
    await tester.ensureVisible(find.text('Zobacz opcje anulowania'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zobacz opcje anulowania'));
    await tester.pumpAndSettle();

    expect(find.text('Anulowanie Premium bez presji'), findsOneWidget);
    expect(find.textContaining('Po anulowaniu nadal widzisz'), findsWidgets);
    expect(find.textContaining('App Store albo Google Play'), findsOneWidget);
    expect(find.textContaining('OCR, PDF i bundle dowodow'), findsOneWidget);

    await tester.tap(find.byKey(const Key('premium-cancel-reason-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Za drogo').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Przejdz na Free'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Przejdz na Free'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Rekordy zostaja czytelne i eksportowalne'),
      findsOneWidget,
    );
    expect(telemetry.eventNames, [
      'premium_cancellation_started',
      'premium_cancellation_reason_selected',
      'premium_cancellation_save_path_selected',
    ]);
    expect(telemetry.events[1].parameters['reason_code'], 'too_expensive');
    expect(telemetry.events[2].parameters['save_path'], 'switch_to_free');
    expect(telemetry.events[2].parameters['platform_handoff'], isTrue);
    expect(
      telemetry.events.any(
        (event) => event.parameters.values.contains('parent@example.com'),
      ),
      isFalse,
    );
  });

  testWidgets('settings exposes family data export request scope', (
    WidgetTester tester,
  ) async {
    var exportRequests = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsScreen(
            userEmail: 'parent@example.com',
            isDemoSession: true,
            onRequestFamilyExport: () async {
              exportRequests += 1;
            },
            onSignOut: () async {},
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Eksport danych rodziny'), 160);
    expect(find.text('Eksport danych rodziny'), findsOneWidget);
    expect(find.textContaining('bez danych innych rodzin'), findsOneWidget);
    expect(
      find.textContaining('audit log i metadane zalacznikow'),
      findsOneWidget,
    );
    expect(
      find.textContaining('same prywatne pliki nie sa kopiowane'),
      findsOneWidget,
    );

    final exportButton = find.widgetWithText(FilledButton, 'Przygotuj eksport');
    await tester.ensureVisible(exportButton);
    await tester.pumpAndSettle();
    await tester.tap(exportButton);
    await tester.pumpAndSettle();

    expect(exportRequests, 1);
    expect(find.text('Eksport zlecony'), findsOneWidget);
    expect(
      find.textContaining('Pliki zalacznikow pozostaja poza paczka MVP'),
      findsOneWidget,
    );
  });

  testWidgets('premium discovery stays calm and dismissible', (
    WidgetTester tester,
  ) async {
    final dismissed = <PremiumDiscoveryPoint>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportsScreen(
            currentDate: DateTime.utc(2026, 6, 24),
            showReportExportPremiumHint: true,
            onPremiumHintDismissed: dismissed.add,
            expenses: [testExpense(id: '1', title: 'Obiad')],
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Raport gotowy do rozmowy'), 180);
    expect(find.text('Raport gotowy do rozmowy'), findsOneWidget);
    expect(find.textContaining('podstawowy CSV zostaja'), findsOneWidget);
    expect(find.text('CSV: kidcost-report-2026-06.csv'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Ukryj na teraz'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ukryj na teraz'));
    await tester.pumpAndSettle();

    expect(dismissed, [PremiumDiscoveryPoint.reportExport]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsScreen(
            userEmail: 'parent@example.com',
            isDemoSession: true,
            showAccountPlanPremiumHint: true,
            onPremiumHintDismissed: dismissed.add,
            onSignOut: () async {},
          ),
        ),
      ),
    );

    expect(find.text('Premium bez presji'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Zakres MVP i przyszlego Premium'),
      120,
    );
    expect(find.text('MVP/basic'), findsOneWidget);
    expect(find.text('Kandydaci Premium'), findsOneWidget);
    expect(find.text('Downgrade'), findsOneWidget);
    expect(find.text('Platnik rodzinny'), findsOneWidget);
    expect(find.textContaining('zalaczniki do limitu'), findsOneWidget);
    expect(find.textContaining('platnosc nie daje wylacznej'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Fee-waiver i dostep po lapse'),
      120,
    );
    expect(
      find.textContaining('Premium automatyzacje sa wstrzymane'),
      findsOneWidget,
    );
    expect(find.textContaining('minimalnego formularza'), findsOneWidget);

    final paywallPreviewButton = find.widgetWithText(
      TextButton,
      'Podglad Premium i trial',
    );
    await tester.ensureVisible(paywallPreviewButton);
    await tester.pumpAndSettle();
    await tester.tap(paywallPreviewButton);
    await tester.pumpAndSettle();

    expect(find.text('Premium po pierwszej wartosci'), findsOneWidget);
    expect(find.textContaining('platnik nie staje sie'), findsOneWidget);
    expect(find.textContaining('Bez subskrypcji nadal'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Przed pierwszym recznym kosztem'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Przed pierwszym recznym kosztem'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Zobacz trial'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Zobacz trial'), findsOneWidget);
  });

  testWidgets('add expense validates amount and date', (
    WidgetTester tester,
  ) async {
    await pumpSignedInOnboardedApp(tester);
    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Zapisz koszt'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Zapisz koszt'));
    await tester.pumpAndSettle();

    expect(find.text('Podaj kwote wieksza od 0.'), findsOneWidget);
    expect(find.text('Podaj date kosztu.'), findsOneWidget);
  });

  testWidgets('add expense uses quick categories and optional description', (
    WidgetTester tester,
  ) async {
    await pumpSignedInOnboardedApp(tester);
    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '30');
    await tester.ensureVisible(find.text('Lekarze i leki'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lekarze i leki'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Koszty'));
    await tester.pumpAndSettle();

    expect(find.text('Lekarze i leki'), findsWidgets);
    expect(find.text('30,00 PLN'), findsOneWidget);
  });

  testWidgets('add expense keeps foreign receipt currency informational', (
    WidgetTester tester,
  ) async {
    ExpenseEntry? savedExpense;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddExpenseScreen(
            profile: testProfile(),
            userEmail: 'parent@example.com',
            attachmentStorage: InMemoryAttachmentStorage(),
            onExpenseSaved: (expense) => savedExpense = expense,
          ),
        ),
      ),
    );

    expect(find.text('Saldo rodziny: PLN'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '120');
    await tester.scrollUntilVisible(
      find.byKey(const Key('receipt-currency-picker')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('receipt-currency-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUR').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Paragon jest w EUR'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('original-receipt-amount-field')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      editableTextByKey(const Key('original-receipt-amount-field')),
      '25,50',
    );
    await tester.ensureVisible(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();

    expect(find.text('Potwierdz walute rozliczenia'), findsOneWidget);
    expect(find.textContaining('KidCost nie liczy kursow'), findsOneWidget);
    await tester.tap(find.text('Zapisz w walucie rodziny'));
    await tester.pumpAndSettle();

    expect(savedExpense, isNotNull);
    expect(savedExpense!.amountCents, 12000);
    expect(savedExpense!.originalReceiptAmountCents, 2550);
    expect(savedExpense!.originalReceiptCurrency, 'EUR');
    expect(savedExpense!.originalReceiptAmountLabel, '25,50 EUR');
  });

  testWidgets('add expense can link an existing calendar event', (
    WidgetTester tester,
  ) async {
    ExpenseEntry? savedExpense;
    const event = ExpenseCalendarEventLink(
      id: 'custody-2026-06-24',
      title: 'Opieka: Drugi rodzic',
      eventDate: '2026-06-24',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddExpenseScreen(
            profile: testProfile(),
            userEmail: 'parent@example.com',
            attachmentStorage: InMemoryAttachmentStorage(),
            calendarEvents: const [event],
            onExpenseSaved: (expense) => savedExpense = expense,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), '42');
    await tester.scrollUntilVisible(
      find.byKey(const Key('expense-calendar-event-picker')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('expense-calendar-event-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(event.displayLabel).last);
    await tester.pumpAndSettle();

    expect(find.text('Opieka: Drugi rodzic'), findsOneWidget);
    expect(find.textContaining('szczegolach wydarzenia'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Zapisz koszt'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Zapisz koszt'));
    await tester.pumpAndSettle();

    expect(savedExpense, isNotNull);
    expect(savedExpense!.calendarEventId, 'custody-2026-06-24');
    expect(savedExpense!.calendarEventTitle, 'Opieka: Drugi rodzic');
    expect(savedExpense!.calendarEventDate, '2026-06-24');
  });

  testWidgets('add expense previews shared agreement rules and thresholds', (
    WidgetTester tester,
  ) async {
    await pumpSignedInOnboardedApp(tester);
    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();

    expect(find.text('Regula kosztu: Jedzenie'), findsOneWidget);
    expect(find.text('Domyslny podzial 50/50.'), findsOneWidget);
    expect(find.textContaining('nie jest porada prawna'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '250');
    await tester.ensureVisible(find.text('Zajecia dodatkowe'));
    await tester.tap(find.text('Zajecia dodatkowe'));
    await tester.pumpAndSettle();

    expect(find.text('Regula kosztu: Zajecia dodatkowe'), findsOneWidget);
    expect(find.textContaining('prog uprzedniej zgody'), findsOneWidget);
    expect(find.textContaining('pending'), findsOneWidget);
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
    expect(find.text('12,50 PLN'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('Wydatki w tym miesiacu'),
      120,
    );
    expect(find.textContaining('Wydatki w tym miesiacu'), findsOneWidget);
    expect(
      find.textContaining('Drugi rodzic oddaje Tobie 6,25 PLN'),
      findsOneWidget,
    );
  });

  testWidgets('recurring template prefills a manually confirmed expense', (
    WidgetTester tester,
  ) async {
    await pumpSignedInOnboardedApp(tester);

    await tester.tap(find.text('Szablony'));
    await tester.pumpAndSettle();

    expect(find.text('Brak szablonow'), findsOneWidget);
    await tester.tap(find.text('Dodaj szablon'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Przedszkole');
    await tester.enterText(find.byType(TextField).at(1), '650');
    await tester.enterText(find.byType(TextField).at(2), '2026-07-01');
    await tester.enterText(find.byType(TextField).at(3), 'Czesne lipiec');
    await tester.ensureVisible(find.text('Zapisz szablon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz szablon'));
    await tester.pumpAndSettle();

    expect(find.text('Przedszkole'), findsOneWidget);
    expect(find.text('650,00 PLN'), findsOneWidget);

    await tester.tap(find.text('Utworz koszt'));
    await tester.pumpAndSettle();

    expect(find.text('Koszt z szablonu: Przedszkole'), findsOneWidget);
    expect(find.text('650,00'), findsOneWidget);
    expect(find.text('2026-07-01'), findsOneWidget);
    expect(find.text('Czesne lipiec'), findsOneWidget);

    await tester.ensureVisible(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Koszty'));
    await tester.pumpAndSettle();

    expect(find.text('Czesne lipiec'), findsOneWidget);
    expect(find.textContaining('Szablon: Przedszkole'), findsOneWidget);
  });

  testWidgets('solo mode saves private manual co-parent expenses', (
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
    await completeOnboarding(tester, coParentLabel: 'Mama Oli');

    expect(find.text('Pracujesz solo'), findsOneWidget);
    expect(
      find.textContaining('Etykieta drugiego rodzica: Mama Oli'),
      findsOneWidget,
    );

    await tester.tap(find.text('Dodaj koszt'));
    await tester.pumpAndSettle();
    expect(find.text('Tryb solo'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '20');
    await tester.enterText(find.byType(TextField).at(1), '2026-06-24');
    await tester.enterText(find.byType(TextField).at(2), 'Lek');
    await tester.ensureVisible(find.byKey(const Key('expense-payer-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-payer-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mama Oli').last);
    await tester.pumpAndSettle();
    expect(find.text('Reczna etykieta platnika'), findsOneWidget);
    await tester.ensureVisible(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Koszty'));
    await tester.pumpAndSettle();

    expect(find.text('Lek'), findsOneWidget);
    expect(find.textContaining('Mama Oli'), findsWidgets);
    expect(find.textContaining('platnik bez konta'), findsOneWidget);
    expect(find.text('Prywatny koszt solo'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Saldo robocze'), 120);
    expect(find.text('Saldo robocze'), findsOneWidget);
    expect(
      find.textContaining('Roboczo: Ty oddajesz Mama Oli 10,00 PLN'),
      findsOneWidget,
    );
  });

  testWidgets('expense status action emits sanitized telemetry', (
    WidgetTester tester,
  ) async {
    final telemetry = RecordingTelemetry();
    await pumpSignedInOnboardedApp(tester, telemetry: telemetry);

    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '45');
    await tester.enterText(find.byType(TextField).at(1), '2026-06-24');
    await tester.enterText(find.byType(TextField).at(2), 'Basen');
    await tester.ensureVisible(find.byKey(const Key('expense-payer-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('expense-payer-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drugi rodzic').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Koszty'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basen'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Zaakceptuj koszt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zaakceptuj koszt'));
    await tester.pumpAndSettle();

    final statusEvents = telemetry.events
        .where((event) => event.event == TelemetryEvent.expenseStatusChanged)
        .toList();
    expect(statusEvents, hasLength(1));
    expect(statusEvents.single.parameters, {
      'from_status': 'pending',
      'to_status': 'accepted',
      'actor': 'counterparty',
      'has_status_comment': false,
      'release_channel': 'demo',
    });
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
    expect(find.text('Aparat'), findsOneWidget);
    expect(find.text('Galeria'), findsOneWidget);
    await tester.tap(find.text('PDF'));
    await tester.pumpAndSettle();
    expect(find.text('rachunek.pdf'), findsOneWidget);
    expect(find.text('Gotowy do wyslania'), findsOneWidget);
    expect(find.text('Szybsze przepisywanie paragonow'), findsOneWidget);
    expect(find.textContaining('reczne pola zostaja'), findsOneWidget);
    expect(find.text('Typ dowodu'), findsOneWidget);
    expect(
      find.textContaining('To pomaga uporzadkowac dokumenty'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(const Key('evidence-type-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('evidence-type-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Faktura imienna').last);
    await tester.pumpAndSettle();
    expect(find.text('Faktura imienna'), findsOneWidget);
    expect(find.textContaining('konkretnego kupujacego'), findsOneWidget);
    expect(find.text('Podejrzyj'), findsOneWidget);
    expect(find.text('Zamien'), findsOneWidget);
    expect(find.text('Usun'), findsOneWidget);
    expect(find.text('Dodaj kolejny'), findsOneWidget);
    expect(find.text('Zapisz bez paragonu'), findsOneWidget);
    expect(find.textContaining('caly paragon'), findsOneWidget);

    await tester.ensureVisible(find.text('Podejrzyj'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Podejrzyj'));
    await tester.pumpAndSettle();
    expect(find.textContaining('application/pdf'), findsWidgets);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koszty'));
    await tester.pumpAndSettle();

    expect(find.text('Faktura'), findsOneWidget);
    expect(find.textContaining('Zalacznik: rachunek.pdf'), findsOneWidget);
    expect(find.textContaining('Dowod: Faktura imienna'), findsOneWidget);
  });

  testWidgets('attachment upload failure keeps the expense saved', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      KidCostApp(
        authRepository: InMemoryAuthRepository(),
        attachmentStorage: FailingAttachmentStorage(),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'parent@example.com');
    await tester.enterText(find.byType(TextField).last, 'secret1');
    await tester.tap(find.byIcon(Icons.login));
    await tester.pumpAndSettle();
    await completeOnboarding(tester);

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
    await tester.ensureVisible(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz koszt'));
    await tester.pumpAndSettle();

    expect(
      find.text('Koszt zapisany, ale zalacznik wymaga ponowienia.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Ostatni koszt zostal zapisany'),
      findsOneWidget,
    );

    await tester.tap(find.text('Koszty'));
    await tester.pumpAndSettle();

    expect(find.text('Faktura'), findsOneWidget);
    expect(find.textContaining('Zalacznik: blad uploadu'), findsOneWidget);

    await tester.tap(find.text('Faktura'));
    await tester.pumpAndSettle();

    expect(find.text('Zalacznik wymaga ponowienia'), findsOneWidget);
    expect(find.textContaining('Koszt zostal zapisany.'), findsOneWidget);
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

  testWidgets('expenses list exposes status and privacy semantics', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpensesScreen(
            expenses: [
              testExpense(
                id: '1',
                title: 'Prywatna faktura',
                amountCents: 7599,
                category: expenseCategories[3],
                status: ExpenseStatus.disputed,
                visibility: ExpenseVisibility.privateAuthor,
                attachment: const ExpenseAttachment(
                  fileName: 'rachunek.pdf',
                  contentType: 'application/pdf',
                  status: AttachmentStatus.uploaded,
                  storagePath: 'expenses/rachunek.pdf',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Prywatna faktura'), findsOneWidget);
    expect(find.text('75,99 PLN'), findsOneWidget);
    expect(find.textContaining('Zalacznik: rachunek.pdf'), findsOneWidget);
    expect(find.text('Wymaga wyjasnienia'), findsOneWidget);
    expect(find.text('Prywatny koszt solo'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Status kosztu: Wymaga wyjasnienia'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Widocznosc kosztu: Prywatny koszt solo'),
      findsOneWidget,
    );
    semantics.dispose();
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
              testExpense(
                id: '3',
                title: 'Rozliczone zajecia',
                amountCents: 7000,
                expenseDate: '2026-04-11',
                category: expenseCategories[4],
                status: ExpenseStatus.settled,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Obiad'), findsOneWidget);
    expect(find.text('Lekarz'), findsOneWidget);
    expect(find.text('Rozliczony'), findsOneWidget);

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

  testWidgets('expense details show status actions and history placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpensesScreen(
            showExpenseHistoryPremiumHint: true,
            expenses: [
              testExpense(
                id: '1',
                title: 'Faktura',
                attachment: const ExpenseAttachment(
                  fileName: 'rachunek.pdf',
                  contentType: 'application/pdf',
                  status: AttachmentStatus.uploaded,
                  storagePath: 'expenses/rachunek.pdf',
                  evidence: EvidenceMetadata(
                    type: EvidenceType.invoice,
                    documentDate: '2026-06-20',
                    merchant: 'Apteka Testowa',
                    documentNumber: 'FV/20/06',
                    paymentMethod: 'karta',
                    buyerNamePresent: true,
                  ),
                ),
              ),
              testExpense(
                id: '2',
                title: 'Sporne leki',
                category: expenseCategories[3],
                status: ExpenseStatus.disputed,
              ),
              testExpense(
                id: '3',
                title: 'Rozliczony obiad',
                status: ExpenseStatus.settled,
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
    expect(find.text('Dowod kosztu'), findsOneWidget);
    expect(find.text('Faktura imienna'), findsOneWidget);
    expect(find.text('Apteka Testowa'), findsOneWidget);
    expect(find.text('FV/20/06'), findsOneWidget);
    expect(find.textContaining('nie jest porada prawna'), findsOneWidget);
    expect(find.text('Twoja rola: autor kosztu'), findsOneWidget);
    expect(find.text('Edytuj koszt'), findsOneWidget);
    expect(find.text('Oznacz jako sporne'), findsNothing);
    expect(find.text('Historia statusu'), findsOneWidget);
    expect(find.text('Pelniejsza historia kosztu'), findsOneWidget);
    expect(
      find.textContaining('Status kosztu i podstawowe szczegoly'),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sporne leki'));
    await tester.pumpAndSettle();

    expect(find.text('Brak zalacznika'), findsOneWidget);
    expect(find.text('Wymaga wyjasnienia'), findsWidgets);
    expect(find.text('Dodaj korekte po wyjasnieniu'), findsOneWidget);
    expect(find.text('Potwierdz po wyjasnieniu'), findsNothing);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rozliczony obiad'));
    await tester.pumpAndSettle();

    expect(find.text('Rozliczony'), findsWidgets);
    expect(find.text('Brak dostepnych akcji'), findsWidgets);
  });

  testWidgets('counterparty can accept or dispute a pending expense', (
    WidgetTester tester,
  ) async {
    var expenses = [
      testExpense(
        id: '1',
        title: 'Kolonie',
        paidBy: const ExpensePayer(
          id: 'coparent',
          label: 'coparent@example.com',
          isCurrentUser: false,
        ),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: ExpensesScreen(
                expenses: expenses,
                onExpenseChanged: (expense) {
                  setState(() {
                    expenses = [
                      for (final item in expenses)
                        if (item.id == expense.id) expense else item,
                    ];
                  });
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Kolonie'));
    await tester.pumpAndSettle();

    expect(find.text('Twoja rola: drugi rodzic'), findsOneWidget);
    expect(find.text('Zaakceptuj koszt'), findsOneWidget);
    expect(find.text('Oznacz jako sporne'), findsOneWidget);

    await tester.ensureVisible(find.text('Oznacz jako sporne'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oznacz jako sporne'));
    await tester.pumpAndSettle();
    expect(find.text('Komentarz do sporu'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('expense-dispute-comment')),
      'Brakuje potwierdzenia platnosci.',
    );
    await tester.tap(find.text('Zapisz spor'));
    await tester.pumpAndSettle();

    expect(find.text('Wymaga wyjasnienia'), findsWidgets);
    expect(expenses.single.status, ExpenseStatus.disputed);
    expect(expenses.single.statusComment, 'Brakuje potwierdzenia platnosci.');

    await tester.tap(find.text('Kolonie'));
    await tester.pumpAndSettle();
    expect(find.text('Potwierdz po wyjasnieniu'), findsOneWidget);
    expect(
      find.textContaining('Brakuje potwierdzenia platnosci.'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Potwierdz po wyjasnieniu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Potwierdz po wyjasnieniu'));
    await tester.pumpAndSettle();

    expect(find.text('Zaakceptowany'), findsWidgets);
    expect(expenses.single.status, ExpenseStatus.accepted);
  });

  testWidgets('dashboard shows empty state and CTA opens add expense', (
    WidgetTester tester,
  ) async {
    await pumpSignedInOnboardedApp(tester);

    await tester.scrollUntilVisible(
      find.text('Brak kosztow w tym miesiacu'),
      120,
    );
    expect(find.text('Brak kosztow w tym miesiacu'), findsOneWidget);

    final firstCostButton = find.widgetWithText(
      OutlinedButton,
      'Dodaj pierwszy koszt',
    );
    await tester.ensureVisible(firstCostButton);
    await tester.pumpAndSettle();
    await tester.tap(firstCostButton);
    await tester.pumpAndSettle();

    expect(find.text('Nowy koszt'), findsOneWidget);
  });

  testWidgets('dashboard attention queue prioritizes actionable expenses', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var openedExpenses = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardScreen(
            profile: testProfile(),
            currentDate: DateTime.utc(2026, 6, 24),
            custodyDays: const [],
            expenses: [
              testExpense(
                id: 'missing-proof',
                title: 'Basen',
                amountCents: 3000,
                paidBy: const ExpensePayer(
                  id: 'current',
                  label: 'Ty',
                  isCurrentUser: true,
                ),
              ),
              testExpense(
                id: 'needs-review',
                title: 'Wycieczka',
                amountCents: 9000,
                paidBy: const ExpensePayer(
                  id: 'co-parent',
                  label: 'Drugi rodzic',
                  isCurrentUser: false,
                ),
              ),
              testExpense(
                id: 'disputed',
                title: 'Apteka',
                amountCents: 4500,
                status: ExpenseStatus.disputed,
              ),
              testExpense(
                id: 'settled',
                title: 'Rozliczony obiad',
                amountCents: 2500,
                status: ExpenseStatus.settled,
              ),
            ],
            onAddExpense: () {},
            onQuickReceiptDraft: () {},
            onOpenExpenses: () => openedExpenses = true,
            onOpenReports: () {},
            onOpenFamily: () {},
          ),
        ),
      ),
    );

    expect(find.text('Wymaga uwagi'), findsOneWidget);
    expect(find.text('Apteka'), findsOneWidget);
    expect(find.textContaining('Spor wymaga wyjasnienia'), findsOneWidget);
    expect(find.text('Wycieczka'), findsOneWidget);
    expect(
      find.textContaining('Koszt od drugiego rodzica czeka na decyzje'),
      findsOneWidget,
    );
    expect(find.text('Basen'), findsOneWidget);
    expect(find.textContaining('Brakuje dowodu kosztu'), findsOneWidget);
    expect(find.text('Rozliczony obiad'), findsNothing);

    final disputedTop = tester.getTopLeft(find.text('Apteka')).dy;
    final reviewTop = tester.getTopLeft(find.text('Wycieczka')).dy;
    final proofTop = tester.getTopLeft(find.text('Basen')).dy;
    expect(disputedTop, lessThan(reviewTop));
    expect(reviewTop, lessThan(proofTop));

    await tester.tap(find.widgetWithText(FilledButton, 'Otworz'));
    expect(openedExpenses, isTrue);
  });

  testWidgets('dashboard quick capture starts private receipt draft', (
    WidgetTester tester,
  ) async {
    var receiptDraftStarted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardScreen(
            profile: testProfile(),
            currentDate: DateTime.utc(2026, 6, 24),
            custodyDays: const [],
            expenses: const [],
            onAddExpense: () {},
            onQuickReceiptDraft: () => receiptDraftStarted = true,
            onOpenExpenses: () {},
            onOpenReports: () {},
            onOpenFamily: () {},
          ),
        ),
      ),
    );

    expect(find.text('Szybkie dodanie'), findsOneWidget);
    expect(find.textContaining('Nic nie trafia do rozliczen'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Szkic z paragonu'));
    expect(receiptDraftStarted, isTrue);
  });

  testWidgets('dashboard attention queue empty state has one useful action', (
    WidgetTester tester,
  ) async {
    var openedExpenses = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardScreen(
            profile: testProfile(),
            currentDate: DateTime.utc(2026, 6, 24),
            custodyDays: const [],
            expenses: [
              testExpense(
                id: 'settled',
                title: 'Rozliczony obiad',
                amountCents: 2500,
                status: ExpenseStatus.settled,
              ),
            ],
            onAddExpense: () {},
            onQuickReceiptDraft: () {},
            onOpenExpenses: () => openedExpenses = true,
            onOpenReports: () {},
            onOpenFamily: () {},
          ),
        ),
      ),
    );

    expect(
      find.text('Nie ma teraz kosztow blokujacych rozliczenie.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Przejrzyj koszty'),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'Dodaj koszt'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Przejrzyj koszty'));
    expect(openedExpenses, isTrue);
  });

  testWidgets('dashboard CTA opens monthly reports', (
    WidgetTester tester,
  ) async {
    await pumpSignedInOnboardedApp(tester);

    final reportsCta = find.widgetWithText(OutlinedButton, 'Raport miesiaca');
    await tester.scrollUntilVisible(reportsCta, 120);
    await tester.tapAt(tester.getTopLeft(reportsCta) + const Offset(24, 12));
    await tester.pumpAndSettle();

    expect(find.text('Raport miesieczny'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Eksport'), 180);
    expect(find.text('Eksport'), findsOneWidget);
  });

  testWidgets('custody calendar adds a date range and edits a day', (
    WidgetTester tester,
  ) async {
    var custodyDays = <CustodyDay>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CustodyCalendarScreen(
                profile: testProfile(),
                userEmail: 'parent@example.com',
                currentDate: DateTime.utc(2026, 6, 24),
                custodyDays: custodyDays,
                onCustodyDaysChanged: (updated) {
                  setState(() => custodyDays = updated);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Kalendarz opieki'), findsOneWidget);
    expect(find.text('2026-06'), findsOneWidget);
    expect(
      find.textContaining('MVP zapisuje plan dla jednej rodziny'),
      findsOneWidget,
    );

    await dragUntilPresent(tester, find.byKey(const Key('custody-start-date')));
    await tester.enterText(
      editableTextByKey(const Key('custody-start-date')),
      '2026-06-24',
    );
    await tester.enterText(
      editableTextByKey(const Key('custody-end-date')),
      '2026-06-26',
    );
    await tester.ensureVisible(find.text('Zapisz opieke'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz opieke'));
    await tester.pumpAndSettle();

    expect(custodyDays, hasLength(3));
    expect(find.text('Plan opieki zapisany.'), findsOneWidget);
    expect(find.text('parent@example.com'), findsWidgets);

    await tester.drag(find.byType(ListView).first, const Offset(0, 800));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, '24'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '24'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drugi rodzic').last);
    await tester.pumpAndSettle();

    expect(custodyDays.first.parent.label, 'Drugi rodzic');
  });

  testWidgets('custody day details show linked expenses and co-parent share', (
    WidgetTester tester,
  ) async {
    const coParent = CustodyParent(
      id: 'co-parent',
      label: 'Drugi rodzic',
      isCurrentUser: false,
    );
    final custodyDays = [
      CustodyDay(
        id: 'custody-2026-06-24',
        date: '2026-06-24',
        childName: 'Antek',
        parent: coParent,
        createdAt: DateTime.utc(2026, 6, 24),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustodyCalendarScreen(
            profile: testProfile(),
            userEmail: 'parent@example.com',
            currentDate: DateTime.utc(2026, 6, 24),
            custodyDays: custodyDays,
            expenses: [
              testExpense(
                id: '1',
                title: 'Basen',
                amountCents: 5000,
                category: expenseCategories[4],
                calendarEvent: const ExpenseCalendarEventLink(
                  id: 'custody-2026-06-24',
                  title: 'Opieka: Drugi rodzic',
                  eventDate: '2026-06-24',
                ),
              ),
            ],
            onCustodyDaysChanged: (_) {},
          ),
        ),
      ),
    );

    await dragUntilPresent(tester, find.widgetWithText(OutlinedButton, '24'));
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, '24'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '24'));
    await tester.pumpAndSettle();

    expect(find.text('Powiazane koszty (1)'), findsOneWidget);
    expect(find.text('Basen'), findsOneWidget);
    expect(find.textContaining('Zajecia dodatkowe'), findsOneWidget);
    expect(
      find.textContaining('udzial drugiego rodzica: 25,00 PLN'),
      findsOneWidget,
    );
  });

  testWidgets('report csv includes linked calendar event date and title', (
    WidgetTester tester,
  ) async {
    final report = MonthlyExpenseReport.fromExpenses(
      month: '2026-06',
      expenses: [
        testExpense(
          id: '1',
          title: 'Basen',
          calendarEvent: const ExpenseCalendarEventLink(
            id: 'custody-2026-06-24',
            title: 'Opieka: Drugi rodzic',
            eventDate: '2026-06-24',
          ),
        ),
      ],
    );

    final csv = report.toCsv();

    expect(csv, contains('"wydarzenie_data","wydarzenie_tytul"'));
    expect(csv, contains('"2026-06-24","Opieka: Drugi rodzic"'));
  });

  testWidgets('custody calendar previews and applies a preset', (
    WidgetTester tester,
  ) async {
    var custodyDays = <CustodyDay>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CustodyCalendarScreen(
                profile: testProfile(),
                userEmail: 'parent@example.com',
                currentDate: DateTime.utc(2026, 6, 24),
                custodyDays: custodyDays,
                onCustodyDaysChanged: (updated) {
                  setState(() => custodyDays = updated);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(
      find.text('Zacznij od gotowego presetu albo wpisz dni recznie nizej.'),
      findsOneWidget,
    );
    await dragUntilPresent(tester, find.text('Presety opieki'));
    expect(find.text('Presety opieki'), findsOneWidget);
    await dragUntilPresent(tester, find.text('Dodaj opieke'));
    await dragUntilPresent(
      tester,
      find.text('Presety opieki'),
      delta: const Offset(0, 700),
    );
    expect(find.text('24\nTy', skipOffstage: false), findsOneWidget);

    await tester.enterText(
      editableTextByKey(const Key('custody-preset-start-date')),
      '2026-06-01',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zastosuj 14 dni'));
    await tester.pumpAndSettle();

    expect(custodyDays, hasLength(14));
    expect(custodyDays.first.date, '2026-06-01');
    expect(custodyDays[6].parent.label, 'parent@example.com');
    expect(custodyDays[7].parent.label, 'Drugi rodzic');
    expect(find.text('Preset opieki zastosowany na 14 dni.'), findsOneWidget);
  });

  testWidgets('custody preset generator supports common schedules', (_) async {
    const firstParent = CustodyParent(
      id: 'self',
      label: 'Pierwszy rodzic',
      isCurrentUser: true,
    );
    const secondParent = CustodyParent(
      id: 'co-parent',
      label: 'Drugi rodzic',
      isCurrentUser: false,
    );

    final twoTwoThree = buildCustodyPresetDays(
      presetType: CustodyPresetType.twoTwoThree,
      startDate: DateTime.utc(2026, 6, 1),
      dayCount: 14,
      childName: 'Ola',
      firstParent: firstParent,
      secondParent: secondParent,
      createdAt: DateTime.utc(2026, 6, 1),
    );
    expect(twoTwoThree.map((day) => day.parent.id), [
      'self',
      'self',
      'co-parent',
      'co-parent',
      'self',
      'self',
      'self',
      'co-parent',
      'co-parent',
      'self',
      'self',
      'co-parent',
      'co-parent',
      'co-parent',
    ]);

    final weekdaysWeekends = buildCustodyPresetDays(
      presetType: CustodyPresetType.weekdaysWeekends,
      startDate: DateTime.utc(2026, 6, 1),
      dayCount: 7,
      childName: 'Ola',
      firstParent: firstParent,
      secondParent: secondParent,
      createdAt: DateTime.utc(2026, 6, 1),
    );
    expect(
      weekdaysWeekends.take(5).every((day) => day.parent.id == 'self'),
      isTrue,
    );
    expect(
      weekdaysWeekends.skip(5).every((day) => day.parent.id == 'co-parent'),
      isTrue,
    );
  });

  testWidgets('custody calendar is reachable from navigation and dashboard', (
    WidgetTester tester,
  ) async {
    await pumpSignedInOnboardedApp(tester);

    await tester.tap(find.text('Opieka'));
    await tester.pumpAndSettle();

    expect(find.text('Kalendarz opieki'), findsOneWidget);

    await dragUntilPresent(
      tester,
      find.byKey(const Key('custody-start-date')),
      scrollable: find.byType(ListView).last,
    );
    await tester.enterText(
      editableTextByKey(const Key('custody-start-date')),
      '2026-06-24',
    );
    await tester.ensureVisible(find.text('Zapisz opieke'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz opieke'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Najblizsza opieka'), 120);
    expect(find.text('Najblizsza opieka'), findsOneWidget);
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
            custodyDays: const [],
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
            onQuickReceiptDraft: () {},
            onOpenExpenses: () {},
            onOpenReports: () {},
            onOpenFamily: () {},
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Drugi rodzic oddaje Tobie 30,00 PLN'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.textContaining('Wydatki w tym miesiacu'),
      120,
    );
    expect(find.textContaining('Wydatki w tym miesiacu'), findsOneWidget);
    expect(find.text('180,00 PLN\n2026-06'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ty zaplaciles'), 120);
    expect(find.text('Ty zaplaciles'), findsOneWidget);
    expect(find.text('120,00 PLN'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Drugi rodzic zaplacil'), 120);
    expect(find.text('Drugi rodzic zaplacil'), findsOneWidget);
    expect(find.text('60,00 PLN'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Ostatnie koszty'), 120);
    expect(find.text('Ostatnie koszty'), findsOneWidget);
    expect(find.text('Lekarz'), findsWidgets);
    expect(find.text('Obiad'), findsWidgets);
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
            custodyDays: const [],
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
            onQuickReceiptDraft: () {},
            onOpenExpenses: () {},
            onOpenReports: () {},
            onOpenFamily: () {},
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Ty oddajesz drugiemu rodzicowi 40,00 PLN'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Drugi rodzic zaplacil'), 120);
    expect(find.text('Drugi rodzic zaplacil'), findsOneWidget);
    expect(find.text('80,00 PLN'), findsWidgets);
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
                attachment: const ExpenseAttachment(
                  fileName: 'faktura.pdf',
                  contentType: 'application/pdf',
                  status: AttachmentStatus.uploaded,
                  evidence: EvidenceMetadata(type: EvidenceType.invoice),
                ),
              ),
              testExpense(
                id: '3',
                title: 'Majowy koszt',
                amountCents: 9900,
                expenseDate: '2026-05-20',
              ),
              testExpense(
                id: '4',
                title: 'Rozliczony obiad',
                amountCents: 2000,
                status: ExpenseStatus.settled,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Raport miesieczny'), findsOneWidget);
    expect(find.text('Do wyrownania'), findsOneWidget);
    expect(
      find.textContaining('Drugi rodzic oddaje Tobie 40,00 PLN'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Zwroty i zaleglosci'), 120);
    expect(find.text('Zwroty i zaleglosci'), findsOneWidget);
    expect(find.text('Czesciowo zaplacone'), findsOneWidget);
    expect(find.text('Otwarta kwota w tym raporcie'), findsOneWidget);
    expect(find.text('Dowod platnosci dolaczony'), findsOneWidget);
    expect(find.text('Stany zalacznika'), findsOneWidget);
    expect(find.text('Bez certyfikacji prawnej'), findsOneWidget);
    expect(find.text('Zaplacone razem'), findsOneWidget);
    expect(find.text('200,00 PLN'), findsWidgets);
    expect(find.text('Zaplaciles Ty'), findsOneWidget);
    expect(find.text('140,00 PLN'), findsWidgets);
    expect(find.text('Zaplacil drugi rodzic'), findsOneWidget);
    expect(find.text('60,00 PLN'), findsWidgets);
    expect(find.text('Twoj udzial'), findsOneWidget);
    expect(find.text('100,00 PLN'), findsWidgets);
    expect(find.text('Reguly rodzinne'), findsOneWidget);
    expect(find.textContaining('nie wnioski prawne'), findsOneWidget);
    expect(find.text('Roznica'), findsOneWidget);
    expect(
      find.text('Zaplaciles o 40,00 PLN wiecej niz Twoj udzial.'),
      findsOneWidget,
    );
    expect(find.text('Wymaga wyjasnienia'), findsOneWidget);
    expect(find.text('Do akceptacji'), findsOneWidget);
    expect(find.text('Rozliczone'), findsWidgets);
    expect(find.text('20,00 PLN'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Zaplacone przez rodzicow'), 180);
    expect(find.text('Zaplacone przez rodzicow'), findsOneWidget);
    expect(find.text('parent@example.com'), findsOneWidget);
    expect(find.text('Drugi rodzic'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Koszty dzieci'), 180);
    expect(find.text('Koszty dzieci'), findsOneWidget);
    expect(find.text('Antek'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Kategorie kosztow'), 180);
    expect(find.text('Kategorie kosztow'), findsOneWidget);
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
    expect(find.textContaining('"typ_dowodu"'), findsOneWidget);
    expect(find.textContaining('"2026-06-20","Lekarz"'), findsOneWidget);
    expect(find.textContaining('"Faktura imienna"'), findsOneWidget);
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

    await tester.scrollUntilVisible(
      find.text('Brak kosztow w tym miesiacu'),
      180,
    );
    expect(find.text('Brak kosztow w tym miesiacu'), findsOneWidget);
    expect(find.text('0,00 PLN'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('CSV: kidcost-report-2026-06.csv'),
      180,
    );
    expect(find.text('CSV: kidcost-report-2026-06.csv'), findsOneWidget);
    expect(find.text('PDF wymaga generatora'), findsOneWidget);
  });

  testWidgets(
    'annual reports summarize a selected year and expose CSV export',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportsScreen(
              currentDate: DateTime.utc(2026, 6, 24, 10),
              expenses: [
                testExpense(id: '1', title: 'Obiad', amountCents: 12000),
                testExpense(
                  id: '2',
                  title: 'Lekarz',
                  amountCents: 6000,
                  expenseDate: '2026-02-20',
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
                  title: 'Wycieczka',
                  amountCents: 3000,
                  expenseDate: '2026-03-10',
                  category: expenseCategories[5],
                  status: ExpenseStatus.settled,
                ),
                testExpense(
                  id: '4',
                  title: 'Poprzedni rok',
                  amountCents: 9900,
                  expenseDate: '2025-12-20',
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Rok'));
      await tester.pumpAndSettle();

      expect(find.text('Raport roczny'), findsOneWidget);
      expect(find.text('Suma roczna'), findsOneWidget);
      expect(find.text('2026'), findsWidgets);
      expect(find.text('210,00 PLN'), findsWidgets);
      expect(find.text('Zaplaciles Ty'), findsOneWidget);
      expect(find.text('150,00 PLN'), findsWidgets);
      expect(find.text('Zaplacil drugi rodzic'), findsOneWidget);
      expect(find.text('60,00 PLN'), findsWidgets);
      expect(find.text('Sporne koszty'), findsOneWidget);
      expect(find.text('Oczekujace koszty'), findsOneWidget);
      expect(find.text('Nierozliczone koszty'), findsOneWidget);
      expect(find.text('180,00 PLN'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Rocznie zaplacone przez rodzicow'),
        180,
      );
      expect(find.text('Rocznie zaplacone przez rodzicow'), findsOneWidget);
      expect(find.text('Roczne koszty dzieci'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Statusy kosztow'), 180);
      expect(find.text('Statusy kosztow'), findsOneWidget);
      expect(find.text('Do akceptacji'), findsWidgets);
      expect(find.text('Wymaga wyjasnienia'), findsWidgets);
      expect(find.text('Rozliczony'), findsOneWidget);
      expect(find.text('Poprzedni rok'), findsNothing);

      final annualExportButton = find.widgetWithText(
        FilledButton,
        'CSV: kidcost-annual-report-2026.csv',
      );
      await tester.scrollUntilVisible(annualExportButton, 180);
      await tester.ensureVisible(annualExportButton);
      await tester.pumpAndSettle();
      await tester.tap(annualExportButton);
      await tester.pumpAndSettle();

      expect(find.text('Eksport CSV'), findsOneWidget);
      expect(find.text('kidcost-annual-report-2026.csv'), findsOneWidget);
      expect(
        find.textContaining('"generated_at","2026-06-24T10:00:00.000Z"'),
        findsOneWidget,
      );
      expect(find.textContaining('"year","2026"'), findsOneWidget);
      expect(find.textContaining('"2026-02-20","Lekarz"'), findsOneWidget);
      expect(find.textContaining('Poprzedni rok'), findsNothing);
    },
  );

  testWidgets('monthly reports expose professional access guardrails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportsScreen(
            currentDate: DateTime.utc(2026, 6, 24),
            expenses: [
              testExpense(id: '1', title: 'Obiad', amountCents: 12000),
            ],
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Dostep mediatora lub prawnika'),
      180,
    );
    expect(find.textContaining('read-only'), findsOneWidget);
    expect(find.textContaining('nie udziela porad prawnych'), findsOneWidget);

    final previewButton = find.widgetWithText(
      OutlinedButton,
      'Podglad bezpiecznego linku',
    );
    await tester.ensureVisible(previewButton);
    await tester.pumpAndSettle();
    await tester.tap(previewButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Udostepnij wybrany raport profesjonaliscie'),
      findsOneWidget,
    );
    expect(find.text('Zakres: raport 2026-06.'), findsOneWidget);
    expect(find.text('Uprawnienia'), findsOneWidget);
    expect(find.text('Podglad wybranego raportu'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Prywatne notatki poza pakietem'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Prywatne notatki poza pakietem'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Kazdy podglad raportu'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Kazdy podglad raportu'), findsOneWidget);
  });
}

Future<void> pumpSignedInOnboardedApp(
  WidgetTester tester, {
  AppTelemetry? telemetry,
}) async {
  await tester.pumpWidget(
    KidCostApp(
      authRepository: InMemoryAuthRepository(),
      attachmentStorage: InMemoryAttachmentStorage(),
      telemetry: telemetry,
      currentDate: DateTime.utc(2026, 6, 24),
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
  String? coParentLabel,
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

  if (coParentLabel != null) {
    await tester.enterText(find.byType(TextField).first, coParentLabel);
  }

  await tester.tap(find.text('Zacznij solo bez zaproszenia'));
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
  ExpenseVisibility visibility = ExpenseVisibility.sharedFamily,
  ExpenseAttachment? attachment,
  ExpenseCalendarEventLink? calendarEvent,
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
    visibility: visibility,
    createdAt: DateTime.utc(2026, 6, 24),
    attachment: attachment,
    calendarEvent: calendarEvent,
  );
}

OnboardingProfile testProfile() {
  return const OnboardingProfile(
    familyName: 'Rodzina Testowa',
    childName: 'Antek',
    coParentConnectionState: CoParentConnectionState.invited,
    coParentEmail: 'coparent@example.com',
    inviteCode: 'KC-1234',
    invitationSkipped: false,
  );
}

class RecordingTelemetry extends AppTelemetry {
  final events = <RecordedTelemetryEvent>[];

  List<String> get eventNames => [for (final event in events) event.event.name];

  @override
  Future<void> track(
    TelemetryEvent event, {
    Map<String, Object?> parameters = const {},
  }) async {
    events.add(
      RecordedTelemetryEvent(event, sanitizeTelemetryParameters(parameters)),
    );
  }

  @override
  void recordError(Object error, StackTrace stackTrace, {String? reason}) {}
}

class RecordedTelemetryEvent {
  const RecordedTelemetryEvent(this.event, this.parameters);

  final TelemetryEvent event;
  final Map<String, Object> parameters;
}

class FailingAttachmentStorage implements AttachmentStorage {
  @override
  Future<AttachmentUploadResult> upload({
    required String expenseId,
    required AttachmentDraft attachment,
  }) async {
    throw StateError('upload failed');
  }
}
