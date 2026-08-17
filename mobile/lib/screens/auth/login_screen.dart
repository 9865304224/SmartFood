import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../customer/customer_home_screen.dart';
import '../restaurant/restaurant_dashboard_screen.dart';
import '../hotel/hotel_dashboard_screen.dart';
import '../delivery/delivery_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _RoleOption {
  final String roleKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String defaultEmail;
  final String defaultPassword;

  const _RoleOption({
    required this.roleKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.defaultEmail,
    required this.defaultPassword,
  });
}

const List<_RoleOption> _roleOptions = [
  _RoleOption(
    roleKey: 'CUSTOMER',
    title: 'Customer',
    subtitle: 'Order Food & AI Menus',
    icon: Icons.person_rounded,
    color: AppColors.primary,
    defaultEmail: 'customer@smartfood.com',
    defaultPassword: 'Customer@123',
  ),
  _RoleOption(
    roleKey: 'RESTAURANT',
    title: 'Restaurant',
    subtitle: 'Manage Menu & Orders',
    icon: Icons.store_rounded,
    color: AppColors.rose,
    defaultEmail: 'restaurant@smartfood.com',
    defaultPassword: 'Restaurant@123',
  ),
  _RoleOption(
    roleKey: 'HOTEL',
    title: 'Hotel / Bulk',
    subtitle: 'FoodSaver & Buffets',
    icon: Icons.business_rounded,
    color: AppColors.indigo,
    defaultEmail: 'hotel@smartfood.com',
    defaultPassword: 'Hotel@123',
  ),
  _RoleOption(
    roleKey: 'DELIVERY_PERSON',
    title: 'Delivery Rider',
    subtitle: 'Live Tracking & Route',
    icon: Icons.two_wheeler_rounded,
    color: AppColors.emerald,
    defaultEmail: 'delivery@smartfood.com',
    defaultPassword: 'Delivery@123',
  ),
  _RoleOption(
    roleKey: 'ADMIN',
    title: 'Admin HQ',
    subtitle: 'Platform Operations & AI',
    icon: Icons.admin_panel_settings_rounded,
    color: Colors.purpleAccent,
    defaultEmail: 'admin@smartfood.com',
    defaultPassword: 'Admin@123',
  ),
];

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _selectedRoleIndex = 0;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: _roleOptions[0].defaultEmail);
    _passwordController = TextEditingController(text: _roleOptions[0].defaultPassword);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectRole(int index, {bool autoLogin = false}) {
    setState(() {
      _selectedRoleIndex = index;
      _usernameController.text = _roleOptions[index].defaultEmail;
      _passwordController.text = _roleOptions[index].defaultPassword;
    });

    if (autoLogin) {
      _handleLogin();
    }
  }

  void _handleLogin() async {
    final success = await ref.read(authProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

    if (success && mounted) {
      final role = ref.read(authProvider).role;
      _navigateByRole(role);
    }
  }

  void _navigateByRole(String? role) {
    Widget target;
    if (role == 'ADMIN') {
      target = const AdminDashboardScreen();
    } else if (role == 'HOTEL') {
      target = const HotelDashboardScreen();
    } else if (role == 'RESTAURANT') {
      target = const RestaurantDashboardScreen();
    } else if (role == 'DELIVERY_PERSON') {
      target = const DeliveryDashboardScreen();
    } else {
      target = const CustomerHomeScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => target),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentRole = _roleOptions[_selectedRoleIndex];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SmartFood Brand Logo Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: currentRole.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        size: 44,
                        color: currentRole.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SmartFood',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select your account role to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),

                  // Role Selection Grid
                  const Text(
                    'SELECT PORTAL ROLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 10),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.1,
                    ),
                    itemCount: _roleOptions.length,
                    itemBuilder: (context, index) {
                      final option = _roleOptions[index];
                      final isSelected = _selectedRoleIndex == index;

                      return InkWell(
                        onTap: () => _selectRole(index),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? option.color.withOpacity(0.18)
                                : AppColors.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? option.color
                                  : AppColors.borderDark,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: option.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  option.icon,
                                  size: 18,
                                  color: option.color,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      option.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textLight,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      option.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected ? option.color : AppColors.textDim,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, size: 16, color: option.color),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  if (authState.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.rose.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.rose.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.rose, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.error!,
                              style: const TextStyle(color: AppColors.rose, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Credentials Inputs
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Email or Phone (${currentRole.title})',
                      prefixIcon: Icon(Icons.email_outlined, size: 20, color: currentRole.color),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordScreen(
                              initialEmail: _usernameController.text.trim(),
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Submit Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentRole.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: authState.isLoading ? null : _handleLogin,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Sign In as ${currentRole.title}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Register / Sign Up Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          'Register Now',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 1-Tap Quick Demo Launchers
                  const Text(
                    '1-TAP INSTANT DEMO LOGIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(_roleOptions.length, (index) {
                      final opt = _roleOptions[index];
                      return ActionChip(
                        avatar: Icon(opt.icon, size: 15, color: opt.color),
                        label: Text(opt.title, style: TextStyle(color: opt.color, fontWeight: FontWeight.w700, fontSize: 12)),
                        backgroundColor: opt.color.withOpacity(0.12),
                        side: BorderSide(color: opt.color.withOpacity(0.3)),
                        onPressed: authState.isLoading ? null : () => _selectRole(index, autoLogin: true),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
