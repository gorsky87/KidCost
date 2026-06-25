import 'package:kidcost_domain/domain.dart';
import 'package:test/test.dart' as t;

void main() {
  t.test('domain assertions pass', () {
    testDailyDigestHoldsRoutineUpdates();
    testImportantUpdatesCanBypassQuietHours();
    testImportantOnlySuppressesRoutineUpdates();
    testQuietHoursWrapAcrossMidnight();
    testPrivatePreviewsAreDefault();
    testPrivatePreviewTemplatesRedactSensitiveDetails();
    testDetailedPreviewsCanIncludeContextAfterOptIn();
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

void testPrivatePreviewsAreDefault() {
  const preferences = NotificationPreferences();

  expectEqual(preferences.previewDetail, NotificationPreviewDetail.private);
}

void testPrivatePreviewTemplatesRedactSensitiveDetails() {
  const preferences = NotificationPreferences();
  const input = NotificationTemplateInput(
    childName: 'Antek',
    amountLabel: '123,45 zl',
    providerName: 'Orto Dent',
    disputeReason: 'Brakuje paragonu z leczenia',
    reportMonth: 'czerwiec 2026',
    itemCount: 2,
  );
  const forbidden = [
    'Antek',
    '123,45',
    'Orto Dent',
    'Brakuje paragonu',
    'czerwiec 2026',
  ];

  for (final template in NotificationTemplateKind.values) {
    final preview = preferences.previewFor(template: template, input: input);

    expectTrue(preview.title.contains('KidCost'));
    for (final sensitiveText in forbidden) {
      expectFalse(preview.searchableText.contains(sensitiveText));
    }
  }
}

void testDetailedPreviewsCanIncludeContextAfterOptIn() {
  const preferences = NotificationPreferences(
    previewDetail: NotificationPreviewDetail.detailed,
  );

  final preview = preferences.previewFor(
    template: NotificationTemplateKind.expenseAdded,
    input: const NotificationTemplateInput(
      childName: 'Antek',
      amountLabel: '123,45 zl',
      providerName: 'Orto Dent',
    ),
  );

  expectTrue(preview.searchableText.contains('Antek'));
  expectTrue(preview.searchableText.contains('123,45 zl'));
  expectTrue(preview.searchableText.contains('Orto Dent'));
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
