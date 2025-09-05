# QueVault 🔐

**QueVault** is a secure, offline-first password manager built with Flutter. It provides military-grade encryption, biometric authentication, and comprehensive vault management while keeping all your sensitive data stored locally on your device.

## ✨ Key Features

### 🔒 **Security First**

- **Military-grade encryption** using AES-256 with PBKDF2 key derivation
- **Offline-first architecture** - no cloud dependency, all data stored locally
- **Biometric authentication** support (fingerprint, face ID, iris)
- **Secure SQLite database** with encrypted storage
- **Master password protection** with configurable security policies

### 🏦 **Vault Management**

- **Multiple vaults** with customizable names, descriptions, and colors
- **Hidden vaults** for sensitive credentials
- **Individual vault encryption** with separate unlock keys
- **Vault-specific security settings** (master key, biometric, custom unlock)

### 🔑 **Credential Management**

- **Secure password storage** with individual encryption
- **Built-in password generator** with customizable parameters
- **Custom fields** for additional credential information
- **Website integration** with URL storage
- **Notes and metadata** for each credential
- **Clipboard integration** for easy copying

### 📱 **Cross-Platform**

- **Android** (API 31+)
- **iOS** (11.0+)
- **Windows** (10+)
- **macOS** (10.14+)
- **Linux** (Ubuntu 18.04+)
- **Web** (modern browsers)

### 🔄 **Import/Export**

- **JSON export/import** for data portability
- **Complete vault backup** with all credentials
- **Cross-device migration** support
- **Selective import** with conflict resolution

## 🏗️ Architecture

QueVault follows **Clean Architecture** principles with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  (Views, ViewModels, Widgets)          │
├─────────────────────────────────────────┤
│            Domain Layer                 │
│     (Models, Business Logic)           │
├─────────────────────────────────────────┤
│             Data Layer                  │
│  (Repositories, Services, Database)    │
├─────────────────────────────────────────┤
│             Core Layer                  │
│   (Utilities, Constants, Configs)      │
└─────────────────────────────────────────┘
```

### State Management

- **Riverpod** for reactive state management
- **Hooks Riverpod** for enhanced performance
- **Provider pattern** for dependency injection

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (^3.9.0)
- **Dart SDK** (included with Flutter)
- **IDE** (VS Code, Android Studio, or IntelliJ IDEA)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/quevault_app.git
   cd quevault_app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android

- Minimum SDK: 31 (Android 12)
- Biometric authentication requires device with fingerprint/face unlock

#### iOS

- Minimum iOS: 11.0
- Biometric authentication requires Touch ID/Face ID enabled device

#### Desktop (Windows/macOS/Linux)

- No additional setup required
- File picker integration for import/export

## 🔧 Development

### Project Structure

```
lib/
├── core/                    # Core utilities and configurations
│   ├── configs/            # App configurations
│   └── constants/          # App constants
├── models/                 # Data models
│   ├── auth_models.dart    # Authentication models
│   ├── credential.dart     # Credential data model
│   └── vault.dart          # Vault data model
├── repositories/           # Data access layer
│   └── auth_repository.dart
├── services/               # Business logic services
│   ├── biometric_service.dart      # Biometric authentication
│   ├── credential_service.dart     # Credential management
│   ├── encryption_service.dart     # Encryption/decryption
│   ├── export_service.dart         # Import/export functionality
│   ├── secure_storage_service.dart # Secure storage
│   └── vault_service.dart          # Vault management
├── viewmodels/             # State management
│   ├── auth_viewmodel.dart         # Authentication state
│   ├── credentials_viewmodel.dart  # Credential state
│   ├── hidden_vault_viewmodel.dart # Hidden vault state
│   └── theme_viewmodel.dart        # Theme state
├── views/                  # UI screens
│   ├── auth/              # Authentication screens
│   ├── home/              # Home screen
│   ├── vault/             # Vault management screens
│   ├── settings/          # Settings screens
│   └── password_generator/ # Password generator
├── widgets/               # Reusable UI components
└── main.dart             # Application entry point
```

### Key Dependencies

| Package                     | Version | Purpose                  |
| --------------------------- | ------- | ------------------------ |
| `hooks_riverpod`            | ^2.6.1  | State management         |
| `sqflite`                   | ^2.4.2  | Local SQLite database    |
| `flutter_secure_storage`    | ^9.2.2  | Secure key-value storage |
| `local_auth`                | ^2.3.0  | Biometric authentication |
| `crypto`                    | ^3.0.6  | Cryptographic functions  |
| `pointycastle`              | ^3.7.3  | Advanced cryptography    |
| `random_password_generator` | ^0.2.1  | Password generation      |
| `shadcn_ui`                 | ^0.29.0 | Modern UI components     |
| `file_picker`               | ^10.3.2 | File import/export       |

### Building for Production

#### Android

```bash
flutter build apk --release
flutter build appbundle --release  # For Play Store
```

#### iOS

```bash
flutter build ios --release
flutter build ipa --release  # For App Store
```

#### Desktop

```bash
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

#### Web

```bash
flutter build web --release
```

## 🔐 Security Implementation

### Encryption Details

- **Algorithm**: AES-256 encryption
- **Key Derivation**: PBKDF2 with 100,000 iterations
- **Salt**: 256-bit random salt per encryption
- **IV**: 128-bit random initialization vector
- **Storage**: Encrypted SQLite database

### Authentication Flow

1. **Master Password Setup** - Initial secure password creation
2. **Biometric Setup** - Optional fingerprint/face ID enrollment
3. **Vault Access** - Multi-factor authentication per vault
4. **Session Management** - Secure session handling

### Data Protection

- **Local Storage Only** - No cloud synchronization
- **Encrypted Database** - All sensitive data encrypted at rest
- **Secure Memory** - Sensitive data cleared from memory
- **No Logging** - Zero sensitive data in logs

## 🧪 Testing

### Run Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

### Linting

```bash
flutter analyze --fatal-infos
```

## 📖 Usage

### First Time Setup

1. **Launch QueVault** - App will show onboarding
2. **Set Master Password** - Create your primary authentication
3. **Enable Biometrics** (Optional) - Add fingerprint/face ID
4. **Create Vaults** - Organize your credentials

### Managing Credentials

1. **Create Vault** - Add a new vault for organization
2. **Add Credentials** - Store usernames, passwords, and metadata
3. **Generate Passwords** - Use built-in secure generator
4. **Copy to Clipboard** - Quick access to stored credentials

### Import/Export

1. **Export Data** - Create JSON backup of all vaults
2. **Import Data** - Restore from previous backup
3. **Cross-Device** - Migrate data between devices

## 🤝 Contributing

### Development Guidelines

- Follow Flutter/Dart style guidelines
- Write comprehensive tests for new features
- Document complex business logic
- Use meaningful variable and function names
- Implement proper error handling

### Security Requirements

- Never log sensitive information
- Use secure coding practices
- Implement proper input validation
- Follow encryption best practices
- Regular security audits

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Documentation

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)

### Issues

- Report bugs via [GitHub Issues](https://github.com/yourusername/quevault_app/issues)
- Request features via [GitHub Discussions](https://github.com/yourusername/quevault_app/discussions)

### Security

- Report security vulnerabilities privately to security@quevault.app
- Do not disclose security issues publicly until resolved

## 🗺️ Roadmap

### Version 1.1

- [ ] Cloud backup (optional)
- [ ] Password strength analyzer
- [ ] Auto-fill browser integration
- [ ] Advanced search and filtering

### Version 1.2

- [ ] Two-factor authentication support
- [ ] Password sharing (encrypted)
- [ ] Advanced vault permissions
- [ ] Audit logs

### Version 2.0

- [ ] Team/enterprise features
- [ ] API integration
- [ ] Advanced reporting
- [ ] Custom themes

---

**QueVault** - Your passwords, your control, your security. 🔐
