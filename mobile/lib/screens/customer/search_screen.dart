import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/food_item_model.dart';
import '../../models/restaurant_model.dart';
import '../../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'hotel_detail_screen.dart';
import 'restaurant_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<FoodItem> _allDishes = [];
  List<Restaurant> _allRestaurants = [];
  List<Map<String, dynamic>> _allHotels = [];
  Map<String, String> _sourceNames = {}; // id -> businessName

  List<FoodItem> _filteredDishes = [];
  List<Restaurant> _filteredRestaurants = [];
  List<Map<String, dynamic>> _filteredHotels = [];

  bool _isLoading = true;
  String _selectedCategory = 'All';
  bool _vegOnly = false;
  double _maxPrice = 1500;

  bool _isListening = false;
  late AnimationController _micAnimController;

  @override
  void initState() {
    super.initState();
    _micAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }

    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _micAnimController.dispose();
    super.dispose();
  }

  void _loadCatalog() async {
    setState(() => _isLoading = true);
    try {
      final resFuture = ApiClient.get('/restaurants/public');
      final hotelFuture = ApiClient.get('/hotels/public');
      final results = await Future.wait([resFuture, hotelFuture]);

      List<Restaurant> restaurants = [];
      List<Map<String, dynamic>> hotels = [];
      List<FoodItem> dishes = [];
      Map<String, String> names = {};

      if (results[0].data['success'] == true && results[0].data['data'] != null) {
        final resList = results[0].data['data'] as List<dynamic>;
        restaurants = resList.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
        for (final r in restaurants) {
          names[r.id] = r.businessName;
          try {
            final menuRes = await ApiClient.get('/restaurants/public/${r.id}/menu');
            if (menuRes.data['success'] == true && menuRes.data['data'] != null) {
              final mList = menuRes.data['data'] as List<dynamic>;
              dishes.addAll(mList.map((e) => FoodItem.fromJson(e as Map<String, dynamic>)));
            }
          } catch (_) {}
        }
      }

      if (results[1].data['success'] == true && results[1].data['data'] != null) {
        final hList = results[1].data['data'] as List<dynamic>;
        hotels = hList.map((e) => e as Map<String, dynamic>).toList();
        for (final h in hotels) {
          final hId = h['id'] ?? '';
          final hName = h['hotelName'] ?? h['businessName'] ?? 'Hotel';
          names[hId] = hName;
          try {
            final menuRes = await ApiClient.get('/hotels/public/$hId/menu');
            if (menuRes.data['success'] == true && menuRes.data['data'] != null) {
              final mList = menuRes.data['data'] as List<dynamic>;
              dishes.addAll(mList.map((e) => FoodItem.fromJson(e as Map<String, dynamic>)));
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _allRestaurants = restaurants;
          _allHotels = hotels;
          _allDishes = dishes;
          _sourceNames = names;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      // Filter dishes
      _filteredDishes = _allDishes.where((dish) {
        final matchesQuery = query.isEmpty ||
            dish.name.toLowerCase().contains(query) ||
            (dish.description?.toLowerCase().contains(query) ?? false) ||
            (dish.category?.toLowerCase().contains(query) ?? false) ||
            dish.tags.any((t) => t.toLowerCase().contains(query)) ||
            (_sourceNames[dish.restaurantId ?? dish.hotelId ?? '']?.toLowerCase().contains(query) ?? false);

        final matchesVeg = !_vegOnly || dish.isVeg;
        final matchesCat = _selectedCategory == 'All' ||
            (dish.category != null && dish.category!.toLowerCase().contains(_selectedCategory.toLowerCase()));
        final matchesPrice = dish.price <= _maxPrice;

        return matchesQuery && matchesVeg && matchesCat && matchesPrice;
      }).toList();

      // Filter restaurants
      _filteredRestaurants = _allRestaurants.where((r) {
        return query.isEmpty ||
            r.businessName.toLowerCase().contains(query) ||
            (r.description?.toLowerCase().contains(query) ?? false) ||
            r.cuisineTypes.any((c) => c.toLowerCase().contains(query));
      }).toList();

      // Filter hotels
      _filteredHotels = _allHotels.where((h) {
        final name = (h['hotelName'] ?? h['businessName'] ?? '').toString().toLowerCase();
        final desc = (h['description'] ?? '').toString().toLowerCase();
        return query.isEmpty || name.contains(query) || desc.contains(query);
      }).toList();
    });
  }

  void _showVoiceSearchDialog() {
    setState(() => _isListening = true);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Mic Soundwave Circle
                  AnimatedBuilder(
                    animation: _micAnimController,
                    builder: (context, child) {
                      return Container(
                        width: 80 + (_micAnimController.value * 20),
                        height: 80 + (_micAnimController.value * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.2 + (_micAnimController.value * 0.3)),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 30),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Smart Voice Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Listening for your favorite food or cravings...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 20),

                  // Quick Voice Suggestion Chips
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Or tap a quick voice command:', style: TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Biryani',
                      'Paneer Tikka',
                      'High-Protein Bowl',
                      'Executive Corporate Feast',
                      'Gulab Jamun with Rabri',
                      'Pizza under 250',
                    ].map((prompt) {
                      return ActionChip(
                        backgroundColor: AppColors.surfaceDark,
                        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                        avatar: const Icon(Icons.mic_none_rounded, size: 14, color: AppColors.primary),
                        label: Text(prompt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        onPressed: () {
                          _searchController.text = prompt;
                          _applyFilters();
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) setState(() => _isListening = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartCount = cartState.cart?.items.fold(0, (sum, i) => sum + i.quantity) ?? 0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          height: 46,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search food, biryani, burgers, banquets...',
              hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textDim),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    ),
                  IconButton(
                    icon: Icon(Icons.mic_rounded, color: _isListening ? AppColors.emerald : AppColors.primary, size: 20),
                    onPressed: _showVoiceSearchDialog,
                  ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (_) => _applyFilters(),
          ),
        ),
      ),
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.shopping_bag_rounded, color: Colors.white),
              label: Text('$cartCount Items • View Cart', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Filter bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.cardDark,
                    border: Border(bottom: BorderSide(color: AppColors.borderDark)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Veg only filter chip
                        FilterChip(
                          avatar: Icon(Icons.circle, size: 10, color: _vegOnly ? Colors.white : AppColors.emerald),
                          label: const Text('Pure Veg'),
                          selected: _vegOnly,
                          selectedColor: AppColors.emerald,
                          backgroundColor: AppColors.surfaceDark,
                          labelStyle: TextStyle(color: _vegOnly ? Colors.white : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                          onSelected: (val) {
                            setState(() => _vegOnly = val);
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),

                        // Categories
                        ...['All', 'Biryani', 'North Indian', 'Healthy & Bowls', 'Desserts', 'Beverages'].map((cat) {
                          final isSel = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: isSel,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.surfaceDark,
                              labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700),
                              onSelected: (_) {
                                setState(() => _selectedCategory = cat);
                                _applyFilters();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Results list
                Expanded(
                  child: _filteredDishes.isEmpty && _filteredRestaurants.isEmpty && _filteredHotels.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textDim),
                              const SizedBox(height: 12),
                              Text('No results for "${_searchController.text}"', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              const SizedBox(height: 6),
                              const Text('Try searching "Biryani", "Paneer", or tap the microphone 🎤', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Dishes results
                            if (_filteredDishes.isNotEmpty) ...[
                              Text('Food Items (${_filteredDishes.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              ..._filteredDishes.map((dish) => _buildDishResultCard(dish)),
                              const SizedBox(height: 20),
                            ],

                            // Restaurants results
                            if (_filteredRestaurants.isNotEmpty) ...[
                              Text('Restaurants (${_filteredRestaurants.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              ..._filteredRestaurants.map((res) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardDark,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.borderDark),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.restaurant_rounded, color: AppColors.primary),
                                    ),
                                    title: Text(res.businessName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                    subtitle: Text(res.cuisineTypes.join(' • '), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: res)));
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(height: 20),
                            ],

                            // Hotels results
                            if (_filteredHotels.isNotEmpty) ...[
                              Text('Hotels & Banquets (${_filteredHotels.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 12),
                              ..._filteredHotels.map((h) {
                                final name = h['hotelName'] ?? h['businessName'] ?? 'Grand Hotel';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardDark,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.indigo.withOpacity(0.3)),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(color: AppColors.indigo.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.hotel_rounded, color: AppColors.indigo),
                                    ),
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                    subtitle: const Text('Event Banquets & Bulk Catering', style: TextStyle(color: AppColors.indigo, fontSize: 12, fontWeight: FontWeight.w700)),
                                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => HotelDetailScreen(hotel: h)));
                                    },
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDishResultCard(FoodItem dish) {
    final placeName = _sourceNames[dish.restaurantId ?? dish.hotelId ?? ''] ?? 'Campus Kitchen';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dish icon/thumbnail
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              image: dish.imageUrl != null && dish.imageUrl!.isNotEmpty
                  ? DecorationImage(image: NetworkImage(dish.imageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: dish.imageUrl == null || dish.imageUrl!.isEmpty
                ? Icon(Icons.fastfood_rounded, color: dish.isVeg ? AppColors.emerald : AppColors.rose, size: 24)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: dish.isVeg ? AppColors.emerald : AppColors.rose),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(dish.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(placeName, style: const TextStyle(fontSize: 11, color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                if (dish.description != null && dish.description!.isNotEmpty)
                  Text(
                    dish.description!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${(dish.bulkPrice ?? dish.price).toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        minimumSize: const Size(60, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final success = await ref.read(cartProvider.notifier).addToCart(
                              foodItemId: dish.id,
                              quantity: dish.isBulkAvailable ? (dish.bulkMinQuantity ?? 5) : 1,
                              restaurantId: dish.restaurantId,
                              hotelId: dish.hotelId,
                              isBulk: dish.isBulkAvailable,
                            );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added ${dish.name} to cart!'),
                              backgroundColor: AppColors.emerald,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      child: const Text('ADD +', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
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
}
