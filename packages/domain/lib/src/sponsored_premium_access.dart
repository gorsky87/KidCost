enum SponsoredPremiumState {
  invited,
  active,
  canceledActiveUntilPeriodEnd,
  expired,
  refunded,
  feeWaiverOverride,
  accountMismatch,
}

enum SponsoredPremiumActor {
  sponsor,
  sponsoredMember,
  support,
  billingProvider,
}

enum SponsoredPremiumPermission {
  payForSeat,
  cancelSponsorship,
  viewBillingStatus,
  viewOwnRecords,
  editOwnRecords,
  exportOwnRecords,
  viewSponsoredMemberRecords,
  editSponsoredMemberRecords,
  exportSponsoredMemberRecords,
  manageSponsoredMemberRole,
  moderateSponsoredMember,
}

enum SponsoredPremiumAnalyticsEvent {
  sponsorshipInvited,
  sponsorshipActivated,
  sponsorshipCanceled,
  sponsorshipExpired,
  sponsorshipRefunded,
  sponsorshipFeeWaiverApplied,
  sponsorshipAccountMismatch,
}

class SponsoredPremiumStateRule {
  const SponsoredPremiumStateRule({
    required this.state,
    required this.memberHasPremium,
    required this.renewalSource,
    required this.summary,
  });

  final SponsoredPremiumState state;
  final bool memberHasPremium;
  final String renewalSource;
  final String summary;
}

class SponsoredPremiumPolicy {
  const SponsoredPremiumPolicy({
    required this.copy,
    required this.stateRules,
    required this.analyticsEvents,
    required this.safeAnalyticsProperties,
  });

  final SponsoredPremiumCopy copy;
  final List<SponsoredPremiumStateRule> stateRules;
  final Set<SponsoredPremiumAnalyticsEvent> analyticsEvents;
  final Set<String> safeAnalyticsProperties;

  SponsoredPremiumStateRule ruleFor(SponsoredPremiumState state) {
    for (final rule in stateRules) {
      if (rule.state == state) {
        return rule;
      }
    }
    throw ArgumentError('No sponsored Premium rule for state: $state');
  }

  bool permissionAllowed({
    required SponsoredPremiumActor actor,
    required SponsoredPremiumPermission permission,
  }) {
    if (actor == SponsoredPremiumActor.sponsoredMember) {
      return _sponsoredMemberPermissions.contains(permission);
    }
    if (actor == SponsoredPremiumActor.sponsor) {
      return _sponsorPermissions.contains(permission);
    }
    if (actor == SponsoredPremiumActor.support) {
      return _supportPermissions.contains(permission);
    }
    if (actor == SponsoredPremiumActor.billingProvider) {
      return _billingProviderPermissions.contains(permission);
    }
    return false;
  }

  bool get sponsorCannotControlSponsoredRecords {
    return !_sponsorPermissions.contains(
          SponsoredPremiumPermission.viewSponsoredMemberRecords,
        ) &&
        !_sponsorPermissions.contains(
          SponsoredPremiumPermission.editSponsoredMemberRecords,
        ) &&
        !_sponsorPermissions.contains(
          SponsoredPremiumPermission.exportSponsoredMemberRecords,
        ) &&
        !_sponsorPermissions.contains(
          SponsoredPremiumPermission.manageSponsoredMemberRole,
        ) &&
        !_sponsorPermissions.contains(
          SponsoredPremiumPermission.moderateSponsoredMember,
        );
  }

  bool analyticsPropertiesAreSafe(Set<String> properties) {
    return safeAnalyticsProperties.containsAll(properties);
  }
}

class SponsoredPremiumCopy {
  const SponsoredPremiumCopy({
    required this.settingsSummary,
    required this.sponsorBoundary,
    required this.cancellation,
    required this.supportTransfer,
  });

  final String settingsSummary;
  final String sponsorBoundary;
  final String cancellation;
  final String supportTransfer;
}

const _sponsorPermissions = {
  SponsoredPremiumPermission.payForSeat,
  SponsoredPremiumPermission.cancelSponsorship,
  SponsoredPremiumPermission.viewBillingStatus,
  SponsoredPremiumPermission.viewOwnRecords,
  SponsoredPremiumPermission.editOwnRecords,
  SponsoredPremiumPermission.exportOwnRecords,
};

const _sponsoredMemberPermissions = {
  SponsoredPremiumPermission.viewOwnRecords,
  SponsoredPremiumPermission.editOwnRecords,
  SponsoredPremiumPermission.exportOwnRecords,
};

const _supportPermissions = {
  SponsoredPremiumPermission.viewBillingStatus,
  SponsoredPremiumPermission.cancelSponsorship,
};

const _billingProviderPermissions = {
  SponsoredPremiumPermission.viewBillingStatus,
};

const kidCostSponsoredPremiumPolicy = SponsoredPremiumPolicy(
  copy: SponsoredPremiumCopy(
    settingsSummary:
        'Sponsor oplaca Premium dla tej osoby, ale nie dostaje dostepu do jej prywatnych rekordow ani kontroli konta.',
    sponsorBoundary:
        'Platnosc nie zmienia roli w rodzinie, wlasciciela danych, praw eksportu, moderacji ani widocznosci rekordow.',
    cancellation:
        'Po anulowaniu sponsor przestaje placic od konca okresu; istniejace rekordy sponsorowanej osoby pozostaja jej dostepne.',
    supportTransfer:
        'Support moze pomoc przy pomylce zakupu bez pokazywania sponsorowi kosztow, paragonow, notatek albo kontekstu prawnego.',
  ),
  stateRules: [
    SponsoredPremiumStateRule(
      state: SponsoredPremiumState.invited,
      memberHasPremium: false,
      renewalSource: 'pending_sponsor_acceptance',
      summary: 'Zaproszenie czeka na przyjecie bez zmiany dostepu do danych.',
    ),
    SponsoredPremiumStateRule(
      state: SponsoredPremiumState.active,
      memberHasPremium: true,
      renewalSource: 'sponsor_payment',
      summary: 'Sponsor placi za Premium, sponsorowany uzywa funkcji Premium.',
    ),
    SponsoredPremiumStateRule(
      state: SponsoredPremiumState.canceledActiveUntilPeriodEnd,
      memberHasPremium: true,
      renewalSource: 'canceled_sponsor_payment',
      summary: 'Dostep trwa do konca oplaconego okresu.',
    ),
    SponsoredPremiumStateRule(
      state: SponsoredPremiumState.expired,
      memberHasPremium: false,
      renewalSource: 'none',
      summary: 'Premium wygaslo; podstawowe rekordy pozostaja czytelne.',
    ),
    SponsoredPremiumStateRule(
      state: SponsoredPremiumState.refunded,
      memberHasPremium: false,
      renewalSource: 'refunded_sponsor_payment',
      summary: 'Zwrot wstrzymuje nowe funkcje Premium bez ukrywania rekordow.',
    ),
    SponsoredPremiumStateRule(
      state: SponsoredPremiumState.feeWaiverOverride,
      memberHasPremium: true,
      renewalSource: 'support_fee_waiver',
      summary:
          'Fee waiver moze zastapic sponsorship bez zaleznosci od sponsora.',
    ),
    SponsoredPremiumStateRule(
      state: SponsoredPremiumState.accountMismatch,
      memberHasPremium: false,
      renewalSource: 'support_review',
      summary:
          'Pomylka konta wymaga supportu bez ujawniania danych rodzinnych.',
    ),
  ],
  analyticsEvents: {
    SponsoredPremiumAnalyticsEvent.sponsorshipInvited,
    SponsoredPremiumAnalyticsEvent.sponsorshipActivated,
    SponsoredPremiumAnalyticsEvent.sponsorshipCanceled,
    SponsoredPremiumAnalyticsEvent.sponsorshipExpired,
    SponsoredPremiumAnalyticsEvent.sponsorshipRefunded,
    SponsoredPremiumAnalyticsEvent.sponsorshipFeeWaiverApplied,
    SponsoredPremiumAnalyticsEvent.sponsorshipAccountMismatch,
  },
  safeAnalyticsProperties: {
    'surface',
    'sponsorship_state',
    'renewal_source',
    'actor_type',
    'billing_platform',
    'has_fee_waiver',
  },
);

bool sponsoredPremiumStatesAreMapped() {
  final mappedStates = {
    for (final rule in kidCostSponsoredPremiumPolicy.stateRules) rule.state,
  };
  return mappedStates.length == SponsoredPremiumState.values.length &&
      mappedStates.containsAll(SponsoredPremiumState.values);
}
