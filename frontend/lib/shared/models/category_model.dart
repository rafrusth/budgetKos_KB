class CategoryModel {
  final String? id;
  final String name;
  final String icon;
  final String color;
  final String type;
  final bool isDefault;
  final int sortOrder;
  final int syncStatus;
  final int isDeleted;
  final String? updatedAt;
  final String? createdAt;

  CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
    this.sortOrder = 0,
    this.syncStatus = 0,
    this.isDeleted = 0,
    this.updatedAt,
    this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id']?.toString(),
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      type: map['type'],
      isDefault: map['is_default'] == 1 || map['is_default'] == true,
      sortOrder: map['sort_order'],
      syncStatus: map['sync_status'] ?? 0,
      isDeleted: map['is_deleted'] ?? 0,
      updatedAt: map['updated_at'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'is_default': isDefault ? 1 : 0,
      'sort_order': sortOrder,
      'sync_status': syncStatus,
      'is_deleted': isDeleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'is_default': isDefault,
      'sort_order': sortOrder,
      'sync_status': syncStatus,
      'is_deleted': isDeleted,
      if (updatedAt != null) 'updated_at': updatedAt!.endsWith('Z') ? updatedAt : '${updatedAt}Z',
      if (createdAt != null) 'created_at': createdAt!.endsWith('Z') ? createdAt : '${createdAt}Z',
    };
  }
}
