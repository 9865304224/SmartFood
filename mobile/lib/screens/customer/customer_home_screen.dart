import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/food_item_model.dart';
import '../../models/restaurant_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_provider.dart';
import '../auth/login_screen.dart';
import 'cart_screen.dart';
import 'customer_order_history_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_ai_assistant_screen.dart';
import 'hotel_detail_screen.dart';
import 'restaurant_detail_screen.dart';
import 'search_screen.dart';
import 'smart_budget_screen.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  List<FoodItem> _allDishes = [];
  Map<String, String> _sourceNames = {};
  List<Map<String, dynamic>> _hotels = [];
  List<dynamic> _savedAddresses = [];
  String _activeAddress = 'College Campus (Aryabhatta Hall)';
  bool _isLoadingDishes = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(cartProvider.notifier).fetchCart();
        _loadAllCatalogAndHotels();
        _fetchCustomerProfile();
      }
    });
  }

  void _fetchCustomerProfile() async {
    try {
      final res = await ApiClient.get('/customers/profile');
      if (res.data['success'] == true && res.data['data'] != null) {
        final d = res.data['data'] as Map<String, dynamic>;
        final addresses = d['savedAddresses'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _savedAddresses = addresses;
            final def = addresses.firstWhere(
              (a) => a['isDefault'] == true,
              orElse: () => addresses.isNotEmpty ? addresses.first : null,
            );
            if (def != null) {
              final label = def['label'] ?? 'Campus';
              final bldg = def['building'] ?? def['formattedAddress'] ?? 'Aryabhatta';
              _activeAddress = '$label ($bldg)';
            }
          });
        }
      }
    } catch (_) {}
  }

  void _showAddressSwitcherBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Choose Delivery Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_savedAddresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No saved addresses yet. Add one below!', style: TextStyle(color: AppColors.textMuted)),
                    )
                  else
                    ..._savedAddresses.map((addr) {
                      final label = addr['label'] ?? 'Address';
                      final bldg = addr['building'] ?? addr['formattedAddress'] ?? '';
                      final isSelected = _activeAddress.contains(label) || _activeAddress.contains(bldg);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderDark),
                        ),
                        child: ListTile(
                          leading: Icon(
                            label.toLowerCase().contains('hostel') || label.toLowerCase().contains('campus')
                                ? Icons.school_rounded
                                : Icons.home_rounded,
                            color: isSelected ? AppColors.primary : AppColors.textMuted,
                          ),
                          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          subtitle: Text(bldg, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
                          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20) : null,
                          onTap: () {
                            setState(() {
                              _activeAddress = '$label ($bldg)';
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceDark,
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text('+ Add New Delivery Address', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddAddressDialog();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddAddressDialog() {
    final labelCtrl = TextEditingController(text: 'Campus Hostel');
    final buildingCtrl = TextEditingController(text: 'Aryabhatta Hall Block B');
    final addressCtrl = TextEditingController(text: 'Campus Road, University Main Gate');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Add Delivery Address', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Address Label (e.g. Hostel, Lab)')),
            const SizedBox(height: 10),
            TextField(controller: buildingCtrl, decoration: const InputDecoration(labelText: 'Building / Room No.')),
            const SizedBox(height: 10),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Full Formatted Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              try {
                await ApiClient.post('/customers/addresses', data: {
                  'label': labelCtrl.text.trim(),
                  'type': 'COLLEGE',
                  'building': buildingCtrl.text.trim(),
                  'formattedAddress': addressCtrl.text.trim(),
                  'location': {'latitude': 12.9716, 'longitude': 77.5946},
                  'isDefault': true,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchCustomerProfile();
                if (mounted) {
                  setState(() {
                    _activeAddress = '${labelCtrl.text.trim()} (${buildingCtrl.text.trim()})';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address added & set as delivering location!'), backgroundColor: AppColors.emerald),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              }
            },
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }

  void _loadAllCatalogAndHotels() async {
    setState(() => _isLoadingDishes = true);
    try {
      final resFuture = ApiClient.get('/restaurants/public');
      final hotelFuture = ApiClient.get('/hotels/public');
      final results = await Future.wait([resFuture, hotelFuture]);

      List<FoodItem> dishes = [];
      Map<String, String> names = {};
      List<Map<String, dynamic>> hotelList = [];

      // 1. Fetch restaurant menus
      if (results[0].data['success'] == true && results[0].data['data'] != null) {
        final rList = results[0].data['data'] as List<dynamic>;
        for (final r in rList) {
          final rId = r['id']?.toString() ?? '';
          final rName = r['businessName']?.toString() ?? 'Kitchen';
          names[rId] = rName;
          try {
            final mRes = await ApiClient.get('/restaurants/public/$rId/menu');
            if (mRes.data['success'] == true && mRes.data['data'] != null) {
              final items = mRes.data['data'] as List<dynamic>;
              dishes.addAll(items.map((e) => FoodItem.fromJson(e as Map<String, dynamic>)));
            }
          } catch (_) {}
        }
      }

      // 2. Fetch hotel menus
      if (results[1].data['success'] == true && results[1].data['data'] != null) {
        final hList = results[1].data['data'] as List<dynamic>;
        hotelList = hList.map((e) => e as Map<String, dynamic>).toList();
        for (final h in hotelList) {
          final hId = h['id']?.toString() ?? '';
          final hName = (h['hotelName'] ?? h['businessName'] ?? 'Hotel').toString();
          names[hId] = hName;
          try {
            final mRes = await ApiClient.get('/hotels/public/$hId/menu');
            if (mRes.data['success'] == true && mRes.data['data'] != null) {
              final items = mRes.data['data'] as List<dynamic>;
              dishes.addAll(items.map((e) => FoodItem.fromJson(e as Map<String, dynamic>)));
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _allDishes = dishes;
          _sourceNames = names;
          _hotels = hotelList;
          _isLoadingDishes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDishes = false);
    }
  }

  List<FoodItem> _getFilteredDishes() {
    if (_selectedCategory == 'All') {
      return _allDishes;
    }
    final cat = _selectedCategory.toLowerCase();
    if (cat.contains('banquet') || cat.contains('catering')) {
      return _allDishes.where((d) => d.isBulkAvailable || (d.category?.toLowerCase().contains('banquet') ?? false)).toList();
    }
    return _allDishes.where((d) {
      final itemCat = (d.category ?? '').toLowerCase();
      final name = d.name.toLowerCase();
      final desc = (d.description ?? '').toLowerCase();
      return itemCat.contains(cat) || name.contains(cat) || desc.contains(cat);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartItemCount = cartState.cart?.items.fold(0, (sum, i) => sum + i.quantity) ?? 0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildExploreView(cartItemCount, cartState.cart?.finalTotal ?? 0),
          const CustomerAiAssistantScreen(),
          CartScreen(onBrowseRestaurants: () => setState(() => _currentIndex = 0)),
          CustomerOrderHistoryScreen(onGoToCart: () => setState(() => _currentIndex = 2)),
          const CustomerProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardDark,
          border: Border(top: BorderSide(color: AppColors.borderDark)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            if (index == 0) {
              _fetchCustomerProfile();
            } else if (index == 2) {
              ref.read(cartProvider.notifier).fetchCart();
            }
          },
          backgroundColor: AppColors.cardDark,
          indicatorColor: AppColors.primary.withOpacity(0.2),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.explore_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.explore_rounded, color: AppColors.primary),
              label: 'Explore',
            ),
            const NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
              label: 'AI Genie',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cartItemCount > 0,
                label: Text('$cartItemCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.shopping_bag_outlined, color: AppColors.textMuted),
              ),
              selectedIcon: Badge(
                isLabelVisible: cartItemCount > 0,
                label: Text('$cartItemCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.shopping_bag_rounded, color: AppColors.primary),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreView(int cartCount, double cartTotal) {
    final homeState = ref.watch(customerProvider);
    final displayedDishes = _getFilteredDishes();

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _showAddressSwitcherBottomSheet,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DELIVERING TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.1)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _activeAddress,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
          ),
        ],
      ),
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.shopping_bag_rounded, color: Colors.white),
              label: Text('$cartCount Items • ₹${cartTotal.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              onPressed: () => setState(() => _currentIndex = 2),
            )
          : null,
      body: homeState.isLoading || _isLoadingDishes
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () async {
                ref.read(customerProvider.notifier).fetchHomeData();
                _loadAllCatalogAndHotels();
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Interactive Search & Voice Assistant Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: const [
                                    Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Search "Biryani", Pizza, Burgers, Banquets...',
                                        style: TextStyle(color: AppColors.textDim, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 22),
                            tooltip: 'Voice Search',
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // AI Food Genie Interactive Assistant Hero Banner
                    InkWell(
                      onTap: () => setState(() => _currentIndex = 1),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE65100), Color(0xFFF57C00), Color(0xFFFFB300)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Row(
                                    children: [
                                      Text('Ask AI Food Genie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                                      SizedBox(width: 6),
                                      Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Tell AI your cravings, budget & mood for instant combos',
                                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // AI Smart Budget Hero Banner
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartBudgetScreen())),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E1065), Color(0xFF4C1D95)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.indigo.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('AI SMART BUDGET', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Got ₹250? We find the best food combinations with zero overflow.', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Food Categories Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Biryani', 'North Indian', 'Banquet Catering', 'Pizza', 'Burgers', 'Desserts', 'Healthy & Bowls', 'Beverages'].map((cat) {
                          final selected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: selected,
                              selectedColor: AppColors.primary,
                              backgroundColor: AppColors.cardDark,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              onSelected: (_) {
                                setState(() => _selectedCategory = cat);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 1. ALL PRODUCTS & DISHES SECTION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedCategory == 'All' ? 'All Dishes & Menus' : '$_selectedCategory Dishes',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${displayedDishes.length} Items',
                            style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (displayedDishes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.fastfood_rounded, size: 40, color: AppColors.textDim),
                              const SizedBox(height: 8),
                              Text('No dishes in "$_selectedCategory"', style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              const Text('Try clicking "All" or browse our partner kitchens below.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...displayedDishes.map((dish) => _buildDishCard(dish)),

                    const SizedBox(height: 28),

                    // 2. Partner Restaurants Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Top Restaurants & Kitchens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        Text('${homeState.restaurants.length} Places', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...homeState.restaurants.map((res) {
                      return _RestaurantCard(
                        restaurant: res,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurant: res)),
                          );
                        },
                      );
                    }),
                    const SizedBox(height: 20),

                    // 3. Partner Hotels & Banquet Caterers Section
                    if (_hotels.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.hotel_rounded, color: AppColors.indigo, size: 20),
                              SizedBox(width: 8),
                              Text('Hotels & Event Banquets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.indigo.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Bulk Catering', style: TextStyle(color: AppColors.indigo, fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ..._hotels.map((hotel) {
                        return _HotelCard(
                          hotel: hotel,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => HotelDetailScreen(hotel: hotel)),
                            );
                          },
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDishCard(FoodItem dish) {
    final sourceName = _sourceNames[dish.restaurantId ?? dish.hotelId ?? ''] ?? 'Campus Kitchen';
    final isHotelPkg = dish.isBulkAvailable;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isHotelPkg ? AppColors.indigo.withOpacity(0.4) : AppColors.borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dish Image / Thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              image: dish.imageUrl != null && dish.imageUrl!.isNotEmpty
                  ? DecorationImage(image: NetworkImage(dish.imageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: dish.imageUrl == null || dish.imageUrl!.isEmpty
                ? Icon(
                    isHotelPkg ? Icons.groups_rounded : Icons.fastfood_rounded,
                    color: dish.isVeg ? AppColors.emerald : AppColors.rose,
                    size: 26,
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // Dish Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: dish.isVeg ? AppColors.emerald : AppColors.rose),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        dish.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isHotelPkg ? AppColors.indigo.withOpacity(0.15) : AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sourceName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isHotelPkg ? AppColors.indigo : AppColors.primaryLight,
                        ),
                      ),
                    ),
                    if (isHotelPkg) ...[
                      const SizedBox(width: 6),
                      Text('Min ${dish.bulkMinQuantity ?? 10} pers', style: const TextStyle(fontSize: 10, color: AppColors.amber, fontWeight: FontWeight.w700)),
                    ] else ...[
                      const SizedBox(width: 6),
                      Text('${dish.preparationTimeMinutes} mins', style: const TextStyle(fontSize: 10, color: AppColors.textDim)),
                    ],
                  ],
                ),
                if (dish.description != null && dish.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dish.description!,
                    style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${(dish.bulkPrice ?? dish.price).toInt()}${isHotelPkg ? ' / person' : ''}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isHotelPkg ? AppColors.indigo : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        minimumSize: const Size(64, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final qty = dish.isBulkAvailable ? (dish.bulkMinQuantity ?? 5) : 1;
                        final success = await ref.read(cartProvider.notifier).addToCart(
                              foodItemId: dish.id,
                              quantity: qty,
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

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon thumbnail
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.businessName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: AppColors.emerald),
                              const SizedBox(width: 2),
                              Text('${restaurant.rating}', style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w800, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.cuisineTypes.join(' • '),
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '~${restaurant.preparationTimeMinutes} mins • ₹${restaurant.averageCostForTwo.toInt()} for two',
                      style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  final Map<String, dynamic> hotel;
  final VoidCallback onTap;

  const _HotelCard({required this.hotel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = hotel['hotelName'] ?? hotel['businessName'] ?? 'Grand Hotel';
    final starRating = hotel['starRating'] ?? 4;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.indigo.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon thumbnail
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.indigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hotel_rounded, color: AppColors.indigo, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                              const SizedBox(width: 2),
                              Text('$starRating ★', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w800, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotel['description'] ?? 'Event catering, student bulk thalis & banquet delivery',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(4)),
                          child: const Text('Bulk Catering Available', style: TextStyle(color: AppColors.indigo, fontSize: 10, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 8),
                        const Text('Campus Delivery', style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
