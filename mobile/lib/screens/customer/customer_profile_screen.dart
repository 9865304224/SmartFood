import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchProfile();
      }
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiClient.get('/customers/profile');
      if (res.data['success'] == true && res.data['data'] != null) {
        setState(() {
          _profileData = res.data['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditProfileDialog() {
    final authState = ref.read(authProvider);
    final currentName = _profileData?['fullName'] ?? authState.name ?? 'Aarav Sharma';
    final currentPhone = _profileData?['phone'] ?? '9876543211';
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone);
    List<String> currentPrefs = List<String>.from(_profileData?['dietaryPreferences'] ?? ['VEG']);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text('Edit Customer Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 16),
                const Text('Dietary Preferences', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDim)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['VEG', 'NON_VEG', 'VEGAN', 'HALAL', 'HIGH_PROTEIN', 'GLUTEN_FREE'].map((pref) {
                    final isSel = currentPrefs.contains(pref);
                    return FilterChip(
                      label: Text(pref.replaceAll('_', ' ')),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceDark,
                      labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700),
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            currentPrefs.add(pref);
                          } else {
                            currentPrefs.remove(pref);
                          }
                        });
                      },
                    );
                  }).toList(),
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
                  final updatedName = nameCtrl.text.trim();
                  final res = await ApiClient.put('/customers/profile', data: {
                    'fullName': updatedName,
                    'phone': phoneCtrl.text.trim(),
                    'dietaryPreferences': currentPrefs,
                  });
                  if (res.data['success'] == true) {
                    await ref.read(authProvider.notifier).updateUserName(updatedName);
                    if (res.data['data'] != null) {
                      setState(() {
                        _profileData = res.data['data'] as Map<String, dynamic>;
                      });
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchProfile();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.emerald),
                      );
                    }
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAddressDialog() {
    final labelCtrl = TextEditingController(text: 'Campus Hostel');
    final buildingCtrl = TextEditingController(text: 'Aryabhatta Hall Block B');
    final addressCtrl = TextEditingController(text: 'Campus Road, University Main Gate');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Add Delivery Address', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick 1-tap Current Location Autofill
            InkWell(
              onTap: () {
                labelCtrl.text = 'Current GPS Location';
                buildingCtrl.text = 'Live Location (12.9716° N, 77.5946° E)';
                addressCtrl.text = 'Indiranagar / Campus Main Gate, Bengaluru';
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.emerald.withOpacity(0.35)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.my_location_rounded, color: AppColors.emerald, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '📍 Autofill Current GPS Location',
                        style: TextStyle(color: AppColors.emeraldLight, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Address Label (e.g. Hostel, Lab)')),
            const SizedBox(height: 10),
            TextField(controller: buildingCtrl, decoration: const InputDecoration(labelText: 'Building / Room No.')),
            const SizedBox(height: 10),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Full Formatted Address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              try {
                await ApiClient.post('/customers/addresses', data: {
                  'label': labelCtrl.text.trim(),
                  'type': 'COLLEGE',
                  'building': buildingCtrl.text.trim(),
                  'formattedAddress': addressCtrl.text.trim(),
                  'location': {'latitude': 12.9716, 'longitude': 77.5946},
                  'isDefault': true,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchProfile();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address saved successfully!'), backgroundColor: AppColors.emerald),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Avatar & Info Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.indigo]),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (_profileData?['fullName'] ?? user.name ?? 'Customer').substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(_profileData?['fullName'] ?? user.name ?? 'Aarav Sharma', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryLight, size: 24),
                                  tooltip: 'Edit Profile',
                                  onPressed: _showEditProfileDialog,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(_profileData?['email'] ?? 'customer@smartfood.com', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            const SizedBox(height: 4),
                            if (_profileData?['phone'] != null)
                              Text('📞 ${_profileData!['phone']}', style: const TextStyle(color: AppColors.textDim, fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('VERIFIED CAMPUS MEMBER', style: TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Eco Impact Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('🌱 YOUR ECO-IMPACT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.1)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: const Text('Top 5% Eco Saver', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildEcoStat('14.2 kg', 'CO2 Reduced'),
                          _buildEcoStat('8', 'Eco Deliveries'),
                          _buildEcoStat('92/100', 'Green Score'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Saved Addresses Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SAVED ADDRESSES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1.0)),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      onPressed: _showAddAddressDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    children: [
                      _buildAddressTile(
                        icon: Icons.school_rounded,
                        title: 'College Campus Hostel',
                        subtitle: 'Aryabhatta Hall Block B, Campus Road',
                        isDefault: true,
                      ),
                      const Divider(color: AppColors.borderDark, height: 1),
                      _buildAddressTile(
                        icon: Icons.business_rounded,
                        title: 'CS Department Lab',
                        subtitle: 'Computing Complex 2nd Floor, Room 204',
                        isDefault: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account Actions
                const Text('APP SETTINGS & OPERATIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1.0)),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                        title: const Text('Switch Role / Demo Switcher', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        onTap: () {
                          ref.read(authProvider.notifier).logout();
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                        },
                      ),
                      const Divider(color: AppColors.borderDark, height: 1),
                      ListTile(
                        leading: const Icon(Icons.headset_mic_rounded, color: AppColors.indigo),
                        title: const Text('24/7 SmartFood Help & Support', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Support line: support@smartfood.com / 1800-SMART-FOOD')),
                          );
                        },
                      ),
                      const Divider(color: AppColors.borderDark, height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppColors.rose),
                        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.rose)),
                        onTap: () {
                          ref.read(authProvider.notifier).logout();
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEcoStat(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAddressTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDefault,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          if (isDefault) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.emerald.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              child: const Text('DEFAULT', style: TextStyle(color: AppColors.emerald, fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ],
        ],
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      trailing: const Icon(Icons.more_vert_rounded, color: AppColors.textDim),
    );
  }
}
