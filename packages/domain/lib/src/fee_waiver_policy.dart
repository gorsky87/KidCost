enum FeeWaiverGrant { essentialRecordsOnly, limitedPremium, fullPremium }

enum FeeWaiverReviewOwner { supportTeam, adminToolingLater }

class FeeWaiverPolicy {
  const FeeWaiverPolicy({
    required this.eligibility,
    required this.durationDays,
    required this.renewalWindowDays,
    required this.grant,
    required this.reviewOwner,
    required this.minimalApplicationFields,
    required this.retentionDaysAfterDecision,
    required this.lapseAccess,
    required this.copy,
    required this.followUpTasks,
  });

  final List<String> eligibility;
  final int durationDays;
  final int renewalWindowDays;
  final FeeWaiverGrant grant;
  final FeeWaiverReviewOwner reviewOwner;
  final List<String> minimalApplicationFields;
  final int retentionDaysAfterDecision;
  final LapsedSubscriptionAccess lapseAccess;
  final FeeWaiverCopy copy;
  final List<String> followUpTasks;

  bool get avoidsSensitiveEvidenceCollection {
    return !minimalApplicationFields.contains('income_document') &&
        !minimalApplicationFields.contains('court_order') &&
        !minimalApplicationFields.contains('abuse_details');
  }
}

class LapsedSubscriptionAccess {
  const LapsedSubscriptionAccess({
    required this.canReadExistingExpenses,
    required this.canReadExistingReceipts,
    required this.canReadExistingBalances,
    required this.canUseBasicExports,
    required this.pausedPremiumFeatures,
  });

  final bool canReadExistingExpenses;
  final bool canReadExistingReceipts;
  final bool canReadExistingBalances;
  final bool canUseBasicExports;
  final List<String> pausedPremiumFeatures;

  bool get keepsCoreRecordsReadable {
    return canReadExistingExpenses &&
        canReadExistingReceipts &&
        canReadExistingBalances &&
        canUseBasicExports;
  }
}

class FeeWaiverCopy {
  const FeeWaiverCopy({
    required this.paymentFailure,
    required this.subscriptionLapse,
    required this.requestHelp,
    required this.privacy,
  });

  final String paymentFailure;
  final String subscriptionLapse;
  final String requestHelp;
  final String privacy;
}

const kidCostFeeWaiverPolicy = FeeWaiverPolicy(
  eligibility: [
    'Financial hardship',
    'Payment failure with need to keep family records available',
    'Safety or coercive-control concern where billing could become leverage',
    'Manual support exception for mediation/court-adjacent record continuity',
  ],
  durationDays: 180,
  renewalWindowDays: 30,
  grant: FeeWaiverGrant.limitedPremium,
  reviewOwner: FeeWaiverReviewOwner.supportTeam,
  minimalApplicationFields: [
    'reason_code',
    'country',
    'preferred_contact',
    'optional_short_note',
  ],
  retentionDaysAfterDecision: 90,
  lapseAccess: LapsedSubscriptionAccess(
    canReadExistingExpenses: true,
    canReadExistingReceipts: true,
    canReadExistingBalances: true,
    canUseBasicExports: true,
    pausedPremiumFeatures: [
      'new_ocr_runs',
      'new_pdf_reports',
      'new_evidence_bundles',
      'additional_storage',
    ],
  ),
  copy: FeeWaiverCopy(
    paymentFailure:
        'Nie udalo sie odnowic platnosci. Premium automatyzacje sa wstrzymane, ale istniejace koszty, paragony, saldo i podstawowy eksport pozostaja dostepne.',
    subscriptionLapse:
        'Po wygasnieciu Premium nie tracisz dostepu do rekordow utworzonych przed lapse.',
    requestHelp:
        'Mozesz poprosic support o czasowy fee-waiver. Decyzja jest reczna, na podstawie minimalnego formularza bez dokumentow dochodowych.',
    privacy:
        'Wniosek zbiera tylko kod powodu, kraj, kontakt i opcjonalna krotka notatke; usuwamy dane po 90 dniach od decyzji.',
  ),
  followUpTasks: [
    'Add entitlement state for active_fee_waiver and lapsed_premium.',
    'Build support queue for manual approval, rejection, renewal and expiry.',
    'Add audit events for waiver_requested, waiver_decided and waiver_expired.',
    'Wire billing-provider failure webhooks into lapsed Premium state.',
  ],
);

bool lapsedSubscriptionKeepsCoreRecordsReadable() {
  return kidCostFeeWaiverPolicy.lapseAccess.keepsCoreRecordsReadable;
}
