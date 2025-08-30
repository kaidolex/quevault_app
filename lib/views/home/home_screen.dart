import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/widgets/base_scaffold.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'QueVault',
      onSearch: (query) {
        // TODO: Implement search functionality for passwords
        if (query.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Searching for: $query')));
        }
      },
      floatingActionButton: Stack(
        children: [
          // Password button
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _isExpanded ? 140.0 : 16.0,
            right: 16.0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isExpanded ? 1.0 : 0.0,
              child: FloatingActionButton.small(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add password coming soon!')));
                },
                heroTag: 'password',
                child: const Icon(Icons.lock),
              ),
            ),
          ),
          // Note button
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _isExpanded ? 80.0 : 16.0,
            right: 16.0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isExpanded ? 1.0 : 0.0,
              child: FloatingActionButton.small(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add note coming soon!')));
                },
                heroTag: 'note',
                child: const Icon(Icons.note),
              ),
            ),
          ),
          // Card button
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _isExpanded ? 20.0 : 16.0,
            right: 16.0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isExpanded ? 1.0 : 0.0,
              child: FloatingActionButton.small(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add card coming soon!')));
                },
                heroTag: 'card',
                child: const Icon(Icons.credit_card),
              ),
            ),
          ),
          // Main FAB
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: _toggleExpanded,
              child: AnimatedRotation(turns: _isExpanded ? 0.125 : 0.0, duration: const Duration(milliseconds: 300), child: const Icon(Icons.add)),
            ),
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
