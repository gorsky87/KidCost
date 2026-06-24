import 'package:flutter/material.dart';
import 'package:kidcost_mobile/src/app.dart';
import 'package:kidcost_mobile/src/config/app_config.dart';
import 'package:kidcost_mobile/src/features/auth/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  final authRepository = await _buildAuthRepository(config);

  runApp(KidCostApp(authRepository: authRepository, config: config));
}

Future<AuthRepository> _buildAuthRepository(AppConfig config) async {
  if (!config.hasSupabaseConfig) {
    return InMemoryAuthRepository();
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
  );
  return SupabaseAuthRepository(Supabase.instance.client);
}
