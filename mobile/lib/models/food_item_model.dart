class FoodItem {
  final String id;
  final String? restaurantId;
  final String? hotelId;
  final String name;
  final String? description;
  final String? category;
  final double price;
  final bool isVeg;
  final bool isAvailable;
  final int preparationTimeMinutes;
  final String? imageUrl;
  final double rating;
  final List<String> tags;
  final bool isBulkAvailable;
  final double? bulkPrice;
  final int? bulkMinQuantity;

  FoodItem({
    required this.id,
    this.restaurantId,
    this.hotelId,
    required this.name,
    this.description,
    this.category,
    required this.price,
    this.isVeg = true,
    this.isAvailable = true,
    this.preparationTimeMinutes = 20,
    this.imageUrl,
    this.rating = 4.5,
    this.tags = const [],
    this.isBulkAvailable = false,
    this.bulkPrice,
    this.bulkMinQuantity,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] ?? '',
      restaurantId: json['restaurantId'],
      hotelId: json['hotelId'],
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isVeg: json['isVeg'] ?? (json['veg'] ?? true),
      isAvailable: json['isAvailable'] ?? (json['available'] ?? true),
      preparationTimeMinutes: json['preparationTimeMinutes'] ?? 20,
      imageUrl: json['imageUrl'],
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isBulkAvailable: json['isBulkAvailable'] ?? false,
      bulkPrice: (json['bulkPrice'] as num?)?.toDouble(),
      bulkMinQuantity: json['bulkMinQuantity'],
    );
  }
}
