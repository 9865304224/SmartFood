import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../orders/order_tracking_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBrowseRestaurants;

  const CartScreen({super.key, this.onBrowseRestaurants});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();
  bool _isEcoDelivery = true;
  String _selectedPaymentMethod = 'MOCK_DEV';
  bool _isCheckingOut = false;

  Map<String, dynamic> _deliveryAddress = {
    'id': 'addr-1',
    'label': 'College Campus Hostel',
    'type': 'COLLEGE',
    'building': 'Aryabhatta Hall Block B',
    'formattedAddress': 'Aryabhatta Hall, Campus Rd, Bengaluru',
    'location': {'latitude': 12.9716, 'longitude': 77.5946},
    'isCurrent': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(cartProvider.notifier).fetchCart();
      }
    });
  }

  void _useCurrentLocation() {
    setState(() {
      _deliveryAddress = {
        'id': 'addr-current-gps',
        'label': 'Current GPS Location',
        'type': 'CURRENT_LOCATION',
        'building': 'Live GPS Location (12.9716° N, 77.5946° E)',
        'formattedAddress': 'Indiranagar / Campus Main Hub, Bengaluru',
        'location': {'latitude': 12.9716, 'longitude': 77.5946},
        'isCurrent': true,
      };
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('📍 Locked delivery to Current GPS Address!'),
          ],
        ),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  void _showAddressDialog() {
    final labelCtrl = TextEditingController(text: _deliveryAddress['label']);
    final buildingCtrl = TextEditingController(text: _deliveryAddress['building']);
    final addressCtrl = TextEditingController(text: _deliveryAddress['formattedAddress']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Change Delivery Address', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick 1-tap Current Location Chip
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _useCurrentLocation();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.my_location_rounded, color: AppColors.emerald, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '📍 Use Current GPS Location',
                        style: TextStyle(color: AppColors.emeraldLight, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Address Label (e.g. Hostel, Office)')),
            const SizedBox(height: 10),
            TextField(controller: buildingCtrl, decoration: const InputDecoration(labelText: 'Building / Room / Floor')),
            const SizedBox(height: 10),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Complete Street Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              setState(() {
                _deliveryAddress = {
                  'id': 'addr-custom',
                  'label': labelCtrl.text.trim().isNotEmpty ? labelCtrl.text.trim() : 'Custom Address',
                  'type': 'CUSTOM',
                  'building': buildingCtrl.text.trim(),
                  'formattedAddress': addressCtrl.text.trim(),
                  'location': {'latitude': 12.9716, 'longitude': 77.5946},
                  'isCurrent': false,
                };
              });
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Address'),
          ),
        ],
      ),
    );
  }

  void _handleCheckout() async {
    final cart = ref.read(cartProvider).cart;
    if (cart == null || cart.items.isEmpty) return;

    setState(() => _isCheckingOut = true);
    try {
      final res = await ApiClient.post(ApiConstants.orderCheckout, data: {
        'deliveryAddress': _deliveryAddress,
        'paymentMethod': _selectedPaymentMethod,
        'couponCode': cart.appliedCouponCode,
        'specialInstructions': 'Deliver at specified location',
        'isEcoDelivery': _isEcoDelivery,
      });

      if (res.data['success'] == true && res.data['data'] != null) {
        final order = OrderModel.fromJson(res.data['data']);
        await ref.read(cartProvider.notifier).clearCart();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message'] ?? 'Failed to place order')),
        );
      }
    } catch (e) {
      String msg = e.toString();
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: $msg'),
          backgroundColor: AppColors.rose,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cart = cartState.cart;

    if (cartState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Cart')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (cart == null || cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Cart')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textDim),
              const SizedBox(height: 16),
              const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Add delicious meals or catering packages to get started', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.restaurant_rounded, size: 18),
                label: const Text('Browse Restaurants & Hotels', style: TextStyle(fontWeight: FontWeight.w800)),
                onPressed: () {
                  if (widget.onBrowseRestaurants != null) {
                    widget.onBrowseRestaurants!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(cart.businessName ?? 'My Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rose),
            onPressed: () => ref.read(cartProvider.notifier).clearCart(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Items List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: cart.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: item.isVeg ? AppColors.emerald : AppColors.rose,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text('₹${item.price.toInt()}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        // Quantity +/-
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: () {
                                  ref.read(cartProvider.notifier).updateQuantity(item.foodItemId, item.quantity - 1);
                                },
                              ),
                              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w800)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: () {
                                  ref.read(cartProvider.notifier).updateQuantity(item.foodItemId, item.quantity + 1);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Coupon Code Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined, color: AppColors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Enter Coupon (SMART50 / WELCOME100)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_couponController.text.isNotEmpty) {
                        ref.read(cartProvider.notifier).applyCoupon(_couponController.text.trim());
                      }
                    },
                    child: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Eco-Delivery Option Toggle
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.emerald.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.eco_rounded, color: AppColors.emerald, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Eco-Friendly Delivery', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.emeraldLight)),
                        Text('Group with nearby campus routes to reduce CO2', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isEcoDelivery,
                    activeColor: AppColors.emerald,
                    onChanged: (v) => setState(() => _isEcoDelivery = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Delivery Location & Current Address Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _deliveryAddress['isCurrent'] == true ? AppColors.emerald : AppColors.borderDark,
                  width: _deliveryAddress['isCurrent'] == true ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _deliveryAddress['isCurrent'] == true ? Icons.my_location_rounded : Icons.location_on_rounded,
                            color: _deliveryAddress['isCurrent'] == true ? AppColors.emerald : AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text('DELIVERY DESTINATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textDim, letterSpacing: 0.8)),
                        ],
                      ),
                      if (_deliveryAddress['isCurrent'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('GPS Live', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emeraldLight)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(_deliveryAddress['label'] ?? 'Address', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(_deliveryAddress['building'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  Text(_deliveryAddress['formattedAddress'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.emerald,
                            side: const BorderSide(color: AppColors.emerald),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.my_location_rounded, size: 16),
                          label: const Text('Use Current Location', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                          onPressed: _useCurrentLocation,
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_location_alt_rounded, size: 16, color: AppColors.primary),
                        label: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        onPressed: _showAddressDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bill Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bill Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const Divider(color: AppColors.borderDark, height: 20),
                  _BillRow(label: 'Item Total', value: '₹${cart.subtotal.toStringAsFixed(1)}'),
                  _BillRow(label: 'Delivery Fee', value: '₹${cart.deliveryFee.toStringAsFixed(1)}'),
                  _BillRow(label: 'Platform Fee', value: '₹${cart.platformFee.toStringAsFixed(1)}'),
                  _BillRow(label: 'GST & Taxes', value: '₹${cart.taxes.toStringAsFixed(1)}'),
                  if (cart.discount > 0)
                    _BillRow(
                      label: 'Discount (${cart.appliedCouponCode})',
                      value: '-₹${cart.discount.toStringAsFixed(1)}',
                      isDiscount: true,
                    ),
                  const Divider(color: AppColors.borderDark, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('To Pay', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      Text(
                        '₹${cart.finalTotal.toStringAsFixed(1)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Place Order Button
            ElevatedButton(
              onPressed: _isCheckingOut ? null : _handleCheckout,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isCheckingOut
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Place Order • ₹${cart.finalTotal.toStringAsFixed(1)}'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDiscount;

  const _BillRow({required this.label, required this.value, this.isDiscount = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isDiscount ? AppColors.emerald : AppColors.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isDiscount ? FontWeight.w700 : FontWeight.w500,
              color: isDiscount ? AppColors.emerald : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
