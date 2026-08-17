class CartItemModel {
  final String foodItemId;
  final String foodName;
  final double price;
  final int quantity;
  final bool isVeg;
  final String? imageUrl;
  final String? notes;
  final bool isBulkItem;
  final bool isFoodSaverItem;

  CartItemModel({
    required this.foodItemId,
    required this.foodName,
    required this.price,
    required this.quantity,
    this.isVeg = true,
    this.imageUrl,
    this.notes,
    this.isBulkItem = false,
    this.isFoodSaverItem = false,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      foodItemId: json['foodItemId'] ?? '',
      foodName: json['foodName'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 1,
      isVeg: json['isVeg'] ?? (json['veg'] ?? true),
      imageUrl: json['imageUrl'],
      notes: json['notes'],
      isBulkItem: json['isBulkItem'] ?? false,
      isFoodSaverItem: json['isFoodSaverItem'] ?? false,
    );
  }
}

class CartModel {
  final String? restaurantId;
  final String? hotelId;
  final String? businessName;
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double platformFee;
  final double taxes;
  final double discount;
  final double finalTotal;
  final String? appliedCouponCode;

  CartModel({
    this.restaurantId,
    this.hotelId,
    this.businessName,
    this.items = const [],
    this.subtotal = 0.0,
    this.deliveryFee = 35.0,
    this.platformFee = 5.0,
    this.taxes = 0.0,
    this.discount = 0.0,
    this.finalTotal = 0.0,
    this.appliedCouponCode,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      restaurantId: json['restaurantId'],
      hotelId: json['hotelId'],
      businessName: json['businessName'],
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      taxes: (json['taxes'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (json['finalTotal'] as num?)?.toDouble() ?? 0.0,
      appliedCouponCode: json['appliedCouponCode'],
    );
  }
}
