import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/widgets/base_scaffold.dart';
import 'package:quevault_app/widgets/credential_list_widget.dart';
import 'package:quevault_app/views/vault/create_vault_screen.dart';
import 'package:quevault_app/views/vault/create_credential_screen.dart';
import 'package:quevault_app/views/vault/edit_credential_screen.dart';
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
        Expanded(
          child: CredentialListWidget(
            credentials: credentialsState.allCredentials,
            filteredCredentials: credentialsState.filteredCredentials,
            isLoading: credentialsState.isLoading,
            searchQuery: credentialsState.searchQuery,
            vaultNames: Map.fromEntries(credentialsState.availableVaults.map((vault) => MapEntry(vault.id, vault.name))),
            vaultColors: Map.fromEntries(credentialsState.availableVaults.map((vault) => MapEntry(vault.id, vault.color.toString()))),
            onRefresh: () => ref.read(credentialsViewModelProvider.notifier).refresh(),
            onAddCredential: () async {
              final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateCredentialScreen()));
              if (result == true) {
                ref.read(credentialsViewModelProvider.notifier).loadCredentials();
              }
            },
            onShowCredentialDetails: _showCredentialDetails,
            onEditCredential: (credential) async {
              final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditCredentialScreen(credential: credential)));
              if (result == true) {
                ref.read(credentialsViewModelProvider.notifier).loadCredentials();
              }
            },
            onDeleteCredential: (credential) {
              ref.read(credentialsViewModelProvider.notifier).deleteCredential(credential.id);
            },
            onSearch: _onSearch,
          ),
        ),
      ],
    );
  }
}
