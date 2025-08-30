import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/widgets/base_scaffold.dart';
import 'package:quevault_app/views/vault/create_vault_screen.dart';
import 'package:quevault_app/views/vault/create_credential_screen.dart';
import 'package:quevault_app/viewmodels/credentials_viewmodel.dart';
import 'package:quevault_app/models/credential.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Load credentials when the screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(credentialsViewModelProvider.notifier).loadCredentials();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync search controller with state
    final credentialsState = ref.read(credentialsViewModelProvider);
    if (_searchController.text != credentialsState.searchQuery) {
      _searchController.text = credentialsState.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(credentialsViewModelProvider.notifier).searchCredentials(query);
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  void _showCredentialDetails(Credential credential) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(credential.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Username', credential.username),
              _buildDetailRow('Password', credential.password, isPassword: true),
              if (credential.website != null) _buildDetailRow('Website', credential.website!),
              if (credential.notes != null) _buildDetailRow('Notes', credential.notes!),
              if (credential.customFields.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Custom Fields:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...credential.customFields.map((field) => _buildDetailRow(field.name, field.value)),
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(isPassword ? '••••••••' : value, style: TextStyle(fontFamily: isPassword ? 'monospace' : null)),
                ),
                IconButton(onPressed: () => _copyToClipboard(value), icon: const Icon(Icons.copy, size: 16), tooltip: 'Copy $label'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credentialsState = ref.watch(credentialsViewModelProvider);

    return BaseScaffold(
      title: 'QueVault',
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
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateVaultScreen()));
            },
            child: const Icon(Icons.folder),
          ),
          FloatingActionButton(
            heroTag: 'credentials',
            onPressed: () async {
              final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateCredentialScreen()));
              if (result == true) {
                // Refresh the credentials list if a new credential was created
                ref.read(credentialsViewModelProvider.notifier).loadCredentials();
              }
            },
            child: const Icon(Icons.lock),
          ),
        ],
      ),
      body: _buildBody(credentialsState),
    );
  }

  Widget _buildBody(CredentialsState credentialsState) {
    if (credentialsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (credentialsState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            AppSpacing.verticalSpacingMD,
            Text('Error loading credentials', style: Theme.of(context).textTheme.titleLarge),
            AppSpacing.verticalSpacingSM,
            Text(credentialsState.errorMessage!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            AppSpacing.verticalSpacingMD,
            ElevatedButton(
              onPressed: () {
                ref.read(credentialsViewModelProvider.notifier).loadCredentials();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Always show search field and list area
    return Column(
      children: [
        // Search field
        Padding(
          padding: AppSpacing.paddingLG,
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search passwords...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
        // Credentials list area
        Expanded(child: _buildCredentialsList(credentialsState)),
      ],
    );
  }

  Widget _buildCredentialsList(CredentialsState credentialsState) {
    // Show empty state only when there are no credentials at all (not when filtering)
    if (credentialsState.allCredentials.isEmpty) {
      return Center(
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
                onPressed: () async {
                  final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateCredentialScreen()));
                  if (result == true) {
                    // Refresh the credentials list if a new credential was created
                    ref.read(credentialsViewModelProvider.notifier).loadCredentials();
                  }
                },
                child: const Text('+ New'),
              ),
            ],
          ),
        ),
      );
    }

    // Show no search results message when filtering but no results found
    if (credentialsState.searchQuery.isNotEmpty && credentialsState.filteredCredentials.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingLG,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 80, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)),
              AppSpacing.verticalSpacingLG,
              Text(
                'No credentials found for "${credentialsState.searchQuery}"',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpacingMD,
              Text(
                'Try adjusting your search terms or check for typos.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show the credentials list
    return RefreshIndicator(
      onRefresh: () => ref.read(credentialsViewModelProvider.notifier).refresh(),
      child: ListView.builder(
        padding: EdgeInsets.only(left: AppSpacing.paddingLG.left, right: AppSpacing.paddingLG.right, bottom: AppSpacing.paddingLG.bottom),
        itemCount: credentialsState.filteredCredentials.length,
        itemBuilder: (context, index) {
          final credential = credentialsState.filteredCredentials[index];
          final vaultName = ref.read(credentialsViewModelProvider.notifier).getVaultName(credential.vaultId);
          final vaultColor = ref.read(credentialsViewModelProvider.notifier).getVaultColor(credential.vaultId);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(vaultColor),
                child: Text(
                  credential.name.isNotEmpty ? credential.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(credential.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(credential.username),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: Color(vaultColor), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(vaultName, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _showCredentialDetails(credential);
                      break;
                    case 'copy_username':
                      _copyToClipboard(credential.username);
                      break;
                    case 'copy_password':
                      _copyToClipboard(credential.password);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(credential);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(children: [Icon(Icons.visibility), SizedBox(width: 8), Text('View Details')]),
                  ),
                  const PopupMenuItem(
                    value: 'copy_username',
                    child: Row(children: [Icon(Icons.copy), SizedBox(width: 8), Text('Copy Username')]),
                  ),
                  const PopupMenuItem(
                    value: 'copy_password',
                    child: Row(children: [Icon(Icons.lock), SizedBox(width: 8), Text('Copy Password')]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => _showCredentialDetails(credential),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(Credential credential) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Credential'),
        content: Text('Are you sure you want to delete "${credential.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(credentialsViewModelProvider.notifier).deleteCredential(credential.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
