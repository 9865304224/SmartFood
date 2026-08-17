class OrderModel {
  final String id;
  final String orderNumber;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? restaurantId;
  final String? hotelId;
  final String? businessName;
  final double pickupLat;
  final double pickupLng;
  final double deliveryLat;
  final double deliveryLng;
  final double driverLat;
  final double driverLng;
  final String? deliveryPersonId;
  final String? deliveryPersonName;
  final String? deliveryPersonPhone;
  final List<OrderItemModel> items;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double platformFee;
  final double taxes;
  final double discount;
  final double finalTotal;
  final String paymentMethod;
  final String deliveryOtp;
  final bool isEcoDelivery;
  final double estimatedDistanceKm;
  final double estimatedCo2SavingKg;
  final double ecoScore;
  final DateTime? createdAt;
  final DateTime? deliveredAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.restaurantId,
    this.hotelId,
    this.businessName,
    this.pickupLat = 12.9716,
    this.pickupLng = 77.5946,
    this.deliveryLat = 12.9720,
    this.deliveryLng = 77.5950,
    this.driverLat = 12.9718,
    this.driverLng = 77.5948,
    this.deliveryPersonId,
    this.deliveryPersonName,
    this.deliveryPersonPhone,
    this.items = const [],
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.platformFee,
    required this.taxes,
    required this.discount,
    required this.finalTotal,
    this.paymentMethod = 'ONLINE',
    required this.deliveryOtp,
    this.isEcoDelivery = false,
    this.estimatedDistanceKm = 2.5,
    this.estimatedCo2SavingKg = 0.0,
    this.ecoScore = 75.0,
    this.createdAt,
    this.deliveredAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    double pLat = 12.9716;
    double pLng = 77.5946;
    if (json['pickupLocation'] != null) {
      pLat = (json['pickupLocation']['latitude'] as num?)?.toDouble() ?? 12.9716;
      pLng = (json['pickupLocation']['longitude'] as num?)?.toDouble() ?? 77.5946;
    }

    double dLat = 12.9720;
    double dLng = 77.5950;
    if (json['deliveryAddress'] != null && json['deliveryAddress']['location'] != null) {
      dLat = (json['deliveryAddress']['location']['latitude'] as num?)?.toDouble() ?? 12.9720;
      dLng = (json['deliveryAddress']['location']['longitude'] as num?)?.toDouble() ?? 77.5950;
    }

    double drLat = 12.9718;
    double drLng = 77.5948;
    if (json['currentDriverLocation'] != null) {
      drLat = (json['currentDriverLocation']['latitude'] as num?)?.toDouble() ?? 12.9718;
      drLng = (json['currentDriverLocation']['longitude'] as num?)?.toDouble() ?? 77.5948;
    }

    return OrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      customerId: json['customerId'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      restaurantId: json['restaurantId'],
      hotelId: json['hotelId'],
      businessName: json['businessName'] ?? json['restaurantName'],
      pickupLat: pLat,
      pickupLng: pLng,
      deliveryLat: dLat,
      deliveryLng: dLng,
      driverLat: drLat,
      driverLng: drLng,
      deliveryPersonId: json['deliveryPersonId'],
      deliveryPersonName: json['deliveryPersonName'],
      deliveryPersonPhone: json['deliveryPersonPhone'],
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] ?? 'PLACED',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      taxes: (json['taxes'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (json['finalTotal'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? 'ONLINE',
      deliveryOtp: json['deliveryOtp'] ?? '',
      isEcoDelivery: json['isEcoDelivery'] ?? (json['ecoDelivery'] ?? false),
      estimatedDistanceKm: (json['estimatedDistanceKm'] as num?)?.toDouble() ?? 2.5,
      estimatedCo2SavingKg: (json['estimatedCo2SavingKg'] as num?)?.toDouble() ?? 0.0,
      ecoScore: (json['ecoScore'] as num?)?.toDouble() ?? 75.0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      deliveredAt: json['deliveredAt'] != null ? DateTime.tryParse(json['deliveredAt']) : null,
    );
  }
}

class OrderItemModel {
  final String foodItemId;
  final String foodName;
  final double price;
  final int quantity;
  final double itemTotal;
  final bool isVeg;

  OrderItemModel({
    this.foodItemId = '',
    required this.foodName,
    required this.price,
    required this.quantity,
    required this.itemTotal,
    this.isVeg = true,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      foodItemId: json['foodItemId'] ?? (json['id'] ?? ''),
      foodName: json['foodName'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 1,
      itemTotal: (json['itemTotal'] as num?)?.toDouble() ?? 0.0,
      isVeg: json['isVeg'] ?? (json['veg'] ?? true),
    );
  }
}
