enum PaywallTrigger {
  afterFirstBalanceViewed,
  afterFirstReceiptAttached,
  receiptOcrIntent,
  pdfReportPreview,
  calendarExportIntent,
  storageLimitReached,
  historyLimitReached,
  afterCoParentInvite,
  beforeFirstManualExpense,
  signupBeforeLedger,
  viewExistingExpense,
}

enum PaywallTriggerStatus { approved, rejected }

class PaywallTriggerDefinition {
  const PaywallTriggerDefinition({
    required this.trigger,
    required this.status,
    required this.label,
    required this.rationale,
    required this.valueMoment,
    required this.analyticsTriggerId,
  });

  final PaywallTrigger trigger;
  final PaywallTriggerStatus status;
  final String label;
  final String rationale;
  final String valueMoment;
  final String analyticsTriggerId;

  bool get isApproved => status == PaywallTriggerStatus.approved;
}

class TrialMessagingPolicy {
  const TrialMessagingPolicy({
    required this.primaryCopy,
    required this.reminderCopy,
    required this.accessAfterTrialCopy,
    required this.reminderDaysBeforeEnd,
    required this.avoidsLegalFear,
  });

  final String primaryCopy;
  final String reminderCopy;
  final String accessAfterTrialCopy;
  final int reminderDaysBeforeEnd;
  final bool avoidsLegalFear;
}

class PremiumAnalyticsEventDefinition {
  const PremiumAnalyticsEventDefinition({
    required this.name,
    required this.requiredProperties,
    required this.rationale,
  });

  final String name;
  final Set<String> requiredProperties;
  final String rationale;
}

const kidCostPaywallTriggers = [
  PaywallTriggerDefinition(
    trigger: PaywallTrigger.afterFirstBalanceViewed,
    status: PaywallTriggerStatus.approved,
    label: 'Po pierwszym zobaczeniu salda',
    rationale:
        'Uzytkownik najpierw widzi efekt wspolnego ledgera, a dopiero potem propozycje automatyzacji.',
    valueMoment: 'balance_viewed',
    analyticsTriggerId: 'after_first_balance_viewed',
  ),
  PaywallTriggerDefinition(
    trigger: PaywallTrigger.afterFirstReceiptAttached,
    status: PaywallTriggerStatus.approved,
    label: 'Po pierwszym dodanym paragonie',
    rationale:
        'Paragon pokazuje wartosc dowodow; paywall moze dotyczyc OCR lub wiekszego storage.',
    valueMoment: 'receipt_attached',
    analyticsTriggerId: 'after_first_receipt_attached',
  ),
  PaywallTriggerDefinition(
    trigger: PaywallTrigger.receiptOcrIntent,
    status: PaywallTriggerStatus.approved,
    label: 'Przy probie OCR',
    rationale:
        'OCR jest oszczednoscia czasu, ale reczne dodawanie kwoty i paragonu zostaje darmowe.',
    valueMoment: 'receipt_ocr_intent',
    analyticsTriggerId: 'receipt_ocr_intent',
  ),
  PaywallTriggerDefinition(
    trigger: PaywallTrigger.pdfReportPreview,
    status: PaywallTriggerStatus.approved,
    label: 'Przy podgladzie PDF',
    rationale:
        'Formalny PDF jest wygoda premium; podstawowy CSV i widok raportu zostaja dostepne.',
    valueMoment: 'report_viewed',
    analyticsTriggerId: 'pdf_report_preview',
  ),
  PaywallTriggerDefinition(
    trigger: PaywallTrigger.calendarExportIntent,
    status: PaywallTriggerStatus.approved,
    label: 'Przy probie eksportu kalendarza',
    rationale:
        'Eksport ICS jest wygoda interoperacyjnosci; plan opieki w aplikacji zostaje dostepny.',
    valueMoment: 'custody_calendar_created',
    analyticsTriggerId: 'calendar_export_intent',
  ),
  PaywallTriggerDefinition(
    trigger: PaywallTrigger.storageLimitReached,
    status: PaywallTriggerStatus.approved,
    label: 'Po osiagnieciu limitu storage',
    rationale:
        'Nowe zalaczniki generuja koszt infrastruktury, ale istniejace dowody pozostaja czytelne.',
    valueMoment: 'storage_limit_reached',
    analyticsTriggerId: 'storage_limit_reached',
  ),
  PaywallTriggerDefinition(
    trigger: PaywallTrigger.historyLimitReached,
    status: PaywallTriggerStatus.approved,
    label: 'Po osiagnieciu limitu historii',
    rationale:
        'Pelna historia jest wygoda analityczna; bazowe rekordy i eksport podstawowy nie znikaja.',
    valueMoment: 'history_limit_reached',
    analyticsTriggerId: 'history_limit_reached',
  ),
  PaywallTriggerDefinition(
    trigger: PaywallTrigger.afterCoParentInvite,
    status: PaywallTriggerStatus.approved,
    label: 'Po zaproszeniu wspolrodzica',
    rationale:
        'Zaproszenie pokazuje wartosc wspolnej pracy, ale dostep drugiego rodzica nie zalezy od platnosci.',
    valueMoment: 'coparent_invited',
    analyticsTriggerId: 'after_coparent_invite',
  ),
  PaywallTriggerDefinition(
    trigger: PaywallTrigger.beforeFirstManualExpense,
    status: PaywallTriggerStatus.rejected,
    label: 'Przed pierwszym recznym kosztem',
    rationale:
        'Pierwszy koszt jest podstawowa obietnica produktu i nie moze byc blokowany platnoscia.',
    valueMoment: 'manual_expense_start',
    analyticsTriggerId: 'before_first_manual_expense',
  ),
  PaywallTriggerDefinition(
    trigger: PaywallTrigger.signupBeforeLedger,
    status: PaywallTriggerStatus.rejected,
    label: 'Przy rejestracji przed ledgerem',
    rationale:
        'Paywall przed doswiadczeniem wartosci podnosi stres i obniza zaufanie.',
    valueMoment: 'signup_started',
    analyticsTriggerId: 'signup_before_ledger',
  ),
  PaywallTriggerDefinition(
    trigger: PaywallTrigger.viewExistingExpense,
    status: PaywallTriggerStatus.rejected,
    label: 'Przy ogladaniu istniejacego kosztu',
    rationale:
        'Wlasne fakty, paragony i saldo musza pozostac dostepne po lapse i downgrade.',
    valueMoment: 'expense_viewed',
    analyticsTriggerId: 'view_existing_expense',
  ),
];

const kidCostTrialMessagingPolicy = TrialMessagingPolicy(
  primaryCopy:
      'Trial obejmuje rodzine lub workspace, a platnik nie staje sie wlascicielem danych drugiego rodzica.',
  reminderCopy:
      'Przypomnimy 3 dni przed koncem triala. Decyzje mozna zmienic bez utraty dostepu do podstawowych rekordow.',
  accessAfterTrialCopy:
      'Bez subskrypcji nadal dostepne sa koszty, saldo, zalaczniki w limicie, statusy i podstawowy CSV.',
  reminderDaysBeforeEnd: 3,
  avoidsLegalFear: true,
);

const kidCostPremiumAnalyticsEvents = [
  PremiumAnalyticsEventDefinition(
    name: 'premium_paywall_viewed',
    requiredProperties: {'trigger', 'surface', 'plan_context'},
    rationale: 'Mierzy ekspozycje paywalla po value moment bez kwot i nazw.',
  ),
  PremiumAnalyticsEventDefinition(
    name: 'premium_trial_started',
    requiredProperties: {'trigger', 'surface'},
    rationale: 'Mierzy start triala bez identyfikatorow rodziny lub dziecka.',
  ),
  PremiumAnalyticsEventDefinition(
    name: 'premium_trial_cancelled',
    requiredProperties: {'surface', 'reason_code'},
    rationale: 'Mierzy rezygnacje przez kontrolowany kod powodu.',
  ),
  PremiumAnalyticsEventDefinition(
    name: 'premium_upgraded',
    requiredProperties: {'surface', 'plan_context'},
    rationale: 'Mierzy upgrade bez danych finansowych rodziny.',
  ),
  PremiumAnalyticsEventDefinition(
    name: 'premium_downgraded',
    requiredProperties: {'surface', 'plan_context'},
    rationale: 'Mierzy downgrade bez danych o sporach lub kosztach.',
  ),
  PremiumAnalyticsEventDefinition(
    name: 'premium_feature_intent',
    requiredProperties: {'feature', 'surface', 'trigger'},
    rationale: 'Mierzy intencje uzycia funkcji premium przed paywallem.',
  ),
  PremiumAnalyticsEventDefinition(
    name: 'calendar_export_intent',
    requiredProperties: {'feature', 'surface', 'trigger', 'export_format'},
    rationale:
        'Mierzy zainteresowanie eksportem ICS bez nazw dzieci, rodzicow i tytulow wydarzen.',
  ),
];

const premiumAnalyticsAllowedProperties = {
  'export_format',
  'feature',
  'plan_context',
  'reason_code',
  'surface',
  'trigger',
};

bool firstManualExpenseCreationIsNeverBlocked() {
  return kidCostPaywallTriggers
      .where(
        (definition) =>
            definition.trigger == PaywallTrigger.beforeFirstManualExpense,
      )
      .every((definition) => !definition.isApproved);
}

List<PaywallTriggerDefinition> approvedPaywallTriggers() {
  return kidCostPaywallTriggers
      .where((definition) => definition.isApproved)
      .toList(growable: false);
}

List<PaywallTriggerDefinition> rejectedPaywallTriggers() {
  return kidCostPaywallTriggers
      .where((definition) => !definition.isApproved)
      .toList(growable: false);
}

bool premiumAnalyticsPropertiesAreSafe(Set<String> properties) {
  return properties.every(premiumAnalyticsAllowedProperties.contains);
}
