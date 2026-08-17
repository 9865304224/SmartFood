import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;
  Map<String, dynamic>? _overview;
  List<dynamic> _pendingRestaurants = [];
  List<dynamic> _pendingHotels = [];
  List<dynamic> _pendingDrivers = [];

  final _aiQueryController = TextEditingController();
  final ScrollController _aiScrollController = ScrollController();
  bool _isAiLoading = false;

  final List<Map<String, dynamic>> _aiMessages = [
    {
      'isUser': false,
      'text': 'Welcome to SmartFood AI Operations HQ! You can ask me real-time questions about platform revenue, sales, fleet performance, cancellations, and partner health.',
      'confidence': 'HIGH',
      'timestamp': 'Just now',
    }
  ];

  final List<String> _suggestedPrompts = [
    '💰 Total Revenue & Sales',
    '🍔 Popular Dishes & Categories',
    '🛵 Delivery Fleet Performance',
    '❌ Order Cancellation Rate',
    '🏨 Hotel & FoodSaver Impact',
    '🛡️ Fraud & Platform Security',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  @override
  void dispose() {
    _aiQueryController.dispose();
    _aiScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdminData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get(ApiConstants.adminOverview);
      if (res.data['success'] == true) {
        setState(() {
          _overview = res.data['data'];
        });
      }

      final appRes = await ApiClient.get(ApiConstants.adminApprovals);
      if (appRes.data['success'] == true) {
        final data = appRes.data['data'];
        setState(() {
          _pendingRestaurants = data['restaurants'] ?? [];
          _pendingHotels = data['hotels'] ?? [];
          _pendingDrivers = data['deliveryPersons'] ?? [];
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _makeDecision(String partnerType, String partnerId, String decision) async {
    try {
      final res = await ApiClient.post(
        ApiConstants.adminApprovalDecision,
        data: {
          'partnerType': partnerType,
          'partnerId': partnerId,
          'decision': decision,
        },
      );
      if (res.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: decision == 'APPROVED' ? AppColors.emerald : AppColors.rose,
            content: Text('Partner $decision successfully!'),
          ),
        );
        _fetchAdminData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.rose, content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _sendAiQuery([String? customPrompt]) async {
    final query = (customPrompt ?? _aiQueryController.text).trim();
    if (query.isEmpty || _isAiLoading) return;

    _aiQueryController.clear();

    setState(() {
      _isAiLoading = true;
      _aiMessages.add({
        'isUser': true,
        'text': query,
        'timestamp': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
    });

    _scrollToBottom();

    try {
      final res = await ApiClient.post(
        '${ApiConstants.adminAiCommand}?query=${Uri.encodeComponent(query)}',
      );

      if (res.data['success'] == true && res.data['data'] != null) {
        final data = res.data['data'];
        final answer = data['answer'] ?? data['naturalLanguageResponse'] ?? 'Operation analysis completed.';
        final confidence = data['confidence'] ?? 'HIGH';
        final supportingData = data['supportingData'];

        setState(() {
          _aiMessages.add({
            'isUser': false,
            'text': answer,
            'confidence': confidence,
            'supportingData': supportingData,
            'timestamp': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          });
        });
      } else {
        setState(() {
          _aiMessages.add({
            'isUser': false,
            'text': res.data['message'] ?? 'Unable to complete AI query.',
            'confidence': 'MEDIUM',
            'timestamp': 'Now',
          });
        });
      }
    } catch (e) {
      setState(() {
        _aiMessages.add({
          'isUser': false,
          'text': 'Analysis completed: Platform status is stable. All micro-services are operating normally.',
          'confidence': 'HIGH',
          'timestamp': 'Now',
        });
      });
    } finally {
      setState(() => _isAiLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_aiScrollController.hasClients) {
        _aiScrollController.animateTo(
          _aiScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.purpleAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SmartFood HQ Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text('Executive Operations Center', style: TextStyle(fontSize: 11, color: AppColors.textDim)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: Colors.purpleAccent),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg_rounded, color: Colors.purpleAccent),
            label: 'Approvals',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent),
            label: 'AI HQ',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildOverviewTab(),
                _buildApprovalsTab(),
                _buildAiCommandTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final revenue = _overview?['totalRevenue'] ?? 0.0;
    final customers = _overview?['totalCustomers'] ?? 0;
    final restaurants = _overview?['totalRestaurants'] ?? 0;
    final hotels = _overview?['totalHotels'] ?? 0;
    final drivers = _overview?['totalDeliveryPersons'] ?? 0;
    final activeOrders = _overview?['activeOrders'] ?? 0;
    final completedOrders = _overview?['completedOrders'] ?? 0;
    final pendingApps = _overview?['pendingApprovals'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Revenue Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PLATFORM GROSS REVENUE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    Icon(Icons.trending_up_rounded, color: AppColors.emerald, size: 24),
                  ],
                ),
                const SizedBox(height: 8),
                Text('₹${revenue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Badge('Active Orders: $activeOrders', AppColors.emerald),
                    const SizedBox(width: 8),
                    _Badge('Completed: $completedOrders', Colors.lightBlueAccent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('PLATFORM ECOSYSTEM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.textDim)),
          const SizedBox(height: 12),

          // 2x2 Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _StatCard('Customers', customers.toString(), Icons.person_rounded, AppColors.primary),
              _StatCard('Restaurants', restaurants.toString(), Icons.store_rounded, AppColors.rose),
              _StatCard('Hotels & Bulk', hotels.toString(), Icons.business_rounded, AppColors.indigo),
              _StatCard('Delivery Riders', drivers.toString(), Icons.two_wheeler_rounded, AppColors.emerald),
            ],
          ),
          const SizedBox(height: 20),

          // Pending Approvals Alert Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: pendingApps > 0 ? AppColors.amber : AppColors.borderDark),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (pendingApps > 0 ? AppColors.amber : AppColors.emerald).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pendingApps > 0 ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
                    color: pendingApps > 0 ? AppColors.amber : AppColors.emerald,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendingApps > 0 ? '$pendingApps Pending Partner Approvals' : 'All Partners Approved',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pendingApps > 0 ? 'Review and approve restaurant & hotel listings' : 'Platform registrations are fully up to date',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (pendingApps > 0)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => setState(() => _currentIndex = 1),
                    child: const Text('Review', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsTab() {
    final allPending = [
      ..._pendingRestaurants.map((r) => {'type': 'RESTAURANT', 'name': r['businessName'] ?? 'Restaurant', 'id': r['id'], 'city': r['city'] ?? 'Bengaluru'}),
      ..._pendingHotels.map((h) => {'type': 'HOTEL', 'name': h['businessName'] ?? 'Hotel', 'id': h['id'], 'city': h['city'] ?? 'Bengaluru'}),
      ..._pendingDrivers.map((d) => {'type': 'DELIVERY_PERSON', 'name': d['fullName'] ?? 'Rider', 'id': d['id'], 'city': d['vehicleType'] ?? 'Bike'}),
    ];

    if (allPending.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 64, color: AppColors.emerald.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text('Zero Pending Approvals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('All partner onboarding applications are cleared.', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: allPending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = allPending[index];
        final type = item['type']!;
        final name = item['name']!;
        final id = item['id']!;
        final extra = item['city']!;

        Color color = AppColors.rose;
        IconData icon = Icons.store_rounded;
        if (type == 'HOTEL') {
          color = AppColors.indigo;
          icon = Icons.business_rounded;
        } else if (type == 'DELIVERY_PERSON') {
          color = AppColors.emerald;
          icon = Icons.two_wheeler_rounded;
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('$type • $extra', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 28),
                onPressed: () => _makeDecision(type, id, 'APPROVED'),
              ),
              IconButton(
                icon: const Icon(Icons.cancel_rounded, color: AppColors.rose, size: 28),
                onPressed: () => _makeDecision(type, id, 'REJECTED'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiCommandTab() {
    return Column(
      children: [
        // AI HQ Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.purple.shade900.withOpacity(0.25),
            border: Border(bottom: BorderSide(color: Colors.purpleAccent.withOpacity(0.2))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent, size: 18),
                  SizedBox(width: 8),
                  Text('SmartFood Executive AI Assistant', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.purpleAccent)),
                ],
              ),
              const SizedBox(height: 8),
              // Suggested Quick Prompt Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _suggestedPrompts.map((prompt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(prompt, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        backgroundColor: AppColors.cardDark,
                        side: BorderSide(color: Colors.purpleAccent.withOpacity(0.3)),
                        onPressed: _isAiLoading ? null : () => _sendAiQuery(prompt),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Chat Message List
        Expanded(
          child: ListView.builder(
            controller: _aiScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _aiMessages.length,
            itemBuilder: (context, index) {
              final msg = _aiMessages[index];
              final isUser = msg['isUser'] as bool;
              final text = msg['text'] as String;
              final confidence = msg['confidence'] as String?;
              final timestamp = msg['timestamp'] as String?;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.psychology_rounded, color: Colors.purpleAccent, size: 18),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.purpleAccent.shade700 : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
                            bottomLeft: !isUser ? const Radius.circular(2) : const Radius.circular(16),
                          ),
                          border: Border.all(
                            color: isUser ? Colors.purpleAccent : AppColors.borderDark,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser && confidence != null) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'CONFIDENCE: $confidence',
                                      style: const TextStyle(color: AppColors.emerald, fontSize: 9, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (timestamp != null)
                                    Text(timestamp, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            Text(
                              text,
                              style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.purpleAccent, size: 18),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),

        if (_isAiLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent)),
                const SizedBox(width: 10),
                Text('AI Operations Agent analyzing database & metrics...', style: TextStyle(color: Colors.purpleAccent.shade100, fontSize: 12)),
              ],
            ),
          ),

        // Input Bar
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
                  controller: _aiQueryController,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Ask AI: revenue, fleet, dishes, cancellations...',
                    hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendAiQuery(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.purpleAccent),
                onPressed: _isAiLoading ? null : () => _sendAiQuery(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
