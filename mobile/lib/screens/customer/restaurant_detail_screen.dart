import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/food_item_model.dart';
import '../../models/restaurant_model.dart';
import '../../providers/cart_provider.dart';
import 'cart_screen.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends ConsumerState<RestaurantDetailScreen> {
  List<FoodItem> _menu = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  void _fetchMenu() async {
    try {
      final res = await ApiClient.get('${ApiConstants.publicRestaurants}/${widget.restaurant.id}/menu');
      if (res.data['success'] == true && res.data['data'] != null) {
        final list = res.data['data'] as List<dynamic>;
        setState(() {
          _menu = list.map((e) => FoodItem.fromJson(e as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cart = cartState.cart;
    final cartItemCount = cart?.items.fold(0, (sum, i) => sum + i.quantity) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.businessName),
      ),
      floatingActionButton: cartItemCount > 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.shopping_bag_rounded, color: Colors.white),
              label: Text('$cartItemCount Items • ₹${cart?.finalTotal.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Restaurant Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.restaurant.businessName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(widget.restaurant.description ?? widget.restaurant.cuisineTypes.join(', '), style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: AppColors.emerald),
                                const SizedBox(width: 4),
                                Text('${widget.restaurant.rating} (${widget.restaurant.totalReviews} reviews)', style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w800, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('~${widget.restaurant.preparationTimeMinutes} mins delivery', style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Menu Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),

                ..._menu.map((food) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.circle, size: 12, color: food.isVeg ? AppColors.emerald : AppColors.rose),
                                  const SizedBox(width: 6),
                                  if (food.tags.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                      child: Text(food.tags.first, style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w700)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(food.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('₹${food.price.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textLight)),
                              if (food.description != null) ...[
                                const SizedBox(height: 6),
                                Text(food.description!, style: const TextStyle(fontSize: 12, color: AppColors.textDim, height: 1.3)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceDark,
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onPressed: () async {
                            final success = await ref.read(cartProvider.notifier).addToCart(
                                  foodItemId: food.id,
                                  quantity: 1,
                                  restaurantId: widget.restaurant.id,
                                );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added ${food.name} to cart'), duration: const Duration(seconds: 1)),
                              );
                            }
                          },
                          child: const Text('ADD +', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
