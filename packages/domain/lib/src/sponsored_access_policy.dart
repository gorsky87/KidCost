enum SponsoredPremiumState {
  inactive,
  active,
  sponsorCancelled,
  memberRemoved,
  refunded,
  accountMismatch,
  feeWaiverOverride,
}

enum SponsoredPremiumRenewalSource { sponsor, support, none }

enum SponsoredAccessAction {
  payForPremium,
  readOwnRecords,
  readSponsoredMemberRecords,
  editSponsoredMemberRecords,
  exportSponsoredMemberRecords,
  changeSponsoredMemberFamilyRole,
  transferSponsoredMemberAccount,
  cancelSponsorship,
  requestSupportCorrection,
}

class SponsoredPremiumEntitlement {
  const SponsoredPremiumEntitlement({
    required this.state,
    required this.renewalSource,
    required this.sponsorUserId,
    required this.sponsoredUserId,
    required this.startsOn,
    this.endsOn,
  });

  final SponsoredPremiumState state;
  final SponsoredPremiumRenewalSource renewalSource;
  final String sponsorUserId;
  final String sponsoredUserId;
  final DateTime startsOn;
  final DateTime? endsOn;

  bool get isActive {
    return state == SponsoredPremiumState.active ||
        state == SponsoredPremiumState.feeWaiverOverride;
  }

  bool get sponsorAndMemberAreDistinct {
    return sponsorUserId != sponsoredUserId;
  }
}

class SponsoredAccessDecision {
  const SponsoredAccessDecision({
    required this.isAllowed,
    required this.action,
    required this.reason,
  });

  final bool isAllowed;
  final SponsoredAccessAction action;
  final String reason;
}

class SponsoredPremiumPrivacyPolicy {
  const SponsoredPremiumPrivacyPolicy({
    required this.billingNeverGrantsDataControl,
    required this.sponsorshipDoesNotChangeFamilyRole,
    required this.sponsorshipDoesNotGrantExportRights,
    required this.sponsorshipDoesNotGrantModerationPower,
    required this.copy,
    required this.analyticsEvents,
    required this.supportOperations,
  });

  final bool billingNeverGrantsDataControl;
  final bool sponsorshipDoesNotChangeFamilyRole;
  final bool sponsorshipDoesNotGrantExportRights;
  final bool sponsorshipDoesNotGrantModerationPower;
  final SponsoredPremiumCopy copy;
  final List<String> analyticsEvents;
  final List<String> supportOperations;

  bool get keepsDataBoundaryExplicit {
    return billingNeverGrantsDataControl &&
        sponsorshipDoesNotChangeFamilyRole &&
        sponsorshipDoesNotGrantExportRights &&
        sponsorshipDoesNotGrantModerationPower;
  }
}

class SponsoredPremiumCopy {
  const SponsoredPremiumCopy({
    required this.settingsSummary,
    required this.sponsorReceipt,
    required this.sponsoredMemberNotice,
    required this.supportCorrection,
  });

  final String settingsSummary;
  final String sponsorReceipt;
  final String sponsoredMemberNotice;
  final String supportCorrection;
}

const kidCostSponsoredPremiumPrivacyPolicy = SponsoredPremiumPrivacyPolicy(
  billingNeverGrantsDataControl: true,
  sponsorshipDoesNotChangeFamilyRole: true,
  sponsorshipDoesNotGrantExportRights: true,
  sponsorshipDoesNotGrantModerationPower: true,
  copy: SponsoredPremiumCopy(
    settingsSummary:
        'Sponsor placi za Premium tej osoby, ale nie dostaje dostepu do jej prywatnych rekordow ani kontroli konta.',
    sponsorReceipt:
        'Platnosc odblokowuje Premium sponsorowanemu kontu. Role rodzinne, eksporty i widocznosc danych pozostaja bez zmian.',
    sponsoredMemberNotice:
        'Masz Premium oplacone przez sponsora. Sponsor nie moze przez to czytac, edytowac, eksportowac ani przejmowac Twoich rekordow.',
    supportCorrection:
        'Support moze przeniesc lub anulowac bledna platnosc bez udostepniania rodzinnych rekordow sponsorowi.',
  ),
  analyticsEvents: [
    'sponsored_premium_started',
    'sponsored_premium_cancelled',
    'sponsored_premium_refunded',
    'sponsored_premium_fee_waiver_override',
  ],
  supportOperations: [
    'cancel mistaken sponsorship',
    'refund sponsor without exporting sponsored records',
    'resolve account mismatch from billing identifiers',
    'apply fee-waiver override without notifying private family details',
  ],
);

SponsoredAccessDecision evaluateSponsoredAccess({
  required SponsoredPremiumEntitlement entitlement,
  required SponsoredAccessAction action,
}) {
  switch (action) {
    case SponsoredAccessAction.payForPremium:
      return SponsoredAccessDecision(
        isAllowed: entitlement.sponsorAndMemberAreDistinct,
        action: action,
        reason: entitlement.sponsorAndMemberAreDistinct
            ? 'Sponsor moze oplacic Premium innej osoby.'
            : 'Sponsoring wymaga osobnego konta sponsorowanego.',
      );
    case SponsoredAccessAction.readOwnRecords:
    case SponsoredAccessAction.cancelSponsorship:
    case SponsoredAccessAction.requestSupportCorrection:
      return SponsoredAccessDecision(
        isAllowed: true,
        action: action,
        reason: 'Ta akcja nie rozszerza dostepu do cudzych rekordow.',
      );
    case SponsoredAccessAction.readSponsoredMemberRecords:
    case SponsoredAccessAction.editSponsoredMemberRecords:
    case SponsoredAccessAction.exportSponsoredMemberRecords:
    case SponsoredAccessAction.changeSponsoredMemberFamilyRole:
    case SponsoredAccessAction.transferSponsoredMemberAccount:
      return SponsoredAccessDecision(
        isAllowed: false,
        action: action,
        reason:
            'Platnosc sponsora nie daje dostepu, eksportu, kontroli roli ani przejecia konta sponsorowanej osoby.',
      );
  }
}

bool sponsoredPremiumKeepsBillingSeparateFromDataControl() {
  final entitlement = SponsoredPremiumEntitlement(
    state: SponsoredPremiumState.active,
    renewalSource: SponsoredPremiumRenewalSource.sponsor,
    sponsorUserId: 'sponsor-user',
    sponsoredUserId: 'sponsored-user',
    startsOn: DateTime.utc(2026, 1, 1),
  );

  final blockedControls = [
    SponsoredAccessAction.readSponsoredMemberRecords,
    SponsoredAccessAction.editSponsoredMemberRecords,
    SponsoredAccessAction.exportSponsoredMemberRecords,
    SponsoredAccessAction.changeSponsoredMemberFamilyRole,
    SponsoredAccessAction.transferSponsoredMemberAccount,
  ];

  return kidCostSponsoredPremiumPrivacyPolicy.keepsDataBoundaryExplicit &&
      evaluateSponsoredAccess(
        entitlement: entitlement,
        action: SponsoredAccessAction.payForPremium,
      ).isAllowed &&
      blockedControls.every(
        (action) => !evaluateSponsoredAccess(
          entitlement: entitlement,
          action: action,
        ).isAllowed,
      );
}
