import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/food_item_model.dart';
import '../../providers/cart_provider.dart';
import 'cart_screen.dart';

class HotelDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> hotel;

  const HotelDetailScreen({super.key, required this.hotel});

  @override
  ConsumerState<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends ConsumerState<HotelDetailScreen> {
  List<FoodItem> _menu = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHotelMenu();
  }

  void _fetchHotelMenu() async {
    try {
      final hotelId = widget.hotel['id'];
      final res = await ApiClient.get('/hotels/public/$hotelId/menu');
      if (res.data['success'] == true && res.data['data'] != null) {
        final list = res.data['data'] as List<dynamic>;
        setState(() {
          _menu = list.map((e) => FoodItem.fromJson(e as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
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
    final hotelName = widget.hotel['hotelName'] ?? widget.hotel['businessName'] ?? 'Hotel & Catering';
    final bulkPackages = _menu.where((f) => f.isBulkAvailable).toList();
    final regularDishes = _menu.where((f) => !f.isBulkAvailable).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(hotelName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                // Hotel Header Card
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.indigo.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('HOTEL & EVENT CATERING', style: TextStyle(color: AppColors.indigo, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                          ),
                          const SizedBox(width: 8),
                          if (widget.hotel['starRating'] != null)
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                                const SizedBox(width: 2),
                                Text('${widget.hotel['starRating']} Star Hotel', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w800, fontSize: 11)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(hotelName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(widget.hotel['description'] ?? 'Grand banquets, student buffet packages, and party catering delivered fresh to campus.',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
                                const Icon(Icons.verified_rounded, size: 14, color: AppColors.emerald),
                                const SizedBox(width: 4),
                                Text('${widget.hotel['rating'] ?? 4.8} (${widget.hotel['totalReviews'] ?? 140}+ orders)',
                                    style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w800, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Banquet & Group Delivery', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bulk Catering Packages Section
                if (bulkPackages.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.indigo.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.groups_rounded, size: 18, color: AppColors.indigo),
                      ),
                      const SizedBox(width: 8),
                      const Text('Bulk & Event Catering Packages', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...bulkPackages.map((pkg) => _buildPackageCard(pkg, widget.hotel['id'] ?? '')),
                  const SizedBox(height: 20),
                ],

                // Regular Dishes Section
                if (regularDishes.isNotEmpty) ...[
                  const Text('Hotel Dining Menu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ...regularDishes.map((food) => _buildDishCard(food, widget.hotel['id'] ?? '')),
                ],

                if (_menu.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: const [
                          Icon(Icons.restaurant_menu_rounded, size: 48, color: AppColors.textDim),
                          SizedBox(height: 12),
                          Text('No catering packages available right now', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildPackageCard(FoodItem pkg, String hotelId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.indigo.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package Image or Banner
          if (pkg.imageUrl != null && pkg.imageUrl!.isNotEmpty)
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                image: DecorationImage(image: NetworkImage(pkg.imageUrl!), fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Min ${pkg.bulkMinQuantity ?? 10} Persons',
                        style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                if (pkg.description != null && pkg.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(pkg.description!, style: const TextStyle(color: AppColors.textDim, fontSize: 12, height: 1.3)),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₹${(pkg.bulkPrice ?? pkg.price).toInt()} / person',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                        if (pkg.bulkPrice != null && pkg.price > pkg.bulkPrice!)
                          Text('Regular ₹${pkg.price.toInt()}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                      label: const Text('Add Package', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      onPressed: () async {
                        final minQty = pkg.bulkMinQuantity ?? 10;
                        final success = await ref.read(cartProvider.notifier).addToCart(
                              foodItemId: pkg.id,
                              quantity: minQty,
                              hotelId: hotelId,
                              isBulk: true,
                            );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added ${pkg.name} ($minQty servings) to cart!'),
                              backgroundColor: AppColors.emerald,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishCard(FoodItem food, String hotelId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: food.isVeg ? AppColors.emerald : AppColors.rose),
                    const SizedBox(width: 6),
                    Text(food.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('₹${food.price.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textLight)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceDark,
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
            onPressed: () async {
              final success = await ref.read(cartProvider.notifier).addToCart(
                    foodItemId: food.id,
                    quantity: 1,
                    hotelId: hotelId,
                  );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${food.name} to cart'), duration: const Duration(seconds: 1)),
                );
              }
            },
            child: const Text('ADD +', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
