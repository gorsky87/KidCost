enum ProfessionalReferralAudience {
  mediator,
  familyLawyer,
  parentSupportProfessional,
}

enum ProfessionalReferralLandingSection {
  hero,
  whyFamiliesUseKidCost,
  sampleWorkflows,
  parentControlledSharing,
  privacyAndBoundaries,
  brochureDownload,
  futureScopedAccess,
}

enum ProfessionalReferralBrochureSection {
  whatKidCostDoes,
  howParentsUseIt,
  exampleReports,
  sharingBoundaries,
  nextStep,
}

enum ProfessionalReferralTrackingField {
  partnerCode,
  utmSource,
  utmMedium,
  utmCampaign,
  inviteSource,
  professionalRole,
  manuallyEnteredProfessionalName,
}

enum ProfessionalReferralWorkflow {
  parentBringsPdfReport,
  parentSharesReadOnlyReportLink,
  parentUsesExpenseLogBeforeMediation,
}

enum ProfessionalReferralTrustBoundary {
  noLegalAdvice,
  noCourtCertification,
  noProfessionalEndorsementClaim,
  parentControlledAccess,
  noProfessionalDashboardRequired,
}

class ProfessionalReferralLandingSectionSpec {
  const ProfessionalReferralLandingSectionSpec({
    required this.section,
    required this.headline,
    required this.body,
    required this.primaryAction,
  });

  final ProfessionalReferralLandingSection section;
  final String headline;
  final String body;
  final String primaryAction;
}

class ProfessionalReferralBrochureSectionSpec {
  const ProfessionalReferralBrochureSectionSpec({
    required this.section,
    required this.title,
    required this.bullets,
  });

  final ProfessionalReferralBrochureSection section;
  final String title;
  final List<String> bullets;
}

class ProfessionalReferralTrackingFieldSpec {
  const ProfessionalReferralTrackingFieldSpec({
    required this.field,
    required this.analyticsProperty,
    required this.storesRawValue,
    required this.summary,
  });

  final ProfessionalReferralTrackingField field;
  final String analyticsProperty;
  final bool storesRawValue;
  final String summary;
}

class ProfessionalReferralWorkflowSpec {
  const ProfessionalReferralWorkflowSpec({
    required this.workflow,
    required this.title,
    required this.steps,
    required this.requiresProfessionalAccount,
    required this.grantsBroadFamilyAccess,
  });

  final ProfessionalReferralWorkflow workflow;
  final String title;
  final List<String> steps;
  final bool requiresProfessionalAccount;
  final bool grantsBroadFamilyAccess;
}

class ProfessionalReferralTrustCopy {
  const ProfessionalReferralTrustCopy({
    required this.heroTitle,
    required this.heroBody,
    required this.parentControl,
    required this.disclaimer,
    required this.futureScopedAccess,
  });

  final String heroTitle;
  final String heroBody;
  final String parentControl;
  final String disclaimer;
  final String futureScopedAccess;
}

class ProfessionalReferralKitPolicy {
  const ProfessionalReferralKitPolicy({
    required this.audiences,
    required this.landingSections,
    required this.brochureSections,
    required this.trackingFields,
    required this.workflows,
    required this.trustBoundaries,
    required this.analyticsEvents,
    required this.copy,
    required this.futureScopedAccessIssueUrl,
  });

  final Set<ProfessionalReferralAudience> audiences;
  final List<ProfessionalReferralLandingSectionSpec> landingSections;
  final List<ProfessionalReferralBrochureSectionSpec> brochureSections;
  final List<ProfessionalReferralTrackingFieldSpec> trackingFields;
  final List<ProfessionalReferralWorkflowSpec> workflows;
  final Set<ProfessionalReferralTrustBoundary> trustBoundaries;
  final List<ProfessionalReferralAnalyticsEventDefinition> analyticsEvents;
  final ProfessionalReferralTrustCopy copy;
  final String futureScopedAccessIssueUrl;

  bool get requiresProfessionalDashboard {
    return workflows.any((workflow) => workflow.requiresProfessionalAccount);
  }

  bool get grantsBroadProfessionalAccess {
    return workflows.any((workflow) => workflow.grantsBroadFamilyAccess);
  }

  bool get copyIsTrustSafe {
    return professionalReferralCopyIsTrustSafe(copy.heroTitle) &&
        professionalReferralCopyIsTrustSafe(copy.heroBody) &&
        professionalReferralCopyIsTrustSafe(copy.parentControl) &&
        professionalReferralCopyIsTrustSafe(copy.disclaimer) &&
        professionalReferralCopyIsTrustSafe(copy.futureScopedAccess) &&
        copy.disclaimer.contains('nie udziela porad prawnych') &&
        copy.disclaimer.contains('nie certyfikuje') &&
        copy.parentControl.contains('rodzic kontroluje');
  }

  ProfessionalReferralLandingSectionSpec landingSectionFor(
    ProfessionalReferralLandingSection section,
  ) {
    for (final spec in landingSections) {
      if (spec.section == section) {
        return spec;
      }
    }
    throw ArgumentError('Unknown professional referral section: $section');
  }

  ProfessionalReferralTrackingFieldSpec trackingFieldFor(
    ProfessionalReferralTrackingField field,
  ) {
    for (final spec in trackingFields) {
      if (spec.field == field) {
        return spec;
      }
    }
    throw ArgumentError('Unknown professional referral tracking field: $field');
  }

  ProfessionalReferralWorkflowSpec workflowFor(
    ProfessionalReferralWorkflow workflow,
  ) {
    for (final spec in workflows) {
      if (spec.workflow == workflow) {
        return spec;
      }
    }
    throw ArgumentError('Unknown professional referral workflow: $workflow');
  }
}

class ProfessionalReferralAnalyticsEventDefinition {
  const ProfessionalReferralAnalyticsEventDefinition({
    required this.name,
    required this.requiredProperties,
    required this.rationale,
  });

  final String name;
  final Set<String> requiredProperties;
  final String rationale;
}

class ProfessionalReferralAttribution {
  const ProfessionalReferralAttribution({
    this.partnerCode,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.inviteSource,
    this.professionalRole,
    this.manuallyEnteredProfessionalName,
  });

  final String? partnerCode;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? inviteSource;
  final String? professionalRole;
  final String? manuallyEnteredProfessionalName;

  Set<String> get analyticsProperties {
    return {
      if (partnerCode != null) 'partner_code_present',
      if (utmSource != null) 'utm_source',
      if (utmMedium != null) 'utm_medium',
      if (utmCampaign != null) 'utm_campaign_bucket',
      if (inviteSource != null) 'invite_source',
      if (professionalRole != null) 'professional_role',
      if (manuallyEnteredProfessionalName != null) 'professional_name_provided',
    };
  }
}

const kidCostProfessionalReferralKitPolicy = ProfessionalReferralKitPolicy(
  audiences: {
    ProfessionalReferralAudience.mediator,
    ProfessionalReferralAudience.familyLawyer,
    ProfessionalReferralAudience.parentSupportProfessional,
  },
  landingSections: [
    ProfessionalReferralLandingSectionSpec(
      section: ProfessionalReferralLandingSection.hero,
      headline: 'KidCost dla rodzin porzadkujacych koszty dziecka',
      body:
          'Neutralny rekord kosztow, paragonow i zwrotow, ktory rodzic moze pokazac przed rozmowa lub mediacja.',
      primaryAction: 'Pobierz one-pager dla rodzicow',
    ),
    ProfessionalReferralLandingSectionSpec(
      section: ProfessionalReferralLandingSection.whyFamiliesUseKidCost,
      headline: 'Mniej chaosu wokol paragonow i rozliczen',
      body:
          'Rodzice moga zbierac koszty, statusy, dowody i podstawowe eksporty bez przekazywania kontroli profesjonalisci.',
      primaryAction: 'Zobacz przykladowe zastosowania',
    ),
    ProfessionalReferralLandingSectionSpec(
      section: ProfessionalReferralLandingSection.sampleWorkflows,
      headline: 'Trzy proste scenariusze uzycia',
      body:
          'PDF na spotkanie, wygasajacy link read-only albo dziennik kosztow przed mediacja.',
      primaryAction: 'Przejrzyj workflow',
    ),
    ProfessionalReferralLandingSectionSpec(
      section: ProfessionalReferralLandingSection.parentControlledSharing,
      headline: 'Udostepnianie kontroluje rodzic',
      body:
          'Profesjonalista dostaje tylko to, co rodzic jawnie wybierze do raportu lub linku.',
      primaryAction: 'Zobacz zasady dostepu',
    ),
    ProfessionalReferralLandingSectionSpec(
      section: ProfessionalReferralLandingSection.privacyAndBoundaries,
      headline: 'Granice zaufania sa jasne',
      body:
          'KidCost porzadkuje rekordy, ale nie udziela porad prawnych, nie przygotowuje pism i nie certyfikuje dowodow.',
      primaryAction: 'Przeczytaj disclaimer',
    ),
    ProfessionalReferralLandingSectionSpec(
      section: ProfessionalReferralLandingSection.brochureDownload,
      headline: 'One-page handout dla rodzicow',
      body:
          'Krotki material do przekazania po rozmowie, z QR/linkiem i bez claimow o rekomendacji zawodowej.',
      primaryAction: 'Pobierz PDF',
    ),
    ProfessionalReferralLandingSectionSpec(
      section: ProfessionalReferralLandingSection.futureScopedAccess,
      headline: 'Profesjonalny dostep scoped jako przyszly krok',
      body:
          'MVP dziala bez kont profesjonalistow; pozniej moze dojsc wygasajacy, audytowany dostep do wybranych raportow.',
      primaryAction: 'Zobacz kierunek produktu',
    ),
  ],
  brochureSections: [
    ProfessionalReferralBrochureSectionSpec(
      section: ProfessionalReferralBrochureSection.whatKidCostDoes,
      title: 'Co robi KidCost',
      bullets: [
        'Pomaga rodzicom zapisywac koszty dziecka, dowody i statusy zwrotu.',
        'Tworzy raporty i eksporty z danych wprowadzonych przez rodzica.',
        'Nie zastepuje porady prawnej ani decyzji profesjonalisty.',
      ],
    ),
    ProfessionalReferralBrochureSectionSpec(
      section: ProfessionalReferralBrochureSection.howParentsUseIt,
      title: 'Jak rodzic moze zaczac',
      bullets: [
        'Dodaje koszty recznie lub z paragonem.',
        'Oznacza status: oczekuje, zaakceptowane, sporne albo rozliczone.',
        'Eksportuje podstawowy CSV lub generuje raport Premium.',
      ],
    ),
    ProfessionalReferralBrochureSectionSpec(
      section: ProfessionalReferralBrochureSection.exampleReports,
      title: 'Przyklady do rozmowy',
      bullets: [
        'Miesieczny raport kosztow dziecka.',
        'Lista wydatkow z dowodami wybranymi przez rodzica.',
        'Historia statusow przed mediacja.',
      ],
    ),
    ProfessionalReferralBrochureSectionSpec(
      section: ProfessionalReferralBrochureSection.sharingBoundaries,
      title: 'Granice udostepniania',
      bullets: [
        'Rodzic kontroluje, co udostepnia.',
        'Link read-only moze wygasnac lub zostac cofniety.',
        'Prywatne notatki i ustawienia rodziny nie sa czescia kitu.',
      ],
    ),
    ProfessionalReferralBrochureSectionSpec(
      section: ProfessionalReferralBrochureSection.nextStep,
      title: 'Nastepny krok',
      bullets: [
        'Rodzic moze wejsc przez link partnera lub kod polecenia.',
        'Aplikacja mierzy zrodlo bez danych dziecka, kosztow ani sporu.',
      ],
    ),
  ],
  trackingFields: [
    ProfessionalReferralTrackingFieldSpec(
      field: ProfessionalReferralTrackingField.partnerCode,
      analyticsProperty: 'partner_code_present',
      storesRawValue: true,
      summary:
          'Kod partnera zapisany jako atrybucja kanalowa, bez danych rodzinnych.',
    ),
    ProfessionalReferralTrackingFieldSpec(
      field: ProfessionalReferralTrackingField.utmSource,
      analyticsProperty: 'utm_source',
      storesRawValue: true,
      summary: 'Zrodlo kampanii publicznej, np. mediator-kit.',
    ),
    ProfessionalReferralTrackingFieldSpec(
      field: ProfessionalReferralTrackingField.utmMedium,
      analyticsProperty: 'utm_medium',
      storesRawValue: true,
      summary: 'Medium kampanii, np. brochure, email lub landing.',
    ),
    ProfessionalReferralTrackingFieldSpec(
      field: ProfessionalReferralTrackingField.utmCampaign,
      analyticsProperty: 'utm_campaign_bucket',
      storesRawValue: false,
      summary: 'Kampania raportowana jako bucket, bez opisow spraw rodzinnych.',
    ),
    ProfessionalReferralTrackingFieldSpec(
      field: ProfessionalReferralTrackingField.inviteSource,
      analyticsProperty: 'invite_source',
      storesRawValue: true,
      summary: 'Powierzchnia wejscia: landing, brochure, report share.',
    ),
    ProfessionalReferralTrackingFieldSpec(
      field: ProfessionalReferralTrackingField.professionalRole,
      analyticsProperty: 'professional_role',
      storesRawValue: true,
      summary: 'Rola w kontrolowanym slowniku: mediator, lawyer, support.',
    ),
    ProfessionalReferralTrackingFieldSpec(
      field: ProfessionalReferralTrackingField.manuallyEnteredProfessionalName,
      analyticsProperty: 'professional_name_provided',
      storesRawValue: true,
      summary:
          'Opcjonalna nazwa do supportu/CRM; analytics widzi tylko flage podania nazwy.',
    ),
  ],
  workflows: [
    ProfessionalReferralWorkflowSpec(
      workflow: ProfessionalReferralWorkflow.parentBringsPdfReport,
      title: 'Rodzic przynosi PDF na spotkanie',
      steps: [
        'Rodzic prowadzi ledger kosztow i dowodow.',
        'Rodzic generuje raport PDF dla wybranego okresu.',
        'Rodzic sam decyduje, czy i komu pokazac plik.',
      ],
      requiresProfessionalAccount: false,
      grantsBroadFamilyAccess: false,
    ),
    ProfessionalReferralWorkflowSpec(
      workflow: ProfessionalReferralWorkflow.parentSharesReadOnlyReportLink,
      title: 'Rodzic udostepnia read-only link',
      steps: [
        'Rodzic wybiera raport i dowody do linku.',
        'Link jest scoped, wygasajacy i audytowany.',
        'Dostep mozna cofnac bez zmiany danych rodziny.',
      ],
      requiresProfessionalAccount: false,
      grantsBroadFamilyAccess: false,
    ),
    ProfessionalReferralWorkflowSpec(
      workflow:
          ProfessionalReferralWorkflow.parentUsesExpenseLogBeforeMediation,
      title: 'Rodzic porzadkuje log przed mediacja',
      steps: [
        'Rodzic dopisuje zalegle koszty i statusy.',
        'KidCost pomaga wykryc braki w dowodach.',
        'Rodzic eksportuje uporzadkowany rekord do rozmowy.',
      ],
      requiresProfessionalAccount: false,
      grantsBroadFamilyAccess: false,
    ),
  ],
  trustBoundaries: {
    ProfessionalReferralTrustBoundary.noLegalAdvice,
    ProfessionalReferralTrustBoundary.noCourtCertification,
    ProfessionalReferralTrustBoundary.noProfessionalEndorsementClaim,
    ProfessionalReferralTrustBoundary.parentControlledAccess,
    ProfessionalReferralTrustBoundary.noProfessionalDashboardRequired,
  },
  analyticsEvents: [
    ProfessionalReferralAnalyticsEventDefinition(
      name: 'professional_landing_viewed',
      requiredProperties: {'surface', 'professional_role'},
      rationale: 'Mierzy wejscia bez danych rodziny lub sprawy.',
    ),
    ProfessionalReferralAnalyticsEventDefinition(
      name: 'professional_brochure_downloaded',
      requiredProperties: {'surface', 'partner_code_present'},
      rationale: 'Mierzy pobrania bez nazw profesjonalistow w analytics.',
    ),
    ProfessionalReferralAnalyticsEventDefinition(
      name: 'professional_referral_signup_started',
      requiredProperties: {'invite_source', 'professional_role'},
      rationale: 'Mierzy intencje signupu bez danych dziecka lub kosztow.',
    ),
    ProfessionalReferralAnalyticsEventDefinition(
      name: 'professional_referral_report_generated',
      requiredProperties: {'invite_source', 'report_type'},
      rationale: 'Mierzy aktywacje raportu bez miesiecy, kwot i opisow.',
    ),
  ],
  copy: ProfessionalReferralTrustCopy(
    heroTitle: 'KidCost pomaga rodzicom uporzadkowac koszty dziecka',
    heroBody:
        'Dla mediatorow, prawnikow rodzinnych i specjalistow wsparcia: neutralny material, ktory mozna pokazac rodzicom bez tworzenia konta profesjonalisty.',
    parentControl:
        'To rodzic kontroluje dane, raporty i linki. Profesjonalista nie dostaje ustawien rodziny ani billing control.',
    disclaimer:
        'KidCost porzadkuje rekordy rodzinne, ale nie udziela porad prawnych, nie przygotowuje pism i nie certyfikuje dopuszczalnosci dowodow.',
    futureScopedAccess:
        'Przyszly scoped access moze dodac wygasajace, audytowane linki do wybranych raportow bez szerokiego dashboardu.',
  ),
  futureScopedAccessIssueUrl: 'https://github.com/gorsky87/KidCost/issues/44',
);

const professionalReferralAnalyticsAllowedProperties = {
  'invite_source',
  'partner_code_present',
  'professional_name_provided',
  'professional_role',
  'report_type',
  'surface',
  'utm_campaign_bucket',
  'utm_medium',
  'utm_source',
};

const _forbiddenReferralClaims = {
  'court certified',
  'court-certified',
  'certifies court admissibility',
  'guaranteed reimbursement',
  'kidcost legal advice',
  'lawyer endorsed',
  'professional endorsement',
  'porada prawna w aplikacji',
  'gwarantowany zwrot',
  'gwarantuje dopuszczalnosc',
};

ProfessionalReferralAttribution buildProfessionalReferralAttribution({
  String? partnerCode,
  String? utmSource,
  String? utmMedium,
  String? utmCampaign,
  String? inviteSource,
  String? professionalRole,
  String? manuallyEnteredProfessionalName,
}) {
  return ProfessionalReferralAttribution(
    partnerCode: _normalizeToken(partnerCode, 'Partner code'),
    utmSource: _normalizeToken(utmSource, 'UTM source'),
    utmMedium: _normalizeToken(utmMedium, 'UTM medium'),
    utmCampaign: _normalizeCampaign(utmCampaign),
    inviteSource: _normalizeToken(inviteSource, 'Invite source'),
    professionalRole: _normalizeProfessionalRole(professionalRole),
    manuallyEnteredProfessionalName: _normalizeOptionalName(
      manuallyEnteredProfessionalName,
    ),
  );
}

bool professionalReferralCopyIsTrustSafe(String copy) {
  final normalized = _normalizeForClaimScan(copy);
  return _forbiddenReferralClaims.every((claim) => !normalized.contains(claim));
}

bool professionalReferralAnalyticsPropertiesAreSafe(Set<String> properties) {
  return properties.every(
    professionalReferralAnalyticsAllowedProperties.contains,
  );
}

bool allProfessionalReferralAnalyticsEventsAreSafe() {
  return kidCostProfessionalReferralKitPolicy.analyticsEvents.every(
    (definition) => professionalReferralAnalyticsPropertiesAreSafe(
      definition.requiredProperties,
    ),
  );
}

String? _normalizeToken(String? value, String label) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (!RegExp(r'^[a-z0-9_-]{2,64}$').hasMatch(normalized)) {
    throw ArgumentError('$label contains unsupported characters.');
  }
  return normalized;
}

String? _normalizeCampaign(String? value) {
  final normalized = _normalizeToken(value, 'UTM campaign');
  if (normalized == null) {
    return null;
  }
  if (normalized.contains('child') ||
      normalized.contains('expense') ||
      normalized.contains('dispute') ||
      normalized.contains('receipt')) {
    throw ArgumentError('UTM campaign cannot contain family case details.');
  }
  return normalized;
}

String? _normalizeProfessionalRole(String? value) {
  final normalized = _normalizeToken(value, 'Professional role');
  if (normalized == null) {
    return null;
  }
  const allowed = {'mediator', 'lawyer', 'support'};
  if (!allowed.contains(normalized)) {
    throw ArgumentError(
      'Professional role must use the controlled vocabulary.',
    );
  }
  return normalized;
}

String? _normalizeOptionalName(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized.length > 120) {
    throw ArgumentError('Professional name is too long.');
  }
  return normalized;
}

String _normalizeForClaimScan(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
