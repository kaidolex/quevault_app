import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/widgets/base_scaffold.dart';

class PasswordGeneratorScreen extends ConsumerStatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  ConsumerState<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends ConsumerState<PasswordGeneratorScreen> {
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _useSmallLetters = true;
  bool _useBigLetters = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  double _passwordLength = 16.0;

  @override
  void initState() {
    super.initState();
    _generatePassword(); // Generate initial password
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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
      finalPassword += 'abcdefghijklmnopqrstuvwxyz'[random.nextInt('abcdefghijklmnopqrstuvwxyz'.length)];
    }
    if (_useBigLetters) {
      finalPassword += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[random.nextInt('ABCDEFGHIJKLMNOPQRSTUVWXYZ'.length)];
    }
    if (_useNumbers) {
      finalPassword += '0123456789'[random.nextInt('0123456789'.length)];
    }
    if (_useSymbols) {
      finalPassword += '!@#\$%^&*()_+-=[]{}|;:,.<>?'[random.nextInt('!@#\$%^&*()_+-=[]{}|;:,.<>?'.length)];
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Password Generator',
      automaticallyImplyLeading: true,
      actions: [IconButton(onPressed: () => _copyToClipboard(_passwordController.text), icon: const Icon(Icons.copy), tooltip: 'Copy Password')],
      body: ListView(
        padding: AppSpacing.paddingLG,
        children: [
          // Generated Password Card
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
                        child: Text('Generated Password', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      IconButton(onPressed: () => _copyToClipboard(_passwordController.text), icon: const Icon(Icons.copy), tooltip: 'Copy Password'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ShadInput(
                          controller: _passwordController,
                          placeholder: Text('Generated password will appear here'),
                          obscureText: !_isPasswordVisible,
                          readOnly: true,
                        ),
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
                ],
              ),
            ),
          ),
          AppSpacing.verticalSpacingLG,

          // Password Options Section
          Text('Password Options', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          AppSpacing.verticalSpacingMD,

          // Password Length Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.straighten, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text('Password Length', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Length: ${_passwordLength.toInt()} characters',
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
                ],
              ),
            ),
          ),
          AppSpacing.verticalSpacingSM,

          // Character Types Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.text_fields, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text('Character Types', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _useSmallLetters,
                    onChanged: (value) => setState(() => _useSmallLetters = value ?? true),
                    title: const Text('Use small letters (a-z)'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    value: _useBigLetters,
                    onChanged: (value) => setState(() => _useBigLetters = value ?? true),
                    title: const Text('Use big letters (A-Z)'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    value: _useNumbers,
                    onChanged: (value) => setState(() => _useNumbers = value ?? true),
                    title: const Text('Use numbers (0-9)'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    value: _useSymbols,
                    onChanged: (value) => setState(() => _useSymbols = value ?? true),
                    title: const Text('Use symbols (!@#\$%^&*)'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.verticalSpacingLG,

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              onPressed: _generatePassword,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(Icons.refresh), SizedBox(width: 8), Text('Generate New Password')],
              ),
            ),
          ),
          AppSpacing.verticalSpacingLG,

          // Password Strength Indicator
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Text('Password Strength', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordStrengthIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      return Text(
        'Generate a password to see strength',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
      );
    }

    // Calculate password strength using entropy and complexity
    int score = 0;
    int entropy = 0;

    // Length contribution (up to 4 points)
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (password.length >= 16) score += 1;
    if (password.length >= 20) score += 1;

    // Character set contribution (up to 4 points)
    bool hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    bool hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    bool hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    bool hasSymbols = RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password);

    if (hasLowercase) score += 1;
    if (hasUppercase) score += 1;
    if (hasNumbers) score += 1;
    if (hasSymbols) score += 1;

    // Calculate entropy (bits of security)
    int charSetSize = 0;
    if (hasLowercase) charSetSize += 26;
    if (hasUppercase) charSetSize += 26;
    if (hasNumbers) charSetSize += 10;
    if (hasSymbols) charSetSize += 32;

    if (charSetSize > 0) {
      entropy = (password.length * (log(charSetSize) / log(2))).round();
    }

    String strengthText;
    Color strengthColor;
    double strengthPercentage;
    String entropyText;

    if (score <= 3 || entropy < 40) {
      strengthText = 'Weak';
      strengthColor = Colors.red;
      strengthPercentage = 0.25;
      entropyText = 'Very low security';
    } else if (score <= 5 || entropy < 60) {
      strengthText = 'Fair';
      strengthColor = Colors.orange;
      strengthPercentage = 0.5;
      entropyText = 'Low security';
    } else if (score <= 7 || entropy < 80) {
      strengthText = 'Good';
      strengthColor = Colors.yellow.shade700;
      strengthPercentage = 0.75;
      entropyText = 'Moderate security';
    } else {
      strengthText = 'Strong';
      strengthColor = Colors.green;
      strengthPercentage = 1.0;
      entropyText = 'High security';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strengthPercentage,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strengthText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: strengthColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Score: $score/8 • Entropy: ${entropy} bits',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          entropyText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: strengthColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        _buildCharacterSetIndicator(hasLowercase, hasUppercase, hasNumbers, hasSymbols),
      ],
    );
  }

  Widget _buildCharacterSetIndicator(bool hasLowercase, bool hasUppercase, bool hasNumbers, bool hasSymbols) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildCharacterSetChip('a-z', hasLowercase),
        _buildCharacterSetChip('A-Z', hasUppercase),
        _buildCharacterSetChip('0-9', hasNumbers),
        _buildCharacterSetChip('!@#', hasSymbols),
      ],
    );
  }

  Widget _buildCharacterSetChip(String label, bool isIncluded) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isIncluded ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isIncluded ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isIncluded ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: isIncluded ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
