import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/shell/kidcost_shell.dart';
import 'theme/kidcost_theme.dart';

class KidCostApp extends StatefulWidget {
  const KidCostApp({super.key});

  @override
  State<KidCostApp> createState() => _KidCostAppState();
}

class _KidCostAppState extends State<KidCostApp> {
  bool _isSignedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KidCost',
      debugShowCheckedModeBanner: false,
      theme: KidCostTheme.light(),
      home: _isSignedIn
          ? KidCostShell(onSignOut: () => setState(() => _isSignedIn = false))
          : SignInScreen(
              config: AppConfig.fromEnvironment(),
              onDemoSignIn: () => setState(() => _isSignedIn = true),
            ),
    );
  }
}
