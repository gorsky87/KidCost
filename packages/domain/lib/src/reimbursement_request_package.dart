import 'reimbursement_deadlines.dart';

enum ReimbursementRequestDeliveryChannel {
  shareSheet,
  emailReadyCopy,
  secureReadOnlyLink,
}

enum ReimbursementRecipientAccessMode {
  noAccountCopyOnly,
  scopedTokenNoAccountRequired,
}

enum ReimbursementEvidenceState { none, attached, failedUpload, removed }

enum ReimbursementRequestAuditAction { packetCreated, packetShared }

class ReimbursementRequestExpenseLine {
  const ReimbursementRequestExpenseLine({
    required this.expenseId,
    required this.title,
    required this.childLabel,
    required this.categoryLabel,
    required this.incurredOn,
    required this.amountCents,
    required this.requestedShareCents,
    required this.statusLabel,
    required this.evidenceState,
  });

  final String expenseId;
  final String title;
  final String childLabel;
  final String categoryLabel;
  final DateTime incurredOn;
  final int amountCents;
  final int requestedShareCents;
  final String statusLabel;
  final ReimbursementEvidenceState evidenceState;
}

class ReimbursementRequestPacket {
  const ReimbursementRequestPacket({
    required this.packetId,
    required this.createdAt,
    required this.deliveryChannel,
    required this.recipientAccessMode,
    required this.lines,
    required this.totalCents,
    required this.requestedShareCents,
    required this.timelineLabel,
    required this.auditAction,
    required this.trustFooter,
    required this.previewCopy,
    required this.grantsBroaderFamilyAccess,
    required this.promisesPaymentProcessing,
    required this.claimsLegalCertification,
    this.tokenExpiresAt,
    this.deadlines,
    this.note,
  });

  final String packetId;
  final DateTime createdAt;
  final ReimbursementRequestDeliveryChannel deliveryChannel;
  final ReimbursementRecipientAccessMode recipientAccessMode;
  final List<ReimbursementRequestExpenseLine> lines;
  final int totalCents;
  final int requestedShareCents;
  final String timelineLabel;
  final ReimbursementRequestAuditAction auditAction;
  final String trustFooter;
  final String previewCopy;
  final bool grantsBroaderFamilyAccess;
  final bool promisesPaymentProcessing;
  final bool claimsLegalCertification;
  final DateTime? tokenExpiresAt;
  final ReimbursementDeadlineSnapshot? deadlines;
  final String? note;

  bool get hasSecureScopedToken {
    return deliveryChannel ==
            ReimbursementRequestDeliveryChannel.secureReadOnlyLink &&
        recipientAccessMode ==
            ReimbursementRecipientAccessMode.scopedTokenNoAccountRequired &&
        tokenExpiresAt != null;
  }

  bool get keepsRecipientOutOfFamilyAccess {
    return !grantsBroaderFamilyAccess;
  }

  bool get usesNeutralTimelineLanguage {
    return timelineLabel == reimbursementRequestTimelineLabels.packetShared ||
        timelineLabel == reimbursementRequestTimelineLabels.waitingForResponse;
  }
}

class ReimbursementRequestTimelineLabels {
  const ReimbursementRequestTimelineLabels({
    required this.packetCreated,
    required this.packetShared,
    required this.waitingForResponse,
  });

  final String packetCreated;
  final String packetShared;
  final String waitingForResponse;
}

class ReimbursementRequestAnalyticsEventDefinition {
  const ReimbursementRequestAnalyticsEventDefinition({
    required this.name,
    required this.requiredProperties,
    required this.rationale,
  });

  final String name;
  final Set<String> requiredProperties;
  final String rationale;
}

const reimbursementRequestTimelineLabels = ReimbursementRequestTimelineLabels(
  packetCreated: 'Request packet prepared',
  packetShared: 'Request sent',
  waitingForResponse: 'Waiting for response',
);

const reimbursementRequestTrustFooter =
    'KidCost porzadkuje rodzinny rekord kosztow. Ten pakiet nie jest porada prawna, certyfikacja sadowa ani platnoscia w aplikacji.';

const reimbursementRequestAuditEvents = {
  'reimbursement_request_packet_created',
  'reimbursement_request_packet_shared',
};

const kidCostReimbursementRequestAnalyticsEvents = [
  ReimbursementRequestAnalyticsEventDefinition(
    name: 'reimbursement_request_previewed',
    requiredProperties: {'delivery_channel', 'expense_count'},
    rationale: 'Mierzy preview bez nazw dzieci, opisow kosztow i kwot.',
  ),
  ReimbursementRequestAnalyticsEventDefinition(
    name: 'reimbursement_request_shared',
    requiredProperties: {
      'delivery_channel',
      'expense_count',
      'recipient_access_mode',
    },
    rationale: 'Mierzy sharing bez adresu odbiorcy i bez identyfikatorow.',
  ),
  ReimbursementRequestAnalyticsEventDefinition(
    name: 'reimbursement_request_token_created',
    requiredProperties: {'delivery_channel', 'recipient_access_mode'},
    rationale: 'Mierzy token tylko jako techniczny tryb dostepu.',
  ),
];

const reimbursementRequestAnalyticsAllowedProperties = {
  'delivery_channel',
  'expense_count',
  'recipient_access_mode',
};

ReimbursementRequestPacket buildReimbursementRequestPacket({
  required String packetId,
  required Iterable<ReimbursementRequestExpenseLine> lines,
  required DateTime createdAt,
  required ReimbursementRequestDeliveryChannel deliveryChannel,
  DateTime? tokenExpiresAt,
  ReimbursementDeadlineSnapshot? deadlines,
  String? note,
}) {
  final normalizedPacketId = packetId.trim();
  if (normalizedPacketId.isEmpty) {
    throw ArgumentError('Packet id cannot be empty.');
  }

  final packetLines = lines.toList(growable: false);
  if (packetLines.isEmpty) {
    throw ArgumentError('Request packet needs at least one expense.');
  }

  var totalCents = 0;
  var requestedShareCents = 0;
  for (final line in packetLines) {
    _validateLine(line);
    totalCents += line.amountCents;
    requestedShareCents += line.requestedShareCents;
  }

  final recipientAccessMode =
      deliveryChannel == ReimbursementRequestDeliveryChannel.secureReadOnlyLink
      ? ReimbursementRecipientAccessMode.scopedTokenNoAccountRequired
      : ReimbursementRecipientAccessMode.noAccountCopyOnly;
  if (recipientAccessMode ==
          ReimbursementRecipientAccessMode.scopedTokenNoAccountRequired &&
      tokenExpiresAt == null) {
    throw ArgumentError('Secure read-only request packets need token expiry.');
  }

  return ReimbursementRequestPacket(
    packetId: normalizedPacketId,
    createdAt: createdAt.toUtc(),
    deliveryChannel: deliveryChannel,
    recipientAccessMode: recipientAccessMode,
    lines: List.unmodifiable(packetLines),
    totalCents: totalCents,
    requestedShareCents: requestedShareCents,
    timelineLabel: reimbursementRequestTimelineLabels.packetShared,
    auditAction: ReimbursementRequestAuditAction.packetShared,
    trustFooter: reimbursementRequestTrustFooter,
    previewCopy: _buildPreviewCopy(
      expenseCount: packetLines.length,
      requestedShareCents: requestedShareCents,
      recipientAccessMode: recipientAccessMode,
    ),
    grantsBroaderFamilyAccess: false,
    promisesPaymentProcessing: false,
    claimsLegalCertification: false,
    tokenExpiresAt: tokenExpiresAt?.toUtc(),
    deadlines: deadlines,
    note: _normalizeOptional(note),
  );
}

String reimbursementRequestShareText(ReimbursementRequestPacket packet) {
  final buffer = StringBuffer()
    ..writeln('KidCost reimbursement request')
    ..writeln(
      'Status: ${reimbursementRequestTimelineLabels.waitingForResponse}',
    )
    ..writeln('Requested share: ${_formatCents(packet.requestedShareCents)}')
    ..writeln('Total included: ${_formatCents(packet.totalCents)}')
    ..writeln('Items:');

  for (final line in packet.lines) {
    buffer.writeln(
      '- ${line.title}: ${_formatCents(line.amountCents)}, requested ${_formatCents(line.requestedShareCents)}, ${_evidenceLabel(line.evidenceState)}',
    );
  }

  final note = packet.note;
  if (note != null && note.isNotEmpty) {
    buffer.writeln('Note: $note');
  }
  final deadlines = packet.deadlines;
  if (deadlines != null) {
    buffer.writeln(
      'Timing: ${reimbursementDeadlineTimingLabels[deadlines.timingState(now: packet.createdAt)]}',
    );
  }
  buffer.writeln(packet.trustFooter);
  return buffer.toString().trim();
}

bool reimbursementRequestAnalyticsPropertiesAreSafe(Set<String> properties) {
  return properties.every(
    reimbursementRequestAnalyticsAllowedProperties.contains,
  );
}

void _validateLine(ReimbursementRequestExpenseLine line) {
  if (line.expenseId.trim().isEmpty) {
    throw ArgumentError('Expense id cannot be empty.');
  }
  if (line.title.trim().isEmpty) {
    throw ArgumentError('Expense title cannot be empty.');
  }
  if (line.childLabel.trim().isEmpty) {
    throw ArgumentError('Child label cannot be empty.');
  }
  if (line.categoryLabel.trim().isEmpty) {
    throw ArgumentError('Category label cannot be empty.');
  }
  if (line.statusLabel.trim().isEmpty) {
    throw ArgumentError('Status label cannot be empty.');
  }
  if (line.amountCents <= 0) {
    throw ArgumentError('Expense amount must be greater than zero.');
  }
  if (line.requestedShareCents <= 0) {
    throw ArgumentError('Requested share must be greater than zero.');
  }
  if (line.requestedShareCents > line.amountCents) {
    throw ArgumentError('Requested share cannot exceed expense amount.');
  }
}

String _buildPreviewCopy({
  required int expenseCount,
  required int requestedShareCents,
  required ReimbursementRecipientAccessMode recipientAccessMode,
}) {
  final accessCopy =
      recipientAccessMode ==
          ReimbursementRecipientAccessMode.scopedTokenNoAccountRequired
      ? 'read-only link, no account required'
      : 'share text, no account required';
  return 'Preview $expenseCount itemized expense(s), requested ${_formatCents(requestedShareCents)}, $accessCopy.';
}

String _formatCents(int cents) {
  final whole = cents ~/ 100;
  final fraction = (cents % 100).toString().padLeft(2, '0');
  return '$whole.$fraction';
}

String _evidenceLabel(ReimbursementEvidenceState state) {
  switch (state) {
    case ReimbursementEvidenceState.none:
      return 'no receipt attached';
    case ReimbursementEvidenceState.attached:
      return 'receipt attached';
    case ReimbursementEvidenceState.failedUpload:
      return 'receipt upload failed';
    case ReimbursementEvidenceState.removed:
      return 'receipt removed';
  }
}

String? _normalizeOptional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
