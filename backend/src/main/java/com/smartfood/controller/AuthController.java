package com.smartfood.controller;

import com.smartfood.dto.auth.AuthResponse;
import com.smartfood.dto.auth.ForgotPasswordRequest;
import com.smartfood.dto.auth.LoginRequest;
import com.smartfood.dto.auth.OtpVerifyRequest;
import com.smartfood.dto.auth.RefreshTokenRequest;
import com.smartfood.dto.auth.RegisterRequest;
import com.smartfood.dto.auth.RegisterVerifyOtpRequest;
import com.smartfood.dto.auth.ResetPasswordRequest;
import com.smartfood.dto.auth.SendOtpResponse;
import com.smartfood.dto.response.ApiResponse;
import com.smartfood.security.UserPrincipal;
import com.smartfood.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse response = authService.register(request);
        return ResponseEntity.ok(ApiResponse.success("Registration successful", response));
    }

    @PostMapping("/register/send-otp")
    public ResponseEntity<ApiResponse<SendOtpResponse>> sendRegistrationOtp(@Valid @RequestBody RegisterRequest request) {
        SendOtpResponse response = authService.sendRegistrationOtp(request);
        return ResponseEntity.ok(ApiResponse.success("Verification OTP sent to your email", response));
    }

    @PostMapping("/register/verify-otp")
    public ResponseEntity<ApiResponse<AuthResponse>> verifyAndCompleteRegistration(@Valid @RequestBody RegisterVerifyOtpRequest request) {
        AuthResponse response = authService.verifyAndCompleteRegistration(request);
        return ResponseEntity.ok(ApiResponse.success("Registration completed and verified successfully", response));
    }

    @PostMapping("/forgot-password/send-otp")
    public ResponseEntity<ApiResponse<SendOtpResponse>> sendForgotPasswordOtp(@Valid @RequestBody ForgotPasswordRequest request) {
        SendOtpResponse response = authService.sendForgotPasswordOtp(request);
        return ResponseEntity.ok(ApiResponse.success("Password reset OTP sent to your email", response));
    }

    @PostMapping("/forgot-password/reset")
    public ResponseEntity<ApiResponse<Boolean>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        boolean success = authService.resetPassword(request);
        return ResponseEntity.ok(ApiResponse.success("Password reset successfully. You can now login.", success));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success("Login successful", response));
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<ApiResponse<Boolean>> verifyOtp(@Valid @RequestBody OtpVerifyRequest request) {
        boolean verified = authService.verifyOtp(request);
        return ResponseEntity.ok(ApiResponse.success("OTP verified successfully", verified));
    }

    @PostMapping("/refresh-token")
    public ResponseEntity<ApiResponse<AuthResponse>> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        AuthResponse response = authService.refreshToken(request);
        return ResponseEntity.ok(ApiResponse.success("Token refreshed successfully", response));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserPrincipal>> getCurrentUser(@AuthenticationPrincipal UserPrincipal userPrincipal) {
        return ResponseEntity.ok(ApiResponse.success("Current user profile retrieved", userPrincipal));
    }
}
