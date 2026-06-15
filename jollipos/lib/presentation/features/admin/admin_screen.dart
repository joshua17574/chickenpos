import 'package:flutter/material.dart';

import '../../widgets/placeholder_screen.dart';

/// Replaced in Step 7 with PIN-protected admin + sales reports.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Admin',
        icon: Icons.admin_panel_settings,
        note: 'Menu/price/tax management + reports — built in Step 7.',
      );
}
