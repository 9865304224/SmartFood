import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'delivery_navigation_screen.dart';

class DeliveryDashboardScreen extends ConsumerStatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  ConsumerState<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends ConsumerState<DeliveryDashboardScreen> {
  int _currentIndex = 0;
  List<OrderModel> _assignedOrders = [];
  List<OrderModel> _availableOrders = [];
  List<OrderModel> _historyOrders = [];
  Map<String, dynamic>? _riderProfile;
  bool _isLoading = true;
  bool _isLoadingPool = false;
  bool _isLoadingHistory = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchAllDeliveryData();
      }
    });
  }

  void _fetchAllDeliveryData() {
    _fetchProfile();
    _fetchAssignedOrders();
    _fetchAvailableOrders();
    _fetchHistory();
  }

  void _fetchProfile() async {
    try {
      final res = await ApiClient.get(ApiConstants.deliveryProfile);
      if (res.data['success'] == true && res.data['data'] != null) {
        final data = res.data['data'] as Map<String, dynamic>;
        setState(() {
          _riderProfile = data;
          _isOnline = (data['currentStatus'] != 'OFFLINE');
        });
      }
    } catch (_) {}
  }

  void _fetchAssignedOrders() async {
    try {
      setState(() => _isLoading = true);
      final res = await ApiClient.get(ApiConstants.deliveryActiveOrders);
      if (res.data['success'] == true && res.data['data'] != null) {
        final list = res.data['data'] as List<dynamic>;
        setState(() {
          _assignedOrders = list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fetchAvailableOrders() async {
    try {
      setState(() => _isLoadingPool = true);
      final res = await ApiClient.get(ApiConstants.deliveryAvailableOrders);
      if (res.data['success'] == true && res.data['data'] != null) {
        final list = res.data['data'] as List<dynamic>;
        setState(() {
          _availableOrders = list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
          _isLoadingPool = false;
        });
      } else {
        setState(() => _isLoadingPool = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPool = false);
    }
  }

  void _fetchHistory() async {
    try {
      setState(() => _isLoadingHistory = true);
      final res = await ApiClient.get(ApiConstants.deliveryHistory);
      if (res.data['success'] == true && res.data['data'] != null) {
        final list = res.data['data'] as List<dynamic>;
        setState(() {
          _historyOrders = list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
          _isLoadingHistory = false;
        });
      } else {
        setState(() => _isLoadingHistory = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _claimOrder(String orderId) async {
    try {
      final res = await ApiClient.post('/delivery/orders/$orderId/claim');
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Order Claimed! You are now the assigned delivery partner.'),
            backgroundColor: AppColors.emerald,
          ),
        );
        setState(() => _currentIndex = 0);
        _fetchAssignedOrders();
        _fetchAvailableOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message'] ?? 'Could not claim order')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error claiming order: $e')));
    }
  }

  void _updateStatus(String orderId, String newStatus) async {
    try {
      await ApiClient.patch('${ApiConstants.orders}/$orderId/status', data: {
        'status': newStatus,
        'note': 'Driver updated state to $newStatus',
      });
      _fetchAssignedOrders();
      _fetchHistory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _toggleOnlineStatus(bool online) async {
    try {
      setState(() => _isOnline = online);
      await ApiClient.put(
        ApiConstants.deliveryStatus,
        queryParameters: {'status': online ? 'AVAILABLE' : 'OFFLINE'},
      );
      _fetchProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(online ? '🟢 You are now ONLINE & receiving delivery orders!' : '🔴 You are now OFFLINE'),
            backgroundColor: online ? AppColors.emerald : AppColors.rose,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status update failed: $e')));
    }
  }

  void _showOtpDialog(OrderModel order) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: AppColors.primaryLight, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Verify #${order.orderNumber}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 4-digit code provided by ${order.customerName ?? "Customer"}:',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 8, color: AppColors.primaryLight),
              decoration: const InputDecoration(hintText: '0000', counterText: ''),
            ),
            const SizedBox(height: 10),
            if (order.deliveryOtp.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.amber, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Customer OTP: ${order.deliveryOtp} (Demo fallback: 0000)',
                        style: const TextStyle(fontSize: 11, color: AppColors.amber, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
            onPressed: () async {
              final otpCode = otpController.text.trim();
              if (otpCode.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter the complete 4-digit OTP')),
                );
                return;
              }
              try {
                final res = await ApiClient.post(
                  '${ApiConstants.orders}/${order.id}/verify-otp',
                  queryParameters: {'otp': otpCode},
                  data: {'otp': otpCode},
                );
                if (res.data['success'] == true) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchAssignedOrders();
                  _fetchHistory();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Delivery Confirmed via OTP! Earnings credited to your wallet.'),
                        backgroundColor: AppColors.emerald,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res.data['message'] ?? 'Invalid OTP code'), backgroundColor: AppColors.rose),
                  );
                }
              } catch (e) {
                String errMsg = 'OTP Verification Failed: $e';
                if (e is DioException && e.response?.data != null) {
                  errMsg = e.response?.data['message'] ?? errMsg;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errMsg), backgroundColor: AppColors.rose),
                );
              }
            },
            child: const Text('Verify & Complete Delivery', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showEditRiderProfileDialog() async {
    final user = ref.read(authProvider);
    final prof = _riderProfile;
    final nameCtrl = TextEditingController(text: prof?['fullName'] ?? user.name ?? 'Rahul Verma');
    final phoneCtrl = TextEditingController(text: prof?['phone'] ?? '9876543215');
    final vehicleNumCtrl = TextEditingController(text: prof?['vehicleNumber'] ?? 'KA-01-AB-1234');
    final licenseCtrl = TextEditingController(text: prof?['drivingLicenseNumber'] ?? 'DL-KA-2019-009182');
    String selectedVehicle = prof?['vehicleType'] ?? 'MOTORCYCLE';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Edit Delivery Rider Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Rider Full Name', prefixIcon: Icon(Icons.person_outline_rounded)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedVehicle,
                  decoration: const InputDecoration(labelText: 'Vehicle Fleet Type', prefixIcon: Icon(Icons.electric_scooter_rounded)),
                  dropdownColor: AppColors.cardDark,
                  items: const [
                    DropdownMenuItem(value: 'MOTORCYCLE', child: Text('🏍️ Petrol Motorcycle')),
                    DropdownMenuItem(value: 'ELECTRIC_VEHICLE', child: Text('⚡ EV Scooter (Green Fleet)')),
                    DropdownMenuItem(value: 'BICYCLE', child: Text('🚲 Campus Bicycle (Zero CO2)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedVehicle = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vehicleNumCtrl,
                  decoration: const InputDecoration(labelText: 'Vehicle Number (Plate)', prefixIcon: Icon(Icons.pin_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: licenseCtrl,
                  decoration: const InputDecoration(labelText: 'Driving License No.', prefixIcon: Icon(Icons.badge_outlined)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                try {
                  final updateRes = await ApiClient.put(ApiConstants.deliveryProfile, data: {
                    'fullName': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'vehicleType': selectedVehicle,
                    'vehicleNumber': vehicleNumCtrl.text.trim(),
                    'drivingLicenseNumber': licenseCtrl.text.trim(),
                  });
                  if (updateRes.data['success'] == true) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchProfile();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rider profile updated!'), backgroundColor: AppColors.emerald),
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_riderProfile?['fullName'] ?? user.name ?? 'Delivery Partner', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isOnline ? AppColors.emerald : AppColors.rose,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isOnline ? 'ONLINE & ACTIVE' : 'OFFLINE',
                  style: TextStyle(fontSize: 10, color: _isOnline ? AppColors.emeraldLight : AppColors.rose, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAllDeliveryData,
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Active Assigned Deliveries
          _buildActiveOrdersView(),

          // Tab 1: Available Orders Pool
          _buildAvailableOrdersPoolView(),

          // Tab 2: Earnings & History
          _buildEarningsHistoryView(),

          // Tab 3: Rider Profile & Status
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
            if (index == 0) _fetchAssignedOrders();
            if (index == 1) _fetchAvailableOrders();
            if (index == 2) _fetchHistory();
          },
          backgroundColor: AppColors.cardDark,
          indicatorColor: AppColors.primary.withOpacity(0.2),
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _assignedOrders.isNotEmpty,
                label: Text('${_assignedOrders.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.two_wheeler_outlined, color: AppColors.textMuted),
              ),
              selectedIcon: Badge(
                isLabelVisible: _assignedOrders.isNotEmpty,
                label: Text('${_assignedOrders.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary),
              ),
              label: 'Active (${_assignedOrders.length})',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: _availableOrders.isNotEmpty,
                label: Text('${_availableOrders.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                backgroundColor: AppColors.amber,
                child: const Icon(Icons.local_shipping_outlined, color: AppColors.textMuted),
              ),
              selectedIcon: Badge(
                isLabelVisible: _availableOrders.isNotEmpty,
                label: Text('${_availableOrders.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                backgroundColor: AppColors.amber,
                child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary),
              ),
              label: 'Available Pool',
            ),
            const NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.textMuted),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
              label: 'Earnings',
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

  // --- 1. ACTIVE DELIVERIES TAB ---
  Widget _buildActiveOrdersView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_assignedOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delivery_dining_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text('No Active Deliveries Assigned', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'When orders are placed, our AI automatically assigns them to you. You can also claim open orders directly from the Available Pool!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                icon: const Icon(Icons.local_shipping_rounded, size: 18),
                label: const Text('View Available Orders Pool', style: TextStyle(fontWeight: FontWeight.w800)),
                onPressed: () {
                  setState(() => _currentIndex = 1);
                  _fetchAvailableOrders();
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignedOrders.length,
      itemBuilder: (context, idx) {
        final order = _assignedOrders[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 1.5),
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
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status.replaceAll('_', ' '),
                      style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Restaurant Pickup Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: AppColors.amber, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PICKUP RESTAURANT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textDim, letterSpacing: 0.8)),
                          const SizedBox(height: 2),
                          Text(order.businessName ?? 'Partner Kitchen / Hotel', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          const Text('Kitchen Pickup Hub • Order Packed', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Customer Delivery Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.emerald, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DELIVER TO CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textDim, letterSpacing: 0.8)),
                          const SizedBox(height: 2),
                          Text(order.customerName ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          const Text('Campus Hostel / University Gate Block B', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Live GPS Turn-by-Turn Navigation Launcher Button
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeliveryNavigationScreen(
                        order: order,
                        onOrderUpdated: _fetchAssignedOrders,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open Live GPS Turn-by-Turn Map',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                            Text(
                              'Live route polyline, distance & ETA guidance',
                              style: TextStyle(color: Colors.white70, fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ),

              const Divider(color: AppColors.borderDark, height: 24),

              // Items Summary
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

              const Divider(color: AppColors.borderDark, height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery Payout', style: TextStyle(fontSize: 10, color: AppColors.textDim, fontWeight: FontWeight.w700)),
                      Text('₹${(order.deliveryFee * 0.8).toInt()} (Earned)', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.emeraldLight)),
                    ],
                  ),

                  // Action Buttons based on status
                  if (order.status == 'DELIVERY_ASSIGNED')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                      icon: const Icon(Icons.inventory_2_rounded, size: 16),
                      label: const Text('Confirm Pickup from Kitchen', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                      onPressed: () => _updateStatus(order.id, 'PICKED_UP'),
                    )
                  else if (order.status == 'PICKED_UP')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                      icon: const Icon(Icons.motorcycle_rounded, size: 16),
                      label: const Text('Start Out for Delivery', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                      onPressed: () => _updateStatus(order.id, 'OUT_FOR_DELIVERY'),
                    )
                  else if (order.status == 'OUT_FOR_DELIVERY')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                      icon: const Icon(Icons.pin_rounded, size: 18),
                      label: const Text('🔑 Enter Customer OTP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      onPressed: () => _showOtpDialog(order),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 2. AVAILABLE ORDERS POOL TAB ---
  Widget _buildAvailableOrdersPoolView() {
    if (_isLoadingPool) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_availableOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.inventory_rounded, size: 64, color: AppColors.textDim),
              SizedBox(height: 16),
              Text('No Open Orders in Pool', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text('As soon as new orders are placed by customers, they will appear here for you to claim.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableOrders.length,
      itemBuilder: (context, idx) {
        final order = _availableOrders[idx];
        final payout = (order.deliveryFee * 0.8).toInt();

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
                  Text('#${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text('WAITING FOR RIDER', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w800, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Pickup: ${order.businessName ?? "Partner Kitchen"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const Text('Delivery: Campus Hostel / Academic Block', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Text('${order.items.length} items • Bill: ₹${order.finalTotal.toInt()}', style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
              const Divider(color: AppColors.borderDark, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payout: ₹$payout', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.emeraldLight)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('🚴 Accept & Claim Delivery', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    onPressed: () => _claimOrder(order.id),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 3. EARNINGS & HISTORY TAB ---
  Widget _buildEarningsHistoryView() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final totalDeliveries = _historyOrders.where((o) => o.status == 'DELIVERED').length;
    final totalEarnings = _historyOrders.where((o) => o.status == 'DELIVERED').fold(0.0, (sum, o) => sum + (o.deliveryFee * 0.8));

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
                  const Text('COMPLETED DELIVERIES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textDim, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text('$totalDeliveries', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.emeraldLight)),
                ],
              ),
              Container(width: 1, height: 35, color: AppColors.borderDark),
              Column(
                children: [
                  const Text('WALLET EARNINGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textDim, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text('₹${totalEarnings.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryLight)),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: _historyOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textDim),
                      SizedBox(height: 16),
                      Text('No delivery history recorded yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 6),
                      Text('Your completed and delivered orders will be archived here.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _historyOrders.length,
                  itemBuilder: (context, idx) {
                    final order = _historyOrders[idx];
                    final dateFormatted = order.createdAt != null
                        ? DateFormat('dd MMM, hh:mm a').format(order.createdAt!)
                        : 'Recently';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('#${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.emerald.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text('✓ ${order.status.replaceAll('_', ' ')}', style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w800, fontSize: 10)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Date: $dateFormatted', style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                          const SizedBox(height: 4),
                          Text('Delivered to: ${order.customerName ?? "Customer"}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const Divider(color: AppColors.borderDark, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Bill Total: ₹${order.finalTotal.toInt()}', style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
                              Text('Payout: ₹${(order.deliveryFee * 0.8).toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.emeraldLight)),
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

  // --- 4. RIDER PROFILE & STATUS TAB ---
  Widget _buildProfileView(dynamic user) {
    final prof = _riderProfile;
    final name = prof?['fullName'] ?? user.name ?? 'Rahul Verma';
    final phone = prof?['phone'] ?? '9876543215';
    final vehicleType = prof?['vehicleType'] ?? 'MOTORCYCLE';
    final vehicleNum = prof?['vehicleNumber'] ?? 'KA-01-AB-1234';
    final license = prof?['drivingLicenseNumber'] ?? 'DL-KA-2019-009182';
    final rating = prof?['rating'] ?? 4.9;

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
                      Text('★ $rating Driver Rating • Verified Rider', style: const TextStyle(fontSize: 12, color: AppColors.amber, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isOnline ? AppColors.emerald.withOpacity(0.2) : AppColors.rose.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isOnline ? '🟢 ON DUTY (ONLINE)' : '🔴 OFF DUTY (OFFLINE)',
                          style: TextStyle(color: _isOnline ? AppColors.emeraldLight : AppColors.rose, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Online / Offline Switch
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isOnline ? AppColors.emerald : AppColors.borderDark),
            ),
            child: SwitchListTile(
              title: const Text('Duty Status (Receive Orders)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              subtitle: Text(
                _isOnline ? 'You are receiving delivery orders in real time.' : 'Turn on to start receiving delivery orders.',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              value: _isOnline,
              activeColor: AppColors.emerald,
              onChanged: _toggleOnlineStatus,
            ),
          ),
          const SizedBox(height: 16),

          // Vehicle & License Card
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
                    const Text('Rider & Vehicle Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryLight, size: 24),
                      tooltip: 'Edit Profile',
                      onPressed: _showEditRiderProfileDialog,
                    ),
                  ],
                ),
                const Divider(color: AppColors.borderDark, height: 16),
                _buildProfileRow(Icons.phone_outlined, 'Contact Phone', phone),
                _buildProfileRow(Icons.two_wheeler_rounded, 'Vehicle Fleet', vehicleType),
                _buildProfileRow(Icons.pin_outlined, 'Plate Number', vehicleNum),
                _buildProfileRow(Icons.badge_outlined, 'Driving License', license),
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
            label: const Text('Edit Rider Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            onPressed: _showEditRiderProfileDialog,
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
