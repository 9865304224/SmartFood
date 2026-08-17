class ApiConstants {
  // Live Render production backend URL:
  static const bool isProduction = true;
  static const String liveBaseUrl = 'https://smartfood-backend-2f18.onrender.com/api';
  static const String liveWsUrl = 'wss://smartfood-backend-2f18.onrender.com/ws-smartfood-direct';

  static const String localBaseUrl = 'http://localhost:8080/api'; // Or http://10.0.2.2:8080/api for Android emulator
  static const String localWsUrl = 'ws://localhost:8080/ws-smartfood-direct';

  static String get baseUrl => isProduction ? liveBaseUrl : localBaseUrl;
  static String get wsUrl => isProduction ? liveWsUrl : localWsUrl;

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String registerSendOtp = '/auth/register/send-otp';
  static const String registerVerifyOtp = '/auth/register/verify-otp';
  static const String forgotPasswordSendOtp = '/auth/forgot-password/send-otp';
  static const String forgotPasswordReset = '/auth/forgot-password/reset';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String me = '/auth/me';

  // Customer Endpoints
  static const String customerProfile = '/customers/profile';
  static const String customerAddresses = '/customers/addresses';
  static const String customerOrders = '/customers/orders';

  // Restaurant & Hotel Endpoints
  static const String publicRestaurants = '/restaurants/public';
  static const String publicHotels = '/hotels/public';
  static const String restaurantProfile = '/restaurants/profile';
  static const String restaurantMenu = '/restaurants/menu';
  static const String restaurantOrders = '/restaurants/orders';
  static const String hotelProfile = '/hotels/profile';
  static const String hotelPackages = '/hotels/packages';
  static const String foodSaverListings = '/restaurants/food-saver';

  // Delivery Endpoints
  static const String deliveryProfile = '/delivery/profile';
  static const String deliveryStatus = '/delivery/status';
  static const String deliveryLocation = '/delivery/location';
  static const String deliveryActiveOrders = '/delivery/active-orders';
  static const String deliveryAvailableOrders = '/delivery/available-orders';
  static const String deliveryHistory = '/delivery/history';

  // Cart & Orders
  static const String cart = '/cart';
  static const String cartAdd = '/cart/add';
  static const String cartItem = '/cart/item';
  static const String cartCoupon = '/cart/coupon';
  static const String orderCheckout = '/orders/checkout';
  static const String orders = '/orders';
  static const String groupOrders = '/group-orders';

  // AI & Discovery
  static const String recommendations = '/recommendations';
  static const String smartBudget = '/recommendations/smart-budget';
  static const String voiceSearch = '/recommendations/voice-search';
  static const String customerAiAssistant = '/recommendations/ai-assistant';
  static const String categories = '/categories';

  // Reviews & Complaints
  static const String reviews = '/reviews';
  static const String complaints = '/complaints';

  // Admin Endpoints
  static const String adminOverview = '/admin/overview';
  static const String adminApprovals = '/admin/approvals';
  static const String adminApprovalDecision = '/admin/approvals/decision';
  static const String adminAuditLogs = '/admin/audit-logs';
  static const String adminAiCommand = '/admin/ai-command';
  static const String adminOrders = '/admin/orders';
}
