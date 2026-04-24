class Item { // try
  final String category;
  final String description;
  final String color;
  final String imageURL;
  final String uniqueFeatures;

  Item({
    required this.category,
    required this.description,
    required this.color,
    required this.imageURL,
    required this.uniqueFeatures,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'description': description,
      'color': color,
      'imageURL': imageURL ,
      'uniqueFeatures': uniqueFeatures,
    };
  }

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
