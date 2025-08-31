import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/widgets/base_scaffold.dart';
import 'package:quevault_app/widgets/credential_list_widget.dart';
import 'package:quevault_app/models/vault.dart';
import 'package:quevault_app/models/credential.dart';
import 'package:quevault_app/models/auth_models.dart';
import 'package:quevault_app/services/credential_service.dart';
import 'package:quevault_app/services/biometric_service.dart';
import 'package:quevault_app/repositories/auth_repository.dart';
import 'package:quevault_app/views/vault/create_credential_screen.dart';
import 'package:quevault_app/views/vault/edit_credential_screen.dart';

class VaultScreen extends ConsumerStatefulWidget {
  final Vault vault;

  const VaultScreen({super.key, required this.vault});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _unlockController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _unlockFocusNode = FocusNode();

  bool _isUnlocked = false;
  bool _isUnlocking = false;
  bool _isPasswordVisible = false;
  String? _unlockError;
  List<Credential> _credentials = [];
  List<Credential> _filteredCredentials = [];
  bool _isLoadingCredentials = false;

  @override
  void initState() {
    super.initState();
    // Check if vault needs unlock
    if (!widget.vault.needsUnlock) {
      _isUnlocked = true;
      _loadCredentials();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _unlockController.dispose();
    _searchFocusNode.dispose();
    _unlockFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    if (!_isUnlocked) return;

    setState(() {
      _isLoadingCredentials = true;
    });

    try {
      final credentials = await CredentialService.instance.getCredentialsByVaultId(widget.vault.id);
      setState(() {
        _credentials = credentials;
        _filteredCredentials = credentials;
        _isLoadingCredentials = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCredentials = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading credentials: $e')));
    }
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCredentials = _credentials;
      });
      return;
    }

    final searchResults = _credentials.where((credential) {
      final searchLower = query.toLowerCase();
      return credential.name.toLowerCase().contains(searchLower) ||
          credential.username.toLowerCase().contains(searchLower) ||
          (credential.website?.toLowerCase().contains(searchLower) ?? false);
    }).toList();

    setState(() {
      _filteredCredentials = searchResults;
    });
  }

  Future<void> _unlockVault() async {
    if (_unlockController.text.isEmpty) {
      setState(() {
        _unlockError = 'Please enter a password';
      });
      return;
    }

    setState(() {
      _isUnlocking = true;
      _unlockError = null;
    });

    try {
      bool isUnlocked = false;
      final authRepository = AuthRepository();

      // Try master key if vault uses master key
      if (widget.vault.useMasterKey) {
        final result = await authRepository.login(LoginRequest(password: _unlockController.text));
        if (result.success) {
          isUnlocked = true;
        }
      }

      // Try custom key if vault uses different unlock key
      if (!isUnlocked && widget.vault.useDifferentUnlockKey && widget.vault.unlockKey != null) {
        if (_unlockController.text == widget.vault.unlockKey) {
          isUnlocked = true;
        }
      }

      if (isUnlocked) {
        setState(() {
          _isUnlocked = true;
          _isUnlocking = false;
        });
        _loadCredentials();
      } else {
        setState(() {
          _unlockError = 'Invalid password';
          _isUnlocking = false;
        });
      }
    } catch (e) {
      setState(() {
        _unlockError = 'Error unlocking vault: $e';
        _isUnlocking = false;
      });
    }
  }

  Future<void> _unlockWithFingerprint() async {
    if (!widget.vault.useFingerprint) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fingerprint unlock is not enabled for this vault')));
      return;
    }

    setState(() {
      _isUnlocking = true;
      _unlockError = null;
    });

    try {
      final biometricService = BiometricService();
      final isAvailable = await biometricService.isBiometricAvailable();

      if (!isAvailable) {
        setState(() {
          _unlockError = 'Biometric authentication is not available';
          _isUnlocking = false;
        });
        return;
      }

      final authenticated = await biometricService.authenticateWithBiometrics(localizedReason: 'Unlock ${widget.vault.name} with your fingerprint');

      if (authenticated) {
        setState(() {
          _isUnlocked = true;
          _isUnlocking = false;
        });
        _loadCredentials();
      } else {
        setState(() {
          _unlockError = 'Biometric authentication failed';
          _isUnlocking = false;
        });
      }
    } catch (e) {
      setState(() {
        _unlockError = 'Error with biometric authentication: $e';
        _isUnlocking = false;
      });
    }
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
    return BaseScaffold(
      title: 'QueVault',
      floatingActionButton: _isUnlocked
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateCredentialScreen()));
                if (result == true) {
                  _loadCredentials();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: _isUnlocked ? _buildUnlockedBody() : _buildLockedBody(),
    );
  }

  Widget _buildLockedBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(widget.vault.color).withValues(alpha: 0.1), Theme.of(context).colorScheme.surface],
        ),
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 100,
          ),
          child: Center(
            child: Padding(
              padding: AppSpacing.paddingLG,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Vault Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Color(widget.vault.color),
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [BoxShadow(color: Color(widget.vault.color).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: const Icon(Icons.lock, size: 60, color: Colors.white),
                  ),

                  AppSpacing.verticalSpacingXL,

                  // Vault Name
                  Text(
                    widget.vault.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Color(widget.vault.color)),
                    textAlign: TextAlign.center,
                  ),

                  AppSpacing.verticalSpacingMD,

                  // Vault Description
                  if (widget.vault.description.isNotEmpty)
                    Text(
                      widget.vault.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                    ),

                  AppSpacing.verticalSpacingXL,

                  // Unlock Card
                  ShadCard(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: AppSpacing.paddingLG,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Unlock Vault',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),

                          AppSpacing.verticalSpacingLG,

                          // Password Input
                          TextFormField(
                            controller: _unlockController,
                            focusNode: _unlockFocusNode,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: widget.vault.useMasterKey ? 'Master Password' : 'Vault Password',
                              hintText: widget.vault.useMasterKey ? 'Enter your master password' : 'Enter vault password',
                              prefixIcon: const Icon(Icons.key),
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: const OutlineInputBorder(),
                              errorText: _unlockError,
                            ),
                            onFieldSubmitted: (_) => _unlockVault(),
                          ),

                          AppSpacing.verticalSpacingMD,

                          // Unlock Button
                          ShadButton(
                            onPressed: _isUnlocking ? null : _unlockVault,
                            child: _isUnlocking
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Unlock Vault'),
                          ),

                          // Fingerprint Option
                          if (widget.vault.useFingerprint) ...[
                            AppSpacing.verticalSpacingMD,
                            const Divider(),
                            AppSpacing.verticalSpacingMD,
                            ShadButton.outline(
                              onPressed: _isUnlocking ? null : _unlockWithFingerprint,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Icon(Icons.fingerprint), SizedBox(width: 8), Text('Unlock with Fingerprint')],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockedBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(widget.vault.color).withValues(alpha: 0.05), Theme.of(context).colorScheme.surface],
        ),
      ),
      child: Column(
        children: [
          // Vault Header
          Container(
            padding: AppSpacing.paddingLG,
            child: Column(
              children: [
                // Vault Info
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(color: Color(widget.vault.color), borderRadius: BorderRadius.circular(30)),
                      child: const Icon(Icons.folder, color: Colors.white, size: 30),
                    ),
                    AppSpacing.horizontalSpacingMD,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.vault.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Color(widget.vault.color)),
                          ),
                          if (widget.vault.description.isNotEmpty)
                            Text(
                              widget.vault.description,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                            ),
                          Text(
                            '${_credentials.length} credential${_credentials.length != 1 ? 's' : ''}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                AppSpacing.verticalSpacingLG,

                // Search field
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search credentials...',
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
                      borderSide: BorderSide(color: Color(widget.vault.color).withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(widget.vault.color).withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(widget.vault.color), width: 2),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ],
            ),
          ),

          // Credentials List
          Expanded(
            child: CredentialListWidget(
              credentials: _credentials,
              filteredCredentials: _filteredCredentials,
              isLoading: _isLoadingCredentials,
              searchQuery: _searchController.text,
              vaultColor: widget.vault.color.toString(),
              vaultName: widget.vault.name,
              onRefresh: _loadCredentials,
              onAddCredential: () async {
                final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateCredentialScreen()));
                if (result == true) {
                  _loadCredentials();
                }
              },
              onShowCredentialDetails: _showCredentialDetails,
              onEditCredential: (credential) async {
                final result = await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => EditCredentialScreen(credential: credential)));
                if (result == true) {
                  _loadCredentials();
                }
              },
              onDeleteCredential: (credential) async {
                try {
                  await CredentialService.instance.deleteCredential(credential.id);
                  _loadCredentials();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting credential: $e')));
                }
              },
              onSearch: _onSearch,
            ),
          ),
        ],
      ),
    );
  }
}
