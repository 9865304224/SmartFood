import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/food_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_provider.dart';
import 'cart_screen.dart';

class CustomerAiAssistantScreen extends ConsumerStatefulWidget {
  const CustomerAiAssistantScreen({super.key});

  @override
  ConsumerState<CustomerAiAssistantScreen> createState() => _CustomerAiAssistantScreenState();
}

class _CustomerAiAssistantScreenState extends ConsumerState<CustomerAiAssistantScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': '👋 Hello! I am your SmartFood AI Chef & Dining Genie.\n\nTell me what you are craving, your budget limit, or dietary preference (e.g. "Spicy chicken dinner under ₹250", "High protein salad", "Late night sweet craving") and I will curate the best dishes for you!',
      'items': <FoodItem>[],
      'tip': 'You can tap any suggested prompt below or type your own request.',
      'timestamp': 'Just now',
    }
  ];

  final List<String> _quickPrompts = [
    '🍛 Best Biryani under ₹250',
    '🥗 Healthy High-Protein Lunch',
    '🍕 Party Pizza Combos',
    '🌶️ Fiery Spicy Cravings',
    '🍰 Artisanal Sweet Desserts',
    '💰 Pocket Friendly Feasts',
  ];

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendQuery([String? customText]) async {
    final text = (customText ?? _queryController.text).trim();
    if (text.isEmpty || _isLoading) return;

    _queryController.clear();

    setState(() {
      _isLoading = true;
      _messages.add({
        'isUser': true,
        'text': text,
        'timestamp': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
    });

    _scrollToBottom();

    try {
      final res = await ApiClient.post(
        '${ApiConstants.customerAiAssistant}?query=${Uri.encodeComponent(text)}',
      );

      if (res.data['success'] == true && res.data['data'] != null) {
        final data = res.data['data'];
        final answer = data['answer'] ?? 'Here are the recommended dishes:';
        final tip = data['aiTip'] as String?;
        final rawItems = data['recommendedItems'] as List<dynamic>? ?? [];

        final items = rawItems.map((j) => FoodItem.fromJson(j as Map<String, dynamic>)).toList();

        setState(() {
          _messages.add({
            'isUser': false,
            'text': answer,
            'items': items,
            'tip': tip,
            'timestamp': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          });
        });
      } else {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': res.data['message'] ?? 'Here are great recommendations from our popular kitchen catalog!',
            'items': <FoodItem>[],
            'timestamp': 'Now',
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'isUser': false,
          'text': 'I found popular top-rated options prepared fresh for you. Enjoy your meal!',
          'items': <FoodItem>[],
          'timestamp': 'Now',
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addDishToCart(FoodItem item) async {
    final success = await ref.read(cartProvider.notifier).addToCart(
          foodItemId: item.id,
          quantity: 1,
          restaurantId: item.restaurantId,
          hotelId: item.hotelId,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? AppColors.emerald : AppColors.rose,
          content: Text(success ? 'Added "${item.name}" to cart!' : 'Failed to add item to cart.'),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartCount = cartState.cart?.items.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.amber],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Food Genie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text('Smart Recommendations & Cravings', style: TextStyle(fontSize: 11, color: AppColors.textDim)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              child: const Icon(Icons.shopping_bag_rounded),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggested Query Chips Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              border: Border(bottom: BorderSide(color: AppColors.borderDark.withOpacity(0.6))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(prompt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      backgroundColor: AppColors.surfaceDark,
                      side: BorderSide(color: AppColors.primary.withOpacity(0.35)),
                      onPressed: _isLoading ? null : () => _sendQuery(prompt),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;
                final text = msg['text'] as String;
                final items = msg['items'] as List<FoodItem>? ?? [];
                final tip = msg['tip'] as String?;
                final timestamp = msg['timestamp'] as String?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.amber]),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser ? AppColors.primary : AppColors.cardDark,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
                              bottomLeft: !isUser ? const Radius.circular(2) : const Radius.circular(16),
                            ),
                            border: Border.all(
                              color: isUser ? AppColors.primaryLight : AppColors.borderDark,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.4,
                                  color: isUser ? Colors.white : AppColors.textLight,
                                  fontWeight: isUser ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),

                              if (items.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                const Text(
                                  'AI RECOMMENDED DISHES',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppColors.primary),
                                ),
                                const SizedBox(height: 8),
                                ...items.map((dish) => _buildDishTile(dish)),
                              ],

                              if (tip != null && tip.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.amber),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          tip,
                                          style: const TextStyle(fontSize: 11, color: AppColors.amber, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (timestamp != null) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    timestamp,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isUser ? Colors.white70 : AppColors.textDim,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 16),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: const [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  SizedBox(width: 10),
                  Text('AI Chef searching live menus, prices & ratings...', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                ],
              ),
            ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(top: BorderSide(color: AppColors.borderDark)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Ask AI: "Spicy biryani under 200", "Healthy lunch"...',
                      hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendQuery(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: _isLoading ? null : () => _sendQuery(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishTile(FoodItem dish) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Veg / Non-Veg Indicator
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(color: dish.isVeg ? AppColors.emerald : AppColors.rose, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.circle,
              size: 8,
              color: dish.isVeg ? AppColors.emerald : AppColors.rose,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dish.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '₹${dish.price.toInt()}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    if (dish.rating > 0) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, size: 13, color: AppColors.amber),
                      Text(' ${dish.rating}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _addDishToCart(dish),
            child: const Text('+ Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
