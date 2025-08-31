import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/widgets/base_scaffold.dart';
import 'package:quevault_app/services/vault_service.dart';
import 'package:quevault_app/models/vault.dart';

class CreateVaultScreen extends ConsumerStatefulWidget {
  const CreateVaultScreen({super.key});

  @override
  ConsumerState<CreateVaultScreen> createState() => _CreateVaultScreenState();
}

class _CreateVaultScreenState extends ConsumerState<CreateVaultScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unlockKeyController = TextEditingController();

  Color _selectedColor = Colors.blue;
  bool _isHidden = false;
  bool _needsUnlock = false;
  bool _useMasterKey = true;
  bool _useDifferentUnlockKey = false;
  bool _useFingerprint = false;
  bool _isFingerprintAvailable = false;
  bool _isLoading = false;

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _checkFingerprintAvailability();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _unlockKeyController.dispose();
    super.dispose();
  }

  Future<void> _checkFingerprintAvailability() async {
    // TODO: Implement fingerprint availability check
    setState(() {
      _isFingerprintAvailable = true; // Placeholder
    });
  }

  Future<void> _saveVault() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final vault = Vault(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _selectedColor.value,
        isHidden: _isHidden,
        needsUnlock: _needsUnlock,
        useMasterKey: _useMasterKey,
        useDifferentUnlockKey: _useDifferentUnlockKey,
        unlockKey: _useDifferentUnlockKey ? _unlockKeyController.text.trim() : null,
        useFingerprint: _useFingerprint && _isFingerprintAvailable,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await VaultService.instance.createVault(vault);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vault created successfully!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating vault: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Create Vault',
      automaticallyImplyLeading: true,
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _saveVault,
          icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
          tooltip: 'Save Vault',
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
                        Icon(Icons.folder, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('Vault Name *', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ShadInput(controller: _nameController, placeholder: Text('Enter vault name')),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalSpacingSM,

            // Description Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('Description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ShadInput(controller: _descriptionController, placeholder: Text('Enter vault description (optional)'), maxLines: 3),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalSpacingSM,

            // Color Selection Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('Color', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: _colorOptions.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 3),
                            ),
                            child: isSelected ? Icon(Icons.check, color: Colors.white, size: 24) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalSpacingLG,

            // Security Settings Section
            Text('Security Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            AppSpacing.verticalSpacingMD,

            // Security Options Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      value: _isHidden,
                      onChanged: (value) => setState(() => _isHidden = value ?? false),
                      title: const Text('Is Hidden'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: _needsUnlock,
                      onChanged: (value) => setState(() => _needsUnlock = value ?? false),
                      title: const Text('Needs to unlock before can be opened'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalSpacingLG,

            // Vault Open Options (only show if needsUnlock is true)
            if (_needsUnlock) ...[
              Text('Vault Open Options', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              AppSpacing.verticalSpacingMD,

              // Unlock Options Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        value: _useMasterKey,
                        onChanged: (value) => setState(() => _useMasterKey = value ?? true),
                        title: const Text('Use Master Key'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        enabled: false, // Always checked and cannot be unchecked
                      ),
                      CheckboxListTile(
                        value: _useDifferentUnlockKey,
                        onChanged: (value) => setState(() => _useDifferentUnlockKey = value ?? false),
                        title: const Text('Use Different Unlock Key'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),

                      // Unlock Key Input (only show if useDifferentUnlockKey is true)
                      if (_useDifferentUnlockKey) ...[
                        const SizedBox(height: 16),
                        ShadInput(controller: _unlockKeyController, placeholder: Text('Enter custom unlock key'), obscureText: true),
                      ],

                      // Fingerprint option (only show if available)
                      if (_isFingerprintAvailable) ...[
                        CheckboxListTile(
                          value: _useFingerprint,
                          onChanged: (value) => setState(() => _useFingerprint = value ?? false),
                          title: const Text('Use Fingerprint'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              AppSpacing.verticalSpacingLG,
            ],
          ],
        ),
      ),
    );
  }
}
