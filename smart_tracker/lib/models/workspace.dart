class Workspace {
  Workspace({
    required this.id,
    required this.name,
    required this.isPersonal,
    required this.memberCount,
  });

  final String id;
  final String name;
  final bool isPersonal;
  final int memberCount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isPersonal': isPersonal,
      'memberCount': memberCount,
    };
  }

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Workspace',
      isPersonal: json['isPersonal'] as bool? ?? false,
      memberCount: json['memberCount'] as int? ?? 1,
    );
  }
}
