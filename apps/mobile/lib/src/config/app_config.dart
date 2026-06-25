class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.releaseChannel,
    required this.buildName,
    required this.buildNumber,
    required this.analyticsEnabled,
    required this.crashReportingEnabled,
    required this.firebaseConfigured,
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
      firebaseConfigured: bool.fromEnvironment('KIDCOST_FIREBASE_CONFIGURED'),
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String releaseChannel;
  final String buildName;
  final String buildNumber;
  final bool analyticsEnabled;
  final bool crashReportingEnabled;
  final bool firebaseConfigured;

  bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  bool get isBetaLike => releaseChannel == 'beta' || releaseChannel == 'public';

  bool get wantsObservability => analyticsEnabled || crashReportingEnabled;

  bool get hasCompleteObservabilityFlags =>
      analyticsEnabled && crashReportingEnabled;

  bool get canUseConfiguredObservability =>
      isBetaLike &&
      hasSupabaseConfig &&
      firebaseConfigured &&
      hasCompleteObservabilityFlags;

  List<String> get betaObservabilityBlockers {
    if (!wantsObservability) {
      return const [];
    }

    final blockers = <String>[];
    if (!isBetaLike) {
      blockers.add('release_channel_must_be_beta_or_public');
    }
    if (!hasSupabaseConfig) {
      blockers.add('supabase_config_required');
    }
    if (!firebaseConfigured) {
      blockers.add('firebase_config_required');
    }
    if (!analyticsEnabled) {
      blockers.add('analytics_flag_required');
    }
    if (!crashReportingEnabled) {
      blockers.add('crash_reporting_flag_required');
    }
    return List.unmodifiable(blockers);
  }
}
