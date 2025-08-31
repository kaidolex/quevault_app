import 'dart:math';
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
  bool _useSmallLetters = true;
  bool _useBigLetters = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  double _passwordLength = 16.0;

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
    final random = Random.secure();

    // Build character pool based on selected options
    String charPool = '';
    if (_useSmallLetters) charPool += 'abcdefghijklmnopqrstuvwxyz';
    if (_useBigLetters) charPool += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_useNumbers) charPool += '0123456789';
    if (_useSymbols) charPool += '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    // Ensure at least one character type is selected
    if (charPool.isEmpty) {
      charPool = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';
    }

    // Start with at least one character from each selected type
    String finalPassword = '';
    if (_useSmallLetters) {
      finalPassword += 'abcdefghijklmnopqrstuvwxyz'[random.nextInt(26)];
    }
    if (_useBigLetters) {
      finalPassword += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[random.nextInt(26)];
    }
    if (_useNumbers) {
      finalPassword += '0123456789'[random.nextInt(10)];
    }
    if (_useSymbols) {
      finalPassword += '!@#\$%^&*()_+-=[]{}|;:,.<>?'[random.nextInt(32)];
    }

    // Fill the rest with random characters from the pool
    while (finalPassword.length < _passwordLength.toInt()) {
      finalPassword += charPool[random.nextInt(charPool.length)];
    }

    // Shuffle the password
    final passwordList = finalPassword.split('');
    passwordList.shuffle(random);
    finalPassword = passwordList.join();

    setState(() {
      _passwordController.text = finalPassword;
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
            // Basic Information Section
            Text('Basic Information', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.verticalSpacingMD,

            // Name Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.label, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('Name *', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ShadInput(controller: _nameController, placeholder: Text('e.g., Gmail Account')),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalSpacingSM,

            // Vault Selection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('Vault *', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                  ],
                ),
              ),
            ),
            AppSpacing.verticalSpacingLG,

            // Credentials Section
            Text('Credentials', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.verticalSpacingMD,

            // Username Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('Username', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ShadInput(controller: _usernameController, placeholder: Text('Enter username or email')),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalSpacingSM,

            // Password Card
            Card(
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
                          onPressed: () => _copyToClipboard(_passwordController.text),
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy Password',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ShadInput(controller: _passwordController, placeholder: Text('Enter password'), obscureText: !_isPasswordVisible),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                          tooltip: _isPasswordVisible ? 'Hide Password' : 'Show Password',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Password Length Slider
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password Length: ${_passwordLength.toInt()}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              Slider(
                                value: _passwordLength,
                                min: 8.0,
                                max: 50.0,
                                divisions: 42,
                                onChanged: (value) => setState(() => _passwordLength = value),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Checkboxes
                    CheckboxListTile(
                      value: _useSmallLetters,
                      onChanged: (value) => setState(() => _useSmallLetters = value ?? true),
                      title: const Text('Use small letters'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: _useBigLetters,
                      onChanged: (value) => setState(() => _useBigLetters = value ?? true),
                      title: const Text('Use big letters'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: _useNumbers,
                      onChanged: (value) => setState(() => _useNumbers = value ?? true),
                      title: const Text('Use numbers'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: _useSymbols,
                      onChanged: (value) => setState(() => _useSymbols = value ?? true),
                      title: const Text('Use symbols'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    const SizedBox(height: 12),

                    // Generate Password Button
                    SizedBox(
                      width: double.infinity,
                      child: ShadButton(onPressed: _generatePassword, child: const Text('Generate Password')),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalSpacingLG,

            // Additional Information Section
            Text('Additional Information', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.verticalSpacingMD,

            // Website Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('Website', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ShadInput(controller: _websiteController, placeholder: Text('https://example.com')),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalSpacingSM,

            // Notes Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('Notes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ShadInput(controller: _notesController, placeholder: Text('Additional notes...'), maxLines: 3),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalSpacingLG,

            // Custom Fields Section
            if (_customFields.isNotEmpty) ...[
              Text('Custom Fields', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              AppSpacing.verticalSpacingMD,

              ..._customFields.map(
                (field) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.key, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(field.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ),
                            IconButton(
                              onPressed: () => _removeCustomField(field.id),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Remove Field',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                                ),
                                child: Text(field.value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(onPressed: () => _copyToClipboard(field.value), icon: const Icon(Icons.copy), tooltip: 'Copy Value'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
