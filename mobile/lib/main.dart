import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/restaurant/restaurant_dashboard_screen.dart';
import 'screens/hotel/hotel_dashboard_screen.dart';
import 'screens/delivery/delivery_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.init();
  runApp(const ProviderScope(child: SmartFoodApp()));
}

class SmartFoodApp extends ConsumerWidget {
  const SmartFoodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    Widget homeScreen;
    if (!authState.isAuthenticated) {
      homeScreen = const LoginScreen();
    } else {
      if (authState.role == 'ADMIN') {
        homeScreen = const AdminDashboardScreen();
      } else if (authState.role == 'HOTEL') {
        homeScreen = const HotelDashboardScreen();
      } else if (authState.role == 'RESTAURANT') {
        homeScreen = const RestaurantDashboardScreen();
      } else if (authState.role == 'DELIVERY_PERSON') {
        homeScreen = const DeliveryDashboardScreen();
      } else {
        homeScreen = const CustomerHomeScreen();
      }
    }

    return MaterialApp(
      title: 'SmartFood',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: homeScreen,
    );
  }
}
