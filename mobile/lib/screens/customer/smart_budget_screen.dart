import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/smart_budget_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_provider.dart';
import 'cart_screen.dart';

class SmartBudgetScreen extends ConsumerStatefulWidget {
  const SmartBudgetScreen({super.key});

  @override
  ConsumerState<SmartBudgetScreen> createState() => _SmartBudgetScreenState();
}

class _SmartBudgetScreenState extends ConsumerState<SmartBudgetScreen> {
  double _budget = 250.0;
  bool _vegOnly = false;
  bool _isSearching = false;
  List<BudgetComboOptionModel> _results = [];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  void _performSearch() async {
    setState(() => _isSearching = true);
    final results = await ref.read(customerProvider.notifier).searchSmartBudget(_budget, vegOnly: _vegOnly);
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Budget Discovery'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AI Header Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.2), AppColors.amber.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AI Budget Guarantee',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your exact spending limit. We guarantee the final cart total (Food + Delivery + GST - Discounts) will stay within your budget.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Budget Slider & Numeric Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your Total Budget:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        '₹${_budget.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary),
                      ),
                    ],
                  ),
                  Slider(
                    value: _budget,
                    min: 100,
                    max: 600,
                    divisions: 50,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceDark,
                    onChanged: (val) {
                      setState(() => _budget = val);
                    },
                    onChangeEnd: (val) {
                      _performSearch();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _vegOnly,
                            activeColor: AppColors.emerald,
                            onChanged: (val) {
                              setState(() => _vegOnly = val ?? false);
                              _performSearch();
                            },
                          ),
                          const Text('Veg Only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        children: [150, 250, 350, 500].map((quick) {
                          final selected = _budget.toInt() == quick;
                          return ChoiceChip(
                            label: Text('₹$quick'),
                            selected: selected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceDark,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (sel) {
                              if (sel) {
                                setState(() => _budget = quick.toDouble());
                                _performSearch();
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Results Section
            Text(
              'Recommended Combos Under ₹${_budget.toInt()}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            if (_isSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_results.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: const Text('No food combinations found under this budget. Try increasing budget slightly.'),
              )
            else
              ..._results.map((combo) => _BudgetComboCard(combo: combo)),
          ],
        ),
      ),
    );
  }
}

class _BudgetComboCard extends ConsumerWidget {
  final BudgetComboOptionModel combo;

  const _BudgetComboCard({required this.combo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Expanded(
                child: Text(
                  combo.comboTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                ),
                child: Text(
                  '₹${combo.grandTotal.toInt()} All-in',
                  style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${combo.restaurantName} • ${combo.restaurantDistanceKm} km away',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          // Items inside combo
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: combo.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: item.isVeg ? AppColors.emerald : AppColors.rose,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      Text('₹${item.price.toInt()}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),
          // Fee Breakdown Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Includes: Items ₹${combo.itemsTotal.toInt()} + Del ₹${combo.deliveryFee.toInt()} + Tax ₹${combo.taxes.toInt()}',
                style: const TextStyle(fontSize: 11, color: AppColors.textDim),
              ),
              Text(
                'Change: ₹${combo.savingsVsBudget.toInt()}',
                style: const TextStyle(fontSize: 11, color: AppColors.emerald, fontWeight: FontWeight.w700),
              ),
            ],
          ),

          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size.fromHeight(40),
            ),
            onPressed: () async {
              // Add all items in combo to cart
              for (var item in combo.items) {
                await ref.read(cartProvider.notifier).addToCart(
                      foodItemId: item.id,
                      quantity: 1,
                      restaurantId: combo.restaurantId,
                    );
              }
              if (context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
              }
            },
            child: const Text('Add Entire Combo to Cart', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
