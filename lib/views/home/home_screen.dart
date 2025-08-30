import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/widgets/base_scaffold.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseScaffold(
      title: 'QueVault',
      onSearch: (query) {
        // TODO: Implement search functionality for passwords
        if (query.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Searching for: $query')));
        }
      },
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        type: ExpandableFabType.up,
        distance: 70.0,
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.add),
          fabSize: ExpandableFabSize.regular,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: const CircleBorder(),
        ),
        closeButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: const Icon(Icons.close),
          fabSize: ExpandableFabSize.regular,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: const CircleBorder(),
        ),
        children: [
          FloatingActionButton(
            heroTag: 'vault',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add vault coming soon!')));
            },
            child: const Icon(Icons.folder),
          ),
          FloatingActionButton(
            heroTag: 'credentials',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add credentials coming soon!')));
            },
            child: const Icon(Icons.lock),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.paddingLG,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)),
              AppSpacing.verticalSpacingLG,
              Text(
                'Your vault is quite empty',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpacingMD,
              Text(
                'Start by adding your first password to keep it secure and easily accessible.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpacingLG,
              ShadButton(
                onPressed: () {
                  // TODO: Navigate to add password screen
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add password feature coming soon!')));
                },
                child: const Text('+ New'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
