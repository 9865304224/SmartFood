import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/order_model.dart';
import '../customer/customer_home_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  Timer? _pollingTimer;

  // Map Coordinates
  LatLng _customerLoc = const LatLng(12.9716, 77.5946);
  LatLng _restaurantLoc = const LatLng(12.9730, 77.6070);
  LatLng _driverLoc = const LatLng(12.9725, 77.6050);

  @override
  void initState() {
    super.initState();
    _fetchOrder();
    // Poll order status and live driver coordinates every 4 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchOrder());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _fetchOrder() async {
    try {
      final res = await ApiClient.get('${ApiConstants.orders}/${widget.orderId}');
      if (res.data['success'] == true && res.data['data'] != null) {
        final order = OrderModel.fromJson(res.data['data']);
        setState(() {
          _order = order;
          _isLoading = false;
          _restaurantLoc = LatLng(order.pickupLat, order.pickupLng);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Tracking')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final isDelivered = _order!.status == 'DELIVERED';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order!.orderNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
              (r) => false,
            );
          },
        ),
      ),
      body: Column(
        children: [
          // 1. FlutterMap OpenStreetMap Interactive View
          Expanded(
            flex: 4,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _restaurantLoc,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.smartfood.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_restaurantLoc, _driverLoc, _customerLoc],
                      strokeWidth: 4.0,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Restaurant Marker
                    Marker(
                      point: _restaurantLoc,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.rose,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    // Delivery Driver Marker
                    Marker(
                      point: _driverLoc,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                          ],
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    // Customer Drop Marker
                    Marker(
                      point: _customerLoc,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.emerald,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Bottom Order Tracking Details
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Delivery OTP Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.emerald.withOpacity(0.25), AppColors.cyan.withOpacity(0.15)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.emerald.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('DELIVERY OTP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emeraldLight, letterSpacing: 1.2)),
                              SizedBox(height: 2),
                              Text('Share with rider on delivery', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _order!.deliveryOtp,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 3, color: AppColors.emeraldLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDelivered ? AppColors.emerald.withOpacity(0.2) : AppColors.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDelivered ? Icons.check_circle_rounded : Icons.delivery_dining_rounded,
                            color: isDelivered ? AppColors.emerald : AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _order!.status.replaceAll('_', ' '),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              Text(
                                isDelivered ? 'Delivered successfully' : 'Arriving in approx ~25 mins',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Driver Profile & Call Card
                    if (_order!.deliveryPersonName != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.surfaceDark,
                              child: Icon(Icons.person_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_order!.deliveryPersonName!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  Text('SmartFood Delivery Partner • ⭐ 4.9', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone_rounded, color: AppColors.emerald),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
