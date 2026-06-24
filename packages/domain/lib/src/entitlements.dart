enum KidCostPlan { free, premium }

enum EntitlementFeature {
  childProfiles,
  families,
  manualExpenses,
  receiptStorageMb,
  statusHistoryMonths,
  basicCsvExport,
  receiptOcr,
  pdfReports,
  evidenceBundles,
  advancedSplitRules,
  calendarLinkedAllocation,
  prioritySupport,
}

enum EntitlementAccess { included, limited, premiumOnly, addOnCandidate }

class EntitlementTier {
  const EntitlementTier({
    required this.access,
    required this.summary,
    this.limit,
  });

  final EntitlementAccess access;
  final String summary;
  final int? limit;

  bool get isAvailable {
    return access == EntitlementAccess.included ||
        access == EntitlementAccess.limited;
  }
}

class EntitlementDefinition {
  const EntitlementDefinition({
    required this.feature,
    required this.label,
    required this.free,
    required this.premium,
    required this.downgradeRule,
    required this.keepsExistingAccessOnDowngrade,
    required this.rationale,
  });

  final EntitlementFeature feature;
  final String label;
  final EntitlementTier free;
  final EntitlementTier premium;
  final String downgradeRule;
  final bool keepsExistingAccessOnDowngrade;
  final String rationale;

  EntitlementTier tierFor(KidCostPlan plan) {
    switch (plan) {
      case KidCostPlan.free:
        return free;
      case KidCostPlan.premium:
        return premium;
    }
  }
}

class EntitlementDecision {
  const EntitlementDecision({
    required this.isAllowed,
    required this.feature,
    required this.plan,
    required this.reason,
    this.remaining,
  });

  final bool isAllowed;
  final EntitlementFeature feature;
  final KidCostPlan plan;
  final String reason;
  final int? remaining;
}

class FamilyBillingPolicy {
  const FamilyBillingPolicy({
    required this.payerCoversFamily,
    required this.payerIsSoleDataAdmin,
    required this.lapseKeepsCoreRecordsReadable,
    required this.summary,
  });

  final bool payerCoversFamily;
  final bool payerIsSoleDataAdmin;
  final bool lapseKeepsCoreRecordsReadable;
  final String summary;
}

const familyBillingPolicy = FamilyBillingPolicy(
  payerCoversFamily: true,
  payerIsSoleDataAdmin: false,
  lapseKeepsCoreRecordsReadable: true,
  summary:
      'Jeden platnik moze pokryc plan rodziny, ale platnosc nie daje wylacznej administracji danych wspolrodzica.',
);

const kidCostEntitlementMatrix = [
  EntitlementDefinition(
    feature: EntitlementFeature.childProfiles,
    label: 'Profile dzieci',
    free: EntitlementTier(
      access: EntitlementAccess.limited,
      limit: 2,
      summary: 'Do 2 dzieci w rodzinie.',
    ),
    premium: EntitlementTier(
      access: EntitlementAccess.included,
      summary: 'Wieksza rodzina bez limitu produktowego MVP.',
    ),
    downgradeRule: 'Istniejace dzieci zostaja widoczne po downgrade.',
    keepsExistingAccessOnDowngrade: true,
    rationale: 'Limit chroni prostote Free, ale nie moze ukryc historii.',
  ),
  EntitlementDefinition(
    feature: EntitlementFeature.families,
    label: 'Rodziny',
    free: EntitlementTier(
      access: EntitlementAccess.limited,
      limit: 1,
      summary: 'Jedna aktywna rodzina.',
    ),
    premium: EntitlementTier(
      access: EntitlementAccess.included,
      summary:
          'Dodatkowe rodziny lub konfiguracje opieki jako przyszly upsell.',
    ),
    downgradeRule: 'Istniejaca rodzina i jej dane pozostaja czytelne.',
    keepsExistingAccessOnDowngrade: true,
    rationale: 'Core ledger nie moze zniknac przez billing.',
  ),
  EntitlementDefinition(
    feature: EntitlementFeature.manualExpenses,
    label: 'Reczne koszty',
    free: EntitlementTier(
      access: EntitlementAccess.included,
      summary: 'Bez limitu dla podstawowego ledgera.',
    ),
    premium: EntitlementTier(
      access: EntitlementAccess.included,
      summary: 'Bez limitu.',
    ),
    downgradeRule:
        'Koszty stworzone przez uzytkownika zawsze zostaja dostepne.',
    keepsExistingAccessOnDowngrade: true,
    rationale: 'To fundament zaufania i nie powinien byc paywallem.',
  ),
  EntitlementDefinition(
    feature: EntitlementFeature.receiptStorageMb,
    label: 'Storage zalacznikow',
    free: EntitlementTier(
      access: EntitlementAccess.limited,
      limit: 250,
      summary: 'Podstawowy limit 250 MB na rodzine.',
    ),
    premium: EntitlementTier(
      access: EntitlementAccess.included,
      summary: 'Wiekszy storage dla dowodow i pakietow.',
    ),
    downgradeRule:
        'Istniejace zalaczniki zostaja czytelne; nowe moga czekac na zwolnienie miejsca.',
    keepsExistingAccessOnDowngrade: true,
    rationale:
        'Storage jest realnym kosztem, ale stare dowody sa rekordem rodziny.',
  ),
  EntitlementDefinition(
    feature: EntitlementFeature.statusHistoryMonths,
    label: 'Historia statusow',
    free: EntitlementTier(
      access: EntitlementAccess.limited,
      limit: 12,
      summary: 'Ostatnie 12 miesiecy historii w aplikacji.',
    ),
    premium: EntitlementTier(
      access: EntitlementAccess.included,
      summary: 'Pelna historia i wygodniejsze filtrowanie.',
    ),
    downgradeRule: 'Surowe rekordy historii nie sa kasowane po downgrade.',
    keepsExistingAccessOnDowngrade: true,
    rationale: 'Historia ma wartosc Premium, ale nie powinna niszczyc audytu.',
  ),
  EntitlementDefinition(
    feature: EntitlementFeature.basicCsvExport,
    label: 'Podstawowy CSV',
    free: EntitlementTier(
      access: EntitlementAccess.included,
      summary: 'CSV miesieczny dla podstawowego raportu.',
    ),
    premium: EntitlementTier(
      access: EntitlementAccess.included,
      summary: 'CSV plus bardziej formalne warianty eksportu.',
    ),
    downgradeRule: 'Podstawowy eksport pozostaje dostepny po lapse.',
    keepsExistingAccessOnDowngrade: true,
    rationale: 'Uzytkownik musi moc wyniesc wlasne fakty z aplikacji.',
  ),
  EntitlementDefinition(
    feature: EntitlementFeature.receiptOcr,
    label: 'OCR paragonow',
    free: EntitlementTier(
      access: EntitlementAccess.premiumOnly,
      summary: 'Podglad jako value moment, bez blokowania recznego wpisu.',
    ),
    premium: EntitlementTier(
      access: EntitlementAccess.included,
      summary: 'OCR z review pol przed zapisem kosztu.',
    ),
    downgradeRule: 'Wyniki OCR zapisane wczesniej zostaja przy kosztach.',
    keepsExistingAccessOnDowngrade: true,
    rationale:
        'Automatyzacja oszczedza czas, ale reczne wpisy musza zostac free.',
  ),
  EntitlementDefinition(
    feature: EntitlementFeature.pdfReports,
    label: 'Raporty PDF',
    free: EntitlementTier(
      access: EntitlementAccess.premiumOnly,
      summary: 'Hint przy eksporcie, podstawowy CSV bez paywalla.',
    ),
    premium: EntitlementTier(
      access: EntitlementAccess.included,
      summary: 'PDF i raporty formalne do mediacji lub rozmowy.',
    ),
    downgradeRule:
        'Wygenerowane pliki pozostaja czytelne; nowe PDF wymagaja Premium.',
    keepsExistingAccessOnDowngrade: true,
    rationale: 'Formalny raport jest wygoda, nie warunek dostepu do danych.',
  ),
  EntitlementDefinition(
    feature: EntitlementFeature.evidenceBundles,
    label: 'Pakiety dowodow',
    free: EntitlementTier(
      access: EntitlementAccess.premiumOnly,
      summary: 'Pojedyncze zalaczniki zostaja podstawowe.',
    ),
    premium: EntitlementTier(
      access: EntitlementAccess.included,
      summary: 'Bundle kosztow, dowodow i historii statusow.',
    ),
    downgradeRule: 'Istniejace dowody i powiazania kosztow pozostaja widoczne.',
    keepsExistingAccessOnDowngrade: true,
    rationale: 'Pakietowanie jest wygoda dla zaawansowanych spraw.',
  ),
  EntitlementDefinition(
    feature: EntitlementFeature.advancedSplitRules,
    label: 'Zaawansowane proporcje',
    free: EntitlementTier(
      access: EntitlementAccess.premiumOnly,
      summary: 'Free zachowuje prosty podzial 50/50.',
    ),
    premium: EntitlementTier(
      access: EntitlementAccess.included,
      summary: 'Niestandardowe proporcje i progi akceptacji.',
    ),
    downgradeRule: 'Istniejace koszty zachowuja zapisany sposob wyliczenia.',
    keepsExistingAccessOnDowngrade: true,
    rationale:
        'Zaawansowane reguly sa wartoscia konfiguracji, nie rekordem bazowym.',
  ),
  EntitlementDefinition(
    feature: EntitlementFeature.calendarLinkedAllocation,
    label: 'Alokacja z kalendarza',
    free: EntitlementTier(
      access: EntitlementAccess.addOnCandidate,
      summary: 'Kalendarz opieki moze sugerowac value moment.',
    ),
    premium: EntitlementTier(
      access: EntitlementAccess.included,
      summary: 'Koszty powiazane z dniami opieki i reguly alokacji.',
    ),
    downgradeRule: 'Daty opieki i koszty pozostaja widoczne.',
    keepsExistingAccessOnDowngrade: true,
    rationale: 'To automatyzacja interpretacji, nie podstawowy ledger.',
  ),
  EntitlementDefinition(
    feature: EntitlementFeature.prioritySupport,
    label: 'Priority support',
    free: EntitlementTier(
      access: EntitlementAccess.premiumOnly,
      summary: 'Standardowy support i materialy pomocy.',
    ),
    premium: EntitlementTier(
      access: EntitlementAccess.included,
      summary: 'Szybsza reakcja na problemy z eksportem i danymi.',
    ),
    downgradeRule: 'Historia ticketow nie zmienia dostepu do danych.',
    keepsExistingAccessOnDowngrade: true,
    rationale: 'Support jest serwisem, nie kontrola nad rekordami rodziny.',
  ),
];

EntitlementDefinition entitlementDefinitionFor(EntitlementFeature feature) {
  for (final definition in kidCostEntitlementMatrix) {
    if (definition.feature == feature) {
      return definition;
    }
  }
  throw ArgumentError('Unknown entitlement feature: $feature');
}

EntitlementDecision evaluateEntitlement({
  required KidCostPlan plan,
  required EntitlementFeature feature,
  int? currentUsage,
}) {
  final definition = entitlementDefinitionFor(feature);
  final tier = definition.tierFor(plan);
  final limit = tier.limit;

  if (tier.access == EntitlementAccess.premiumOnly ||
      tier.access == EntitlementAccess.addOnCandidate) {
    return EntitlementDecision(
      isAllowed: false,
      feature: feature,
      plan: plan,
      reason: tier.summary,
    );
  }

  if (limit != null && currentUsage != null && currentUsage >= limit) {
    return EntitlementDecision(
      isAllowed: false,
      feature: feature,
      plan: plan,
      remaining: 0,
      reason: 'Limit planu zostal wykorzystany: ${tier.summary}',
    );
  }

  return EntitlementDecision(
    isAllowed: true,
    feature: feature,
    plan: plan,
    remaining: limit == null || currentUsage == null
        ? null
        : limit - currentUsage,
    reason: tier.summary,
  );
}

bool coreRecordsRemainReadableAfterDowngrade() {
  final coreFeatures = {
    EntitlementFeature.manualExpenses,
    EntitlementFeature.receiptStorageMb,
    EntitlementFeature.basicCsvExport,
  };

  return kidCostEntitlementMatrix
      .where((definition) => coreFeatures.contains(definition.feature))
      .every((definition) => definition.keepsExistingAccessOnDowngrade);
}

String freePlanSummaryText() {
  return 'Koszty, saldo, zalaczniki do limitu, statusy i podstawowy CSV.';
}

String premiumPlanSummaryText() {
  return 'OCR, PDF, pakiety dowodow, wiekszy storage, historia i reguly.';
}

String downgradeProtectionSummaryText() {
  return 'Po lapse istniejace koszty, paragony, saldo i podstawowy eksport pozostaja czytelne.';
}
