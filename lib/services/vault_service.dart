import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/vault.dart';

class VaultService {
  static final VaultService instance = VaultService._internal();
  VaultService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'quevault.db');
    return await openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create vaults table
    await db.execute('''
      CREATE TABLE vaults(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        color INTEGER NOT NULL,
        isHidden INTEGER NOT NULL,
        needsUnlock INTEGER NOT NULL,
        useMasterKey INTEGER NOT NULL,
        useDifferentUnlockKey INTEGER NOT NULL,
        unlockKey TEXT,
        useFingerprint INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Create credentials table for version 2
    if (version >= 2) {
      await db.execute('''
        CREATE TABLE credentials(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          vaultId TEXT NOT NULL,
          username TEXT NOT NULL,
          password TEXT NOT NULL,
          passwordIV TEXT,
          isEncrypted INTEGER DEFAULT 0,
          website TEXT,
          notes TEXT,
          customFields TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY (vaultId) REFERENCES vaults (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add credentials table for version 2
      await db.execute('''
        CREATE TABLE credentials(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          vaultId TEXT NOT NULL,
          username TEXT NOT NULL,
          password TEXT NOT NULL,
          passwordIV TEXT,
          isEncrypted INTEGER DEFAULT 0,
          website TEXT,
          notes TEXT,
          customFields TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY (vaultId) REFERENCES vaults (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      // Add encryption fields to existing credentials table
      try {
        await db.execute('ALTER TABLE credentials ADD COLUMN passwordIV TEXT');
        await db.execute('ALTER TABLE credentials ADD COLUMN isEncrypted INTEGER DEFAULT 0');
      } catch (e) {
        // Columns might already exist, ignore error
        if (kDebugMode) {
          print('VaultService: Encryption columns might already exist: $e');
        }
      }
    }
  }

  Future<void> createVault(Vault vault) async {
    final db = await database;
    await db.insert('vaults', vault.toMap());
  }

  Future<List<Vault>> getAllVaults() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vaults');
    return List.generate(maps.length, (i) => Vault.fromMap(maps[i]));
  }

  Future<Vault?> getVaultById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vaults', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Vault.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateVault(Vault vault) async {
    final db = await database;
    await db.update('vaults', vault.toMap(), where: 'id = ?', whereArgs: [vault.id]);
  }

  Future<void> deleteVault(String id) async {
    final db = await database;
    await db.delete('vaults', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Vault>> getVisibleVaults() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vaults', where: 'isHidden = ?', whereArgs: [0]);
    return List.generate(maps.length, (i) => Vault.fromMap(maps[i]));
  }

  Future<List<Vault>> getHiddenVaults() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('vaults', where: 'isHidden = ?', whereArgs: [1]);
    return List.generate(maps.length, (i) => Vault.fromMap(maps[i]));
  }
}
