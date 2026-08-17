import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class DeliveryNavigationScreen extends StatefulWidget {
  final OrderModel order;
  final VoidCallback? onOrderUpdated;

  const DeliveryNavigationScreen({
    super.key,
    required this.order,
    this.onOrderUpdated,
  });

  @override
  State<DeliveryNavigationScreen> createState() => _DeliveryNavigationScreenState();
}

class _DeliveryNavigationScreenState extends State<DeliveryNavigationScreen> {
  final MapController _mapController = MapController();
  late OrderModel _currentOrder;

  // GPS Coordinates
  late LatLng _riderLoc;
  late LatLng _restaurantLoc;
  late LatLng _customerLoc;

  bool _isNavigating = true;
  Timer? _gpsSimulationTimer;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;

    _restaurantLoc = LatLng(_currentOrder.pickupLat, _currentOrder.pickupLng);
    _customerLoc = LatLng(_currentOrder.deliveryLat, _currentOrder.deliveryLng);

    // Initial rider position near restaurant or en route
    _riderLoc = LatLng(
      _currentOrder.driverLat != 0 ? _currentOrder.driverLat : _restaurantLoc.latitude - 0.003,
      _currentOrder.driverLng != 0 ? _currentOrder.driverLng : _restaurantLoc.longitude - 0.002,
    );

    _startLiveGpsTracking();
  }

  @override
  void dispose() {
    _gpsSimulationTimer?.cancel();
    super.dispose();
  }

  void _startLiveGpsTracking() {
    // Smoothly simulate rider movement towards destination
    _gpsSimulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      final target = _currentOrder.status == 'DELIVERY_ASSIGNED' ? _restaurantLoc : _customerLoc;

      setState(() {
        final latDelta = (target.latitude - _riderLoc.latitude) * 0.15;
        final lngDelta = (target.longitude - _riderLoc.longitude) * 0.15;

        _riderLoc = LatLng(_riderLoc.latitude + latDelta, _riderLoc.longitude + lngDelta);
      });

      // Update map center smoothly
      if (_isNavigating) {
        _mapController.move(_riderLoc, 16.0);
      }
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final res = await ApiClient.patch(
        '${ApiConstants.orders}/${_currentOrder.id}/status',
        data: {
          'status': newStatus,
          'note': 'Driver updated state to $newStatus',
        },
        queryParameters: {'status': newStatus},
      );

      if (res.data['success'] == true) {
        setState(() {
          if (res.data['data'] != null) {
            _currentOrder = OrderModel.fromJson(res.data['data']);
          }
        });
        widget.onOrderUpdated?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order status updated to: ${newStatus.replaceAll('_', ' ')}'),
              backgroundColor: AppColors.emerald,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.data['message'] ?? 'Failed to update status'),
              backgroundColor: AppColors.rose,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            msg = data['message'].toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status update error: $msg'),
            backgroundColor: AppColors.rose,
          ),
        );
      }
    }
  }

  void _showOtpDialog() {
    final otpCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Verify Delivery OTP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ask customer for the 4-digit secret delivery PIN shown on their screen:', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            const SizedBox(height: 14),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 8, color: AppColors.primary),
              decoration: InputDecoration(
                hintText: '••••',
                counterText: '',
                fillColor: AppColors.surfaceDark,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald),
            onPressed: () async {
              final code = otpCtrl.text.trim();
              if (code.length != 4) return;

              try {
                final res = await ApiClient.post(
                  '${ApiConstants.orders}/${_currentOrder.id}/verify-otp',
                  queryParameters: {'otp': code},
                  data: {'otp': code},
                );

                if (res.data['success'] == true) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  widget.onOrderUpdated?.call();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🎉 Order Delivered Successfully! Delivery Fee credited.'), backgroundColor: AppColors.emerald),
                    );
                    Navigator.pop(context);
                  }
                } else {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(res.data['message'] ?? 'Invalid OTP code!'), backgroundColor: AppColors.rose),
                    );
                  }
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Verify & Complete Delivery', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGoingToPickup = _currentOrder.status == 'DELIVERY_ASSIGNED';
    final destinationTitle = isGoingToPickup ? (_currentOrder.businessName ?? 'Pickup Kitchen') : (_currentOrder.customerName ?? 'Customer Dropoff');
    final destinationSub = isGoingToPickup ? 'Kitchen Food Pickup Hub' : 'Campus Hostel Block B, Main Gate';
    final targetLoc = isGoingToPickup ? _restaurantLoc : _customerLoc;

    final distanceKm = const Distance().as(LengthUnit.Meter, _riderLoc, targetLoc) / 1000.0;
    final etaMins = (distanceKm * 3.5).ceil().clamp(1, 45);

    // Route points
    final routePoints = [
      _riderLoc,
      LatLng((_riderLoc.latitude + targetLoc.latitude) / 2 + 0.0005, (_riderLoc.longitude + targetLoc.longitude) / 2 - 0.0004),
      targetLoc,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Turn-by-Turn GPS Navigation', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            Text('Order #${_currentOrder.orderNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isNavigating ? Icons.my_location_rounded : Icons.location_searching_rounded, color: AppColors.primary),
            tooltip: 'Recenter on Rider',
            onPressed: () {
              setState(() => _isNavigating = true);
              _mapController.move(_riderLoc, 16.0);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _riderLoc,
              initialZoom: 15.5,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _isNavigating) {
                  setState(() => _isNavigating = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartfood.delivery',
              ),

              // Navigation Route Polyline
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 5.0,
                    color: AppColors.primary,
                  ),
                ],
              ),

              // Markers
              MarkerLayer(
                markers: [
                  // Restaurant Marker
                  Marker(
                    point: _restaurantLoc,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.black, size: 26),
                    ),
                  ),

                  // Customer Marker
                  Marker(
                    point: _customerLoc,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                    ),
                  ),

                  // Rider Marker (Live Pulsing)
                  Marker(
                    point: _riderLoc,
                    width: 55,
                    height: 55,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 12, spreadRadius: 3),
                        ],
                      ),
                      child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top Turn-by-Turn Instruction Banner
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.turn_right_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGoingToPickup ? 'Head towards Pickup Restaurant' : 'Proceed to Customer Address',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          destinationTitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          destinationSub,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primary),
                        ),
                        Text(
                          '$etaMins min',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textDim, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Control HUD
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderDark),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speed_rounded, size: 16, color: AppColors.emerald),
                          const SizedBox(width: 6),
                          const Text('Live GPS: 24 km/h', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.emeraldLight)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _currentOrder.status.replaceAll('_', ' '),
                          style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w800, fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderDark, height: 20),

                  // Actions depending on order status
                  if (_currentOrder.status == 'DELIVERY_ASSIGNED')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 46),
                      ),
                      icon: const Icon(Icons.inventory_2_rounded, size: 18),
                      label: const Text('Confirm Food Pickup from Kitchen', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      onPressed: () => _updateStatus('PICKED_UP'),
                    )
                  else if (_currentOrder.status == 'PICKED_UP')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 46),
                      ),
                      icon: const Icon(Icons.two_wheeler_rounded, size: 18),
                      label: const Text('Start Out for Customer Delivery', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      onPressed: () => _updateStatus('OUT_FOR_DELIVERY'),
                    )
                  else if (_currentOrder.status == 'OUT_FOR_DELIVERY')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 46),
                      ),
                      icon: const Icon(Icons.pin_rounded, size: 20),
                      label: const Text('🔑 Enter Customer Delivery OTP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      onPressed: _showOtpDialog,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
