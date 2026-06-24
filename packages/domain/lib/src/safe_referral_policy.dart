enum ReferralTrigger {
  coParentInviteAccepted,
  firstSharedExpenseAcknowledged,
  firstReportShared,
  trustedHelperInvited,
}

enum ReferralRewardType {
  trialExtensionDays,
  oneTimeReportCredit,
  temporaryOcrCredits,
  storageBoostMb,
}

enum ReferralSurface {
  soloModeInvitePrompt,
  familyOnboarding,
  postFirstBalance,
  settingsSubscription,
}

enum ReferralRewardDecisionReason {
  granted,
  declinedOrIgnoredInvite,
  duplicateAccountSuspected,
  alreadyRewardedFamilyPair,
  cooldownActive,
  ineligibleTrigger,
}

class ReferralReward {
  const ReferralReward({
    required this.type,
    required this.amount,
    required this.expiresAfterDays,
    required this.summary,
  });

  final ReferralRewardType type;
  final int amount;
  final int expiresAfterDays;
  final String summary;
}

class ReferralTriggerDefinition {
  const ReferralTriggerDefinition({
    required this.trigger,
    required this.reward,
    required this.analyticsTriggerId,
    required this.healthyCollaborationEvent,
    required this.allowedSurfaces,
    required this.primaryActionCopy,
  });

  final ReferralTrigger trigger;
  final ReferralReward reward;
  final String analyticsTriggerId;
  final bool healthyCollaborationEvent;
  final Set<ReferralSurface> allowedSurfaces;
  final String primaryActionCopy;
}

class ReferralAntiCoercionRule {
  const ReferralAntiCoercionRule({required this.code, required this.summary});

  final String code;
  final String summary;
}

class ReferralAbuseLimits {
  const ReferralAbuseLimits({
    required this.oneRewardPerFamilyPair,
    required this.cooldownDays,
    required this.maxTrialExtensionDaysPerFamily,
    required this.duplicateAccountRule,
    required this.revocationRule,
  });

  final bool oneRewardPerFamilyPair;
  final int cooldownDays;
  final int maxTrialExtensionDaysPerFamily;
  final String duplicateAccountRule;
  final String revocationRule;
}

class SafeReferralCopy {
  const SafeReferralCopy({
    required this.soloMode,
    required this.familyOnboarding,
    required this.postFirstBalance,
    required this.dismissal,
    required this.declineSafe,
    required this.rewardGranted,
  });

  final String soloMode;
  final String familyOnboarding;
  final String postFirstBalance;
  final String dismissal;
  final String declineSafe;
  final String rewardGranted;
}

class SafeReferralPolicy {
  const SafeReferralPolicy({
    required this.triggers,
    required this.antiCoercionRules,
    required this.abuseLimits,
    required this.copy,
  });

  final List<ReferralTriggerDefinition> triggers;
  final List<ReferralAntiCoercionRule> antiCoercionRules;
  final ReferralAbuseLimits abuseLimits;
  final SafeReferralCopy copy;

  ReferralTriggerDefinition definitionFor(ReferralTrigger trigger) {
    for (final definition in triggers) {
      if (definition.trigger == trigger) {
        return definition;
      }
    }
    throw ArgumentError('Unknown referral trigger: $trigger');
  }
}

class ReferralRewardRequest {
  const ReferralRewardRequest({
    required this.trigger,
    required this.invitedUserAccepted,
    this.hasPriorRewardForFamilyPair = false,
    this.daysSinceLastReward,
    this.duplicateAccountSuspected = false,
  });

  final ReferralTrigger trigger;
  final bool invitedUserAccepted;
  final bool hasPriorRewardForFamilyPair;
  final int? daysSinceLastReward;
  final bool duplicateAccountSuspected;
}

class ReferralRewardDecision {
  const ReferralRewardDecision({
    required this.isGranted,
    required this.reason,
    required this.coreTrackingRemainsAvailable,
    this.reward,
  });

  final bool isGranted;
  final ReferralRewardDecisionReason reason;
  final bool coreTrackingRemainsAvailable;
  final ReferralReward? reward;
}

class ReferralAnalyticsEventDefinition {
  const ReferralAnalyticsEventDefinition({
    required this.name,
    required this.requiredProperties,
    required this.rationale,
  });

  final String name;
  final Set<String> requiredProperties;
  final String rationale;
}

const kidCostSafeReferralPolicy = SafeReferralPolicy(
  triggers: [
    ReferralTriggerDefinition(
      trigger: ReferralTrigger.coParentInviteAccepted,
      reward: ReferralReward(
        type: ReferralRewardType.trialExtensionDays,
        amount: 14,
        expiresAfterDays: 45,
        summary: '14 dni dodatkowego triala po zaakceptowaniu zaproszenia.',
      ),
      analyticsTriggerId: 'coparent_invite_accepted',
      healthyCollaborationEvent: true,
      allowedSurfaces: {
        ReferralSurface.familyOnboarding,
        ReferralSurface.soloModeInvitePrompt,
        ReferralSurface.postFirstBalance,
      },
      primaryActionCopy: 'Zapros rodzica bez zmiany praw do danych',
    ),
    ReferralTriggerDefinition(
      trigger: ReferralTrigger.firstSharedExpenseAcknowledged,
      reward: ReferralReward(
        type: ReferralRewardType.temporaryOcrCredits,
        amount: 5,
        expiresAfterDays: 30,
        summary: '5 tymczasowych kredytow OCR po pierwszym wspolnym koszcie.',
      ),
      analyticsTriggerId: 'first_shared_expense_acknowledged',
      healthyCollaborationEvent: true,
      allowedSurfaces: {
        ReferralSurface.postFirstBalance,
        ReferralSurface.settingsSubscription,
      },
      primaryActionCopy: 'Zobacz, co druga osoba moze potwierdzic',
    ),
    ReferralTriggerDefinition(
      trigger: ReferralTrigger.firstReportShared,
      reward: ReferralReward(
        type: ReferralRewardType.oneTimeReportCredit,
        amount: 1,
        expiresAfterDays: 60,
        summary: '1 kredyt raportu po pierwszym udostepnieniu raportu.',
      ),
      analyticsTriggerId: 'first_report_shared',
      healthyCollaborationEvent: true,
      allowedSurfaces: {
        ReferralSurface.postFirstBalance,
        ReferralSurface.settingsSubscription,
      },
      primaryActionCopy: 'Udostepnij raport bez dawania kontroli nad rodzina',
    ),
    ReferralTriggerDefinition(
      trigger: ReferralTrigger.trustedHelperInvited,
      reward: ReferralReward(
        type: ReferralRewardType.storageBoostMb,
        amount: 250,
        expiresAfterDays: 60,
        summary: '250 MB czasowego boostu storage po zaproszeniu helpera.',
      ),
      analyticsTriggerId: 'trusted_helper_invited',
      healthyCollaborationEvent: true,
      allowedSurfaces: {ReferralSurface.settingsSubscription},
      primaryActionCopy: 'Udostepnij wybrany kontekst bez ustawien rodziny',
    ),
  ],
  antiCoercionRules: [
    ReferralAntiCoercionRule(
      code: 'decline_never_blocks_core',
      summary:
          'Odmowa lub ignorowanie zaproszenia nie blokuje recznego ledgera, salda, dowodow ani podstawowego eksportu.',
    ),
    ReferralAntiCoercionRule(
      code: 'payer_is_not_data_admin',
      summary:
          'Platnik lub osoba zapraszajaca nie staje sie jedynym administratorem danych drugiego rodzica.',
    ),
    ReferralAntiCoercionRule(
      code: 'no_public_pressure',
      summary:
          'Nie ma leaderboardow, publicznych rankingow, presji copy ani kar za brak akceptacji.',
    ),
    ReferralAntiCoercionRule(
      code: 'normal_detail_confirmation',
      summary:
          'Akceptacja kosztu, spor, zaplata i udostepnienie raportu ida przez normalny flow potwierdzenia.',
    ),
  ],
  abuseLimits: ReferralAbuseLimits(
    oneRewardPerFamilyPair: true,
    cooldownDays: 30,
    maxTrialExtensionDaysPerFamily: 30,
    duplicateAccountRule:
        'Podejrzane duplikaty kont nie dostaja nagrody do czasu wyjasnienia przez support.',
    revocationRule:
        'Nagroda moze byc cofnieta za abuse, ale istniejace rekordy i eksport core pozostaja dostepne.',
  ),
  copy: SafeReferralCopy(
    soloMode:
        'Mozesz zaprosic drugiego rodzica pozniej. Jesli odmowi, nadal prowadzisz swoje koszty.',
    familyOnboarding:
        'Zaproszenie nie pokazuje danych rodzinnych przed akceptacja i nie daje kontroli nad Twoimi rekordami.',
    postFirstBalance:
        'Jesli wspolrodzic dolaczy, latwiej potwierdzicie koszty. Twoj ledger dziala takze bez tego.',
    dismissal:
        'Mozesz pominac zaproszenie i wrocic do niego pozniej w ustawieniach rodziny.',
    declineSafe:
        'Brak akceptacji zaproszenia nie usuwa kosztow, paragonow, salda ani eksportu.',
    rewardGranted:
        'Nagroda dotyczy wygody Premium, a nie prawa dostepu do cudzych danych.',
  ),
);

const kidCostReferralAnalyticsEvents = [
  ReferralAnalyticsEventDefinition(
    name: 'referral_invite_prompt_viewed',
    requiredProperties: {'surface', 'trigger'},
    rationale: 'Mierzy ekspozycje zaproszenia bez danych rodziny.',
  ),
  ReferralAnalyticsEventDefinition(
    name: 'referral_invite_sent',
    requiredProperties: {'surface', 'trigger'},
    rationale: 'Mierzy intencje zaproszenia bez emaila odbiorcy.',
  ),
  ReferralAnalyticsEventDefinition(
    name: 'referral_invite_accepted',
    requiredProperties: {'surface', 'trigger'},
    rationale: 'Mierzy akceptacje bez identyfikatorow wspolrodzica.',
  ),
  ReferralAnalyticsEventDefinition(
    name: 'referral_reward_granted',
    requiredProperties: {'trigger', 'reward_type'},
    rationale: 'Mierzy przyznanie nagrody bez danych kosztow.',
  ),
  ReferralAnalyticsEventDefinition(
    name: 'referral_reward_used',
    requiredProperties: {'reward_type', 'surface'},
    rationale: 'Mierzy uzycie nagrody bez opisow paragonow lub raportow.',
  ),
  ReferralAnalyticsEventDefinition(
    name: 'referral_invite_declined_or_ignored',
    requiredProperties: {'surface', 'trigger'},
    rationale: 'Mierzy odmowe bez zapisywania powodu opisowego.',
  ),
];

const referralAnalyticsAllowedProperties = {
  'reward_type',
  'surface',
  'trigger',
};

ReferralRewardDecision evaluateReferralReward(
  ReferralRewardRequest request, {
  SafeReferralPolicy policy = kidCostSafeReferralPolicy,
}) {
  final definition = policy.definitionFor(request.trigger);

  if (!definition.healthyCollaborationEvent) {
    return const ReferralRewardDecision(
      isGranted: false,
      reason: ReferralRewardDecisionReason.ineligibleTrigger,
      coreTrackingRemainsAvailable: true,
    );
  }
  if (!request.invitedUserAccepted) {
    return const ReferralRewardDecision(
      isGranted: false,
      reason: ReferralRewardDecisionReason.declinedOrIgnoredInvite,
      coreTrackingRemainsAvailable: true,
    );
  }
  if (request.duplicateAccountSuspected) {
    return const ReferralRewardDecision(
      isGranted: false,
      reason: ReferralRewardDecisionReason.duplicateAccountSuspected,
      coreTrackingRemainsAvailable: true,
    );
  }
  if (request.hasPriorRewardForFamilyPair) {
    return const ReferralRewardDecision(
      isGranted: false,
      reason: ReferralRewardDecisionReason.alreadyRewardedFamilyPair,
      coreTrackingRemainsAvailable: true,
    );
  }
  final daysSinceLastReward = request.daysSinceLastReward;
  if (daysSinceLastReward != null &&
      daysSinceLastReward < policy.abuseLimits.cooldownDays) {
    return const ReferralRewardDecision(
      isGranted: false,
      reason: ReferralRewardDecisionReason.cooldownActive,
      coreTrackingRemainsAvailable: true,
    );
  }

  return ReferralRewardDecision(
    isGranted: true,
    reason: ReferralRewardDecisionReason.granted,
    coreTrackingRemainsAvailable: true,
    reward: definition.reward,
  );
}

bool safeReferralPolicyProtectsCoreAccess() {
  final ruleCodes = {
    for (final rule in kidCostSafeReferralPolicy.antiCoercionRules) rule.code,
  };
  return ruleCodes.contains('decline_never_blocks_core') &&
      ruleCodes.contains('payer_is_not_data_admin') &&
      kidCostSafeReferralPolicy.copy.declineSafe.contains('nie usuwa');
}

bool referralAnalyticsPropertiesAreSafe(Set<String> properties) {
  return properties.every(referralAnalyticsAllowedProperties.contains);
}
