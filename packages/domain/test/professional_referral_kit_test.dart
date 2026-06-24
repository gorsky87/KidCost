import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testReferralKitDefinesLandingBrochureTrackingAndWorkflows();
    testReferralKitAvoidsProfessionalDashboardAndBroadAccess();
    testReferralCopyAvoidsLegalAndCertificationClaims();
    testReferralTrackingNormalizesAttributionWithoutSensitiveAnalytics();
    testProfessionalReferralAnalyticsTaxonomyUsesSafeProperties();
  });
}

void testReferralKitDefinesLandingBrochureTrackingAndWorkflows() {
  final policy = kidCostProfessionalReferralKitPolicy;
  final sectionIds = {
    for (final section in policy.landingSections) section.section,
  };
  final brochureIds = {
    for (final section in policy.brochureSections) section.section,
  };
  final trackingIds = {for (final field in policy.trackingFields) field.field};
  final workflowIds = {
    for (final workflow in policy.workflows) workflow.workflow,
  };

  expectTrue(policy.audiences.contains(ProfessionalReferralAudience.mediator));
  expectTrue(
    policy.audiences.contains(ProfessionalReferralAudience.familyLawyer),
  );
  expectTrue(sectionIds.contains(ProfessionalReferralLandingSection.hero));
  expectTrue(
    sectionIds.contains(ProfessionalReferralLandingSection.brochureDownload),
  );
  expectTrue(
    sectionIds.contains(ProfessionalReferralLandingSection.futureScopedAccess),
  );
  expectTrue(
    brochureIds.contains(ProfessionalReferralBrochureSection.whatKidCostDoes),
  );
  expectTrue(
    brochureIds.contains(ProfessionalReferralBrochureSection.sharingBoundaries),
  );
  expectTrue(
    trackingIds.contains(ProfessionalReferralTrackingField.partnerCode),
  );
  expectTrue(
    trackingIds.contains(
      ProfessionalReferralTrackingField.manuallyEnteredProfessionalName,
    ),
  );
  expectTrue(
    workflowIds.contains(ProfessionalReferralWorkflow.parentBringsPdfReport),
  );
  expectTrue(
    workflowIds.contains(
      ProfessionalReferralWorkflow.parentSharesReadOnlyReportLink,
    ),
  );
  expectTrue(policy.futureScopedAccessIssueUrl.endsWith('/issues/44'));
}

void testReferralKitAvoidsProfessionalDashboardAndBroadAccess() {
  final policy = kidCostProfessionalReferralKitPolicy;

  expectFalse(policy.requiresProfessionalDashboard);
  expectFalse(policy.grantsBroadProfessionalAccess);
  expectTrue(
    policy.trustBoundaries.contains(
      ProfessionalReferralTrustBoundary.noProfessionalDashboardRequired,
    ),
  );
  expectTrue(
    policy.trustBoundaries.contains(
      ProfessionalReferralTrustBoundary.parentControlledAccess,
    ),
  );

  for (final workflow in policy.workflows) {
    expectFalse(workflow.requiresProfessionalAccount);
    expectFalse(workflow.grantsBroadFamilyAccess);
    expectTrue(workflow.steps.isNotEmpty);
  }
}

void testReferralCopyAvoidsLegalAndCertificationClaims() {
  final policy = kidCostProfessionalReferralKitPolicy;

  expectTrue(policy.copyIsTrustSafe);
  expectTrue(policy.copy.disclaimer.contains('nie udziela porad prawnych'));
  expectTrue(policy.copy.disclaimer.contains('nie certyfikuje'));
  expectTrue(policy.copy.parentControl.contains('rodzic kontroluje'));
  expectFalse(professionalReferralCopyIsTrustSafe('KidCost legal advice'));
  expectFalse(professionalReferralCopyIsTrustSafe('court certified export'));
  expectFalse(professionalReferralCopyIsTrustSafe('lawyer endorsed reports'));
}

void testReferralTrackingNormalizesAttributionWithoutSensitiveAnalytics() {
  final attribution = buildProfessionalReferralAttribution(
    partnerCode: ' MED-123 ',
    utmSource: ' Partner ',
    utmMedium: ' Brochure ',
    utmCampaign: ' q3-mediation ',
    inviteSource: ' Landing ',
    professionalRole: ' Mediator ',
    manuallyEnteredProfessionalName: ' Example Mediation Office ',
  );

  expectEqual(attribution.partnerCode, 'med-123');
  expectEqual(attribution.utmSource, 'partner');
  expectEqual(attribution.utmMedium, 'brochure');
  expectEqual(attribution.utmCampaign, 'q3-mediation');
  expectEqual(attribution.inviteSource, 'landing');
  expectEqual(attribution.professionalRole, 'mediator');
  expectEqual(
    attribution.manuallyEnteredProfessionalName,
    'Example Mediation Office',
  );
  expectTrue(
    professionalReferralAnalyticsPropertiesAreSafe(
      attribution.analyticsProperties,
    ),
  );
  expectTrue(
    attribution.analyticsProperties.contains('professional_name_provided'),
  );
  expectFalse(attribution.analyticsProperties.contains('family_id'));

  expectThrows(
    () =>
        buildProfessionalReferralAttribution(utmCampaign: 'child-expense-case'),
  );
  expectThrows(
    () => buildProfessionalReferralAttribution(professionalRole: 'judge'),
  );
}

void testProfessionalReferralAnalyticsTaxonomyUsesSafeProperties() {
  final eventNames = {
    for (final definition
        in kidCostProfessionalReferralKitPolicy.analyticsEvents)
      definition.name,
  };

  expectTrue(eventNames.contains('professional_landing_viewed'));
  expectTrue(eventNames.contains('professional_brochure_downloaded'));
  expectTrue(eventNames.contains('professional_referral_signup_started'));
  expectTrue(eventNames.contains('professional_referral_report_generated'));
  expectTrue(allProfessionalReferralAnalyticsEventsAreSafe());
  expectFalse(professionalReferralAnalyticsPropertiesAreSafe({'family_id'}));
  expectFalse(professionalReferralAnalyticsPropertiesAreSafe({'child_id'}));
  expectFalse(professionalReferralAnalyticsPropertiesAreSafe({'expense_id'}));
  expectFalse(professionalReferralAnalyticsPropertiesAreSafe({'receipt_text'}));
  expectFalse(professionalReferralAnalyticsPropertiesAreSafe({'dispute_note'}));
}

void expectTrue(bool value) {
  if (!value) {
    throw StateError('Expected value to be true.');
  }
}

void expectFalse(bool value) {
  if (value) {
    throw StateError('Expected value to be false.');
  }
}

void expectEqual(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected <$expected>, got <$actual>.');
  }
}

void expectThrows(void Function() action) {
  var didThrow = false;
  try {
    action();
  } on ArgumentError {
    didThrow = true;
  }
  if (!didThrow) {
    throw StateError('Expected ArgumentError.');
  }
}
