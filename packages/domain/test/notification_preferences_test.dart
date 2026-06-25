import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testDailyDigestHoldsRoutineUpdates();
    testImportantUpdatesCanBypassQuietHours();
    testImportantOnlySuppressesRoutineUpdates();
    testQuietHoursWrapAcrossMidnight();
  });
}

void testDailyDigestHoldsRoutineUpdates() {
  const preferences = NotificationPreferences(
    deliveryMode: NotificationDeliveryMode.dailyDigest,
  );

  final decision = preferences.deliveryDecision(
    updateKind: NotificationUpdateKind.expenseUpdate,
    now: DateTime.utc(2026, 6, 25, 10),
  );

  expectEqual(decision.channel, NotificationDeliveryChannel.dailyDigest);
  expectTrue(decision.reason.contains('digest'));
}

void testImportantUpdatesCanBypassQuietHours() {
  const preferences = NotificationPreferences(
    quietHours: QuietHoursWindow(startHour: 21, endHour: 7),
  );

  final decision = preferences.deliveryDecision(
    updateKind: NotificationUpdateKind.paymentDueSoon,
    now: DateTime.utc(2026, 6, 25, 22),
  );

  expectEqual(decision.channel, NotificationDeliveryChannel.immediate);
  expectTrue(NotificationUpdateKind.paymentDueSoon.isImportant);
}

void testImportantOnlySuppressesRoutineUpdates() {
  const preferences = NotificationPreferences(
    deliveryMode: NotificationDeliveryMode.importantOnly,
  );

  final routine = preferences.deliveryDecision(
    updateKind: NotificationUpdateKind.calendarUpdate,
    now: DateTime.utc(2026, 6, 25, 12),
  );
  final urgent = preferences.deliveryDecision(
    updateKind: NotificationUpdateKind.overdueBalance,
    now: DateTime.utc(2026, 6, 25, 12),
  );

  expectEqual(routine.channel, NotificationDeliveryChannel.suppressed);
  expectEqual(urgent.channel, NotificationDeliveryChannel.immediate);
}

void testQuietHoursWrapAcrossMidnight() {
  const quietHours = QuietHoursWindow(startHour: 21, endHour: 7);

  expectTrue(quietHours.contains(DateTime(2026, 6, 25, 22)));
  expectTrue(quietHours.contains(DateTime(2026, 6, 25, 6)));
  expectFalse(quietHours.contains(DateTime(2026, 6, 25, 12)));
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
