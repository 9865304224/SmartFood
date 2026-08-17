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

class HotelDashboardScreen extends ConsumerStatefulWidget {
  const HotelDashboardScreen({super.key});

  @override
  ConsumerState<HotelDashboardScreen> createState() => _HotelDashboardScreenState();
}

class _HotelDashboardScreenState extends ConsumerState<HotelDashboardScreen> {
  int _currentIndex = 0;
  List<OrderModel> _orders = [];
  List<FoodItem> _bulkItems = [];
  Map<String, dynamic>? _hotelProfile;
  bool _isLoadingOrders = true;
  bool _isLoadingMenu = true;
  bool _isLoadingProfile = true;
  String? _hotelId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchHotelData();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _fetchHotelData() {
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
      final profileRes = await ApiClient.get(ApiConstants.hotelProfile);
      if (profileRes.data['success'] == true && profileRes.data['data'] != null) {
        final profData = profileRes.data['data'] as Map<String, dynamic>;
        _hotelId = profData['id']?.toString();
        setState(() {
          _hotelProfile = profData;
          _isLoadingProfile = false;
        });

        if (_hotelId != null) {
          final menuRes = await ApiClient.get('${ApiConstants.publicHotels}/$_hotelId/packages');
          if (menuRes.data['success'] == true && menuRes.data['data'] != null) {
            final list = menuRes.data['data'] as List<dynamic>;
            setState(() {
              _bulkItems = list.map((e) => FoodItem.fromJson(e as Map<String, dynamic>)).toList();
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
        'note': 'Status updated to $newStatus by hotel banquet kitchen',
      });
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'ACCEPTED' ? 'Bulk Catering Order Accepted!' : 'Order status updated to $newStatus'),
            backgroundColor: AppColors.emerald,
          ),
        );
        _fetchOrders();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showEditHotelProfileDialog() {
    final prof = _hotelProfile;
    final nameCtrl = TextEditingController(text: prof?['hotelName'] ?? 'The Grand Palace Resort & Banquet');
    final descCtrl = TextEditingController(text: prof?['description'] ?? '5-Star luxury dining & bulk institutional catering with custom chef menus.');
    final managerCtrl = TextEditingController(text: prof?['managerName'] ?? 'Chef Rajesh Verma');
    final phoneCtrl = TextEditingController(text: prof?['phone'] ?? '9876543213');
    final addressCtrl = TextEditingController(text: prof?['address'] ?? '42 Palace Road, Vasanth Nagar, Bengaluru');
    final discountCtrl = TextEditingController(text: (prof?['bulkDiscountPercentage'] ?? 15.0).toString());
    final minOrderCtrl = TextEditingController(text: (prof?['minBulkOrderValue'] ?? 1500.0).toString());
    bool banquetAvailable = prof?['banquetAvailable'] ?? true;
    bool requiresAdvanceNotice = prof?['requiresAdvanceNotice'] ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Edit Hotel Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Hotel / Resort Name', prefixIcon: Icon(Icons.hotel_rounded)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: managerCtrl,
                          decoration: const InputDecoration(labelText: 'Manager / Chef', prefixIcon: Icon(Icons.person_outline)),
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
                    decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: discountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Bulk Discount (%)', prefixIcon: Icon(Icons.percent_rounded)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: minOrderCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Min Bulk Order (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Banquet / Catering Available', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    value: banquetAvailable,
                    activeColor: AppColors.emerald,
                    onChanged: (v) => setDialogState(() => banquetAvailable = v),
                  ),
                  SwitchListTile(
                    title: const Text('Requires 2hr Advance Notice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    value: requiresAdvanceNotice,
                    activeColor: AppColors.emerald,
                    onChanged: (v) => setDialogState(() => requiresAdvanceNotice = v),
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
                  final updateRes = await ApiClient.put(ApiConstants.hotelProfile, data: {
                    'hotelName': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'managerName': managerCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'address': addressCtrl.text.trim(),
                    'bulkDiscountPercentage': double.tryParse(discountCtrl.text) ?? 15.0,
                    'minBulkOrderValue': double.tryParse(minOrderCtrl.text) ?? 1500.0,
                    'banquetAvailable': banquetAvailable,
                    'requiresAdvanceNotice': requiresAdvanceNotice,
                  });
                  if (updateRes.data['success'] == true) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchHotelData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hotel profile updated!'), backgroundColor: AppColors.emerald),
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

  void _showAddBulkPackageDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final prepCtrl = TextEditingController(text: '45');
    final imgCtrl = TextEditingController();
    String selectedCategory = 'Buffet Packages';
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
              Text('Add Bulk Catering Package', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                    decoration: const InputDecoration(labelText: 'Package / Buffet Name *', hintText: 'e.g. Grand Campus Feast (Serves 10)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price (₹) *', hintText: '1999'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: prepCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Prep (mins)', hintText: '45'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: AppColors.cardDark,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['Buffet Packages', 'Party Platters', 'Executive Lunch Box', 'Banquet Specials', 'Dessert Platters']
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
                    decoration: const InputDecoration(labelText: 'Package Details', hintText: 'Complete royal buffet meal with starters, main course, and dessert...'),
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
                            const Text('Package Photo (Cloudinary)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDim)),
                            if (isUploadingImage)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

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
                                        'folder': 'packages',
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
                                          imgCtrl.text = 'https://images.unsplash.com/photo-1555244162-803834f70033?w=600';
                                          uploadedPreviewUrl = imgCtrl.text;
                                          isUploadingImage = false;
                                        });
                                      }
                                    }
                                  } catch (e) {
                                    setDialogState(() {
                                      imgCtrl.text = 'https://images.unsplash.com/photo-1555244162-803834f70033?w=600';
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
                            hintText: 'https://res.cloudinary.com/.../package.jpg',
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
                      final prep = int.tryParse(prepCtrl.text.trim()) ?? 45;
                      final desc = descCtrl.text.trim();
                      final img = imgCtrl.text.trim();

                      if (name.isEmpty || price == null || price <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid package name and price')),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        final res = await ApiClient.post(ApiConstants.hotelPackages, data: {
                          'name': name,
                          'price': price,
                          'description': desc.isNotEmpty ? desc : 'Grand royal buffet catering package designed for parties and campus gatherings.',
                          'preparationTimeMinutes': prep,
                          'category': selectedCategory,
                          'isVeg': isVeg,
                          'imageUrl': img.isNotEmpty ? img : 'https://images.unsplash.com/photo-1555244162-803834f70033?w=600',
                          'isAvailable': true,
                        });

                        if (res.data['success'] == true) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          _fetchProfileAndMenu();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('🎉 $name package added!'), backgroundColor: AppColors.emerald),
                            );
                          }
                        } else {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res.data['message'] ?? 'Failed to add package')),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding package: $e')));
                      }
                    },
              child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add Package'),
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
            Text(_hotelProfile?['hotelName'] ?? user.name ?? 'Hotel Banquet Operations', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const Text('HOTEL & BULK CATERING HUB', style: TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.w700)),
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
            label: const Text('+ Add Package', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            onPressed: _showAddBulkPackageDialog,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchHotelData,
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
              label: const Text('Add Package', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              onPressed: _showAddBulkPackageDialog,
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 1. Live Kitchen Orders
          _buildLiveOrdersView(activeOrders),

          // 2. Order History
          _buildOrderHistoryView(deliveredOrders),

          // 3. Menu & Packages
          _buildMenuProductsView(),

          // 4. Analytics
          _buildAnalyticsView(deliveredOrders),

          // 5. Hotel Profile
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
              icon: Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.inventory_2_rounded, color: AppColors.primary),
              label: 'Packages',
            ),
            const NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.primary),
              label: 'Analytics',
            ),
            const NavigationDestination(
              icon: Icon(Icons.hotel_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.hotel_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveOrdersView(List<OrderModel> activeOrders) {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.room_service_outlined, size: 64, color: AppColors.textDim),
            SizedBox(height: 16),
            Text('No active bulk orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('New institutional catering orders will appear here.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                'Host / Customer: ${order.customerName ?? "Customer"} (${order.customerPhone ?? "9876543210"})',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const Divider(color: AppColors.borderDark, height: 20),

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
                  Text('Total: ₹${order.finalTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),

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
                      label: const Text('Catering Ready for Pickup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      onPressed: () => _updateStatus(order.id, 'READY_FOR_PICKUP'),
                    )
                  else if (order.status == 'READY_FOR_PICKUP')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.amber)),
                      child: const Text('⏳ AI Assigning Delivery Van...', style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w800)),
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
                      child: const Text('🚀 Catering Out for Delivery', style: TextStyle(color: AppColors.indigo, fontSize: 11, fontWeight: FontWeight.w800)),
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

  Widget _buildOrderHistoryView(List<OrderModel> deliveredOrders) {
    final totalSales = deliveredOrders.fold(0.0, (sum, o) => sum + o.finalTotal);

    return Column(
      children: [
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
                  const Text('COMPLETED CATERING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textDim, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text('${deliveredOrders.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.emeraldLight)),
                ],
              ),
              Container(width: 1, height: 35, color: AppColors.borderDark),
              Column(
                children: [
                  const Text('CATERING REVENUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textDim, letterSpacing: 0.8)),
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
                      Text('No completed catering history yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 6),
                      Text('Fulfilled banquet orders will be archived here.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                          Text('Fulfilled on $dateFormatted', style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                          const SizedBox(height: 8),
                          Text('Host: ${order.customerName ?? "Customer"}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                              Text('Total: ₹${order.finalTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.emeraldLight)),
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

  Widget _buildMenuProductsView() {
    if (_isLoadingMenu) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_bulkItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textDim),
            const SizedBox(height: 16),
            const Text('No bulk catering packages listed yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Catering Package'),
              onPressed: _showAddBulkPackageDialog,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bulkItems.length,
      itemBuilder: (context, idx) {
        final item = _bulkItems[idx];
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
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: item.imageUrl == null || item.imageUrl!.isEmpty
                    ? Icon(Icons.restaurant_rounded, color: item.isVeg ? AppColors.emerald : AppColors.rose)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: item.isVeg ? AppColors.emerald : AppColors.rose),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category ?? "Bulk Catering"} • ~${item.preparationTimeMinutes} mins',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text('₹${item.price.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primaryLight)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rose, size: 20),
                onPressed: () async {
                  try {
                    await ApiClient.delete('${ApiConstants.hotelPackages}/${item.id}');
                    _fetchProfileAndMenu();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package removed')));
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

  Widget _buildAnalyticsView(List<OrderModel> deliveredOrders) {
    final totalRevenue = deliveredOrders.fold(0.0, (sum, o) => sum + o.finalTotal);
    final avgTicket = deliveredOrders.isNotEmpty ? totalRevenue / deliveredOrders.length : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      const Text('Total Catering Sales', style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w700)),
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
                      const Text('Fulfilled Banquets', style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w700)),
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
                      const Text('Avg Catering Ticket', style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w700)),
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
                      Text('${_hotelProfile?['rating'] ?? "4.9"} ★', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('Banquet Rating', style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Top Catering Packages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (_bulkItems.isEmpty)
            const Text('Add packages to track catering analytics', style: TextStyle(color: AppColors.textMuted))
          else
            ..._bulkItems.take(5).map((dish) {
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
                      child: const Text('🏆 POPULAR', style: TextStyle(color: AppColors.primaryLight, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildProfileView(dynamic user) {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    final prof = _hotelProfile;
    final name = prof?['hotelName'] ?? user.name ?? 'The Grand Palace Resort & Banquet';
    final desc = prof?['description'] ?? '5-Star luxury dining & bulk institutional catering with custom chef menus.';
    final manager = prof?['managerName'] ?? 'Chef Rajesh Verma';
    final phone = prof?['phone'] ?? '9876543213';
    final address = prof?['address'] ?? '42 Palace Road, Vasanth Nagar, Bengaluru';
    final discount = prof?['bulkDiscountPercentage'] ?? 15.0;
    final minOrder = prof?['minBulkOrderValue'] ?? 1500.0;
    final banquetAvailable = prof?['banquetAvailable'] ?? true;
    final notice = prof?['requiresAdvanceNotice'] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                              color: banquetAvailable ? AppColors.emerald.withOpacity(0.2) : AppColors.rose.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              banquetAvailable ? '🟢 BANQUET ACTIVE' : '🔴 UNAVAILABLE',
                              style: TextStyle(color: banquetAvailable ? AppColors.emeraldLight : AppColors.rose, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (notice)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('⏳ 2HR ADVANCE', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w800)),
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
                    const Text('Hotel & Banquet Operations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryLight, size: 24),
                      tooltip: 'Edit Profile',
                      onPressed: _showEditHotelProfileDialog,
                    ),
                  ],
                ),
                const Divider(color: AppColors.borderDark, height: 16),
                _buildProfileRow(Icons.person_outline, 'Manager / Executive Chef', manager),
                _buildProfileRow(Icons.phone_outlined, 'Contact Phone', phone),
                _buildProfileRow(Icons.location_on_outlined, 'Venue Address', address),
                _buildProfileRow(Icons.percent_rounded, 'Bulk Discount', '$discount% off'),
                _buildProfileRow(Icons.currency_rupee_rounded, 'Min Order Value', '₹${minOrder.toInt()}'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit Hotel Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            onPressed: _showEditHotelProfileDialog,
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
