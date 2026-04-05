// lib/models/item_model.dart

class Item {
  String category;
  String description;
  String color;
  String imageURL;
  String uniqueFeatures;

  /// Creates an [Item] with all required fields.
  Item({
    required this.category,
    required this.description,
    required this.color,
    required this.imageURL,
    required this.uniqueFeatures,
  });

  /// Converts this [Item] into a [Map] for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'description': description,
      'color': color,
      'imageURL': imageURL ,
      'uniqueFeatures': uniqueFeatures,
    };
  }

  /// Creates an [Item] from a Firestore document [map].
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      color: map['color'] ?? '',
      imageURL: map['imageURL'] ?? '',
      uniqueFeatures: map['uniqueFeatures'] ?? '',
    );
  }
}
