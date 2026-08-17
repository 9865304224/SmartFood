import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? token;
  final String? userId;
  final String? role;
  final String? name;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.token,
    this.userId,
    this.role,
    this.name,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? token,
    String? userId,
    String? role,
    String? name,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      name: name ?? this.name,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    checkInitialAuth();
  }

  String _extractErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return e.toString();
  }

  Future<void> checkInitialAuth() async {
    final token = await LocalStorage.getToken();
    final role = await LocalStorage.getUserRole();
    final userId = await LocalStorage.getUserId();
    final name = await LocalStorage.getUserName();

    if (token != null && token.isNotEmpty) {
      state = state.copyWith(
        isAuthenticated: true,
        token: token,
        role: role,
        userId: userId,
        name: name,
      );
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final res = await ApiClient.post(ApiConstants.login, data: {
        'username': username,
        'password': password,
      });

      if (res.data['success'] == true) {
        final data = res.data['data'];
        final token = data['accessToken'];
        final userId = data['userId'];
        final role = data['role'];
        final name = data['fullName'];

        await LocalStorage.saveAuthData(
          token: token,
          userId: userId,
          role: role,
          name: name,
        );

        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          token: token,
          userId: userId,
          role: role,
          name: name,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: res.data['message']);
        return false;
      }
    } catch (e) {
      final msg = _extractErrorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  /// Sends 6-digit verification OTP to Gmail for new user registration
  Future<Map<String, dynamic>> sendRegistrationOtp(Map<String, dynamic> regData) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final res = await ApiClient.post(ApiConstants.registerSendOtp, data: regData);

      state = state.copyWith(isLoading: false);
      if (res.data['success'] == true) {
        final data = res.data['data'];
        return {
          'success': true,
          'message': res.data['message'] ?? 'Verification OTP sent to your email',
          'debugOtp': data != null ? data['debugOtp'] : null,
        };
      } else {
        final msg = res.data['message'] ?? 'Failed to send verification OTP';
        state = state.copyWith(error: msg);
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      final msg = _extractErrorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      return {'success': false, 'message': msg};
    }
  }

  /// Confirms OTP and completes user registration & auto-login
  Future<bool> verifyAndCompleteRegistration(Map<String, dynamic> regData, String otp) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final res = await ApiClient.post(ApiConstants.registerVerifyOtp, data: {
        'registerData': regData,
        'otp': otp.trim(),
      });

      if (res.data['success'] == true) {
        final data = res.data['data'];
        final token = data['accessToken'];
        final userId = data['userId'];
        final userRole = data['role'];
        final name = data['fullName'];

        await LocalStorage.saveAuthData(
          token: token,
          userId: userId,
          role: userRole,
          name: name,
        );

        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          token: token,
          userId: userId,
          role: userRole,
          name: name,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: res.data['message']);
        return false;
      }
    } catch (e) {
      final msg = _extractErrorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  /// Direct registration fallback
  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final res = await ApiClient.post(ApiConstants.register, data: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      });

      if (res.data['success'] == true) {
        final data = res.data['data'];
        final token = data['accessToken'];
        final userId = data['userId'];
        final userRole = data['role'];
        final name = data['fullName'];

        await LocalStorage.saveAuthData(
          token: token,
          userId: userId,
          role: userRole,
          name: name,
        );

        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          token: token,
          userId: userId,
          role: userRole,
          name: name,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: res.data['message']);
        return false;
      }
    } catch (e) {
      final msg = _extractErrorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  /// Sends 6-digit password reset OTP to user's registered Gmail
  Future<Map<String, dynamic>> sendForgotPasswordOtp(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final res = await ApiClient.post(ApiConstants.forgotPasswordSendOtp, data: {
        'email': email.trim(),
      });

      state = state.copyWith(isLoading: false);
      if (res.data['success'] == true) {
        final data = res.data['data'];
        return {
          'success': true,
          'message': res.data['message'] ?? 'Password reset code sent to your email',
          'debugOtp': data != null ? data['debugOtp'] : null,
        };
      } else {
        final msg = res.data['message'] ?? 'Failed to send password reset code';
        state = state.copyWith(error: msg);
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      final msg = _extractErrorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      return {'success': false, 'message': msg};
    }
  }

  /// Verifies reset OTP and updates user's password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final res = await ApiClient.post(ApiConstants.forgotPasswordReset, data: {
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword,
      });

      state = state.copyWith(isLoading: false);
      if (res.data['success'] == true) {
        return {
          'success': true,
          'message': res.data['message'] ?? 'Password reset successfully',
        };
      } else {
        final msg = res.data['message'] ?? 'Failed to reset password';
        state = state.copyWith(error: msg);
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      final msg = _extractErrorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      return {'success': false, 'message': msg};
    }
  }

  Future<void> updateUserName(String newName) async {
    state = state.copyWith(name: newName);
    if (state.token != null && state.userId != null && state.role != null) {
      await LocalStorage.saveAuthData(
        token: state.token!,
        userId: state.userId!,
        role: state.role!,
        name: newName,
      );
    }
  }

  Future<void> logout() async {
    await LocalStorage.clearAuthData();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
