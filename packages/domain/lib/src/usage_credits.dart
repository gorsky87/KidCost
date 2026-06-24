import 'subscription_lifecycle.dart';

enum UsageCreditType { receiptOcr, premiumReport }

enum UsageCreditScope { user, family }

enum UsageCreditGrantSource {
  freeMonthlyAllowance,
  premiumMonthlyBundle,
  premiumAnnualBundle,
  referralReward,
  hardshipSupportGrant,
  adminAdjustment,
  addOnPurchase,
}

enum UsageCreditLedgerReason {
  grant,
  successfulConsumption,
  failedJobNoCharge,
  refundReversal,
  adminReversal,
}

enum UsageCreditFeatureAction {
  manualExpenseCreation,
  existingRecordAccess,
  basicCsvExport,
  receiptAttachmentStorage,
  receiptOcrExtraction,
  premiumReportGeneration,
}

class UsageCreditGrantRule {
  const UsageCreditGrantRule({
    required this.source,
    required this.eligibleStates,
    required this.receiptOcrCredits,
    required this.premiumReportCredits,
    required this.expiresAfter,
    required this.requiresSupportAudit,
    required this.summary,
  });

  final UsageCreditGrantSource source;
  final Set<SubscriptionLifecycleState> eligibleStates;
  final int receiptOcrCredits;
  final int premiumReportCredits;
  final Duration? expiresAfter;
  final bool requiresSupportAudit;
  final String summary;

  int amountFor(UsageCreditType type) {
    switch (type) {
      case UsageCreditType.receiptOcr:
        return receiptOcrCredits;
      case UsageCreditType.premiumReport:
        return premiumReportCredits;
    }
  }

  bool isEligibleFor(SubscriptionLifecycleState state) {
    return eligibleStates.contains(state);
  }
}

class UsageCreditLedgerEntry {
  const UsageCreditLedgerEntry({
    required this.id,
    required this.scope,
    required this.scopeId,
    required this.type,
    required this.delta,
    required this.reason,
    required this.occurredAt,
    required this.auditActor,
    this.grantSource,
    this.grantReason,
    this.balanceAfter,
    this.consumedAt,
    this.expiresAt,
    this.relatedFeatureEvent,
    this.auditMetadataKeys = const {},
  });

  final String id;
  final UsageCreditScope scope;
  final String scopeId;
  final UsageCreditType type;
  final int delta;
  final UsageCreditLedgerReason reason;
  final DateTime occurredAt;
  final String auditActor;
  final UsageCreditGrantSource? grantSource;
  final String? grantReason;
  final int? balanceAfter;
  final DateTime? consumedAt;
  final DateTime? expiresAt;
  final String? relatedFeatureEvent;
  final Set<String> auditMetadataKeys;

  bool get isGrant => delta > 0;
  bool get isConsumption =>
      reason == UsageCreditLedgerReason.successfulConsumption;
  bool get isReversal {
    return reason == UsageCreditLedgerReason.refundReversal ||
        reason == UsageCreditLedgerReason.adminReversal;
  }
}

class UsageCreditBalance {
  const UsageCreditBalance({
    required this.type,
    required this.available,
    required this.granted,
    required this.consumed,
    required this.reversed,
    required this.expired,
  });

  final UsageCreditType type;
  final int available;
  final int granted;
  final int consumed;
  final int reversed;
  final int expired;

  bool get hasCredits => available > 0;
}

class UsageCreditSpendDecision {
  const UsageCreditSpendDecision({
    required this.type,
    required this.isAllowed,
    required this.consumesCredit,
    required this.requested,
    required this.remainingAfter,
    required this.reason,
  });

  final UsageCreditType type;
  final bool isAllowed;
  final bool consumesCredit;
  final int requested;
  final int remainingAfter;
  final String reason;
}

class UsageCreditAnalyticsEventDefinition {
  const UsageCreditAnalyticsEventDefinition({
    required this.name,
    required this.requiredProperties,
    required this.rationale,
  });

  final String name;
  final Set<String> requiredProperties;
  final String rationale;
}

class _CreditBucket {
  _CreditBucket({
    required this.remaining,
    required this.occurredAt,
    this.expiresAt,
  });

  int remaining;
  final DateTime occurredAt;
  final DateTime? expiresAt;

  bool isExpiredAt(DateTime asOf) {
    final expiry = expiresAt;
    return expiry != null && !expiry.isAfter(asOf);
  }

  bool wasValidAt(DateTime moment) {
    final expiry = expiresAt;
    return expiry == null || expiry.isAfter(moment);
  }
}

const kidCostUsageCreditGrantRules = [
  UsageCreditGrantRule(
    source: UsageCreditGrantSource.freeMonthlyAllowance,
    eligibleStates: {
      SubscriptionLifecycleState.free,
      SubscriptionLifecycleState.trial,
      SubscriptionLifecycleState.activePremium,
      SubscriptionLifecycleState.gracePeriod,
      SubscriptionLifecycleState.billingRetry,
      SubscriptionLifecycleState.accountHold,
      SubscriptionLifecycleState.canceledActiveUntilPeriodEnd,
      SubscriptionLifecycleState.expired,
      SubscriptionLifecycleState.refunded,
      SubscriptionLifecycleState.feeWaiver,
    },
    receiptOcrCredits: 2,
    premiumReportCredits: 0,
    expiresAfter: Duration(days: 35),
    requiresSupportAudit: false,
    summary:
        'Free allowance daje maly value moment OCR bez blokowania recznego wpisu.',
  ),
  UsageCreditGrantRule(
    source: UsageCreditGrantSource.premiumMonthlyBundle,
    eligibleStates: {
      SubscriptionLifecycleState.trial,
      SubscriptionLifecycleState.activePremium,
      SubscriptionLifecycleState.gracePeriod,
      SubscriptionLifecycleState.canceledActiveUntilPeriodEnd,
    },
    receiptOcrCredits: 50,
    premiumReportCredits: 4,
    expiresAfter: Duration(days: 35),
    requiresSupportAudit: false,
    summary:
        'Miesieczne Premium obejmuje kosztowne akcje OCR i raporty formalne.',
  ),
  UsageCreditGrantRule(
    source: UsageCreditGrantSource.premiumAnnualBundle,
    eligibleStates: {
      SubscriptionLifecycleState.activePremium,
      SubscriptionLifecycleState.canceledActiveUntilPeriodEnd,
    },
    receiptOcrCredits: 600,
    premiumReportCredits: 48,
    expiresAfter: Duration(days: 370),
    requiresSupportAudit: false,
    summary:
        'Roczne Premium przyznaje roczny pakiet, zachowujac osobny audyt uzyc.',
  ),
  UsageCreditGrantRule(
    source: UsageCreditGrantSource.referralReward,
    eligibleStates: {
      SubscriptionLifecycleState.free,
      SubscriptionLifecycleState.trial,
      SubscriptionLifecycleState.activePremium,
      SubscriptionLifecycleState.gracePeriod,
      SubscriptionLifecycleState.billingRetry,
      SubscriptionLifecycleState.accountHold,
      SubscriptionLifecycleState.canceledActiveUntilPeriodEnd,
      SubscriptionLifecycleState.expired,
      SubscriptionLifecycleState.refunded,
      SubscriptionLifecycleState.feeWaiver,
    },
    receiptOcrCredits: 10,
    premiumReportCredits: 1,
    expiresAfter: Duration(days: 180),
    requiresSupportAudit: false,
    summary:
        'Referral reward nagradza zaproszenie bez zmiany praw do danych rodziny.',
  ),
  UsageCreditGrantRule(
    source: UsageCreditGrantSource.hardshipSupportGrant,
    eligibleStates: {
      SubscriptionLifecycleState.free,
      SubscriptionLifecycleState.expired,
      SubscriptionLifecycleState.refunded,
      SubscriptionLifecycleState.feeWaiver,
    },
    receiptOcrCredits: 50,
    premiumReportCredits: 4,
    expiresAfter: Duration(days: 90),
    requiresSupportAudit: true,
    summary:
        'Support moze przyznac pomoc bez platnosci, z audytem bez danych dziecka.',
  ),
  UsageCreditGrantRule(
    source: UsageCreditGrantSource.adminAdjustment,
    eligibleStates: {
      SubscriptionLifecycleState.free,
      SubscriptionLifecycleState.trial,
      SubscriptionLifecycleState.activePremium,
      SubscriptionLifecycleState.gracePeriod,
      SubscriptionLifecycleState.billingRetry,
      SubscriptionLifecycleState.accountHold,
      SubscriptionLifecycleState.canceledActiveUntilPeriodEnd,
      SubscriptionLifecycleState.expired,
      SubscriptionLifecycleState.refunded,
      SubscriptionLifecycleState.feeWaiver,
    },
    receiptOcrCredits: 0,
    premiumReportCredits: 0,
    expiresAfter: null,
    requiresSupportAudit: true,
    summary:
        'Admin adjustment wymaga jawnej kwoty i powodu w audycie operacyjnym.',
  ),
  UsageCreditGrantRule(
    source: UsageCreditGrantSource.addOnPurchase,
    eligibleStates: {},
    receiptOcrCredits: 0,
    premiumReportCredits: 0,
    expiresAfter: null,
    requiresSupportAudit: true,
    summary:
        'Add-on purchase jest przyszlym rozszerzeniem, bez zatwierdzonej ceny MVP.',
  ),
];

const kidCostUsageCreditAnalyticsEvents = [
  UsageCreditAnalyticsEventDefinition(
    name: 'usage_credit_granted',
    requiredProperties: {
      'credit_type',
      'credit_source',
      'credit_scope',
      'entitlement_state',
      'surface',
    },
    rationale:
        'Mierzy przyznanie kredytow bez nazw dzieci, kwot kosztow i tresci paragonow.',
  ),
  UsageCreditAnalyticsEventDefinition(
    name: 'usage_credit_consumed',
    requiredProperties: {
      'credit_type',
      'feature',
      'outcome',
      'remaining_bucket',
      'surface',
    },
    rationale:
        'Mierzy zuzycie po sukcesie OCR/raportu bez identyfikatorow rodzinnych.',
  ),
  UsageCreditAnalyticsEventDefinition(
    name: 'usage_credit_job_failed_no_charge',
    requiredProperties: {'credit_type', 'feature', 'job_result', 'surface'},
    rationale: 'Mierzy awarie kosztownej akcji bez naliczania kredytu.',
  ),
  UsageCreditAnalyticsEventDefinition(
    name: 'usage_credit_reversed',
    requiredProperties: {
      'credit_type',
      'credit_source',
      'outcome',
      'reversal_reason',
      'surface',
    },
    rationale:
        'Mierzy refund/reversal bez powodow opisowych z danych rodzinnych.',
  ),
];

const usageCreditAnalyticsAllowedProperties = {
  'credit_scope',
  'credit_source',
  'credit_type',
  'entitlement_state',
  'feature',
  'grant_reason',
  'job_result',
  'outcome',
  'remaining_bucket',
  'reversal_reason',
  'surface',
};

const usageCreditAuditMetadataAllowedKeys = {
  'job_result',
  'ledger_policy_version',
  'store_transaction_state',
  'support_case_id',
  'worker_attempt',
};

UsageCreditGrantRule usageCreditGrantRuleFor(UsageCreditGrantSource source) {
  for (final rule in kidCostUsageCreditGrantRules) {
    if (rule.source == source) {
      return rule;
    }
  }
  throw ArgumentError('Unknown usage credit grant source: $source');
}

UsageCreditLedgerEntry buildUsageCreditGrantEntry({
  required String id,
  required UsageCreditScope scope,
  required String scopeId,
  required UsageCreditType type,
  required UsageCreditGrantSource source,
  required SubscriptionLifecycleState lifecycleState,
  required DateTime grantedAt,
  required String auditActor,
  int? overrideAmount,
  int? balanceAfter,
  String? relatedFeatureEvent,
  Set<String> auditMetadataKeys = const {},
}) {
  final rule = usageCreditGrantRuleFor(source);
  if (!rule.isEligibleFor(lifecycleState)) {
    throw ArgumentError(
      'Grant source $source is not eligible for $lifecycleState.',
    );
  }
  final amount = overrideAmount ?? rule.amountFor(type);
  if (amount <= 0) {
    throw ArgumentError('Grant amount must be positive for $source and $type.');
  }

  return UsageCreditLedgerEntry(
    id: _requireNonEmpty(id, 'Ledger entry id'),
    scope: scope,
    scopeId: _requireNonEmpty(scopeId, 'Scope id'),
    type: type,
    delta: amount,
    reason: UsageCreditLedgerReason.grant,
    occurredAt: grantedAt.toUtc(),
    auditActor: _requireNonEmpty(auditActor, 'Audit actor'),
    grantSource: source,
    grantReason: rule.summary,
    balanceAfter: balanceAfter,
    expiresAt: rule.expiresAfter == null
        ? null
        : grantedAt.toUtc().add(rule.expiresAfter!),
    relatedFeatureEvent: _normalizeOptional(relatedFeatureEvent),
    auditMetadataKeys: Set.unmodifiable(auditMetadataKeys),
  );
}

UsageCreditLedgerEntry buildUsageCreditConsumptionEntry({
  required String id,
  required UsageCreditScope scope,
  required String scopeId,
  required UsageCreditType type,
  required DateTime consumedAt,
  required String auditActor,
  required String relatedFeatureEvent,
  int amount = 1,
  int? balanceAfter,
  Set<String> auditMetadataKeys = const {},
}) {
  if (amount <= 0) {
    throw ArgumentError('Consumption amount must be positive.');
  }

  return UsageCreditLedgerEntry(
    id: _requireNonEmpty(id, 'Ledger entry id'),
    scope: scope,
    scopeId: _requireNonEmpty(scopeId, 'Scope id'),
    type: type,
    delta: -amount,
    reason: UsageCreditLedgerReason.successfulConsumption,
    occurredAt: consumedAt.toUtc(),
    auditActor: _requireNonEmpty(auditActor, 'Audit actor'),
    balanceAfter: balanceAfter,
    consumedAt: consumedAt.toUtc(),
    relatedFeatureEvent: _requireNonEmpty(
      relatedFeatureEvent,
      'Related feature event',
    ),
    auditMetadataKeys: Set.unmodifiable(auditMetadataKeys),
  );
}

UsageCreditLedgerEntry buildUsageCreditReversalEntry({
  required String id,
  required UsageCreditScope scope,
  required String scopeId,
  required UsageCreditType type,
  required DateTime reversedAt,
  required String auditActor,
  required UsageCreditLedgerReason reason,
  int amount = 1,
  int? balanceAfter,
  Set<String> auditMetadataKeys = const {},
}) {
  if (reason != UsageCreditLedgerReason.refundReversal &&
      reason != UsageCreditLedgerReason.adminReversal) {
    throw ArgumentError('Reversal entries need a reversal reason.');
  }
  if (amount <= 0) {
    throw ArgumentError('Reversal amount must be positive.');
  }

  return UsageCreditLedgerEntry(
    id: _requireNonEmpty(id, 'Ledger entry id'),
    scope: scope,
    scopeId: _requireNonEmpty(scopeId, 'Scope id'),
    type: type,
    delta: -amount,
    reason: reason,
    occurredAt: reversedAt.toUtc(),
    auditActor: _requireNonEmpty(auditActor, 'Audit actor'),
    balanceAfter: balanceAfter,
    auditMetadataKeys: Set.unmodifiable(auditMetadataKeys),
  );
}

UsageCreditBalance calculateUsageCreditBalance({
  required Iterable<UsageCreditLedgerEntry> entries,
  required UsageCreditType type,
  required DateTime asOf,
}) {
  final moment = asOf.toUtc();
  final relevant = entries
      .where(
        (entry) => entry.type == type && !entry.occurredAt.isAfter(moment),
      )
      .toList()
    ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

  final buckets = <_CreditBucket>[];
  var granted = 0;
  var consumed = 0;
  var reversed = 0;

  for (final entry in relevant) {
    _validateLedgerEntry(entry);
    if (entry.delta > 0) {
      granted += entry.delta;
      buckets.add(
        _CreditBucket(
          remaining: entry.delta,
          occurredAt: entry.occurredAt,
          expiresAt: entry.expiresAt,
        ),
      );
      continue;
    }

    final amount = -entry.delta;
    if (entry.isConsumption) {
      consumed += amount;
    } else if (entry.isReversal) {
      reversed += amount;
    }
    _drainCreditBuckets(buckets, amount, entry.occurredAt);
  }

  var available = 0;
  var expired = 0;
  for (final bucket in buckets) {
    if (bucket.isExpiredAt(moment)) {
      expired += bucket.remaining;
    } else {
      available += bucket.remaining;
    }
  }

  return UsageCreditBalance(
    type: type,
    available: available,
    granted: granted,
    consumed: consumed,
    reversed: reversed,
    expired: expired,
  );
}

UsageCreditSpendDecision evaluateUsageCreditSpend({
  required Iterable<UsageCreditLedgerEntry> entries,
  required UsageCreditType type,
  required DateTime asOf,
  int requested = 1,
  bool jobSucceeded = true,
}) {
  if (requested <= 0) {
    throw ArgumentError('Requested credits must be positive.');
  }

  final balance = calculateUsageCreditBalance(
    entries: entries,
    type: type,
    asOf: asOf,
  );

  if (!jobSucceeded) {
    return UsageCreditSpendDecision(
      type: type,
      isAllowed: true,
      consumesCredit: false,
      requested: requested,
      remainingAfter: balance.available,
      reason: 'Nie naliczaj kredytu, dopoki OCR lub raport nie da wyniku.',
    );
  }

  if (balance.available < requested) {
    return UsageCreditSpendDecision(
      type: type,
      isAllowed: false,
      consumesCredit: false,
      requested: requested,
      remainingAfter: balance.available,
      reason: 'Brak wystarczajacych kredytow dla kosztownej akcji Premium.',
    );
  }

  return UsageCreditSpendDecision(
    type: type,
    isAllowed: true,
    consumesCredit: true,
    requested: requested,
    remainingAfter: balance.available - requested,
    reason: 'Kredyt naliczany tylko po udanym wyniku funkcji.',
  );
}

bool usageCreditsCanGateAction(UsageCreditFeatureAction action) {
  switch (action) {
    case UsageCreditFeatureAction.receiptOcrExtraction:
    case UsageCreditFeatureAction.premiumReportGeneration:
      return true;
    case UsageCreditFeatureAction.manualExpenseCreation:
    case UsageCreditFeatureAction.existingRecordAccess:
    case UsageCreditFeatureAction.basicCsvExport:
    case UsageCreditFeatureAction.receiptAttachmentStorage:
      return false;
  }
}

bool usageCreditAnalyticsPropertiesAreSafe(Set<String> properties) {
  return properties.every(usageCreditAnalyticsAllowedProperties.contains);
}

bool allUsageCreditAnalyticsEventsAreSafe() {
  return kidCostUsageCreditAnalyticsEvents.every(
    (definition) =>
        usageCreditAnalyticsPropertiesAreSafe(definition.requiredProperties),
  );
}

bool usageCreditAuditMetadataKeysAreSafe(Set<String> keys) {
  return keys.every(usageCreditAuditMetadataAllowedKeys.contains);
}

void _drainCreditBuckets(
  List<_CreditBucket> buckets,
  int amount,
  DateTime occurredAt,
) {
  var remainingToDrain = amount;
  buckets.sort((a, b) {
    final aExpiry = a.expiresAt;
    final bExpiry = b.expiresAt;
    if (aExpiry == null && bExpiry != null) {
      return 1;
    }
    if (aExpiry != null && bExpiry == null) {
      return -1;
    }
    if (aExpiry != null && bExpiry != null) {
      final expiryComparison = aExpiry.compareTo(bExpiry);
      if (expiryComparison != 0) {
        return expiryComparison;
      }
    }
    return a.occurredAt.compareTo(b.occurredAt);
  });

  for (final bucket in buckets) {
    if (remainingToDrain == 0) {
      break;
    }
    if (!bucket.wasValidAt(occurredAt) || bucket.remaining == 0) {
      continue;
    }

    final used = bucket.remaining < remainingToDrain
        ? bucket.remaining
        : remainingToDrain;
    bucket.remaining -= used;
    remainingToDrain -= used;
  }
}

void _validateLedgerEntry(UsageCreditLedgerEntry entry) {
  _requireNonEmpty(entry.id, 'Ledger entry id');
  _requireNonEmpty(entry.scopeId, 'Scope id');
  _requireNonEmpty(entry.auditActor, 'Audit actor');
  if (entry.delta == 0) {
    throw ArgumentError('Ledger delta cannot be zero.');
  }
  if (entry.delta > 0 && entry.reason != UsageCreditLedgerReason.grant) {
    throw ArgumentError('Positive ledger entries must be grants.');
  }
  if (entry.delta > 0 && entry.grantSource == null) {
    throw ArgumentError('Grant ledger entries need a grant source.');
  }
  final balanceAfter = entry.balanceAfter;
  if (balanceAfter != null && balanceAfter < 0) {
    throw ArgumentError('Balance after cannot be negative.');
  }
  if (entry.delta < 0 &&
      entry.reason != UsageCreditLedgerReason.successfulConsumption &&
      entry.reason != UsageCreditLedgerReason.refundReversal &&
      entry.reason != UsageCreditLedgerReason.adminReversal) {
    throw ArgumentError('Negative ledger entries must consume or reverse.');
  }
  if (entry.isConsumption && entry.consumedAt == null) {
    throw ArgumentError('Consumption ledger entries need consumedAt.');
  }
  if (!usageCreditAuditMetadataKeysAreSafe(entry.auditMetadataKeys)) {
    throw ArgumentError('Audit metadata keys contain unsafe properties.');
  }
}

String _requireNonEmpty(String value, String label) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError('$label cannot be empty.');
  }
  return normalized;
}

String? _normalizeOptional(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}
