enum ProfessionalAccessMechanism {
  expiringSecureReportLink,
  inviteBasedAccountAccess,
}

enum ProfessionalReportPermission {
  viewSelectedReport,
  downloadPdfIfAllowed,
  viewIncludedReceipts,
}

enum ProfessionalAccessAuditAction {
  invitationCreated,
  invitationAccepted,
  reportViewed,
  pdfDownloaded,
  accessRevoked,
  accessExpired,
}

enum ProfessionalDataMinimizationRule {
  redactChildNamesByDefault,
  excludePrivateNotes,
  excludeUnselectedReceipts,
  hideBillingControls,
  hideFamilySettings,
}

class ProfessionalAccessPolicy {
  const ProfessionalAccessPolicy({
    required this.mechanism,
    required this.mechanismRationale,
    required this.permissions,
    required this.auditActions,
    required this.dataMinimizationRules,
    required this.defaultExpiryDays,
    required this.copy,
  });

  final ProfessionalAccessMechanism mechanism;
  final String mechanismRationale;
  final Set<ProfessionalReportPermission> permissions;
  final Set<ProfessionalAccessAuditAction> auditActions;
  final Set<ProfessionalDataMinimizationRule> dataMinimizationRules;
  final int defaultExpiryDays;
  final ProfessionalAccessCopy copy;

  bool get isReadOnly {
    return permissions.every(
      (permission) =>
          permission == ProfessionalReportPermission.viewSelectedReport ||
          permission == ProfessionalReportPermission.downloadPdfIfAllowed ||
          permission == ProfessionalReportPermission.viewIncludedReceipts,
    );
  }

  bool get isScopedAndRevocable {
    return mechanism == ProfessionalAccessMechanism.expiringSecureReportLink &&
        defaultExpiryDays > 0 &&
        auditActions.contains(ProfessionalAccessAuditAction.accessRevoked) &&
        auditActions.contains(ProfessionalAccessAuditAction.accessExpired);
  }

  bool get auditsEveryAccess {
    return auditActions.contains(ProfessionalAccessAuditAction.reportViewed) &&
        auditActions.contains(ProfessionalAccessAuditAction.pdfDownloaded);
  }
}

class ProfessionalAccessCopy {
  const ProfessionalAccessCopy({
    required this.title,
    required this.body,
    required this.noLegalAdvice,
  });

  final String title;
  final String body;
  final String noLegalAdvice;
}

class ProfessionalAccessAuditEvent {
  const ProfessionalAccessAuditEvent({
    required this.action,
    required this.familyId,
    required this.reportMonth,
    required this.actorId,
    required this.occurredAt,
    this.professionalRole,
  });

  final ProfessionalAccessAuditAction action;
  final String familyId;
  final String reportMonth;
  final String actorId;
  final DateTime occurredAt;
  final String? professionalRole;
}

const kidCostProfessionalAccessPolicy = ProfessionalAccessPolicy(
  mechanism: ProfessionalAccessMechanism.expiringSecureReportLink,
  mechanismRationale:
      'MVP wybiera wygasajacy link do wybranego raportu zamiast konta profesjonalisty, zeby ograniczyc zakres danych i uniknac szerokiego dostepu do rodziny.',
  permissions: {
    ProfessionalReportPermission.viewSelectedReport,
    ProfessionalReportPermission.downloadPdfIfAllowed,
    ProfessionalReportPermission.viewIncludedReceipts,
  },
  auditActions: {
    ProfessionalAccessAuditAction.invitationCreated,
    ProfessionalAccessAuditAction.invitationAccepted,
    ProfessionalAccessAuditAction.reportViewed,
    ProfessionalAccessAuditAction.pdfDownloaded,
    ProfessionalAccessAuditAction.accessRevoked,
    ProfessionalAccessAuditAction.accessExpired,
  },
  dataMinimizationRules: {
    ProfessionalDataMinimizationRule.redactChildNamesByDefault,
    ProfessionalDataMinimizationRule.excludePrivateNotes,
    ProfessionalDataMinimizationRule.excludeUnselectedReceipts,
    ProfessionalDataMinimizationRule.hideBillingControls,
    ProfessionalDataMinimizationRule.hideFamilySettings,
  },
  defaultExpiryDays: 14,
  copy: ProfessionalAccessCopy(
    title: 'Udostepnij wybrany raport profesjonaliscie',
    body:
        'Mediator lub prawnik dostaje tylko wybrany okres raportu, bez edycji kosztow, usuwania paragonow, billing control i ustawien rodziny.',
    noLegalAdvice:
        'KidCost porzadkuje rekordy rodzinne, ale nie udziela porad prawnych i nie obiecuje akceptacji raportu przez sad.',
  ),
);

ProfessionalAccessAuditEvent buildProfessionalAccessAuditEvent({
  required ProfessionalAccessAuditAction action,
  required String familyId,
  required String reportMonth,
  required String actorId,
  required DateTime occurredAt,
  String? professionalRole,
}) {
  final normalizedFamilyId = familyId.trim();
  final normalizedReportMonth = reportMonth.trim();
  final normalizedActorId = actorId.trim();
  final normalizedRole = professionalRole?.trim();

  if (normalizedFamilyId.isEmpty) {
    throw ArgumentError('Family id cannot be empty.');
  }
  if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(normalizedReportMonth)) {
    throw ArgumentError('Report month must use YYYY-MM format.');
  }
  if (normalizedActorId.isEmpty) {
    throw ArgumentError('Actor id cannot be empty.');
  }

  return ProfessionalAccessAuditEvent(
    action: action,
    familyId: normalizedFamilyId,
    reportMonth: normalizedReportMonth,
    actorId: normalizedActorId,
    occurredAt: occurredAt.toUtc(),
    professionalRole: normalizedRole == null || normalizedRole.isEmpty
        ? null
        : normalizedRole,
  );
}

String professionalPermissionLabel(ProfessionalReportPermission permission) {
  switch (permission) {
    case ProfessionalReportPermission.viewSelectedReport:
      return 'Podglad wybranego raportu';
    case ProfessionalReportPermission.downloadPdfIfAllowed:
      return 'Pobranie PDF, jesli rodzic pozwoli';
    case ProfessionalReportPermission.viewIncludedReceipts:
      return 'Podglad tylko dolaczonych dowodow';
  }
}

String professionalDataRuleLabel(ProfessionalDataMinimizationRule rule) {
  switch (rule) {
    case ProfessionalDataMinimizationRule.redactChildNamesByDefault:
      return 'Imiona dzieci domyslnie zredagowane';
    case ProfessionalDataMinimizationRule.excludePrivateNotes:
      return 'Prywatne notatki poza pakietem';
    case ProfessionalDataMinimizationRule.excludeUnselectedReceipts:
      return 'Niewybrane paragony poza linkiem';
    case ProfessionalDataMinimizationRule.hideBillingControls:
      return 'Bez billing control';
    case ProfessionalDataMinimizationRule.hideFamilySettings:
      return 'Bez ustawien rodziny';
  }
}
