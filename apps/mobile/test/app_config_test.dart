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
    );
    const public = AppConfig(
      supabaseUrl: 'https://kidcost.supabase.co',
      supabaseAnonKey: 'anon',
      releaseChannel: 'public',
      buildName: '1.0.0',
      buildNumber: '3',
      analyticsEnabled: true,
      crashReportingEnabled: true,
    );
    const demo = AppConfig(
      supabaseUrl: '',
      supabaseAnonKey: '',
      releaseChannel: 'demo',
      buildName: '1.0.0',
      buildNumber: '2',
      analyticsEnabled: false,
      crashReportingEnabled: false,
    );

    expect(beta.isBetaLike, isTrue);
    expect(public.isBetaLike, isTrue);
    expect(demo.isBetaLike, isFalse);
  });
}
