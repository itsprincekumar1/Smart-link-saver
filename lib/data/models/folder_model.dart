import 'package:hive/hive.dart';

part 'folder_model.g.dart';

/// Hive model for a folder that contains links.
@HiveType(typeId: 1)
class FolderModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final String? parentId;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  String iconName;

  FolderModel({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    this.iconName = 'folder',
  });

  /// Creates a copy with optional field overrides.
  FolderModel copyWith({
    String? id,
    String? name,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? iconName,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      iconName: iconName ?? this.iconName,
    );
  }

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parentId': parentId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'iconName': iconName,
      };

  /// Deserializes from JSON map.
  factory FolderModel.fromJson(Map<String, dynamic> json) => FolderModel(
        id: json['id'] as String,
        name: json['name'] as String,
        parentId: json['parentId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        iconName: json['iconName'] as String? ?? 'folder',
      );
}
