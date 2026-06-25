enum NotificationDeliveryMode { immediate, dailyDigest, importantOnly }

enum NotificationUpdateKind {
  expenseUpdate,
  calendarUpdate,
  paymentDueSoon,
  overdueBalance,
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
    this.quietHoursEnabled = true,
    this.quietHours = const QuietHoursWindow(startHour: 21, endHour: 7),
    this.importantCanBypassQuietHours = true,
  });

  final NotificationDeliveryMode deliveryMode;
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

const notificationDeliveryChannelLabels = {
  NotificationDeliveryChannel.immediate: 'Wyslane od razu',
  NotificationDeliveryChannel.dailyDigest: 'Trafi do dziennego digestu',
  NotificationDeliveryChannel.suppressed: 'Wyciszone dla zwyklych aktualizacji',
};

void _validateHour(int hour) {
  if (hour < 0 || hour > 23) {
    throw RangeError.range(hour, 0, 23, 'hour');
  }
}
