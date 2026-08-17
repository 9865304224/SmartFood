class Restaurant {
  final String id;
  final String userId;
  final String businessName;
  final String? description;
  final String? address;
  final double latitude;
  final double longitude;
  final List<String> cuisineTypes;
  final double rating;
  final int totalReviews;
  final bool isOpen;
  final bool isPureVeg;
  final int preparationTimeMinutes;
  final double averageCostForTwo;
  final String? coverImageUrl;
  final String? logoUrl;

  Restaurant({
    required this.id,
    required this.userId,
    required this.businessName,
    this.description,
    this.address,
    this.latitude = 12.9716,
    this.longitude = 77.5946,
    this.cuisineTypes = const [],
    this.rating = 4.5,
    this.totalReviews = 0,
    this.isOpen = true,
    this.isPureVeg = false,
    this.preparationTimeMinutes = 25,
    this.averageCostForTwo = 350.0,
    this.coverImageUrl,
    this.logoUrl,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    double lat = 12.9716;
    double lng = 77.5946;
    if (json['location'] != null) {
      lat = (json['location']['latitude'] as num?)?.toDouble() ?? 12.9716;
      lng = (json['location']['longitude'] as num?)?.toDouble() ?? 77.5946;
    }

    return Restaurant(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      businessName: json['businessName'] ?? '',
      description: json['description'],
      address: json['address'],
      latitude: lat,
      longitude: lng,
      cuisineTypes: (json['cuisineTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      totalReviews: json['totalReviews'] ?? 0,
      isOpen: json['isOpen'] ?? true,
      isPureVeg: json['isPureVeg'] ?? false,
      preparationTimeMinutes: json['preparationTimeMinutes'] ?? 25,
      averageCostForTwo: (json['averageCostForTwo'] as num?)?.toDouble() ?? 350.0,
      coverImageUrl: json['coverImageUrl'],
      logoUrl: json['logoUrl'],
    );
  }
}
