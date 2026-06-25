import 'package:flutter_test/flutter_test.dart';
import 'package:kidcost_mobile/src/telemetry/app_telemetry.dart';

void main() {
  test('privacy-safe telemetry sanitizes event payloads', () async {
    final delegate = SpyTelemetry();
    final telemetry = PrivacySafeTelemetry(delegate);

    await telemetry.track(
      TelemetryEvent.expenseCreated,
      parameters: {
        'release_channel': 'beta',
        'category_id': 'school',
        'has_attachment': true,
        'amount': '123.45',
        'child_name': 'Antek',
        'email': 'parent@example.com',
        'note': 'Prywatna notatka o koszcie',
        'signed_url': 'https://storage.example.com/receipt.pdf?token=secret',
      },
    );

    expect(delegate.trackedEvents.single, TelemetryEvent.expenseCreated);
    expect(delegate.trackedParameters.single, {
      'release_channel': 'beta',
      'category_id': 'school',
      'has_attachment': true,
    });
  });

  test(
    'privacy-safe telemetry redacts crash error text and unsafe reasons',
    () {
      final delegate = SpyTelemetry();
      final telemetry = PrivacySafeTelemetry(delegate);
      final stackTrace = StackTrace.current;

      telemetry.recordError(
        StateError('child Antek receipt path /families/f1/receipt.pdf'),
        stackTrace,
        reason: 'restore_session_failed',
      );
      telemetry.recordError(
        ArgumentError('parent@example.com 123.45 PLN'),
        stackTrace,
        reason: 'receipt https://storage.example.com/file.pdf',
      );

      expect(delegate.recordedErrors.map((error) => error.toString()), [
        'StateError',
        'ArgumentError',
      ]);
      expect(delegate.recordedReasons, ['restore_session_failed', null]);
      expect(delegate.recordedStackTraces, [stackTrace, stackTrace]);
    },
  );

  test('crash reasons allow only short technical codes', () {
    expect(sanitizeCrashReason('flutter_error'), 'flutter_error');
    expect(
      sanitizeCrashReason('restore-session-failed'),
      'restore-session-failed',
    );
    expect(sanitizeCrashReason('parent@example.com'), isNull);
    expect(sanitizeCrashReason('/families/f1/receipt.pdf'), isNull);
    expect(sanitizeCrashReason('123.45 PLN'), isNull);
    expect(sanitizeCrashReason('Opis z polskimi znakami'), isNull);
  });
}

class SpyTelemetry extends AppTelemetry {
  final trackedEvents = <TelemetryEvent>[];
  final trackedParameters = <Map<String, Object?>>[];
  final recordedErrors = <Object>[];
  final recordedStackTraces = <StackTrace>[];
  final recordedReasons = <String?>[];
  var wasDisposed = false;

  @override
  Future<void> track(
    TelemetryEvent event, {
    Map<String, Object?> parameters = const {},
  }) async {
    trackedEvents.add(event);
    trackedParameters.add(parameters);
  }

  @override
  void recordError(Object error, StackTrace stackTrace, {String? reason}) {
    recordedErrors.add(error);
    recordedStackTraces.add(stackTrace);
    recordedReasons.add(reason);
  }

  @override
  void dispose() {
    wasDisposed = true;
  }
}
