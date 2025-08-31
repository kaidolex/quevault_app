import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:quevault_app/widgets/app_drawer.dart';
import 'package:quevault_app/viewmodels/hidden_vault_viewmodel.dart';

class BaseScaffold extends ConsumerStatefulWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final Widget? drawer;

  const BaseScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.centerTitle = true,
    this.automaticallyImplyLeading = false,
    this.drawer,
  });

  @override
  ConsumerState<BaseScaffold> createState() => _BaseScaffoldState();
}

class _BaseScaffoldState extends ConsumerState<BaseScaffold> {
  @override
  Widget build(BuildContext context) {
    final hiddenVaultState = ref.watch(hiddenVaultViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            final currentState = ref.read(hiddenVaultViewModelProvider);
            ref.read(hiddenVaultViewModelProvider.notifier).handleTitleTap();

            // Show feedback when hidden vaults are revealed
            if (!currentState.showHiddenVaults && currentState.tapCount == 9) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Hidden vaults are now available!'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          child: Text(widget.title),
        ),
        centerTitle: widget.centerTitle,
        actions: widget.actions,
        automaticallyImplyLeading: widget.automaticallyImplyLeading,
        leading: widget.automaticallyImplyLeading
            ? null
            : Builder(
                builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
              ),
      ),
      drawer: widget.drawer ?? (widget.automaticallyImplyLeading ? null : const AppDrawer()),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }
}
