import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RoleOption {
  final String roleKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _RoleOption({
    required this.roleKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const List<_RoleOption> _registerRoles = [
  _RoleOption(
    roleKey: 'CUSTOMER',
    title: 'Customer',
    subtitle: 'Order Food & AI Menus',
    icon: Icons.person_rounded,
    color: AppColors.primary,
  ),
  _RoleOption(
    roleKey: 'RESTAURANT',
    title: 'Restaurant',
    subtitle: 'Partner Kitchen & Menu',
    icon: Icons.store_rounded,
    color: AppColors.rose,
  ),
  _RoleOption(
    roleKey: 'HOTEL',
    title: 'Hotel / Bulk',
    subtitle: 'FoodSaver & Buffets',
    icon: Icons.business_rounded,
    color: AppColors.indigo,
  ),
  _RoleOption(
    roleKey: 'DELIVERY_PERSON',
    title: 'Delivery Rider',
    subtitle: 'Earn with Deliveries',
    icon: Icons.two_wheeler_rounded,
    color: AppColors.emerald,
  ),
];

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedRoleIndex = 0;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Partner specific fields
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  String _selectedVehicleType = 'MOTORCYCLE';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _vehicleNumberController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  void _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() => _errorMessage = null);

    final selectedRole = _registerRoles[_selectedRoleIndex];
    final Map<String, dynamic> regData = {
      'fullName': _fullNameController.text.trim(),
      'email': _emailController.text.toLowerCase().trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text.trim(),
      'role': selectedRole.roleKey,
    };

    if (selectedRole.roleKey == 'RESTAURANT' || selectedRole.roleKey == 'HOTEL') {
      if (_businessNameController.text.isNotEmpty) {
        regData['businessName'] = _businessNameController.text.trim();
      }
      if (_businessAddressController.text.isNotEmpty) {
        regData['businessAddress'] = _businessAddressController.text.trim();
      }
    } else if (selectedRole.roleKey == 'DELIVERY_PERSON') {
      regData['vehicleType'] = _selectedVehicleType;
      if (_vehicleNumberController.text.isNotEmpty) {
        regData['vehicleNumber'] = _vehicleNumberController.text.trim();
      }
      if (_licenseNumberController.text.isNotEmpty) {
        regData['drivingLicenseNumber'] = _licenseNumberController.text.trim();
      }
    }

    final result = await ref.read(authProvider.notifier).sendRegistrationOtp(regData);

    if (result['success'] == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            registerData: regData,
            initialDebugOtp: result['debugOtp'],
          ),
        ),
      );
    } else if (mounted) {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to send verification email.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final selectedRole = _registerRoles[_selectedRoleIndex];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textLight,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Role Selection Heading
                    const Text(
                      'I WANT TO REGISTER AS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Role Selection Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 64,
                      ),
                      itemCount: _registerRoles.length,
                      itemBuilder: (context, index) {
                        final option = _registerRoles[index];
                        final isSelected = _selectedRoleIndex == index;

                        return InkWell(
                          onTap: () => setState(() => _selectedRoleIndex = index),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? option.color.withOpacity(0.18)
                                  : AppColors.cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? option.color : AppColors.borderDark,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: option.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(option.icon, size: 18, color: option.color),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        option.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : AppColors.textLight,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
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
                                  Icon(Icons.check_circle_rounded, size: 15, color: option.color),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    if (_errorMessage != null) ...[
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
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.rose, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Full Name Input
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Gmail / Email Input
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address (Gmail)',
                        helperText: 'Verification OTP code will be sent here',
                        helperStyle: const TextStyle(color: AppColors.textDim, fontSize: 11),
                        prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: selectedRole.color),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Phone Number Input
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Password Input with Visibility Toggle
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password (min 6 characters)',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
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
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Confirm Password Input with Visibility Toggle
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your password';
                        if (v != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),

                    // Role Specific Extra Fields
                    if (selectedRole.roleKey == 'RESTAURANT' || selectedRole.roleKey == 'HOTEL') ...[
                      const SizedBox(height: 16),
                      Text(
                        '${selectedRole.title.toUpperCase()} DETAILS',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.textDim,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _businessNameController,
                        decoration: InputDecoration(
                          labelText: '${selectedRole.title} Name',
                          prefixIcon: const Icon(Icons.storefront_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _businessAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Business Address',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                        ),
                      ),
                    ] else if (selectedRole.roleKey == 'DELIVERY_PERSON') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'VEHICLE & LICENSE DETAILS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.textDim,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedVehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type',
                          prefixIcon: Icon(Icons.directions_bike_rounded, size: 20),
                        ),
                        dropdownColor: AppColors.cardDark,
                        items: const [
                          DropdownMenuItem(value: 'MOTORCYCLE', child: Text('Motorcycle / Bike')),
                          DropdownMenuItem(value: 'SCOOTER', child: Text('Scooter')),
                          DropdownMenuItem(value: 'BICYCLE', child: Text('Bicycle / EV Cycle')),
                          DropdownMenuItem(value: 'CAR', child: Text('Car / Van')),
                        ],
                        onChanged: (v) => setState(() => _selectedVehicleType = v ?? 'MOTORCYCLE'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _vehicleNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Plate Number',
                          prefixIcon: Icon(Icons.tag_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _licenseNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Driving License Number',
                          prefixIcon: Icon(Icons.badge_outlined, size: 20),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit & Send OTP Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedRole.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: authState.isLoading ? null : _handleSendOtp,
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Send Email OTP & Verify',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),

                    const SizedBox(height: 20),

                    // Already have an account row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
