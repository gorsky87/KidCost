enum NotificationDeliveryMode { immediate, dailyDigest, importantOnly }

enum NotificationPreviewDetail { private, detailed }

enum NotificationUpdateKind {
  expenseUpdate,
  calendarUpdate,
  paymentDueSoon,
  overdueBalance,
}

enum NotificationTemplateKind {
  expenseAdded,
  expenseAccepted,
  disputeOpened,
  settlementRecorded,
  reportReady,
  digest,
}

class QuietHoursWindow {
  const QuietHoursWindow({required this.startHour, required this.endHour});

  final int startHour;
  final int endHour;

  bool contains(DateTime moment) {
    _validateHour(startHour);
    _validateHour(endHour);

    final hour = moment.toLocal().hour;
    if (startHour == endHour) return true;
    if (startHour < endHour) {
      return hour >= startHour && hour < endHour;
    }
    return hour >= startHour || hour < endHour;
  }
}

class NotificationPreferences {
  const NotificationPreferences({
    this.deliveryMode = NotificationDeliveryMode.immediate,
    this.previewDetail = NotificationPreviewDetail.private,
    this.quietHoursEnabled = true,
    this.quietHours = const QuietHoursWindow(startHour: 21, endHour: 7),
    this.importantCanBypassQuietHours = true,
  });

  final NotificationDeliveryMode deliveryMode;
  final NotificationPreviewDetail previewDetail;
  final bool quietHoursEnabled;
  final QuietHoursWindow quietHours;
  final bool importantCanBypassQuietHours;

  NotificationDeliveryDecision deliveryDecision({
    required NotificationUpdateKind updateKind,
    required DateTime now,
  }) {
    final important = updateKind.isImportant;
    final inQuietHours = quietHoursEnabled && quietHours.contains(now);

    if (deliveryMode == NotificationDeliveryMode.importantOnly && !important) {
      return const NotificationDeliveryDecision(
        channel: NotificationDeliveryChannel.suppressed,
        reason: 'Only important notifications are enabled.',
      );
    }

    if (deliveryMode == NotificationDeliveryMode.dailyDigest && !important) {
      return const NotificationDeliveryDecision(
        channel: NotificationDeliveryChannel.dailyDigest,
        reason: 'Routine updates are held for the daily digest.',
      );
    }

    if (inQuietHours && !(important && importantCanBypassQuietHours)) {
      return const NotificationDeliveryDecision(
        channel: NotificationDeliveryChannel.dailyDigest,
        reason: 'Quiet hours are active.',
      );
    }

    return NotificationDeliveryDecision(
      channel: NotificationDeliveryChannel.immediate,
      reason: important
          ? 'Important deadline updates can be sent now.'
          : 'Immediate notifications are enabled.',
    );
  }

  NotificationPreviewContent previewFor({
    required NotificationTemplateKind template,
    NotificationTemplateInput input = const NotificationTemplateInput(),
  }) {
    if (previewDetail == NotificationPreviewDetail.private) {
      return _privatePreviewFor(template, input);
    }
    return _detailedPreviewFor(template, input);
  }
}

enum NotificationDeliveryChannel { immediate, dailyDigest, suppressed }

class NotificationDeliveryDecision {
  const NotificationDeliveryDecision({
    required this.channel,
    required this.reason,
  });

  final NotificationDeliveryChannel channel;
  final String reason;
}

class NotificationTemplateInput {
  const NotificationTemplateInput({
    this.childName,
    this.amountLabel,
    this.providerName,
    this.disputeReason,
    this.reportMonth,
    this.itemCount,
  });

  final String? childName;
  final String? amountLabel;
  final String? providerName;
  final String? disputeReason;
  final String? reportMonth;
  final int? itemCount;
}

class NotificationPreviewContent {
  const NotificationPreviewContent({required this.title, required this.body});

  final String title;
  final String body;

  String get searchableText => '$title $body';
}

extension NotificationUpdateKindPriority on NotificationUpdateKind {
  bool get isImportant {
    switch (this) {
      case NotificationUpdateKind.paymentDueSoon:
      case NotificationUpdateKind.overdueBalance:
        return true;
      case NotificationUpdateKind.expenseUpdate:
      case NotificationUpdateKind.calendarUpdate:
        return false;
    }
  }
}

const notificationDeliveryModeLabels = {
  NotificationDeliveryMode.immediate: 'Od razu',
  NotificationDeliveryMode.dailyDigest: 'Dzienny digest',
  NotificationDeliveryMode.importantOnly: 'Tylko wazne',
};

const notificationPreviewDetailLabels = {
  NotificationPreviewDetail.private: 'Prywatne podglady',
  NotificationPreviewDetail.detailed: 'Szczegoly po odblokowaniu',
};

const notificationDeliveryChannelLabels = {
  NotificationDeliveryChannel.immediate: 'Wyslane od razu',
  NotificationDeliveryChannel.dailyDigest: 'Trafi do dziennego digestu',
  NotificationDeliveryChannel.suppressed: 'Wyciszone dla zwyklych aktualizacji',
};

NotificationPreviewContent _privatePreviewFor(
  NotificationTemplateKind template,
  NotificationTemplateInput input,
) {
  switch (template) {
    case NotificationTemplateKind.expenseAdded:
      return const NotificationPreviewContent(
        title: 'KidCost: koszt wymaga sprawdzenia',
        body: 'Otworz KidCost, aby zobaczyc szczegoly.',
      );
    case NotificationTemplateKind.expenseAccepted:
      return const NotificationPreviewContent(
        title: 'KidCost: status kosztu zmieniony',
        body: 'Szczegoly sa widoczne po otwarciu aplikacji.',
      );
    case NotificationTemplateKind.disputeOpened:
      return const NotificationPreviewContent(
        title: 'KidCost: koszt wymaga odpowiedzi',
        body: 'Powod i dane kosztu sa ukryte na ekranie blokady.',
      );
    case NotificationTemplateKind.settlementRecorded:
      return const NotificationPreviewContent(
        title: 'KidCost: rozliczenie zaktualizowane',
        body: 'Otworz aplikacje, aby zobaczyc saldo.',
      );
    case NotificationTemplateKind.reportReady:
      return const NotificationPreviewContent(
        title: 'KidCost: raport jest gotowy',
        body: 'Raport i kwoty sa dostepne w aplikacji.',
      );
    case NotificationTemplateKind.digest:
      return NotificationPreviewContent(
        title: 'KidCost: dzienne podsumowanie',
        body: input.itemCount == null
            ? 'Masz aktualizacje do sprawdzenia.'
            : 'Masz ${input.itemCount} aktualizacji do sprawdzenia.',
      );
  }
}

NotificationPreviewContent _detailedPreviewFor(
  NotificationTemplateKind template,
  NotificationTemplateInput input,
) {
  final child = _fallback(input.childName, 'dziecka');
  final amount = _fallback(input.amountLabel, 'nowa kwota');
  final provider = _fallback(input.providerName, 'dostawca');
  final reason = _fallback(input.disputeReason, 'powod wymaga sprawdzenia');
  final reportMonth = _fallback(input.reportMonth, 'wybrany miesiac');

  switch (template) {
    case NotificationTemplateKind.expenseAdded:
      return NotificationPreviewContent(
        title: 'Nowy koszt: $amount',
        body: '$provider dla $child wymaga sprawdzenia.',
      );
    case NotificationTemplateKind.expenseAccepted:
      return NotificationPreviewContent(
        title: 'Koszt zaakceptowany: $amount',
        body: '$provider dla $child ma nowy status.',
      );
    case NotificationTemplateKind.disputeOpened:
      return NotificationPreviewContent(
        title: 'Spor do kosztu: $amount',
        body: '$reason.',
      );
    case NotificationTemplateKind.settlementRecorded:
      return NotificationPreviewContent(
        title: 'Rozliczenie zapisane',
        body: '$amount zostalo dodane do salda.',
      );
    case NotificationTemplateKind.reportReady:
      return NotificationPreviewContent(
        title: 'Raport za $reportMonth jest gotowy',
        body: 'Mozesz sprawdzic koszty i eksport.',
      );
    case NotificationTemplateKind.digest:
      final count = input.itemCount ?? 0;
      return NotificationPreviewContent(
        title: 'Dzienne podsumowanie KidCost',
        body: count == 1
            ? 'Masz 1 aktualizacje kosztow.'
            : 'Masz $count aktualizacji kosztow.',
      );
  }
}

String _fallback(String? value, String fallback) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return fallback;
  }
  return trimmed;
}

void _validateHour(int hour) {
  if (hour < 0 || hour > 23) {
    throw RangeError.range(hour, 0, 23, 'hour');
  }
}
