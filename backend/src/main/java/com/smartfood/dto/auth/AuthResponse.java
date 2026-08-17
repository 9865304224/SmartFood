package com.smartfood.dto.auth;

import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.model.enums.UserRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    @Builder.Default
    private String tokenType = "Bearer";
    private String userId;
    private String email;
    private String phone;
    private String fullName;
    private UserRole role;
    private ApprovalStatus approvalStatus;
    private boolean isEmailVerified;
    private boolean isPhoneVerified;
    private String profileId; // Restaurant/Hotel/Delivery/Customer profile ID
}
