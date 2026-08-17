package com.smartfood.model;

import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.model.enums.UserRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "users")
public class User {

    @Id
    private String id;

    @Indexed(unique = true)
    private String email;

    @Indexed(unique = true)
    private String phone;

    private String passwordHash;

    private String fullName;

    @Indexed
    private UserRole role;

    @Builder.Default
    private boolean isEmailVerified = false;

    @Builder.Default
    private boolean isPhoneVerified = false;

    private String otpSecret;
    private String currentOtp;
    private Instant otpExpiresAt;

    @Builder.Default
    @Indexed
    private ApprovalStatus approvalStatus = ApprovalStatus.PENDING;

    private String rejectionReason;

    private String avatarUrl;

    @Builder.Default
    private boolean isActive = true;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;
}
