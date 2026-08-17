package com.smartfood.dto.auth;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterVerifyOtpRequest {

    @NotNull(message = "Registration data is required")
    @Valid
    private RegisterRequest registerData;

    @NotBlank(message = "OTP code is required")
    private String otp;
}
