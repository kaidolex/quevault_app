import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/models/credential.dart';

class CredentialListWidget extends StatelessWidget {
  final List<Credential> credentials;
  final List<Credential> filteredCredentials;
  final bool isLoading;
  final String searchQuery;
  final String? vaultColor;
  final String? vaultName;
  final Map<String, String>? vaultNames;
  final Map<String, String>? vaultColors;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onAddCredential;
  final Function(Credential) onShowCredentialDetails;
  final Function(Credential) onDeleteCredential;
  final Function(String) onSearch;

  const CredentialListWidget({
    super.key,
    required this.credentials,
    required this.filteredCredentials,
    required this.isLoading,
    required this.searchQuery,
    this.vaultColor,
    this.vaultName,
    this.vaultNames,
    this.vaultColors,
    this.onRefresh,
    this.onAddCredential,
    required this.onShowCredentialDetails,
    required this.onDeleteCredential,
    required this.onSearch,
  });

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  void _showDeleteConfirmation(BuildContext context, Credential credential) {
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
              onDeleteCredential(credential);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show empty state only when there are no credentials at all (not when filtering)
    if (credentials.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingLG,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: vaultColor != null
                    ? Color(int.parse(vaultColor!)).withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              ),
              AppSpacing.verticalSpacingLG,
              Text(
                vaultName != null ? 'This vault is empty' : 'Your vault is quite empty',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpacingMD,
              Text(
                vaultName != null
                    ? 'Start by adding your first credential to this vault.'
                    : 'Start by adding your first password to keep it secure and easily accessible.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpacingLG,
              if (onAddCredential != null) ShadButton(onPressed: onAddCredential, child: Text(vaultName != null ? '+ Add Credential' : '+ New')),
            ],
          ),
        ),
      );
    }

    // Show no search results message when filtering but no results found
    if (searchQuery.isNotEmpty && filteredCredentials.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.paddingLG,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: vaultColor != null
                    ? Color(int.parse(vaultColor!)).withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              ),
              AppSpacing.verticalSpacingLG,
              Text(
                'No credentials found for "$searchQuery"',
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
      onRefresh: onRefresh ?? () async => Future.value(),
      child: ListView.builder(
        padding: EdgeInsets.only(left: AppSpacing.paddingLG.left, right: AppSpacing.paddingLG.right, bottom: AppSpacing.paddingLG.bottom),
        itemCount: filteredCredentials.length,
        itemBuilder: (context, index) {
          final credential = filteredCredentials[index];
          final credentialColor = vaultColor != null
              ? Color(int.parse(vaultColor!))
              : vaultColors != null && vaultColors!.containsKey(credential.vaultId)
              ? Color(int.parse(vaultColors![credential.vaultId]!))
              : Theme.of(context).colorScheme.primary;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: credentialColor,
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
                  if (vaultName != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: credentialColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(vaultName!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  ] else if (vaultNames != null && vaultNames!.containsKey(credential.vaultId)) ...[
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: credentialColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vaultNames![credential.vaultId]!,
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ] else if (credential.website != null) ...[
                    Text(credential.website!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                  ],
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      onShowCredentialDetails(credential);
                      break;
                    case 'copy_username':
                      _copyToClipboard(context, credential.username);
                      break;
                    case 'copy_password':
                      _copyToClipboard(context, credential.password);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(context, credential);
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
              onTap: () => onShowCredentialDetails(credential),
            ),
          );
        },
      ),
    );
  }
}
