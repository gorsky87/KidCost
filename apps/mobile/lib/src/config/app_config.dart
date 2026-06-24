class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.releaseChannel,
    required this.buildName,
    required this.buildNumber,
    required this.analyticsEnabled,
    required this.crashReportingEnabled,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      releaseChannel: String.fromEnvironment(
        'KIDCOST_RELEASE_CHANNEL',
        defaultValue: 'demo',
      ),
      buildName: String.fromEnvironment(
        'KIDCOST_BUILD_NAME',
        defaultValue: '1.0.0',
      ),
      buildNumber: String.fromEnvironment(
        'KIDCOST_BUILD_NUMBER',
        defaultValue: '2',
      ),
      analyticsEnabled: bool.fromEnvironment('KIDCOST_ANALYTICS_ENABLED'),
      crashReportingEnabled: bool.fromEnvironment(
        'KIDCOST_CRASH_REPORTING_ENABLED',
      ),
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String releaseChannel;
  final String buildName;
  final String buildNumber;
  final bool analyticsEnabled;
  final bool crashReportingEnabled;

  bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  bool get isBetaLike => releaseChannel == 'beta' || releaseChannel == 'public';
}
