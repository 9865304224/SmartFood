import 'food_item_model.dart';

class BudgetComboOptionModel {
  final String comboTitle;
  final String restaurantId;
  final String restaurantName;
  final double restaurantDistanceKm;
  final List<FoodItem> items;
  final double itemsTotal;
  final double deliveryFee;
  final double platformFee;
  final double taxes;
  final double estimatedDiscount;
  final double grandTotal;
  final double savingsVsBudget;
  final String smartReason;

  BudgetComboOptionModel({
    required this.comboTitle,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantDistanceKm,
    required this.items,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.platformFee,
    required this.taxes,
    required this.estimatedDiscount,
    required this.grandTotal,
    required this.savingsVsBudget,
    required this.smartReason,
  });

  factory BudgetComboOptionModel.fromJson(Map<String, dynamic> json) {
    return BudgetComboOptionModel(
      comboTitle: json['comboTitle'] ?? '',
      restaurantId: json['restaurantId'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      restaurantDistanceKm: (json['restaurantDistanceKm'] as num?)?.toDouble() ?? 2.5,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      itemsTotal: (json['itemsTotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      taxes: (json['taxes'] as num?)?.toDouble() ?? 0.0,
      estimatedDiscount: (json['estimatedDiscount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      savingsVsBudget: (json['savingsVsBudget'] as num?)?.toDouble() ?? 0.0,
      smartReason: json['smartReason'] ?? '',
    );
  }
}
