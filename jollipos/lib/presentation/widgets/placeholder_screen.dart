import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// Temporary scaffold used by screens that are fully implemented in later
/// build steps. Keeps the app runnable end-to-end from Step 1.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.icon,
    this.note,
    super.key,
  });

  final String title;
  final IconData icon;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${AppConstants.appName} · $title')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (note != null) ...[
              const SizedBox(height: 8),
              Text(note!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
