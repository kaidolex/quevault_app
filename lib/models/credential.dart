class Credential {
  final String id;
  final String name;
  final String vaultId;
  final String username;
  final String password;
  final String? website;
  final String? notes;
  final List<CustomField> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  Credential({
    required this.id,
    required this.name,
    required this.vaultId,
    required this.username,
    required this.password,
    this.website,
    this.notes,
    this.customFields = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'vaultId': vaultId,
      'username': username,
      'password': password,
      'website': website,
      'notes': notes,
      'customFields': customFields.map((field) => field.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Credential.fromMap(Map<String, dynamic> map) {
    return Credential(
      id: map['id'],
      name: map['name'],
      vaultId: map['vaultId'],
      username: map['username'],
      password: map['password'],
      website: map['website'],
      notes: map['notes'],
      customFields: (map['customFields'] as List<dynamic>?)?.map((field) => CustomField.fromMap(field)).toList() ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  Credential copyWith({
    String? id,
    String? name,
    String? vaultId,
    String? username,
    String? password,
    String? website,
    String? notes,
    List<CustomField>? customFields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Credential(
      id: id ?? this.id,
      name: name ?? this.name,
      vaultId: vaultId ?? this.vaultId,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CustomField {
  final String id;
  final String name;
  final String value;

  CustomField({required this.id, required this.name, required this.value});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'value': value};
  }

  factory CustomField.fromMap(Map<String, dynamic> map) {
    return CustomField(id: map['id'], name: map['name'], value: map['value']);
  }

  CustomField copyWith({String? id, String? name, String? value}) {
    return CustomField(id: id ?? this.id, name: name ?? this.name, value: value ?? this.value);
  }
}
