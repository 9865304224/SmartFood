import 'package:flutter_test/flutter_test.dart';
import 'package:smartfood_mobile/models/cart_model.dart';
import 'package:smartfood_mobile/models/food_item_model.dart';

void main() {
  group('SmartFood Mobile Unit & Model Tests', () {
    test('Test 1: FoodItem deserialization from JSON', () {
      final json = {
        'id': 'f-101',
        'name': 'Hyderabadi Dum Biryani',
        'price': 250.0,
        'isVeg': false,
        'category': 'Biryani',
        'rating': 4.9,
      };

      final item = FoodItem.fromJson(json);

      expect(item.id, 'f-101');
      expect(item.name, 'Hyderabadi Dum Biryani');
      expect(item.price, 250.0);
      expect(item.isVeg, false);
      expect(item.category, 'Biryani');
    });

    test('Test 2: CartModel pricing and item count calculation', () {
      final json = {
        'restaurantId': 'res-1',
        'businessName': 'Royal Biryani Kitchen',
        'items': [
          {
            'foodItemId': 'f-1',
            'foodName': 'Special Biryani',
            'price': 220.0,
            'quantity': 2,
            'isVeg': false,
          },
          {
            'foodItemId': 'f-2',
            'foodName': 'Gulab Jamun',
            'price': 60.0,
            'quantity': 1,
            'isVeg': true,
          }
        ],
        'subtotal': 500.0,
        'deliveryFee': 30.0,
        'platformFee': 5.0,
        'taxes': 25.0,
        'discount': 50.0,
        'finalTotal': 510.0,
        'appliedCouponCode': 'SMART50',
      };

      final cart = CartModel.fromJson(json);

      expect(cart.items.length, 2);
      expect(cart.subtotal, 500.0);
      expect(cart.finalTotal, 510.0);
      expect(cart.appliedCouponCode, 'SMART50');
      expect(cart.items.first.quantity, 2);
    });
  });
}
