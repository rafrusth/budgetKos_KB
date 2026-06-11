class CategoryModel {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final String type;
  final bool isDefault;
  final int sortOrder;

  CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      type: map['type'],
      isDefault: map['is_default'] == 1,
      sortOrder: map['sort_order'],
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
    };
  }
}
