import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/widgets/base_scaffold.dart';
import 'package:quevault_app/models/credential.dart';
import 'package:quevault_app/models/vault.dart';
import 'package:quevault_app/services/vault_service.dart';
import 'package:quevault_app/services/credential_service.dart';
import 'package:quevault_app/views/vault/edit_credential_screen.dart';

class CredentialDetailsScreen extends ConsumerStatefulWidget {
  final Credential credential;

  const CredentialDetailsScreen({super.key, required this.credential});

  @override
  ConsumerState<CredentialDetailsScreen> createState() => _CredentialDetailsScreenState();
}

class _CredentialDetailsScreenState extends ConsumerState<CredentialDetailsScreen> {
  Vault? _vault;
  bool _isPasswordVisible = false;
  bool _isLoadingVault = true;

  @override
  void initState() {
    super.initState();
    _loadVault();
  }

  Future<void> _loadVault() async {
    try {
      final vault = await VaultService.instance.getVaultById(widget.credential.vaultId);
      setState(() {
        _vault = vault;
        _isLoadingVault = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVault = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Credential'),
        content: Text('Are you sure you want to delete "${widget.credential.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ShadButton.destructive(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await CredentialService.instance.deleteCredential(widget.credential.id);
                if (mounted) {
                  Navigator.of(context).pop(true); // Return true to indicate deletion
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting credential: $e')));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Credential Details',
      automaticallyImplyLeading: true,
      actions: [
        IconButton(
          onPressed: () async {
            final result = await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => EditCredentialScreen(credential: widget.credential)));
            if (result == true) {
              Navigator.of(context).pop(true); // Return true to indicate update
            }
          },
          icon: const Icon(Icons.edit),
          tooltip: 'Edit Credential',
        ),
        IconButton(onPressed: _showDeleteConfirmation, icon: const Icon(Icons.delete), tooltip: 'Delete Credential'),
      ],
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.credential.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              if (_isLoadingVault)
                                const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              else if (_vault != null)
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(color: Color(_vault!.color), shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _vault!.name,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text(
                              'Created ${_formatDate(widget.credential.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.update, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text(
                              'Updated ${_formatDate(widget.credential.updatedAt)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalSpacingLG,

            // Credentials Section
            Text('Credentials', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.verticalSpacingMD,

            // Username Card
            _buildInfoCard(
              title: 'Username',
              value: widget.credential.username,
              icon: Icons.person,
              onCopy: () => _copyToClipboard(widget.credential.username),
            ),
            AppSpacing.verticalSpacingSM,

            // Password Card
            _buildPasswordCard(),
            AppSpacing.verticalSpacingLG,

            // Additional Information Section
            if (widget.credential.website != null || widget.credential.notes != null) ...[
              Text('Additional Information', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              AppSpacing.verticalSpacingMD,

              if (widget.credential.website != null) ...[
                _buildInfoCard(
                  title: 'Website',
                  value: widget.credential.website!,
                  icon: Icons.language,
                  onCopy: () => _copyToClipboard(widget.credential.website!),
                  isUrl: true,
                ),
                AppSpacing.verticalSpacingSM,
              ],

              if (widget.credential.notes != null) ...[
                _buildInfoCard(
                  title: 'Notes',
                  value: widget.credential.notes!,
                  icon: Icons.note,
                  onCopy: () => _copyToClipboard(widget.credential.notes!),
                  isMultiline: true,
                ),
                AppSpacing.verticalSpacingSM,
              ],
              AppSpacing.verticalSpacingLG,
            ],

            // Custom Fields Section
            if (widget.credential.customFields.isNotEmpty) ...[
              Text('Custom Fields', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              AppSpacing.verticalSpacingMD,

              ...widget.credential.customFields.map(
                (field) => _buildInfoCard(title: field.name, value: field.value, icon: Icons.key, onCopy: () => _copyToClipboard(field.value)),
              ),
              AppSpacing.verticalSpacingLG,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onCopy,
    bool isUrl = false,
    bool isMultiline = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                IconButton(onPressed: onCopy, icon: const Icon(Icons.copy, size: 18), tooltip: 'Copy $title'),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
              child: isUrl
                  ? InkWell(
                      onTap: () => _launchUrl(value),
                      child: Text(
                        value,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
                      ),
                    )
                  : Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: isMultiline ? null : 'monospace')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Password', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, size: 18),
                  tooltip: _isPasswordVisible ? 'Hide Password' : 'Show Password',
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(widget.credential.password),
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy Password',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
              child: Text(
                _isPasswordVisible ? widget.credential.password : '••••••••••••••••',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace', letterSpacing: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _launchUrl(String url) {
    // TODO: Implement URL launching
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening $url')));
  }
}
