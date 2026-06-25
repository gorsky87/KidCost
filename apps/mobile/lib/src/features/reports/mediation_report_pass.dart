import '../expenses/expense_models.dart';

const mediationReportPassPriceHypothesis = '49 PLN jednorazowo';
const mediationReportPassExpiryDays = 14;
const mediationReportPassDownloadWindowDays = 30;
const mediationReportPassRegenerationLimit = 3;

const mediationReportPassLegalCopy =
    'Pakiet porzadkuje rekordy KidCost do rozmowy lub mediacji; nie jest porada prawna ani gwarancja dopuszczalnosci.';

const mediationReportPassFreeAccessCopy =
    'Istniejace rekordy i podstawowy CSV pozostaja dostepne bez passu.';

const mediationReportPassTelemetryEvents = [
  'report_pass_preview_viewed',
  'report_pass_purchase_started',
  'report_pass_purchased',
  'report_pass_generation_started',
  'report_pass_generated',
  'report_pass_downloaded',
  'report_pass_expired_viewed',
  'report_pass_refund_requested',
];

const mediationReportPassTelemetryProperties = [
  'pass_state',
  'range_type',
  'expense_count',
  'has_receipts',
  'has_disputed_items',
  'regenerations_remaining',
  'export_format',
];

enum MediationReportPassState { locked, active, exhausted, expired }

class MediationReportPass {
  const MediationReportPass({
    required this.purchasedAt,
    required this.expiresAt,
    required this.downloadsAvailableUntil,
    this.regenerationsRemaining = mediationReportPassRegenerationLimit,
    this.refunded = false,
  });

  factory MediationReportPass.purchase(DateTime now) {
    return MediationReportPass(
      purchasedAt: now.toUtc(),
      expiresAt: now.toUtc().add(
        const Duration(days: mediationReportPassExpiryDays),
      ),
      downloadsAvailableUntil: now.toUtc().add(
        const Duration(days: mediationReportPassDownloadWindowDays),
      ),
    );
  }

  final DateTime purchasedAt;
  final DateTime expiresAt;
  final DateTime downloadsAvailableUntil;
  final int regenerationsRemaining;
  final bool refunded;

  MediationReportPassState stateAt(DateTime now) {
    final timestamp = now.toUtc();
    if (refunded || timestamp.isAfter(expiresAt)) {
      return MediationReportPassState.expired;
    }
    if (regenerationsRemaining <= 0) {
      return MediationReportPassState.exhausted;
    }
    return MediationReportPassState.active;
  }

  MediationReportPass useRegeneration() {
    return MediationReportPass(
      purchasedAt: purchasedAt,
      expiresAt: expiresAt,
      downloadsAvailableUntil: downloadsAvailableUntil,
      regenerationsRemaining: regenerationsRemaining > 0
          ? regenerationsRemaining - 1
          : 0,
      refunded: refunded,
    );
  }
}

class MediationReportPacket {
  const MediationReportPacket({
    required this.rangeLabel,
    required this.expenses,
    required this.generatedAt,
    required this.isRedactedPreview,
  });

  final String rangeLabel;
  final List<ExpenseEntry> expenses;
  final DateTime generatedAt;
  final bool isRedactedPreview;

  int get totalCents =>
      expenses.fold(0, (total, expense) => total + expense.amountCents);

  int get disputedCount => expenses
      .where((expense) => expense.status == ExpenseStatus.disputed)
      .length;

  int get pendingCount => expenses
      .where((expense) => expense.status == ExpenseStatus.pending)
      .length;

  int get receiptCount =>
      expenses.where((expense) => expense.attachment != null).length;

  Map<String, int> get byCategory {
    final values = <String, int>{};
    for (final expense in expenses) {
      values.update(
        expense.category.label,
        (value) => value + expense.amountCents,
        ifAbsent: () => expense.amountCents,
      );
    }
    return Map.unmodifiable(values);
  }

  String get previewTitle =>
      isRedactedPreview ? 'Podglad pakietu mediacyjnego' : 'Pakiet gotowy';

  String get fileName => 'kidcost-mediation-packet-$rangeLabel.pdf';

  String get csvFileName => 'kidcost-mediation-packet-$rangeLabel.csv';
}
