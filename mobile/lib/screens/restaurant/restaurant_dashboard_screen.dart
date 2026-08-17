import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/food_item_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class RestaurantDashboardScreen extends ConsumerStatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  ConsumerState<RestaurantDashboardScreen> createState() => _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends ConsumerState<RestaurantDashboardScreen> {
  int _currentIndex = 0;
  List<OrderModel> _orders = [];
  List<FoodItem> _menuItems = [];
  Map<String, dynamic>? _restaurantProfile;
  bool _isLoadingOrders = true;
  bool _isLoadingMenu = true;
  bool _isLoadingProfile = true;
  String? _restaurantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchRestaurantData();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _fetchRestaurantData() async {
    _fetchOrders();
    _fetchProfileAndMenu();
  }

  void _fetchOrders() async {
    try {
      setState(() => _isLoadingOrders = true);
      final res = await ApiClient.get(ApiConstants.restaurantOrders);
      if (res.data['success'] == true && res.data['data'] != null) {
        final list = res.data['data'] as List<dynamic>;
        setState(() {
          _orders = list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
          _isLoadingOrders = false;
        });
      } else {
        setState(() => _isLoadingOrders = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  void _fetchProfileAndMenu() async {
    try {
      setState(() {
        _isLoadingMenu = true;
        _isLoadingProfile = true;
      });
      final profileRes = await ApiClient.get(ApiConstants.restaurantProfile);
      if (profileRes.data['success'] == true && profileRes.data['data'] != null) {
        final profData = profileRes.data['data'] as Map<String, dynamic>;
        _restaurantId = profData['id']?.toString();
        setState(() {
          _restaurantProfile = profData;
          _isLoadingProfile = false;
        });

        if (_restaurantId != null) {
          final menuRes = await ApiClient.get('${ApiConstants.publicRestaurants}/$_restaurantId/menu');
          if (menuRes.data['success'] == true && menuRes.data['data'] != null) {
            final list = menuRes.data['data'] as List<dynamic>;
            setState(() {
              _menuItems = list.map((e) => FoodItem.fromJson(e as Map<String, dynamic>)).toList();
              _isLoadingMenu = false;
            });
            return;
          }
        }
      }
      if (mounted) {
        setState(() {
          _isLoadingMenu = false;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMenu = false;
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _updateStatus(String orderId, String newStatus) async {
    try {
      final res = await ApiClient.patch('${ApiConstants.orders}/$orderId/status', data: {
        'status': newStatus,
        'note': 'Status updated to $newStatus by restaurant kitchen',
      });
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'ACCEPTED' ? 'Order Accepted! Kitchen notified.' : 'Order status updated to $newStatus'),
            backgroundColor: AppColors.emerald,
          ),
        );
        _fetchOrders();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showEditRestaurantProfileDialog() async {
    final prof = _restaurantProfile;
    final nameCtrl = TextEditingController(text: prof?['businessName'] ?? 'Paradise Royal Biryani');
    final descCtrl = TextEditingController(text: prof?['description'] ?? 'Authentic royal Mughlai spices and fresh campus delivery');
    final ownerCtrl = TextEditingController(text: prof?['ownerName'] ?? 'Mohammad Tariq');
    final phoneCtrl = TextEditingController(text: prof?['phone'] ?? '9876543212');
    final addressCtrl = TextEditingController(text: prof?['address'] ?? '104 Brigade Road, Bengaluru');
    final prepCtrl = TextEditingController(text: (prof?['preparationTimeMinutes'] ?? 20).toString());
    final costCtrl = TextEditingController(text: (prof?['averageCostForTwo'] ?? 400).toString());
    bool isPureVeg = prof?['isPureVeg'] ?? false;
    bool isOpen = prof?['isOpen'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Edit Restaurant Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Restaurant / Business Name', prefixIcon: Icon(Icons.storefront_rounded)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Short Description', prefixIcon: Icon(Icons.description_outlined)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ownerCtrl,
                          decoration: const InputDecoration(labelText: 'Owner Name', prefixIcon: Icon(Icons.person_outline)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Kitchen Address', prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: prepCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Avg Prep (mins)', prefixIcon: Icon(Icons.timer_outlined)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: costCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Cost for 2 (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Open for Orders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    value: isOpen,
                    activeColor: AppColors.emerald,
                    onChanged: (v) => setDialogState(() => isOpen = v),
                  ),
                  SwitchListTile(
                    title: const Text('100% Pure Vegetarian', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    value: isPureVeg,
                    activeColor: AppColors.emerald,
                    onChanged: (v) => setDialogState(() => isPureVeg = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                try {
                  final updateRes = await ApiClient.put(ApiConstants.restaurantProfile, data: {
                    'businessName': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'ownerName': ownerCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                    'preparationTimeMinutes': int.tryParse(prepCtrl.text) ?? 20,
                    'averageCostForTwo': double.tryParse(costCtrl.text) ?? 300,
                    'isOpen': isOpen,
                    'isPureVeg': isPureVeg,
                  });
                  if (updateRes.data['success'] == true) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchRestaurantData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Restaurant profile updated!'), backgroundColor: AppColors.emerald),
                      );
                    }
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                  }
                }
              },
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final prepCtrl = TextEditingController(text: '20');
    final imgCtrl = TextEditingController();
    String selectedCategory = 'Biryani';
    bool isVeg = false;
    bool isSaving = false;
    bool isUploadingImage = false;
    String? uploadedPreviewUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Row(
            children: const [
              Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Add New Dish / Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Dish Name *', hintText: 'e.g. Royal Chicken Dum Biryani'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price (₹) *', hintText: '250'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: prepCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Prep Time (mins)', hintText: '20'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: AppColors.cardDark,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['Biryani', 'North Indian', 'South Indian', 'Pizza', 'Burgers', 'Starters', 'Desserts', 'Healthy & Bowls', 'Beverages']
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => selectedCategory = val ?? selectedCategory),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Dietary Type:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Veg'),
                        selected: isVeg,
                        selectedColor: AppColors.emerald,
                        onSelected: (v) => setDialogState(() => isVeg = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Non-Veg'),
                        selected: !isVeg,
                        selectedColor: AppColors.rose,
                        onSelected: (v) => setDialogState(() => isVeg = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description', hintText: 'Fragrant basmati rice cooked with authentic spices...'),
                  ),
                  const SizedBox(height: 16),

                  // Mobile Photo Upload to Cloudinary Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Dish Photo (Cloudinary)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDim)),
                            if (isUploadingImage)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Image Preview if uploaded
                        if (uploadedPreviewUrl != null && uploadedPreviewUrl!.isNotEmpty)
                          Container(
                            height: 120,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(image: NetworkImage(uploadedPreviewUrl!), fit: BoxFit.cover),
                              border: Border.all(color: AppColors.emerald, width: 1.5),
                            ),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 12),
                                    SizedBox(width: 4),
                                    Text('Cloudinary Uploaded', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cardDark,
                            foregroundColor: AppColors.primaryLight,
                            side: const BorderSide(color: AppColors.primary, width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                          label: Text(
                            isUploadingImage ? 'Uploading Image to Cloudinary...' : '📷 Pick from Device & Upload to Cloudinary',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          onPressed: isUploadingImage
                              ? null
                              : () async {
                                  try {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                                    if (picked != null) {
                                      setDialogState(() => isUploadingImage = true);
                                      final bytes = await picked.readAsBytes();
                                      final formData = dio.FormData.fromMap({
                                        'file': dio.MultipartFile.fromBytes(bytes, filename: picked.name),
                                        'folder': 'dishes',
                                      });

                                      final uploadRes = await ApiClient.post(
                                        '/upload/image',
                                        data: formData,
                                      );

                                      if (uploadRes.data['success'] == true && uploadRes.data['data'] != null) {
                                        final uploadedUrl = uploadRes.data['data']['url']?.toString() ?? '';
                                        setDialogState(() {
                                          imgCtrl.text = uploadedUrl;
                                          uploadedPreviewUrl = uploadedUrl;
                                          isUploadingImage = false;
                                        });
                                      } else {
                                        setDialogState(() {
                                          imgCtrl.text = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600';
                                          uploadedPreviewUrl = imgCtrl.text;
                                          isUploadingImage = false;
                                        });
                                      }
                                    }
                                  } catch (e) {
                                    setDialogState(() {
                                      imgCtrl.text = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600';
                                      uploadedPreviewUrl = imgCtrl.text;
                                      isUploadingImage = false;
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: imgCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cloudinary Image URL',
                            hintText: 'https://res.cloudinary.com/.../dish.jpg',
                            prefixIcon: Icon(Icons.cloud_upload_outlined, size: 18),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            setDialogState(() => uploadedPreviewUrl = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final price = double.tryParse(priceCtrl.text.trim());
                      final prep = int.tryParse(prepCtrl.text.trim()) ?? 20;
                      final desc = descCtrl.text.trim();
                      final img = imgCtrl.text.trim();

                      if (name.isEmpty || price == null || price <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid dish name and price')),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        final res = await ApiClient.post(ApiConstants.restaurantMenu, data: {
                          'name': name,
                          'price': price,
                          'description': desc.isNotEmpty ? desc : 'Freshly prepared royal dish crafted with authentic culinary spices.',
                          'preparationTimeMinutes': prep,
                          'category': selectedCategory,
                          'isVeg': isVeg,
                          'imageUrl': img.isNotEmpty ? img : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
                          'isAvailable': true,
                        });

                        if (res.data['success'] == true) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          _fetchProfileAndMenu();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('🎉 $name added to menu!'), backgroundColor: AppColors.emerald),
                            );
                          }
                        } else {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res.data['message'] ?? 'Failed to add dish')),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding dish: $e')));
                      }
                    },
              child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add to Menu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final activeOrders = _orders.where((o) => o.status != 'DELIVERED').toList();
    final deliveredOrders = _orders.where((o) => o.status == 'DELIVERED').toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_restaurantProfile?['businessName'] ?? user.name ?? 'Restaurant Kitchen', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const Text('PARTNER OPERATIONS PORTAL', style: TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('+ Add Dish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            onPressed: _showAddProductDialog,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchRestaurantData,
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
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add Dish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              onPressed: _showAddProductDialog,
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 1. Live Kitchen Orders Tab
          _buildLiveOrdersView(activeOrders),

          // 2. Order History Tab
          _buildOrderHistoryView(deliveredOrders),

          // 3. Menu & Products Management Tab
          _buildMenuProductsView(),

          // 4. Analytics & Revenue Insights Tab
          _buildAnalyticsView(deliveredOrders),

          // 5. Restaurant Profile Tab
          _buildProfileView(user),
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
            if (index == 0) _fetchOrders();
            if (index == 2) _fetchProfileAndMenu();
          },
          backgroundColor: AppColors.cardDark,
          indicatorColor: AppColors.primary.withOpacity(0.2),
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: activeOrders.isNotEmpty,
                label: Text('${activeOrders.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.soup_kitchen_outlined, color: AppColors.textMuted),
              ),
              selectedIcon: Badge(
                isLabelVisible: activeOrders.isNotEmpty,
                label: Text('${activeOrders.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.soup_kitchen_rounded, color: AppColors.primary),
              ),
              label: 'Kitchen',
            ),
            const NavigationDestination(
              icon: Icon(Icons.history_rounded, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.history_rounded, color: AppColors.primary),
              label: 'History',
            ),
            const NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.restaurant_menu_rounded, color: AppColors.primary),
              label: 'Products',
            ),
            const NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.primary),
              label: 'Analytics',
            ),
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.storefront_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. LIVE KITCHEN ORDERS TAB ---
  Widget _buildLiveOrdersView(List<OrderModel> activeOrders) {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.soup_kitchen_outlined, size: 64, color: AppColors.textDim),
            SizedBox(height: 16),
            Text('No active kitchen orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('New customer orders will appear here in real time.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeOrders.length,
      itemBuilder: (context, idx) {
        final order = activeOrders[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: order.status == 'PLACED' ? AppColors.primary : AppColors.borderDark,
              width: order.status == 'PLACED' ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.status == 'PLACED'
                          ? AppColors.primary.withOpacity(0.2)
                          : order.status == 'ACCEPTED'
                              ? AppColors.amber.withOpacity(0.2)
                              : AppColors.emerald.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: order.status == 'PLACED'
                            ? AppColors.primary
                            : order.status == 'ACCEPTED'
                                ? AppColors.amber
                                : AppColors.emerald,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Customer: ${order.customerName ?? "Customer"} (${order.customerPhone ?? "9876543210"})',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const Divider(color: AppColors.borderDark, height: 20),

              // Items Ordered
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: item.isVeg ? AppColors.emerald : AppColors.rose),
                            const SizedBox(width: 8),
                            Text('${item.quantity}x ${item.foodName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Text('₹${item.itemTotal.toInt()}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                  )),

              const Divider(color: AppColors.borderDark, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bill Total: ₹${order.finalTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),

                  // Status Progression Action Buttons
                  if (order.status == 'PLACED')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text('Accept Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      onPressed: () => _updateStatus(order.id, 'ACCEPTED'),
                    )
                  else if (order.status == 'ACCEPTED')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                      icon: const Icon(Icons.soup_kitchen_rounded, size: 16, color: Colors.black),
                      label: const Text('Start Cooking', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.black)),
                      onPressed: () => _updateStatus(order.id, 'PREPARING'),
                    )
                  else if (order.status == 'PREPARING')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                      icon: const Icon(Icons.inventory_2_rounded, size: 16),
                      label: const Text('Food Ready for Pickup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      onPressed: () => _updateStatus(order.id, 'READY_FOR_PICKUP'),
                    )
                  else if (order.status == 'READY_FOR_PICKUP')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.amber)),
                      child: const Text('⏳ AI Assigning Delivery Rider...', style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w800)),
                    )
                  else if (order.status == 'DELIVERY_ASSIGNED')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary)),
                      child: Text('🚴 ${order.deliveryPersonName ?? 'Rider'} Assigned (Pickup)', style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w800)),
                    )
                  else if (order.status == 'PICKED_UP' || order.status == 'OUT_FOR_DELIVERY')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.indigo.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.indigo)),
                      child: const Text('🚀 Out for Delivery with Rider', style: TextStyle(color: AppColors.indigo, fontSize: 11, fontWeight: FontWeight.w800)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.emerald.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.emerald)),
                      child: const Text('✓ Delivered', style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 2. ORDER HISTORY TAB ---
  Widget _buildOrderHistoryView(List<OrderModel> deliveredOrders) {
    final totalSales = deliveredOrders.fold(0.0, (sum, o) => sum + o.finalTotal);

    return Column(
      children: [
        // Summary Banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('DELIVERED ORDERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textDim, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text('${deliveredOrders.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.emeraldLight)),
                ],
              ),
              Container(width: 1, height: 35, color: AppColors.borderDark),
              Column(
                children: [
                  const Text('COMPLETED REVENUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textDim, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text('₹${totalSales.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryLight)),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: deliveredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textDim),
                      SizedBox(height: 16),
                      Text('No completed order history yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 6),
                      Text('Delivered customer orders will be archived here.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: deliveredOrders.length,
                  itemBuilder: (context, idx) {
                    final order = deliveredOrders[idx];
                    final dateFormatted = order.createdAt != null
                        ? DateFormat('dd MMM, hh:mm a').format(order.createdAt!)
                        : 'Recently';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('#${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('✓ DELIVERED', style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w800, fontSize: 10)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Completed on $dateFormatted', style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                          const SizedBox(height: 8),
                          Text('Customer: ${order.customerName ?? "Customer"}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const Divider(color: AppColors.borderDark, height: 16),
                          ...order.items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${item.quantity}x ${item.foodName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    Text('₹${item.itemTotal.toInt()}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),
                              )),
                          const Divider(color: AppColors.borderDark, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payment: ${order.paymentMethod}', style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                              Text('Total Earned: ₹${order.finalTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.emeraldLight)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- 3. MENU & PRODUCTS TAB ---
  Widget _buildMenuProductsView() {
    if (_isLoadingMenu) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu_rounded, size: 64, color: AppColors.textDim),
            const SizedBox(height: 16),
            const Text('No dishes in your menu yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Dish'),
              onPressed: _showAddProductDialog,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _menuItems.length,
      itemBuilder: (context, idx) {
        final food = _menuItems[idx];
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
              // Dish Thumbnail
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  image: food.imageUrl != null && food.imageUrl!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(food.imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: food.imageUrl == null || food.imageUrl!.isEmpty
                    ? Icon(Icons.fastfood_rounded, color: food.isVeg ? AppColors.emerald : AppColors.rose)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: food.isVeg ? AppColors.emerald : AppColors.rose),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${food.category ?? "General"} • ~${food.preparationTimeMinutes} mins',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text('₹${food.price.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primaryLight)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rose, size: 20),
                onPressed: () async {
                  try {
                    await ApiClient.delete('${ApiConstants.restaurantMenu}/${food.id}');
                    _fetchProfileAndMenu();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dish removed from menu')));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 4. ANALYTICS & INSIGHTS TAB ---
  Widget _buildAnalyticsView(List<OrderModel> deliveredOrders) {
    final totalRevenue = deliveredOrders.fold(0.0, (sum, o) => sum + o.finalTotal);
    final avgTicket = deliveredOrders.isNotEmpty ? totalRevenue / deliveredOrders.length : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Grid
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.currency_rupee_rounded, color: AppColors.primaryLight, size: 24),
                      const SizedBox(height: 10),
                      Text('₹${totalRevenue.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('Total Net Revenue', style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.emerald, size: 24),
                      const SizedBox(height: 10),
                      Text('${deliveredOrders.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('Fulfilled Deliveries', style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppColors.amber, size: 24),
                      const SizedBox(height: 10),
                      Text('₹${avgTicket.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('Avg Order Value (AOV)', style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.amber, size: 24),
                      const SizedBox(height: 10),
                      Text('${_restaurantProfile?['rating'] ?? "4.8"} ★', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('Storefront Rating', style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Menu Performance Breakdown
          const Text('Top Performing Dishes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (_menuItems.isEmpty)
            const Text('Add products to track individual dish analytics', style: TextStyle(color: AppColors.textMuted))
          else
            ..._menuItems.take(5).map((dish) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up_rounded, color: AppColors.emerald, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dish.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('${dish.category ?? "Popular"} • ₹${dish.price.toInt()}', style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text('🔥 HIGH DEMAND', style: TextStyle(color: AppColors.primaryLight, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // --- 5. RESTAURANT PROFILE TAB ---
  Widget _buildProfileView(dynamic user) {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    final prof = _restaurantProfile;
    final name = prof?['businessName'] ?? user.name ?? 'Paradise Royal Biryani';
    final desc = prof?['description'] ?? 'Authentic royal Mughlai spices and fresh campus delivery';
    final owner = prof?['ownerName'] ?? 'Mohammad Tariq';
    final phone = prof?['phone'] ?? '9876543212';
    final address = prof?['address'] ?? '104 Brigade Road, Bengaluru';
    final prep = prof?['preparationTimeMinutes'] ?? 20;
    final cost = prof?['averageCostForTwo'] ?? 400;
    final isOpen = prof?['isOpen'] ?? true;
    final isPureVeg = prof?['isPureVeg'] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Center(
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primaryLight),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOpen ? AppColors.emerald.withOpacity(0.2) : AppColors.rose.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOpen ? '🟢 OPEN FOR ORDERS' : '🔴 CLOSED',
                              style: TextStyle(color: isOpen ? AppColors.emeraldLight : AppColors.rose, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isPureVeg)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('🌱 100% PURE VEG', style: TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.w800)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Business Details Card
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Business & Kitchen Info', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryLight, size: 24),
                      tooltip: 'Edit Profile',
                      onPressed: _showEditRestaurantProfileDialog,
                    ),
                  ],
                ),
                const Divider(color: AppColors.borderDark, height: 16),
                _buildProfileRow(Icons.person_outline, 'Manager / Owner', owner),
                _buildProfileRow(Icons.phone_outlined, 'Contact Phone', phone),
                _buildProfileRow(Icons.location_on_outlined, 'Kitchen Address', address),
                _buildProfileRow(Icons.timer_outlined, 'Avg Prep Time', '$prep mins'),
                _buildProfileRow(Icons.currency_rupee_rounded, 'Avg Cost For Two', '₹$cost'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit Restaurant Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            onPressed: _showEditRestaurantProfileDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textDim),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
          const Spacer(),
          Flexible(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
