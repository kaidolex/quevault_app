class Vault {
  final String id;
  final String name;
  final String description;
  final int color;
  final bool isHidden;
  final bool needsUnlock;
  final bool useMasterKey;
  final bool useDifferentUnlockKey;
  final String? unlockKey;
  final bool useFingerprint;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vault({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.isHidden,
    required this.needsUnlock,
    required this.useMasterKey,
    required this.useDifferentUnlockKey,
    this.unlockKey,
    required this.useFingerprint,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'isHidden': isHidden ? 1 : 0,
      'needsUnlock': needsUnlock ? 1 : 0,
      'useMasterKey': useMasterKey ? 1 : 0,
      'useDifferentUnlockKey': useDifferentUnlockKey ? 1 : 0,
      'unlockKey': unlockKey,
      'useFingerprint': useFingerprint ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Vault.fromMap(Map<String, dynamic> map) {
    return Vault(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      color: map['color'],
      isHidden: map['isHidden'] == 1,
      needsUnlock: map['needsUnlock'] == 1,
      useMasterKey: map['useMasterKey'] == 1,
      useDifferentUnlockKey: map['useDifferentUnlockKey'] == 1,
      unlockKey: map['unlockKey'],
      useFingerprint: map['useFingerprint'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  Vault copyWith({
    String? id,
    String? name,
    String? description,
    int? color,
    bool? isHidden,
    bool? needsUnlock,
    bool? useMasterKey,
    bool? useDifferentUnlockKey,
    String? unlockKey,
    bool? useFingerprint,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vault(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      isHidden: isHidden ?? this.isHidden,
      needsUnlock: needsUnlock ?? this.needsUnlock,
      useMasterKey: useMasterKey ?? this.useMasterKey,
      useDifferentUnlockKey: useDifferentUnlockKey ?? this.useDifferentUnlockKey,
      unlockKey: unlockKey ?? this.unlockKey,
      useFingerprint: useFingerprint ?? this.useFingerprint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
