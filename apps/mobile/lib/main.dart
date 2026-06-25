import 'package:flutter/material.dart';
import 'package:kidcost_mobile/src/app.dart';
import 'package:kidcost_mobile/src/config/app_config.dart';
import 'package:kidcost_mobile/src/features/auth/auth_repository.dart';
import 'package:kidcost_mobile/src/features/expenses/attachment_storage.dart';
import 'package:kidcost_mobile/src/telemetry/app_telemetry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final dependencies = await _buildAppDependencies(config);

  runApp(
    KidCostApp(
      authRepository: dependencies.authRepository,
      attachmentStorage: dependencies.attachmentStorage,
      telemetry: dependencies.telemetry,
      config: config,
    ),
  );
}

Future<_AppDependencies> _buildAppDependencies(AppConfig config) async {
  if (!config.hasSupabaseConfig) {
    return _AppDependencies(
      authRepository: InMemoryAuthRepository(),
      attachmentStorage: InMemoryAttachmentStorage(),
      telemetry: _buildTelemetry(config),
    );
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
  );
  final client = Supabase.instance.client;
  return _AppDependencies(
    authRepository: SupabaseAuthRepository(client),
    attachmentStorage: SupabaseAttachmentStorage(client),
    telemetry: _buildTelemetry(config),
  );
}

AppTelemetry _buildTelemetry(AppConfig config) {
  if (!config.canUseConfiguredObservability) {
    return const NoopTelemetry();
  }

  return const PrivacySafeTelemetry(NoopTelemetry());
}

class _AppDependencies {
  const _AppDependencies({
    required this.authRepository,
    required this.attachmentStorage,
    required this.telemetry,
  });

  final AuthRepository authRepository;
  final AttachmentStorage attachmentStorage;
  final AppTelemetry telemetry;
}
