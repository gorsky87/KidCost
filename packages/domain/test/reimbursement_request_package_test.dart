import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testOneExpensePacketShowsTotalsAndRequestedShare();
    testMultipleExpensesBuildOneItemizedPacket();
    testSecureTokenAccessRequiresExpiryAndDoesNotGrantFamilyAccess();
    testFallbackShareCopyNeedsNoKidCostAccount();
    testAuditCopyAvoidsPaymentAndLegalPromises();
    testAnalyticsTaxonomyUsesSafeProperties();
  });
}

void testOneExpensePacketShowsTotalsAndRequestedShare() {
  final packet = buildReimbursementRequestPacket(
    packetId: 'packet-1',
    createdAt: DateTime.utc(2026, 6, 24, 21),
    deliveryChannel: ReimbursementRequestDeliveryChannel.shareSheet,
    lines: [
      requestLine(
        id: 'expense-1',
        title: 'Dentysta',
        amountCents: 12000,
        requestedShareCents: 6000,
        evidenceState: ReimbursementEvidenceState.attached,
      ),
    ],
  );

  expectEqual(packet.totalCents, 12000);
  expectEqual(packet.requestedShareCents, 6000);
  expectEqual(packet.lines.single.title, 'Dentysta');
  expectEqual(
    packet.lines.single.evidenceState,
    ReimbursementEvidenceState.attached,
  );
  expectTrue(packet.previewCopy.contains('1 itemized expense'));
  expectTrue(
    reimbursementRequestShareText(packet).contains('receipt attached'),
  );
}

void testMultipleExpensesBuildOneItemizedPacket() {
  final packet = buildReimbursementRequestPacket(
    packetId: 'packet-2',
    createdAt: DateTime.utc(2026, 6, 24, 21),
    deliveryChannel: ReimbursementRequestDeliveryChannel.emailReadyCopy,
    note: 'Czerwiec',
    lines: [
      requestLine(
        id: 'e1',
        title: 'Obiad',
        amountCents: 4500,
        requestedShareCents: 2250,
      ),
      requestLine(
        id: 'e2',
        title: 'Buty',
        amountCents: 9900,
        requestedShareCents: 4950,
        evidenceState: ReimbursementEvidenceState.none,
      ),
    ],
  );

  expectEqual(packet.totalCents, 14400);
  expectEqual(packet.requestedShareCents, 7200);
  expectEqual(packet.lines.length, 2);
  expectEqual(packet.note, 'Czerwiec');
  expectTrue(reimbursementRequestShareText(packet).contains('Items:'));
}

void testSecureTokenAccessRequiresExpiryAndDoesNotGrantFamilyAccess() {
  expectThrows(
    () => buildReimbursementRequestPacket(
      packetId: 'packet-token-missing',
      createdAt: DateTime.utc(2026, 6, 24, 21),
      deliveryChannel: ReimbursementRequestDeliveryChannel.secureReadOnlyLink,
      lines: [requestLine(id: 'e1')],
    ),
  );

  final packet = buildReimbursementRequestPacket(
    packetId: 'packet-token',
    createdAt: DateTime.utc(2026, 6, 24, 21),
    deliveryChannel: ReimbursementRequestDeliveryChannel.secureReadOnlyLink,
    tokenExpiresAt: DateTime.utc(2026, 7, 1),
    lines: [requestLine(id: 'e1')],
  );

  expectTrue(packet.hasSecureScopedToken);
  expectTrue(packet.keepsRecipientOutOfFamilyAccess);
  expectFalse(packet.grantsBroaderFamilyAccess);
  expectEqual(
    packet.recipientAccessMode,
    ReimbursementRecipientAccessMode.scopedTokenNoAccountRequired,
  );
}

void testFallbackShareCopyNeedsNoKidCostAccount() {
  final packet = buildReimbursementRequestPacket(
    packetId: 'packet-copy',
    createdAt: DateTime.utc(2026, 6, 24, 21),
    deliveryChannel: ReimbursementRequestDeliveryChannel.emailReadyCopy,
    lines: [requestLine(id: 'e1')],
  );

  expectEqual(
    packet.recipientAccessMode,
    ReimbursementRecipientAccessMode.noAccountCopyOnly,
  );
  expectTrue(packet.previewCopy.contains('no account required'));
  expectTrue(packet.usesNeutralTimelineLanguage);
}

void testAuditCopyAvoidsPaymentAndLegalPromises() {
  final packet = buildReimbursementRequestPacket(
    packetId: 'packet-audit',
    createdAt: DateTime.utc(2026, 6, 24, 21),
    deliveryChannel: ReimbursementRequestDeliveryChannel.shareSheet,
    lines: [requestLine(id: 'e1')],
  );

  expectEqual(packet.auditAction, ReimbursementRequestAuditAction.packetShared);
  expectEqual(
    reimbursementRequestAuditEvents.contains(
      'reimbursement_request_packet_created',
    ),
    true,
  );
  expectEqual(
    reimbursementRequestAuditEvents.contains(
      'reimbursement_request_packet_shared',
    ),
    true,
  );
  expectFalse(packet.promisesPaymentProcessing);
  expectFalse(packet.claimsLegalCertification);
  expectTrue(packet.trustFooter.contains('nie jest porada prawna'));
  expectTrue(packet.trustFooter.contains('platnoscia w aplikacji'));
}

void testAnalyticsTaxonomyUsesSafeProperties() {
  final eventNames = {
    for (final definition in kidCostReimbursementRequestAnalyticsEvents)
      definition.name,
  };

  expectTrue(eventNames.contains('reimbursement_request_previewed'));
  expectTrue(eventNames.contains('reimbursement_request_shared'));
  expectTrue(eventNames.contains('reimbursement_request_token_created'));
  expectTrue(
    kidCostReimbursementRequestAnalyticsEvents.every(
      (definition) => reimbursementRequestAnalyticsPropertiesAreSafe(
        definition.requiredProperties,
      ),
    ),
  );
  expectFalse(reimbursementRequestAnalyticsPropertiesAreSafe({'amount'}));
  expectFalse(reimbursementRequestAnalyticsPropertiesAreSafe({'child_id'}));
  expectFalse(reimbursementRequestAnalyticsPropertiesAreSafe({'expense_id'}));
  expectFalse(
    reimbursementRequestAnalyticsPropertiesAreSafe({'recipient_email'}),
  );
  expectFalse(reimbursementRequestAnalyticsPropertiesAreSafe({'receipt_id'}));
}

ReimbursementRequestExpenseLine requestLine({
  required String id,
  String title = 'Koszt',
  int amountCents = 10000,
  int requestedShareCents = 5000,
  ReimbursementEvidenceState evidenceState =
      ReimbursementEvidenceState.attached,
}) {
  return ReimbursementRequestExpenseLine(
    expenseId: id,
    title: title,
    childLabel: 'Dziecko',
    categoryLabel: 'Zdrowie',
    incurredOn: DateTime.utc(2026, 6, 24),
    amountCents: amountCents,
    requestedShareCents: requestedShareCents,
    statusLabel: 'Waiting for response',
    evidenceState: evidenceState,
  );
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
