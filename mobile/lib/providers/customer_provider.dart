import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/restaurant_model.dart';
import '../models/smart_budget_model.dart';

class CustomerHomeState {
  final List<Restaurant> restaurants;
  final List<dynamic> categories;
  final List<dynamic> foodSaverDeals;
  final List<dynamic> recommendationSections;
  final bool isLoading;
  final String? error;

  CustomerHomeState({
    this.restaurants = const [],
    this.categories = const [],
    this.foodSaverDeals = const [],
    this.recommendationSections = const [],
    this.isLoading = false,
    this.error,
  });

  CustomerHomeState copyWith({
    List<Restaurant>? restaurants,
    List<dynamic>? categories,
    List<dynamic>? foodSaverDeals,
    List<dynamic>? recommendationSections,
    bool? isLoading,
    String? error,
  }) {
    return CustomerHomeState(
      restaurants: restaurants ?? this.restaurants,
      categories: categories ?? this.categories,
      foodSaverDeals: foodSaverDeals ?? this.foodSaverDeals,
      recommendationSections: recommendationSections ?? this.recommendationSections,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CustomerNotifier extends StateNotifier<CustomerHomeState> {
  CustomerNotifier() : super(CustomerHomeState()) {
    fetchHomeData();
  }

  Future<void> fetchHomeData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final resFuture = ApiClient.get(ApiConstants.publicRestaurants);
      final catFuture = ApiClient.get(ApiConstants.categories);
      final recFuture = ApiClient.get(ApiConstants.recommendations);

      final results = await Future.wait([resFuture, catFuture, recFuture]);

      List<Restaurant> restaurants = [];
      if (results[0].data['success'] == true) {
        restaurants = (results[0].data['data'] as List<dynamic>)
            .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      List<dynamic> categories = [];
      if (results[1].data['success'] == true) {
        categories = results[1].data['data'] as List<dynamic>;
      }

      List<dynamic> recs = [];
      if (results[2].data['success'] == true) {
        recs = results[2].data['data'] as List<dynamic>;
      }

      state = state.copyWith(
        restaurants: restaurants,
        categories: categories,
        recommendationSections: recs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<BudgetComboOptionModel>> searchSmartBudget(double budget, {bool vegOnly = false}) async {
    try {
      final res = await ApiClient.post(ApiConstants.smartBudget, data: {
        'budgetAmount': budget,
        'isVegOnly': vegOnly,
        'userLatitude': 12.9716,
        'userLongitude': 77.5946,
      });

      if (res.data['success'] == true && res.data['data'] != null) {
        final recs = res.data['data']['recommendations'] as List<dynamic>;
        return recs.map((e) => BudgetComboOptionModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerHomeState>((ref) {
  return CustomerNotifier();
});
