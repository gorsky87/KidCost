import 'entitlements.dart';

enum SubscriptionLifecycleState {
  free,
  trial,
  activePremium,
  gracePeriod,
  billingRetry,
  accountHold,
  canceledActiveUntilPeriodEnd,
  expired,
  refunded,
  feeWaiver,
}

enum SubscriptionStore { appStore, googlePlay, supportGranted }

enum SubscriptionBillingPeriod { monthly, annual }

enum SubscriptionFeatureAccess {
  included,
  limited,
  readOnlyExisting,
  pausedForNewUse,
  unavailable,
}

enum SubscriptionOfferMechanism {
  appStoreIntroductoryOffer,
  appStoreOfferCode,
  appStorePromotionalOffer,
  appStoreWinBackOffer,
  googlePlayBasePlan,
  googlePlayOffer,
  googlePlayGracePeriod,
  googlePlayAccountHold,
}

class SubscriptionLifecycleFeatureRule {
  const SubscriptionLifecycleFeatureRule({
    required this.feature,
    required this.access,
    required this.summary,
    required this.keepsExistingRecordsReadable,
  });

  final EntitlementFeature feature;
  final SubscriptionFeatureAccess access;
  final String summary;
  final bool keepsExistingRecordsReadable;

  bool get allowsNewUse {
    return access == SubscriptionFeatureAccess.included ||
        access == SubscriptionFeatureAccess.limited;
  }
}

class SubscriptionLifecycleRule {
  const SubscriptionLifecycleRule({
    required this.state,
    required this.entitlementPlan,
    required this.userMessage,
    required this.featureRules,
    required this.analyticsState,
    required this.releaseOperationRequirement,
  });

  final SubscriptionLifecycleState state;
  final KidCostPlan entitlementPlan;
  final String userMessage;
  final List<SubscriptionLifecycleFeatureRule> featureRules;
  final String analyticsState;
  final String releaseOperationRequirement;

  bool get keepsCoreRecordsReadable {
    return _coreRecordFeatures.every((feature) {
      return featureRuleFor(feature).keepsExistingRecordsReadable;
    });
  }

  bool get allowsNewPremiumConvenienceUse {
    return _premiumConvenienceFeatures.every((feature) {
      return featureRuleFor(feature).allowsNewUse;
    });
  }

  SubscriptionLifecycleFeatureRule featureRuleFor(EntitlementFeature feature) {
    for (final rule in featureRules) {
      if (rule.feature == feature) {
        return rule;
      }
    }
    throw ArgumentError('No lifecycle rule for feature: $feature');
  }
}

class LocalizedSubscriptionPrice {
  const LocalizedSubscriptionPrice({
    required this.productId,
    required this.storefrontCountryCode,
    required this.currencyCode,
    required this.period,
    required this.priceMinorUnits,
    required this.isPrimaryBetaOffer,
    required this.familyScoped,
  });

  final String productId;
  final String storefrontCountryCode;
  final String currencyCode;
  final SubscriptionBillingPeriod period;
  final int priceMinorUnits;
  final bool isPrimaryBetaOffer;
  final bool familyScoped;
}

class SubscriptionPricingPolicy {
  const SubscriptionPricingPolicy({
    required this.baseStorefrontCountryCode,
    required this.baseCurrencyCode,
    required this.prices,
    required this.copy,
    required this.priceChangeRequirement,
    required this.futureSafeOfferMechanisms,
  });

  final String baseStorefrontCountryCode;
  final String baseCurrencyCode;
  final List<LocalizedSubscriptionPrice> prices;
  final SubscriptionPricingCopy copy;
  final String priceChangeRequirement;
  final Set<SubscriptionOfferMechanism> futureSafeOfferMechanisms;

  LocalizedSubscriptionPrice primaryBetaOffer() {
    return prices.singleWhere((price) => price.isPrimaryBetaOffer);
  }
}

class SubscriptionPricingCopy {
  const SubscriptionPricingCopy({
    required this.billingOwnerDoesNotControlData,
    required this.afterCancellation,
    required this.priceChange,
  });

  final String billingOwnerDoesNotControlData;
  final String afterCancellation;
  final String priceChange;
}

class SubscriptionAnalyticsEventDefinition {
  const SubscriptionAnalyticsEventDefinition({
    required this.name,
    required this.requiredProperties,
    required this.rationale,
  });

  final String name;
  final Set<String> requiredProperties;
  final String rationale;
}

const _coreRecordFeatures = {
  EntitlementFeature.childProfiles,
  EntitlementFeature.families,
  EntitlementFeature.manualExpenses,
  EntitlementFeature.receiptStorageMb,
  EntitlementFeature.statusHistoryMonths,
  EntitlementFeature.basicCsvExport,
};

const _premiumConvenienceFeatures = {
  EntitlementFeature.receiptOcr,
  EntitlementFeature.pdfReports,
  EntitlementFeature.evidenceBundles,
  EntitlementFeature.advancedSplitRules,
  EntitlementFeature.calendarLinkedAllocation,
  EntitlementFeature.calendarIcsExport,
  EntitlementFeature.prioritySupport,
};

const _allLifecycleFeatures = {
  ..._coreRecordFeatures,
  ..._premiumConvenienceFeatures,
};

List<SubscriptionLifecycleFeatureRule> _premiumRules({
  required String premiumSummary,
}) {
  return [
    for (final feature in _allLifecycleFeatures)
      SubscriptionLifecycleFeatureRule(
        feature: feature,
        access: SubscriptionFeatureAccess.included,
        summary: _coreRecordFeatures.contains(feature)
            ? 'Podstawowy rekord pozostaje dostepny.'
            : premiumSummary,
        keepsExistingRecordsReadable: true,
      ),
  ];
}

List<SubscriptionLifecycleFeatureRule> _freeRules({
  required String premiumSummary,
}) {
  return [
    for (final feature in _coreRecordFeatures)
      SubscriptionLifecycleFeatureRule(
        feature: feature,
        access: SubscriptionFeatureAccess.included,
        summary: 'Podstawowy rekord i eksport pozostaja dostepne.',
        keepsExistingRecordsReadable: true,
      ),
    for (final feature in _premiumConvenienceFeatures)
      SubscriptionLifecycleFeatureRule(
        feature: feature,
        access: SubscriptionFeatureAccess.unavailable,
        summary: premiumSummary,
        keepsExistingRecordsReadable: true,
      ),
  ];
}

List<SubscriptionLifecycleFeatureRule> _pausedPremiumRules({
  required String premiumSummary,
}) {
  return [
    for (final feature in _coreRecordFeatures)
      SubscriptionLifecycleFeatureRule(
        feature: feature,
        access: SubscriptionFeatureAccess.included,
        summary: 'Podstawowy rekord i eksport pozostaja dostepne.',
        keepsExistingRecordsReadable: true,
      ),
    for (final feature in _premiumConvenienceFeatures)
      SubscriptionLifecycleFeatureRule(
        feature: feature,
        access: SubscriptionFeatureAccess.pausedForNewUse,
        summary: premiumSummary,
        keepsExistingRecordsReadable: true,
      ),
  ];
}

final kidCostSubscriptionLifecycleRules = [
  SubscriptionLifecycleRule(
    state: SubscriptionLifecycleState.free,
    entitlementPlan: KidCostPlan.free,
    userMessage:
        'Free nadal pozwala widziec koszty, saldo, zapisane dowody i podstawowy eksport.',
    featureRules: _freeFeatures,
    analyticsState: 'free',
    releaseOperationRequirement:
        'Nie pokazuj komunikatu o utracie danych; premium dotyczy wygody i automatyzacji.',
  ),
  SubscriptionLifecycleRule(
    state: SubscriptionLifecycleState.trial,
    entitlementPlan: KidCostPlan.premium,
    userMessage:
        'Trial odblokowuje funkcje Premium dla rodziny bez zmiany praw do danych.',
    featureRules: _trialFeatures,
    analyticsState: 'trial',
    releaseOperationRequirement:
        'Pokazuj termin konca triala i cene po trialu przed startem subskrypcji.',
  ),
  SubscriptionLifecycleRule(
    state: SubscriptionLifecycleState.activePremium,
    entitlementPlan: KidCostPlan.premium,
    userMessage: 'Premium jest aktywne dla rodziny.',
    featureRules: _activePremiumFeatures,
    analyticsState: 'active_premium',
    releaseOperationRequirement:
        'Store receipt/status musi byc zweryfikowany przed wlaczeniem platnych funkcji.',
  ),
  SubscriptionLifecycleRule(
    state: SubscriptionLifecycleState.gracePeriod,
    entitlementPlan: KidCostPlan.premium,
    userMessage:
        'Platnosc wymaga uwagi, ale dostep Premium trwa w okresie grace period.',
    featureRules: _gracePeriodFeatures,
    analyticsState: 'grace_period',
    releaseOperationRequirement:
        'Uzyj spokojnego recovery copy; nie strasz utrata rekordow dziecka.',
  ),
  SubscriptionLifecycleRule(
    state: SubscriptionLifecycleState.billingRetry,
    entitlementPlan: KidCostPlan.free,
    userMessage:
        'Nie udalo sie odnowic platnosci; nowe funkcje Premium sa wstrzymane, rekordy zostaja.',
    featureRules: _billingRetryFeatures,
    analyticsState: 'billing_retry',
    releaseOperationRequirement:
        'Retry/recovery event ma wskazywac sklep i stan, bez kwot rodzinnych ani danych dziecka.',
  ),
  SubscriptionLifecycleRule(
    state: SubscriptionLifecycleState.accountHold,
    entitlementPlan: KidCostPlan.free,
    userMessage:
        'Konto subskrypcji jest wstrzymane przez sklep; podstawowy ledger pozostaje czytelny.',
    featureRules: _accountHoldFeatures,
    analyticsState: 'account_hold',
    releaseOperationRequirement:
        'Nie pozwalaj na nowe kosztowne akcje Premium dopoki sklep nie przywroci subskrypcji.',
  ),
  SubscriptionLifecycleRule(
    state: SubscriptionLifecycleState.canceledActiveUntilPeriodEnd,
    entitlementPlan: KidCostPlan.premium,
    userMessage:
        'Subskrypcja zostala anulowana, ale Premium dziala do konca oplaconego okresu.',
    featureRules: _canceledActiveFeatures,
    analyticsState: 'canceled_active',
    releaseOperationRequirement:
        'Copy musi pokazac date konca i co zostanie dostepne po downgrade.',
  ),
  SubscriptionLifecycleRule(
    state: SubscriptionLifecycleState.expired,
    entitlementPlan: KidCostPlan.free,
    userMessage:
        'Premium wygaslo; istniejace rekordy i podstawowy eksport pozostaja dostepne.',
    featureRules: _expiredFeatures,
    analyticsState: 'expired',
    releaseOperationRequirement:
        'Zachowaj read/export dla historycznych rekordow; nie kasuj dowodow przy wygasnieciu.',
  ),
  SubscriptionLifecycleRule(
    state: SubscriptionLifecycleState.refunded,
    entitlementPlan: KidCostPlan.free,
    userMessage:
        'Zwrot platnosci wylacza nowe funkcje Premium, ale nie usuwa historii rodziny.',
    featureRules: _refundedFeatures,
    analyticsState: 'refunded',
    releaseOperationRequirement:
        'Refund event nie moze zawierac powodow opisowych z danych rodzinnych.',
  ),
  SubscriptionLifecycleRule(
    state: SubscriptionLifecycleState.feeWaiver,
    entitlementPlan: KidCostPlan.premium,
    userMessage:
        'Fee waiver daje Premium bez platnosci i bez gorszego traktowania danych.',
    featureRules: _feeWaiverFeatures,
    analyticsState: 'fee_waiver',
    releaseOperationRequirement:
        'Fee waiver przyznaje support/admin, a nie klient sklepu; audytuj bez danych wrazliwych.',
  ),
];

final _freeFeatures = _freeRules(
  premiumSummary:
      'Nowe funkcje Premium wymagaja triala, subskrypcji lub fee waiver.',
);
final _trialFeatures = _premiumRules(
  premiumSummary: 'Dostepne w trialu Premium.',
);
final _activePremiumFeatures = _premiumRules(
  premiumSummary: 'Dostepne w aktywnym Premium.',
);
final _gracePeriodFeatures = _premiumRules(
  premiumSummary: 'Dostepne w grace period, z prosba o aktualizacje platnosci.',
);
final _billingRetryFeatures = _pausedPremiumRules(
  premiumSummary: 'Nowe uzycie Premium wstrzymane do odzyskania platnosci.',
);
final _accountHoldFeatures = _pausedPremiumRules(
  premiumSummary: 'Nowe uzycie Premium wstrzymane podczas account hold.',
);
final _canceledActiveFeatures = _premiumRules(
  premiumSummary: 'Dostepne do konca oplaconego okresu.',
);
final _expiredFeatures = _freeRules(
  premiumSummary: 'Nowe funkcje Premium wymagaja ponownej subskrypcji.',
);
final _refundedFeatures = _freeRules(
  premiumSummary: 'Nowe funkcje Premium sa wylaczone po refundzie.',
);
final _feeWaiverFeatures = _premiumRules(
  premiumSummary: 'Dostepne przez fee waiver.',
);

const kidCostPlEuPricingPolicy = SubscriptionPricingPolicy(
  baseStorefrontCountryCode: 'PL',
  baseCurrencyCode: 'PLN',
  prices: [
    LocalizedSubscriptionPrice(
      productId: 'kidcost_premium_monthly_pl',
      storefrontCountryCode: 'PL',
      currencyCode: 'PLN',
      period: SubscriptionBillingPeriod.monthly,
      priceMinorUnits: 2499,
      isPrimaryBetaOffer: true,
      familyScoped: true,
    ),
    LocalizedSubscriptionPrice(
      productId: 'kidcost_premium_annual_pl',
      storefrontCountryCode: 'PL',
      currencyCode: 'PLN',
      period: SubscriptionBillingPeriod.annual,
      priceMinorUnits: 19999,
      isPrimaryBetaOffer: false,
      familyScoped: true,
    ),
  ],
  copy: SubscriptionPricingCopy(
    billingOwnerDoesNotControlData:
        'Platnik odblokowuje wygode Premium, ale nie staje sie wlascicielem danych wspolrodzica.',
    afterCancellation:
        'Po anulowaniu nadal widzisz koszty, saldo, dowody i podstawowy eksport.',
    priceChange:
        'Zmiany ceny wymagaja jasnego komunikatu sklepu, nowej ceny i informacji, ze rekordy nie znikna.',
  ),
  priceChangeRequirement:
      'Zmiany cen PL/EU prowadzi release ops: komunikat sklepu, storefront, data wejscia, plan rollback i pomiar opt-in/cancel.',
  futureSafeOfferMechanisms: {
    SubscriptionOfferMechanism.appStoreIntroductoryOffer,
    SubscriptionOfferMechanism.appStoreOfferCode,
    SubscriptionOfferMechanism.appStorePromotionalOffer,
    SubscriptionOfferMechanism.appStoreWinBackOffer,
    SubscriptionOfferMechanism.googlePlayBasePlan,
    SubscriptionOfferMechanism.googlePlayOffer,
    SubscriptionOfferMechanism.googlePlayGracePeriod,
    SubscriptionOfferMechanism.googlePlayAccountHold,
  },
);

const kidCostSubscriptionAnalyticsEvents = [
  SubscriptionAnalyticsEventDefinition(
    name: 'subscription_lifecycle_changed',
    requiredProperties: {
      'store',
      'lifecycle_state',
      'entitlement_state',
      'plan_id',
      'storefront_country',
    },
    rationale: 'Mierzy przejscia sklepu bez rodzinnych identyfikatorow.',
  ),
  SubscriptionAnalyticsEventDefinition(
    name: 'subscription_recovery_prompt_viewed',
    requiredProperties: {'store', 'lifecycle_state', 'surface'},
    rationale: 'Mierzy billing recovery bez danych kosztow lub dziecka.',
  ),
  SubscriptionAnalyticsEventDefinition(
    name: 'subscription_price_change_presented',
    requiredProperties: {'store', 'plan_id', 'storefront_country'},
    rationale: 'Mierzy price-change ops bez zapisu kwoty w analytics.',
  ),
  SubscriptionAnalyticsEventDefinition(
    name: 'subscription_offer_redeemed',
    requiredProperties: {'store', 'offer_type', 'plan_id'},
    rationale: 'Mierzy mechanizm oferty bez kodow promocyjnych w payloadzie.',
  ),
  SubscriptionAnalyticsEventDefinition(
    name: 'premium_cancellation_started',
    requiredProperties: {'surface', 'entitlement_state'},
    rationale: 'Mierzy start flow bez danych rodziny i bez powodow opisowych.',
  ),
  SubscriptionAnalyticsEventDefinition(
    name: 'premium_cancellation_reason_selected',
    requiredProperties: {'surface', 'reason_code', 'entitlement_state'},
    rationale: 'Mierzy opcjonalny powod churnu jako kod, bez tekstu wolnego.',
  ),
  SubscriptionAnalyticsEventDefinition(
    name: 'premium_cancellation_save_path_selected',
    requiredProperties: {
      'surface',
      'save_path',
      'entitlement_state',
      'platform_handoff',
    },
    rationale: 'Mierzy etyczna sciezke zapisu lub handoff sklepu bez PII.',
  ),
];

const subscriptionAnalyticsAllowedProperties = {
  'entitlement_state',
  'lifecycle_state',
  'offer_type',
  'plan_id',
  'platform_handoff',
  'reason_code',
  'recovery_outcome',
  'save_path',
  'store',
  'storefront_country',
  'surface',
};

SubscriptionLifecycleRule subscriptionLifecycleRuleFor(
  SubscriptionLifecycleState state,
) {
  for (final rule in kidCostSubscriptionLifecycleRules) {
    if (rule.state == state) {
      return rule;
    }
  }
  throw ArgumentError('Unknown subscription lifecycle state: $state');
}

bool allSubscriptionLifecycleStatesAreMapped() {
  final mappedStates = {
    for (final rule in kidCostSubscriptionLifecycleRules) rule.state,
  };
  return mappedStates.length == SubscriptionLifecycleState.values.length &&
      SubscriptionLifecycleState.values.every(mappedStates.contains);
}

bool allSubscriptionStatesKeepCoreRecordsReadable() {
  return kidCostSubscriptionLifecycleRules.every(
    (rule) => rule.keepsCoreRecordsReadable,
  );
}

bool subscriptionAnalyticsPropertiesAreSafe(Set<String> properties) {
  return properties.every(subscriptionAnalyticsAllowedProperties.contains);
}
