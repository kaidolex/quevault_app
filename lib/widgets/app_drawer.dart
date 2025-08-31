import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:quevault_app/viewmodels/auth_viewmodel.dart';
import 'package:quevault_app/viewmodels/hidden_vault_viewmodel.dart';
import 'package:quevault_app/views/home/home_screen.dart';
import 'package:quevault_app/views/settings/settings_screen.dart';
import 'package:quevault_app/views/vault/vault_screen.dart';
import 'package:quevault_app/views/password_generator/password_generator_screen.dart';
import 'package:quevault_app/services/vault_service.dart';
import 'package:quevault_app/models/vault.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  List<Vault> _vaults = [];
  List<Vault> _hiddenVaults = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVaults();
  }

  Future<void> _loadVaults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final vaults = await VaultService.instance.getVisibleVaults();
      final hiddenVaults = await VaultService.instance.getHiddenVaults();

      setState(() {
        _vaults = vaults;
        _hiddenVaults = hiddenVaults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hiddenVaultState = ref.watch(hiddenVaultViewModelProvider);

    // Refresh vaults when hidden vault state changes
    if (hiddenVaultState.showHiddenVaults && _hiddenVaults.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadVaults();
      });
    }

    return Drawer(
      child: RefreshIndicator(
        onRefresh: _loadVaults,
        child: Column(
          children: [
            // Space for future header
            const SizedBox(height: 80),

            // Main menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.home_rounded,
                    title: 'Home',
                    onTap: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
                    },
                  ),

                  _buildDrawerItem(
                    context: context,
                    icon: Icons.key_rounded,
                    title: 'Password Generator',
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PasswordGeneratorScreen()));
                    },
                  ),

                  // Vaults Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text(
                      'Vaults',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),

                  // Vaults List
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Error loading vaults',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                          ),
                          const SizedBox(height: 8),
                          ShadButton.outline(onPressed: _loadVaults, child: const Text('Retry')),
                        ],
                      ),
                    )
                  else if (_vaults.isEmpty && (!hiddenVaultState.showHiddenVaults || _hiddenVaults.isEmpty))
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No vaults created yet',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    )
                  else ...[
                    // Regular vaults
                    ..._vaults.map((vault) => _buildVaultItem(context, vault)).toList(),

                    // Hidden vaults (when revealed)
                    if (hiddenVaultState.showHiddenVaults && _hiddenVaults.isNotEmpty) ...[
                      const Divider(height: 32),

                      // Hidden Vaults Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                        child: Row(
                          children: [
                            Icon(Icons.visibility_off, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                            const SizedBox(width: 8),
                            Text(
                              'Hidden Vaults',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),

                      ..._hiddenVaults.map((vault) => _buildHiddenVaultItem(context, vault)).toList(),
                    ],
                  ],
                ],
              ),
            ),

            // Settings and Logout at bottom
            const Divider(),
            _buildDrawerItem(
              context: context,
              icon: Icons.settings_rounded,
              title: 'Settings',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.logout_rounded,
              title: 'Logout',
              onTap: () {
                _showLogoutDialog(context, ref);
              },
            ),
            const SizedBox(height: 16), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({required BuildContext context, required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildVaultItem(BuildContext context, Vault vault) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Color(vault.color), borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.folder, color: Colors.white, size: 20),
      ),
      title: Text(
        vault.name,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
      ),
      subtitle: vault.description.isNotEmpty
          ? Text(
              vault.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: vault.needsUnlock ? Icon(Icons.lock, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)) : null,
      onTap: () async {
        final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => VaultScreen(vault: vault)));
        // Refresh the vault list if we returned from a vault screen (indicating possible changes)
        if (result == true) {
          _loadVaults();
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }

  Widget _buildHiddenVaultItem(BuildContext context, Vault vault) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Color(vault.color).withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.folder, color: Colors.white, size: 20),
      ),
      title: Text(
        vault.name,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
      ),
      subtitle: vault.description.isNotEmpty
          ? Text(
              vault.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (vault.needsUnlock) Icon(Icons.lock, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Icon(Icons.visibility_off, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        ],
      ),
      onTap: () async {
        final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => VaultScreen(vault: vault)));
        // Refresh the vault list if we returned from a vault screen (indicating possible changes)
        if (result == true) {
          _loadVaults();
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ShadButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authViewModelProvider.notifier).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
