import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/cart_model.dart';

class CartState {
  final CartModel? cart;
  final bool isLoading;
  final String? error;

  CartState({this.cart, this.isLoading = false, this.error});

  CartState copyWith({CartModel? cart, bool? isLoading, String? error}) {
    return CartState(
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  Future<void> fetchCart() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final res = await ApiClient.get(ApiConstants.cart);
      if (res.data['success'] == true && res.data['data'] != null) {
        state = state.copyWith(
          cart: CartModel.fromJson(res.data['data']),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addToCart({
    required String foodItemId,
    required int quantity,
    String? restaurantId,
    String? hotelId,
    String? notes,
    bool isBulk = false,
    bool isFoodSaver = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final res = await ApiClient.post(ApiConstants.cartAdd, data: {
        'foodItemId': foodItemId,
        'quantity': quantity,
        'restaurantId': restaurantId,
        'hotelId': hotelId,
        'notes': notes,
        'bulkItem': isBulk,
        'foodSaverItem': isFoodSaver,
      });

      if (res.data['success'] == true) {
        state = state.copyWith(
          cart: CartModel.fromJson(res.data['data']),
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: res.data['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> updateQuantity(String foodItemId, int quantity) async {
    try {
      final res = await ApiClient.put(
        ApiConstants.cartItem,
        queryParameters: {'foodItemId': foodItemId, 'quantity': quantity},
      );
      if (res.data['success'] == true) {
        state = state.copyWith(cart: CartModel.fromJson(res.data['data']));
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> applyCoupon(String code) async {
    try {
      final res = await ApiClient.post(
        ApiConstants.cartCoupon,
        queryParameters: {'couponCode': code},
      );
      if (res.data['success'] == true) {
        state = state.copyWith(cart: CartModel.fromJson(res.data['data']));
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> clearCart() async {
    try {
      await ApiClient.delete(ApiConstants.cart);
      state = CartState(cart: CartModel());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
