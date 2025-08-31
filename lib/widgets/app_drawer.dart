import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:quevault_app/viewmodels/auth_viewmodel.dart';
import 'package:quevault_app/views/home/home_screen.dart';
import 'package:quevault_app/views/settings/settings_screen.dart';
import 'package:quevault_app/views/vault/vault_screen.dart';
import 'package:quevault_app/services/vault_service.dart';
import 'package:quevault_app/models/vault.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
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
                FutureBuilder<List<Vault>>(
                  future: VaultService.instance.getVisibleVaults(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading vaults',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                        ),
                      );
                    }

                    final vaults = snapshot.data ?? [];

                    if (vaults.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No vaults created yet',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                      );
                    }

                    return Column(children: vaults.map((vault) => _buildVaultItem(context, vault)).toList());
                  },
                ),
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
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => VaultScreen(vault: vault)));
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
