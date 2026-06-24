enum AgreementSettingStage { mvp, beta, later }

class SharedExpenseCategoryRule {
  const SharedExpenseCategoryRule({
    required this.categoryId,
    required this.label,
    required this.isShareableByDefault,
    required this.currentUserSharePercent,
    required this.coParentSharePercent,
    required this.stage,
    required this.rationale,
    this.approvalThresholdCents,
  });

  final String categoryId;
  final String label;
  final bool isShareableByDefault;
  final int currentUserSharePercent;
  final int coParentSharePercent;
  final AgreementSettingStage stage;
  final String rationale;
  final int? approvalThresholdCents;

  String get splitSummary {
    if (!isShareableByDefault) {
      return 'Domyslnie poza wspolnym rozliczeniem.';
    }
    return 'Domyslny podzial $currentUserSharePercent/$coParentSharePercent.';
  }
}

class SharedExpenseAgreement {
  const SharedExpenseAgreement({
    required this.rules,
    required this.defaultApprovalThresholdCents,
    required this.addExpenseCopy,
    required this.thresholdCopy,
    required this.reportDisclaimer,
    required this.balanceDependency,
    required this.statusDependency,
  });

  final List<SharedExpenseCategoryRule> rules;
  final int defaultApprovalThresholdCents;
  final String addExpenseCopy;
  final String thresholdCopy;
  final String reportDisclaimer;
  final String balanceDependency;
  final String statusDependency;
}

class SharedExpenseRuleDecision {
  const SharedExpenseRuleDecision({
    required this.rule,
    required this.amountCents,
    required this.requiresPriorApproval,
    required this.guidance,
  });

  final SharedExpenseCategoryRule rule;
  final int amountCents;
  final bool requiresPriorApproval;
  final String guidance;
}

const kidCostSharedExpenseAgreement = SharedExpenseAgreement(
  rules: [
    SharedExpenseCategoryRule(
      categoryId: 'food',
      label: 'Jedzenie',
      isShareableByDefault: true,
      currentUserSharePercent: 50,
      coParentSharePercent: 50,
      stage: AgreementSettingStage.mvp,
      rationale:
          'Codzienne jedzenie dziecka jest zwykle wspolnym kosztem operacyjnym.',
    ),
    SharedExpenseCategoryRule(
      categoryId: 'clothes',
      label: 'Ubrania',
      isShareableByDefault: true,
      currentUserSharePercent: 50,
      coParentSharePercent: 50,
      stage: AgreementSettingStage.mvp,
      rationale:
          'Ubrania sa typowym kosztem dziecka, ale drozsze zakupy moga wymagac uprzedniej zgody.',
      approvalThresholdCents: 30000,
    ),
    SharedExpenseCategoryRule(
      categoryId: 'school',
      label: 'Szkola/przedszkole',
      isShareableByDefault: true,
      currentUserSharePercent: 50,
      coParentSharePercent: 50,
      stage: AgreementSettingStage.mvp,
      rationale:
          'Szkola i przedszkole sa centralnym scenariuszem wspolnego rozliczania.',
      approvalThresholdCents: 50000,
    ),
    SharedExpenseCategoryRule(
      categoryId: 'health',
      label: 'Lekarze i leki',
      isShareableByDefault: true,
      currentUserSharePercent: 50,
      coParentSharePercent: 50,
      stage: AgreementSettingStage.mvp,
      rationale:
          'Zdrowie dziecka jest domyslnie wspolne, z neutralnym miejscem na dowody i status.',
    ),
    SharedExpenseCategoryRule(
      categoryId: 'activities',
      label: 'Zajecia dodatkowe',
      isShareableByDefault: true,
      currentUserSharePercent: 50,
      coParentSharePercent: 50,
      stage: AgreementSettingStage.beta,
      rationale:
          'Zajecia czesto wymagaja ustalenia z gory, zwlaszcza przy wyzszej kwocie.',
      approvalThresholdCents: 20000,
    ),
    SharedExpenseCategoryRule(
      categoryId: 'holiday',
      label: 'Wakacje',
      isShareableByDefault: false,
      currentUserSharePercent: 50,
      coParentSharePercent: 50,
      stage: AgreementSettingStage.beta,
      rationale:
          'Wakacje maja duzy kontekst rodzinny, wiec domyslnie prosza o osobne ustalenie.',
      approvalThresholdCents: 100000,
    ),
    SharedExpenseCategoryRule(
      categoryId: 'transport',
      label: 'Transport',
      isShareableByDefault: true,
      currentUserSharePercent: 50,
      coParentSharePercent: 50,
      stage: AgreementSettingStage.beta,
      rationale:
          'Transport bywa wspolny, ale moze zalezec od kalendarza opieki.',
      approvalThresholdCents: 20000,
    ),
    SharedExpenseCategoryRule(
      categoryId: 'other',
      label: 'Inne',
      isShareableByDefault: false,
      currentUserSharePercent: 50,
      coParentSharePercent: 50,
      stage: AgreementSettingStage.later,
      rationale:
          'Inne koszty wymagaja recznego doprecyzowania, zanim trafia do wspolnego rozliczenia.',
    ),
  ],
  defaultApprovalThresholdCents: 50000,
  addExpenseCopy:
      'Regula pokazuje ustawienia rodziny dla kategorii; nie jest porada prawna.',
  thresholdCopy:
      'Kwota przekracza prog uprzedniej zgody. Zapisz koszt jako pending i dodaj kontekst lub dowod ustalenia.',
  reportDisclaimer:
      'Raport pokazuje skonfigurowane reguly rodzinne i statusy kosztow, a nie wnioski prawne.',
  balanceDependency:
      'Balance MVP nadal liczy 50/50; custom split per kategoria wymaga osobnego silnika udzialow.',
  statusDependency:
      'Przekroczenie progu powinno zostawic koszt w pending/disputed do akceptacji wspolrodzica.',
);

SharedExpenseCategoryRule sharedExpenseRuleForCategory(String categoryId) {
  final normalized = categoryId.trim().toLowerCase();
  for (final rule in kidCostSharedExpenseAgreement.rules) {
    if (rule.categoryId == normalized) {
      return rule;
    }
  }
  return kidCostSharedExpenseAgreement.rules.last;
}

SharedExpenseRuleDecision evaluateSharedExpenseRule({
  required String categoryId,
  required int amountCents,
}) {
  final rule = sharedExpenseRuleForCategory(categoryId);
  final threshold = rule.approvalThresholdCents ??
      kidCostSharedExpenseAgreement.defaultApprovalThresholdCents;
  final requiresPriorApproval =
      rule.isShareableByDefault && amountCents > threshold;

  final guidance = !rule.isShareableByDefault
      ? 'Ta kategoria domyslnie wymaga osobnego ustalenia przed wspolnym rozliczeniem.'
      : requiresPriorApproval
          ? kidCostSharedExpenseAgreement.thresholdCopy
          : 'Koszt pasuje do domyslnej reguly rodzinnej dla tej kategorii.';

  return SharedExpenseRuleDecision(
    rule: rule,
    amountCents: amountCents,
    requiresPriorApproval: requiresPriorApproval,
    guidance: guidance,
  );
}

List<SharedExpenseCategoryRule> sharedExpenseRulesForStage(
  AgreementSettingStage stage,
) {
  return kidCostSharedExpenseAgreement.rules
      .where((rule) => rule.stage == stage)
      .toList(growable: false);
}
