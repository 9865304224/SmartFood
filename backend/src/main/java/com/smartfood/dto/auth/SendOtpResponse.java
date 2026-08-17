package com.smartfood.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SendOtpResponse {
    private String email;
    private String message;
    private boolean otpSent;
    private String debugOtp; // Provided for frictionless testing/demo
}
