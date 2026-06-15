import 'package:flutter/material.dart';

import '../../widgets/placeholder_screen.dart';

/// Replaced in Step 6 with the live Kitchen Display order queue.
class KdsScreen extends StatelessWidget {
  const KdsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Kitchen Display',
        icon: Icons.kitchen,
        note: 'Live order queue (Pending → Ready) — built in Step 6.',
      );
}
