import 'package:flutter/material.dart';

import '../../widgets/placeholder_screen.dart';

/// Replaced in Step 7 with cashier login + shift open/close.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Cashier Login',
        icon: Icons.lock_outline,
        note: 'PIN login + shift management — built in Step 7.',
      );
}
