import 'package:flutter_test/flutter_test.dart';
import 'package:kidcost_mobile/src/config/app_config.dart';

void main() {
  test('environment defaults match the first beta build metadata', () {
    final config = AppConfig.fromEnvironment();

    expect(config.releaseChannel, 'demo');
    expect(config.buildName, '1.0.0');
    expect(config.buildNumber, '2');
    expect(config.analyticsEnabled, isFalse);
    expect(config.crashReportingEnabled, isFalse);
    expect(config.firebaseConfigured, isFalse);
  });

  test('beta-like releases include beta and public channels only', () {
    const beta = AppConfig(
      supabaseUrl: 'https://kidcost-beta.supabase.co',
      supabaseAnonKey: 'anon',
      releaseChannel: 'beta',
      buildName: '1.0.0',
      buildNumber: '2',
      analyticsEnabled: false,
      crashReportingEnabled: false,
      firebaseConfigured: false,
    );
    const public = AppConfig(
      supabaseUrl: 'https://kidcost.supabase.co',
      supabaseAnonKey: 'anon',
      releaseChannel: 'public',
      buildName: '1.0.0',
      buildNumber: '3',
      analyticsEnabled: true,
      crashReportingEnabled: true,
      firebaseConfigured: true,
    );
    const demo = AppConfig(
      supabaseUrl: '',
      supabaseAnonKey: '',
      releaseChannel: 'demo',
      buildName: '1.0.0',
      buildNumber: '2',
      analyticsEnabled: false,
      crashReportingEnabled: false,
      firebaseConfigured: false,
    );

    expect(beta.isBetaLike, isTrue);
    expect(public.isBetaLike, isTrue);
    expect(demo.isBetaLike, isFalse);
  });

  test('observability stays disabled until beta config is complete', () {
    const complete = AppConfig(
      supabaseUrl: 'https://kidcost-beta.supabase.co',
      supabaseAnonKey: 'anon',
      releaseChannel: 'beta',
      buildName: '1.0.0',
      buildNumber: '2',
      analyticsEnabled: true,
      crashReportingEnabled: true,
      firebaseConfigured: true,
    );
    const missingFirebase = AppConfig(
      supabaseUrl: 'https://kidcost-beta.supabase.co',
      supabaseAnonKey: 'anon',
      releaseChannel: 'beta',
      buildName: '1.0.0',
      buildNumber: '2',
      analyticsEnabled: true,
      crashReportingEnabled: true,
      firebaseConfigured: false,
    );
    const partialFlags = AppConfig(
      supabaseUrl: 'https://kidcost-beta.supabase.co',
      supabaseAnonKey: 'anon',
      releaseChannel: 'beta',
      buildName: '1.0.0',
      buildNumber: '2',
      analyticsEnabled: true,
      crashReportingEnabled: false,
      firebaseConfigured: true,
    );
    const demoWithFlags = AppConfig(
      supabaseUrl: '',
      supabaseAnonKey: '',
      releaseChannel: 'demo',
      buildName: '1.0.0',
      buildNumber: '2',
      analyticsEnabled: true,
      crashReportingEnabled: true,
      firebaseConfigured: true,
    );

    expect(complete.canUseConfiguredObservability, isTrue);
    expect(complete.betaObservabilityBlockers, isEmpty);

    expect(missingFirebase.canUseConfiguredObservability, isFalse);
    expect(missingFirebase.betaObservabilityBlockers, [
      'firebase_config_required',
    ]);

    expect(partialFlags.canUseConfiguredObservability, isFalse);
    expect(partialFlags.betaObservabilityBlockers, [
      'crash_reporting_flag_required',
    ]);

    expect(demoWithFlags.canUseConfiguredObservability, isFalse);
    expect(demoWithFlags.betaObservabilityBlockers, [
      'release_channel_must_be_beta_or_public',
      'supabase_config_required',
    ]);
  });

  test('disabled observability does not create release blockers', () {
    const demo = AppConfig(
      supabaseUrl: '',
      supabaseAnonKey: '',
      releaseChannel: 'demo',
      buildName: '1.0.0',
      buildNumber: '2',
      analyticsEnabled: false,
      crashReportingEnabled: false,
      firebaseConfigured: false,
    );

    expect(demo.wantsObservability, isFalse);
    expect(demo.canUseConfiguredObservability, isFalse);
    expect(demo.betaObservabilityBlockers, isEmpty);
  });
}
