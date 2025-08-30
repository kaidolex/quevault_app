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
      actions: [
        ShadButton(
          onPressed: _isLoading ? null : _saveVault,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.paddingLG,
          children: [
            // Vault Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Vault Name', hintText: 'Enter vault name', border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vault name is required';
                }
                return null;
              },
            ),
            AppSpacing.verticalSpacingMD,

            // Color Selection
            Text('Color', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            AppSpacing.verticalSpacingSM,
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
            AppSpacing.verticalSpacingLG,

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter vault description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            AppSpacing.verticalSpacingLG,

            // Checkboxes
            CheckboxListTile(
              value: _isHidden,
              onChanged: (value) => setState(() => _isHidden = value ?? false),
              title: const Text('Is Hidden'),
              contentPadding: EdgeInsets.zero,
            ),

            CheckboxListTile(
              value: _needsUnlock,
              onChanged: (value) => setState(() => _needsUnlock = value ?? false),
              title: const Text('Needs to unlock before can be opened'),
              contentPadding: EdgeInsets.zero,
            ),
            AppSpacing.verticalSpacingLG,

            // Vault Open Options (only show if needsUnlock is true)
            if (_needsUnlock) ...[
              Text('Vault Open Options', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              AppSpacing.verticalSpacingMD,

              CheckboxListTile(
                value: _useMasterKey,
                onChanged: (value) => setState(() => _useMasterKey = value ?? true),
                title: const Text('Use Master Key'),
                contentPadding: EdgeInsets.zero,
                enabled: false, // Always checked and cannot be unchecked
              ),

              CheckboxListTile(
                value: _useDifferentUnlockKey,
                onChanged: (value) => setState(() => _useDifferentUnlockKey = value ?? false),
                title: const Text('Use Different Unlock Key'),
                contentPadding: EdgeInsets.zero,
              ),

              // Unlock Key Input (only show if useDifferentUnlockKey is true)
              if (_useDifferentUnlockKey) ...[
                AppSpacing.verticalSpacingSM,
                TextFormField(
                  controller: _unlockKeyController,
                  decoration: const InputDecoration(labelText: 'Unlock Key', hintText: 'Enter custom unlock key', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Unlock key is required';
                    }
                    if (value.length < 6) {
                      return 'Unlock key must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                AppSpacing.verticalSpacingSM,
              ],

              // Fingerprint option (only show if available)
              if (_isFingerprintAvailable) ...[
                CheckboxListTile(
                  value: _useFingerprint,
                  onChanged: (value) => setState(() => _useFingerprint = value ?? false),
                  title: const Text('Use Fingerprint'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
