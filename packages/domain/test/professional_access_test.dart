import 'package:kidcost_domain/domain.dart';

void main() {
  testPolicyUsesScopedExpiringReportLink();
  testPolicyIsReadOnlyAuditedAndMinimized();
  testAuditEventNormalizesRequiredFields();
  testAuditEventRejectsInvalidScope();
}

void testPolicyUsesScopedExpiringReportLink() {
  expectEqual(
    kidCostProfessionalAccessPolicy.mechanism,
    ProfessionalAccessMechanism.expiringSecureReportLink,
  );
  expectTrue(kidCostProfessionalAccessPolicy.defaultExpiryDays > 0);
  expectTrue(kidCostProfessionalAccessPolicy.isScopedAndRevocable);
}

void testPolicyIsReadOnlyAuditedAndMinimized() {
  expectTrue(kidCostProfessionalAccessPolicy.isReadOnly);
  expectTrue(kidCostProfessionalAccessPolicy.auditsEveryAccess);
  expectTrue(
    kidCostProfessionalAccessPolicy.auditActions.contains(
      ProfessionalAccessAuditAction.invitationCreated,
    ),
  );
  expectTrue(
    kidCostProfessionalAccessPolicy.dataMinimizationRules.contains(
      ProfessionalDataMinimizationRule.excludePrivateNotes,
    ),
  );
  expectTrue(
    kidCostProfessionalAccessPolicy.copy.noLegalAdvice.contains(
      'nie udziela porad prawnych',
    ),
  );
}

void testAuditEventNormalizesRequiredFields() {
  final event = buildProfessionalAccessAuditEvent(
    action: ProfessionalAccessAuditAction.reportViewed,
    familyId: ' family-1 ',
    reportMonth: '2026-06',
    actorId: ' parent-1 ',
    professionalRole: ' mediator ',
    occurredAt: DateTime.utc(2026, 6, 24, 12),
  );

  expectEqual(event.familyId, 'family-1');
  expectEqual(event.reportMonth, '2026-06');
  expectEqual(event.actorId, 'parent-1');
  expectEqual(event.professionalRole, 'mediator');
  expectEqual(event.occurredAt, DateTime.utc(2026, 6, 24, 12));
}

void testAuditEventRejectsInvalidScope() {
  expectThrows(
    () => buildProfessionalAccessAuditEvent(
      action: ProfessionalAccessAuditAction.invitationCreated,
      familyId: 'family-1',
      reportMonth: 'June 2026',
      actorId: 'parent-1',
      occurredAt: DateTime.utc(2026, 6, 24),
    ),
  );
  expectThrows(
    () => buildProfessionalAccessAuditEvent(
      action: ProfessionalAccessAuditAction.invitationCreated,
      familyId: '',
      reportMonth: '2026-06',
      actorId: 'parent-1',
      occurredAt: DateTime.utc(2026, 6, 24),
    ),
  );
}

void expectTrue(bool value) {
  if (!value) {
    throw StateError('Expected value to be true.');
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
