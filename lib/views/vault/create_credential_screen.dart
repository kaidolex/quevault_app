import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:random_password_generator/random_password_generator.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/widgets/base_scaffold.dart';
import 'package:quevault_app/models/credential.dart';
import 'package:quevault_app/models/vault.dart';
import 'package:quevault_app/services/credential_service.dart';
import 'package:quevault_app/services/vault_service.dart';

class CreateCredentialScreen extends ConsumerStatefulWidget {
  const CreateCredentialScreen({super.key});

  @override
  ConsumerState<CreateCredentialScreen> createState() => _CreateCredentialScreenState();
}

class _CreateCredentialScreenState extends ConsumerState<CreateCredentialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  List<Vault> _vaults = [];
  Vault? _selectedVault;
  List<CustomField> _customFields = [];
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVaults();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadVaults() async {
    try {
      final vaults = await VaultService.instance.getVisibleVaults();
      setState(() {
        _vaults = vaults;
        // Set Main Vault as default if available
        if (vaults.isNotEmpty) {
          _selectedVault = vaults.firstWhere((vault) => vault.name == 'Main Vault', orElse: () => vaults.first);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load vaults: $e')));
      }
    }
  }

  void _generatePassword() {
    final generator = RandomPasswordGenerator();
    final password = generator.randomPassword(letters: true, numbers: true, passwordLength: 16, specialChar: true);
    setState(() {
      _passwordController.text = password;
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  void _showAddCustomFieldDialog() {
    final fieldNameController = TextEditingController();
    final fieldValueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Field'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: fieldNameController,
              decoration: const InputDecoration(labelText: 'Field Name', hintText: 'e.g., API Key, PIN', border: OutlineInputBorder()),
            ),
            AppSpacing.verticalSpacingMD,
            TextFormField(
              controller: fieldValueController,
              decoration: const InputDecoration(labelText: 'Field Value', hintText: 'Enter the value', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (fieldNameController.text.isNotEmpty) {
                setState(() {
                  _customFields.add(
                    CustomField(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: fieldNameController.text,
                      value: fieldValueController.text,
                    ),
                  );
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeCustomField(String fieldId) {
    setState(() {
      _customFields.removeWhere((field) => field.id == fieldId);
    });
  }

  Future<void> _saveCredential() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVault == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a vault')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = Credential(
        id: 'credential_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        vaultId: _selectedVault!.id,
        username: _usernameController.text,
        password: _passwordController.text,
        website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        customFields: _customFields,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await CredentialService.instance.createCredential(credential);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credential saved successfully')));
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save credential: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Create Credential',
      automaticallyImplyLeading: true,
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _saveCredential,
          icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
          tooltip: 'Save Credential',
        ),
      ],
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingLG,
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g., Gmail Account', border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            AppSpacing.verticalSpacingMD,

            // Vault Selection
            Text('Vault', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            AppSpacing.verticalSpacingSM,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Vault>(
                  value: _selectedVault,
                  hint: const Text('Select a vault'),
                  isExpanded: true,
                  items: _vaults.map((vault) {
                    return DropdownMenuItem<Vault>(
                      value: vault,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(color: Color(vault.color), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(vault.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (vault) {
                    setState(() {
                      _selectedVault = vault;
                    });
                  },
                ),
              ),
            ),
            AppSpacing.verticalSpacingLG,

            // Username
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username', hintText: 'Enter username or email', border: OutlineInputBorder()),
            ),
            AppSpacing.verticalSpacingMD,

            // Password field with generate and copy buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Password', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                AppSpacing.verticalSpacingSM,
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(hintText: 'Enter password', border: OutlineInputBorder()),
                        obscureText: !_isPasswordVisible,
                      ),
                    ),
                    AppSpacing.horizontalSpacingSM,
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    ),
                    IconButton(onPressed: _generatePassword, icon: const Icon(Icons.refresh), tooltip: 'Generate Password'),
                    IconButton(onPressed: () => _copyToClipboard(_passwordController.text), icon: const Icon(Icons.copy), tooltip: 'Copy Password'),
                  ],
                ),
              ],
            ),
            AppSpacing.verticalSpacingLG,

            // Website
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'Website', hintText: 'https://example.com', border: OutlineInputBorder()),
            ),
            AppSpacing.verticalSpacingMD,

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes', hintText: 'Additional notes...', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            AppSpacing.verticalSpacingLG,

            // Custom Fields Section
            if (_customFields.isNotEmpty) ...[
              Text('Custom Fields', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              AppSpacing.verticalSpacingMD,

              ..._customFields
                  .map(
                    (field) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(field.name, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  onPressed: () => _removeCustomField(field.id),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Remove Field',
                                ),
                              ],
                            ),
                            AppSpacing.verticalSpacingSM,
                            Row(
                              children: [
                                Expanded(child: Text(field.value, style: Theme.of(context).textTheme.bodyMedium)),
                                IconButton(onPressed: () => _copyToClipboard(field.value), icon: const Icon(Icons.copy), tooltip: 'Copy Value'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
              AppSpacing.verticalSpacingLG,
            ],

            // Add Custom Field Button
            ShadButton.outline(
              onPressed: _showAddCustomFieldDialog,
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add), SizedBox(width: 8), Text('Add Custom Field')]),
            ),
          ],
        ),
      ),
    );
  }
}
