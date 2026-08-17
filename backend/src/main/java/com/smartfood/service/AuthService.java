package com.smartfood.service;

import com.smartfood.dto.auth.AuthResponse;
import com.smartfood.dto.auth.ForgotPasswordRequest;
import com.smartfood.dto.auth.LoginRequest;
import com.smartfood.dto.auth.OtpVerifyRequest;
import com.smartfood.dto.auth.RefreshTokenRequest;
import com.smartfood.dto.auth.RegisterRequest;
import com.smartfood.dto.auth.RegisterVerifyOtpRequest;
import com.smartfood.dto.auth.ResetPasswordRequest;
import com.smartfood.dto.auth.SendOtpResponse;
import com.smartfood.exception.BadRequestException;
import com.smartfood.exception.ResourceNotFoundException;
import com.smartfood.model.CustomerProfile;
import com.smartfood.model.DeliveryProfile;
import com.smartfood.model.GeoLocation;
import com.smartfood.model.HotelProfile;
import com.smartfood.model.RestaurantProfile;
import com.smartfood.model.User;
import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.model.enums.DeliveryStatus;
import com.smartfood.model.enums.UserRole;
import com.smartfood.model.enums.VehicleType;
import com.smartfood.repository.CustomerProfileRepository;
import com.smartfood.repository.DeliveryProfileRepository;
import com.smartfood.repository.HotelProfileRepository;
import com.smartfood.repository.RestaurantProfileRepository;
import com.smartfood.repository.UserRepository;
import com.smartfood.security.JwtTokenProvider;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final CustomerProfileRepository customerProfileRepository;
    private final RestaurantProfileRepository restaurantProfileRepository;
    private final HotelProfileRepository hotelProfileRepository;
    private final DeliveryProfileRepository deliveryProfileRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final EmailService emailService;

    // Cache for pending registrations awaiting email OTP confirmation
    private final Map<String, PendingRegistration> pendingRegistrations = new ConcurrentHashMap<>();

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    private static class PendingRegistration {
        private RegisterRequest registerRequest;
        private String otp;
        private Instant expiresAt;
    }

    /**
     * Step 1 of Registration: Validate input, generate 6-digit OTP, send to Gmail
     */
    public SendOtpResponse sendRegistrationOtp(RegisterRequest request) {
        String email = request.getEmail().toLowerCase().trim();
        String phone = request.getPhone().trim();

        var existingUserByEmail = userRepository.findByEmail(email);
        if (existingUserByEmail.isPresent() && existingUserByEmail.get().isEmailVerified()) {
            throw new BadRequestException("Email is already registered: " + email + ". Please sign in or use Forgot Password.");
        }

        var existingUserByPhone = userRepository.findByPhone(phone);
        if (existingUserByPhone.isPresent() && existingUserByPhone.get().isPhoneVerified() 
                && !existingUserByPhone.get().getEmail().equalsIgnoreCase(email)) {
            throw new BadRequestException("Phone number is already associated with another account: " + phone);
        }

        String otp = String.format("%06d", new Random().nextInt(1000000));
        Instant expiresAt = Instant.now().plus(15, ChronoUnit.MINUTES);

        pendingRegistrations.put(email, PendingRegistration.builder()
                .registerRequest(request)
                .otp(otp)
                .expiresAt(expiresAt)
                .build());

        emailService.sendRegistrationOtp(email, request.getFullName(), otp);

        return SendOtpResponse.builder()
                .email(email)
                .message("Verification OTP has been sent to " + email)
                .otpSent(true)
                .debugOtp(otp)
                .build();
    }

    /**
     * Step 2 of Registration: Verify OTP and complete account creation
     */
    @Transactional
    public AuthResponse verifyAndCompleteRegistration(RegisterVerifyOtpRequest request) {
        RegisterRequest regData = request.getRegisterData();
        String email = regData.getEmail().toLowerCase().trim();
        String submittedOtp = request.getOtp().trim();

        PendingRegistration pending = pendingRegistrations.get(email);

        // Check if OTP matches pending registration
        boolean isValidOtp = false;
        if (pending != null) {
            if (pending.getExpiresAt().isBefore(Instant.now())) {
                pendingRegistrations.remove(email);
                throw new BadRequestException("Registration OTP has expired. Please request a new code.");
            }
            if (pending.getOtp().equals(submittedOtp)) {
                isValidOtp = true;
                pendingRegistrations.remove(email);
            }
        }

        if (!isValidOtp) {
            throw new BadRequestException("Invalid or expired OTP code. Please check your email.");
        }

        ApprovalStatus initialStatus = ApprovalStatus.APPROVED;

        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) {
            user = User.builder()
                    .fullName(regData.getFullName())
                    .email(email)
                    .phone(regData.getPhone().trim())
                    .passwordHash(passwordEncoder.encode(regData.getPassword()))
                    .role(regData.getRole())
                    .approvalStatus(initialStatus)
                    .isEmailVerified(true)
                    .isPhoneVerified(true)
                    .isActive(true)
                    .build();
        } else {
            user.setFullName(regData.getFullName());
            user.setPhone(regData.getPhone().trim());
            user.setPasswordHash(passwordEncoder.encode(regData.getPassword()));
            user.setRole(regData.getRole());
            user.setApprovalStatus(initialStatus);
            user.setEmailVerified(true);
            user.setPhoneVerified(true);
            user.setActive(true);
        }

        user = userRepository.save(user);
        log.info("User registered and email verified successfully: id={}, email={}, role={}", 
                user.getId(), user.getEmail(), user.getRole());

        String profileId = createRoleSpecificProfile(user, regData);

        String accessToken = jwtTokenProvider.generateAccessToken(user);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(user.getId())
                .email(user.getEmail())
                .phone(user.getPhone())
                .fullName(user.getFullName())
                .role(user.getRole())
                .approvalStatus(user.getApprovalStatus())
                .isEmailVerified(user.isEmailVerified())
                .isPhoneVerified(user.isPhoneVerified())
                .profileId(profileId)
                .build();
    }

    /**
     * Direct registration (legacy support with OTP email dispatch)
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Email is already registered: " + request.getEmail());
        }
        if (userRepository.existsByPhone(request.getPhone())) {
            throw new BadRequestException("Phone number is already registered: " + request.getPhone());
        }

        ApprovalStatus initialStatus = ApprovalStatus.APPROVED;
        String generatedOtp = String.format("%06d", new Random().nextInt(1000000));

        User user = User.builder()
                .fullName(request.getFullName())
                .email(request.getEmail().toLowerCase().trim())
                .phone(request.getPhone().trim())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(request.getRole())
                .approvalStatus(initialStatus)
                .isEmailVerified(false)
                .isPhoneVerified(false)
                .currentOtp(generatedOtp)
                .otpExpiresAt(Instant.now().plus(15, ChronoUnit.MINUTES))
                .isActive(true)
                .build();

        user = userRepository.save(user);
        emailService.sendRegistrationOtp(user.getEmail(), user.getFullName(), generatedOtp);

        String profileId = createRoleSpecificProfile(user, request);

        String accessToken = jwtTokenProvider.generateAccessToken(user);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(user.getId())
                .email(user.getEmail())
                .phone(user.getPhone())
                .fullName(user.getFullName())
                .role(user.getRole())
                .approvalStatus(user.getApprovalStatus())
                .isEmailVerified(user.isEmailVerified())
                .isPhoneVerified(user.isPhoneVerified())
                .profileId(profileId)
                .build();
    }

    /**
     * Step 1 of Forgot Password: Send OTP to user's registered Gmail
     */
    public SendOtpResponse sendForgotPasswordOtp(ForgotPasswordRequest request) {
        String email = request.getEmail().toLowerCase().trim();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new BadRequestException("No registered account found with email: " + email + ". Please create an account first."));

        String otp = String.format("%06d", new Random().nextInt(1000000));
        user.setCurrentOtp(otp);
        user.setOtpExpiresAt(Instant.now().plus(15, ChronoUnit.MINUTES));
        userRepository.save(user);

        emailService.sendPasswordResetOtp(email, user.getFullName(), otp);

        return SendOtpResponse.builder()
                .email(email)
                .message("Password reset OTP code sent to " + email)
                .otpSent(true)
                .debugOtp(otp)
                .build();
    }

    /**
     * Step 2 of Forgot Password: Verify OTP and reset password
     */
    @Transactional
    public boolean resetPassword(ResetPasswordRequest request) {
        String email = request.getEmail().toLowerCase().trim();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new BadRequestException("No registered account found with email: " + email + ". Please create an account first."));

        if (user.getCurrentOtp() == null || !user.getCurrentOtp().equals(request.getOtp().trim())) {
            throw new BadRequestException("Invalid verification OTP code.");
        }

        if (user.getOtpExpiresAt() != null && user.getOtpExpiresAt().isBefore(Instant.now())) {
            throw new BadRequestException("OTP code has expired. Please request a new one.");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        user.setCurrentOtp(null);
        user.setOtpExpiresAt(null);
        userRepository.save(user);

        log.info("Password successfully reset for user: {}", email);
        return true;
    }

    public AuthResponse login(LoginRequest request) {
        String username = request.getUsername().trim();
        User user = userRepository.findByEmail(username.toLowerCase())
                .or(() -> userRepository.findByPhone(username))
                .orElseThrow(() -> new BadCredentialsException("Invalid email/phone or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BadCredentialsException("Invalid email/phone or password");
        }

        if (!user.isActive()) {
            throw new BadRequestException("This account has been deactivated. Please contact support.");
        }

        String profileId = getProfileIdForUser(user);

        String accessToken = jwtTokenProvider.generateAccessToken(user);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userId(user.getId())
                .email(user.getEmail())
                .phone(user.getPhone())
                .fullName(user.getFullName())
                .role(user.getRole())
                .approvalStatus(user.getApprovalStatus())
                .isEmailVerified(user.isEmailVerified())
                .isPhoneVerified(user.isPhoneVerified())
                .profileId(profileId)
                .build();
    }

    public boolean verifyOtp(OtpVerifyRequest request) {
        String username = request.getUsername().trim();
        User user = userRepository.findByEmail(username.toLowerCase())
                .or(() -> userRepository.findByPhone(username))
                .orElseThrow(() -> new ResourceNotFoundException("User", "username", username));

        if (user.getCurrentOtp() == null || !user.getCurrentOtp().equals(request.getOtp())) {
            throw new BadRequestException("Invalid OTP code");
        }

        if (user.getOtpExpiresAt() != null && user.getOtpExpiresAt().isBefore(Instant.now())) {
            throw new BadRequestException("OTP code has expired. Please request a new one.");
        }

        user.setPhoneVerified(true);
        user.setEmailVerified(true);
        user.setCurrentOtp(null);
        user.setOtpExpiresAt(null);
        userRepository.save(user);

        return true;
    }

    public AuthResponse refreshToken(RefreshTokenRequest request) {
        if (!jwtTokenProvider.validateToken(request.getRefreshToken())) {
            throw new BadRequestException("Invalid or expired refresh token");
        }

        String userId = jwtTokenProvider.getUserIdFromToken(request.getRefreshToken());
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        String profileId = getProfileIdForUser(user);
        String newAccessToken = jwtTokenProvider.generateAccessToken(user);
        String newRefreshToken = jwtTokenProvider.generateRefreshToken(user);

        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .userId(user.getId())
                .email(user.getEmail())
                .phone(user.getPhone())
                .fullName(user.getFullName())
                .role(user.getRole())
                .approvalStatus(user.getApprovalStatus())
                .isEmailVerified(user.isEmailVerified())
                .isPhoneVerified(user.isPhoneVerified())
                .profileId(profileId)
                .build();
    }

    private String createRoleSpecificProfile(User user, RegisterRequest request) {
        switch (user.getRole()) {
            case CUSTOMER -> {
                CustomerProfile profile = CustomerProfile.builder()
                        .userId(user.getId())
                        .walletBalance(100.0) // Welcome ₹100 wallet credit
                        .build();
                return customerProfileRepository.save(profile).getId();
            }
            case RESTAURANT -> {
                RestaurantProfile profile = RestaurantProfile.builder()
                        .userId(user.getId())
                        .businessName(request.getBusinessName() != null ? request.getBusinessName() : user.getFullName() + "'s Kitchen")
                        .ownerName(user.getFullName())
                        .phone(user.getPhone())
                        .email(user.getEmail())
                        .address(request.getBusinessAddress() != null ? request.getBusinessAddress() : "Main Road, City Center")
                        .location(GeoLocation.builder()
                                .latitude(request.getLatitude() != null ? request.getLatitude() : 12.9716)
                                .longitude(request.getLongitude() != null ? request.getLongitude() : 77.5946)
                                .formattedAddress(request.getBusinessAddress() != null ? request.getBusinessAddress() : "MG Road, Bengaluru")
                                .build())
                        .approvalStatus(user.getApprovalStatus())
                        .build();
                return restaurantProfileRepository.save(profile).getId();
            }
            case HOTEL -> {
                HotelProfile profile = HotelProfile.builder()
                        .userId(user.getId())
                        .businessName(request.getBusinessName() != null ? request.getBusinessName() : user.getFullName() + " Grand Hotel")
                        .ownerName(user.getFullName())
                        .phone(user.getPhone())
                        .email(user.getEmail())
                        .address(request.getBusinessAddress() != null ? request.getBusinessAddress() : "Resort Road, Tech Park")
                        .location(GeoLocation.builder()
                                .latitude(request.getLatitude() != null ? request.getLatitude() : 12.9780)
                                .longitude(request.getLongitude() != null ? request.getLongitude() : 77.6010)
                                .formattedAddress(request.getBusinessAddress() != null ? request.getBusinessAddress() : "Indiranagar, Bengaluru")
                                .build())
                        .approvalStatus(user.getApprovalStatus())
                        .build();
                return hotelProfileRepository.save(profile).getId();
            }
            case DELIVERY_PERSON -> {
                VehicleType vType = VehicleType.MOTORCYCLE;
                if (request.getVehicleType() != null) {
                    try {
                        vType = VehicleType.valueOf(request.getVehicleType().toUpperCase());
                    } catch (Exception ignored) {}
                }
                DeliveryProfile profile = DeliveryProfile.builder()
                        .userId(user.getId())
                        .fullName(user.getFullName())
                        .phone(user.getPhone())
                        .email(user.getEmail())
                        .vehicleType(vType)
                        .vehicleNumber(request.getVehicleNumber() != null ? request.getVehicleNumber() : "KA-01-EA-2024")
                        .drivingLicenseNumber(request.getDrivingLicenseNumber() != null ? request.getDrivingLicenseNumber() : "DL-98234710")
                        .currentStatus(DeliveryStatus.AVAILABLE)
                        .currentLocation(GeoLocation.builder()
                                .latitude(request.getLatitude() != null ? request.getLatitude() : 12.9720)
                                .longitude(request.getLongitude() != null ? request.getLongitude() : 77.5950)
                                .formattedAddress("Koramangala, Bengaluru")
                                .build())
                        .approvalStatus(user.getApprovalStatus())
                        .build();
                return deliveryProfileRepository.save(profile).getId();
            }
            default -> {
                return null;
            }
        }
    }

    private String getProfileIdForUser(User user) {
        return switch (user.getRole()) {
            case CUSTOMER -> customerProfileRepository.findByUserId(user.getId()).map(CustomerProfile::getId).orElse(null);
            case RESTAURANT -> restaurantProfileRepository.findByUserId(user.getId()).map(RestaurantProfile::getId).orElse(null);
            case HOTEL -> hotelProfileRepository.findByUserId(user.getId()).map(HotelProfile::getId).orElse(null);
            case DELIVERY_PERSON -> deliveryProfileRepository.findByUserId(user.getId()).map(DeliveryProfile::getId).orElse(null);
            default -> null;
        };
    }
}
