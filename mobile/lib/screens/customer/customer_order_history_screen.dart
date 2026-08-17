import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/order_model.dart';
import '../../providers/cart_provider.dart';
import '../orders/order_tracking_screen.dart';

class CustomerOrderHistoryScreen extends ConsumerStatefulWidget {
  final VoidCallback? onGoToCart;

  const CustomerOrderHistoryScreen({super.key, this.onGoToCart});

  @override
  ConsumerState<CustomerOrderHistoryScreen> createState() => _CustomerOrderHistoryScreenState();
}

class _CustomerOrderHistoryScreenState extends ConsumerState<CustomerOrderHistoryScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get('/customers/orders');
      if (res.data['success'] == true && res.data['data'] != null) {
        final list = res.data['data'] as List<dynamic>;
        setState(() {
          _orders = list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PLACED':
        return AppColors.amber;
      case 'ACCEPTED':
      case 'PREPARING':
        return AppColors.indigo;
      case 'READY_FOR_PICKUP':
      case 'DELIVERY_ASSIGNED':
      case 'PICKED_UP':
      case 'OUT_FOR_DELIVERY':
        return AppColors.primary;
      case 'DELIVERED':
        return AppColors.emerald;
      case 'CANCELLED':
      case 'REJECTED':
        return AppColors.rose;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = _orders.where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED' && o.status != 'REJECTED').toList();
    final pastOrders = _orders.where((o) => o.status == 'DELIVERED' || o.status == 'CANCELLED' || o.status == 'REJECTED').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders & History', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              color: AppColors.primary,
              child: _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: AppColors.cardDark, shape: BoxShape.circle),
                            child: const Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          const Text('No Orders Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          const Text('Order delicious meals & track live delivery here.', style: TextStyle(color: AppColors.textDim, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      children: [
                        // Active Orders Section
                        if (activeOrders.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppColors.emerald, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text('LIVE ACTIVE ORDERS (${activeOrders.length})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.emerald, letterSpacing: 1.0)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...activeOrders.map((order) => _buildActiveOrderCard(order)),
                          const SizedBox(height: 24),
                        ],

                        // Past Orders Section
                        if (pastOrders.isNotEmpty) ...[
                          const Text('PAST ORDERS & INVOICES',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1.0)),
                          const SizedBox(height: 10),
                          ...pastOrders.map((order) => _buildPastOrderCard(order)),
                        ],
                      ],
                    ),
            ),
    );
  }

  Widget _buildActiveOrderCard(OrderModel order) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Order # and Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(order.businessName ?? 'Partner Kitchen', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    order.status.replaceAll('_', ' '),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.borderDark, height: 20),

            // OTP Box - Prominently displayed so customer can tell delivery boy
            if (order.deliveryOtp.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pin_rounded, color: AppColors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SECRET DELIVERY OTP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.amber)),
                          const Text('Share with delivery rider at your doorstep:', style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.amber),
                      ),
                      child: Text(
                        order.deliveryOtp,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.amber, letterSpacing: 2.0),
                      ),
                    ),
                  ],
                ),
              ),

            // Item summary
            Text(
              order.items.map((i) => '${i.quantity}x ${i.foodName}').join(', '),
              style: const TextStyle(fontSize: 13, color: AppColors.textDim),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Bottom Actions: Price & Track Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ₹${order.finalTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 16),
                  label: const Text('Live Track Map', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastOrderCard(OrderModel order) {
    final isDelivered = order.status == 'DELIVERED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.businessName ?? 'Partner Kitchen', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDelivered ? AppColors.emerald.withOpacity(0.15) : AppColors.rose.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isDelivered ? '✓ Delivered' : order.status,
                    style: TextStyle(
                      color: isDelivered ? AppColors.emerald : AppColors.rose,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order.items.map((i) => '${i.quantity}x ${i.foodName}').join(', '),
              style: const TextStyle(fontSize: 12, color: AppColors.textDim),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${order.finalTotal.toInt()} • ${order.paymentMethod}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textMuted)),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 14),
                  label: const Text('Reorder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  onPressed: () async {
                    if (order.items.isNotEmpty) {
                      final item = order.items.first;
                      await ref.read(cartProvider.notifier).addToCart(
                            foodItemId: item.foodItemId,
                            quantity: item.quantity,
                            restaurantId: order.restaurantId ?? '',
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added ${item.foodName} to cart!'), backgroundColor: AppColors.emerald),
                        );
                        widget.onGoToCart?.call();
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
