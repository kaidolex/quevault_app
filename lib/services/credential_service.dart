import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/credential.dart';
import 'vault_service.dart';

class CredentialService {
  static final CredentialService instance = CredentialService._internal();
  CredentialService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Use the same database instance as VaultService
    return await VaultService.instance.database;
  }

  Future<void> createCredential(Credential credential) async {
    final db = await database;
    await db.insert('credentials', {
      'id': credential.id,
      'name': credential.name,
      'vaultId': credential.vaultId,
      'username': credential.username,
      'password': credential.password,
      'website': credential.website,
      'notes': credential.notes,
      'customFields': jsonEncode(credential.customFields.map((field) => field.toMap()).toList()),
      'createdAt': credential.createdAt.millisecondsSinceEpoch,
      'updatedAt': credential.updatedAt.millisecondsSinceEpoch,
    });
  }

  Future<List<Credential>> getAllCredentials() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('credentials');
    return List.generate(maps.length, (i) => _mapToCredential(maps[i]));
  }

  Future<List<Credential>> getCredentialsByVaultId(String vaultId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('credentials', where: 'vaultId = ?', whereArgs: [vaultId]);
    return List.generate(maps.length, (i) => _mapToCredential(maps[i]));
  }

  Future<Credential?> getCredentialById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('credentials', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return _mapToCredential(maps.first);
    }
    return null;
  }

  Future<void> updateCredential(Credential credential) async {
    final db = await database;
    await db.update(
      'credentials',
      {
        'name': credential.name,
        'vaultId': credential.vaultId,
        'username': credential.username,
        'password': credential.password,
        'website': credential.website,
        'notes': credential.notes,
        'customFields': jsonEncode(credential.customFields.map((field) => field.toMap()).toList()),
        'updatedAt': credential.updatedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [credential.id],
    );
  }

  Future<void> deleteCredential(String id) async {
    final db = await database;
    await db.delete('credentials', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Credential>> searchCredentials(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'credentials',
      where: 'name LIKE ? OR username LIKE ? OR website LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => _mapToCredential(maps[i]));
  }

  Credential _mapToCredential(Map<String, dynamic> map) {
    List<CustomField> customFields = [];
    if (map['customFields'] != null) {
      try {
        final List<dynamic> fieldsJson = jsonDecode(map['customFields']);
        customFields = fieldsJson.map((field) => CustomField.fromMap(field)).toList();
      } catch (e) {
        // If JSON parsing fails, use empty list
        customFields = [];
      }
    }

    return Credential(
      id: map['id'],
      name: map['name'],
      vaultId: map['vaultId'],
      username: map['username'],
      password: map['password'],
      website: map['website'],
      notes: map['notes'],
      customFields: customFields,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
}
