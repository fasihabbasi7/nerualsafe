import 'package:flutter/material.dart';

import 'app_shell.dart';

/// Kept so existing references still work. The real home of the app is now
/// [AppShell] (bottom navigation with Status, Message, Voice and You).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const AppShell();
}
