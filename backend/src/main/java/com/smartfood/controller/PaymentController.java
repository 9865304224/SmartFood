package com.smartfood.controller;

import com.smartfood.dto.response.ApiResponse;
import com.smartfood.model.Payment;
import com.smartfood.service.PaymentService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    @PostMapping("/initiate/{orderId}")
    public ResponseEntity<ApiResponse<PaymentService.PaymentOrderResponse>> initiate(@PathVariable String orderId) {
        return ResponseEntity.ok(ApiResponse.success("Payment initiated", paymentService.initiatePayment(orderId)));
    }

    @Data
    public static class VerifyPaymentDto {
        private String razorpayOrderId;
        private String razorpayPaymentId;
        private String razorpaySignature;
    }

    @PostMapping("/verify/{orderId}")
    public ResponseEntity<ApiResponse<Payment>> verify(@PathVariable String orderId,
                                                       @RequestBody(required = false) VerifyPaymentDto dto) {
        String rzpOrderId = dto != null ? dto.getRazorpayOrderId() : "order_mock";
        String rzpPaymentId = dto != null ? dto.getRazorpayPaymentId() : "pay_mock";
        String rzpSig = dto != null ? dto.getRazorpaySignature() : "sig_mock";

        Payment payment = paymentService.verifyPayment(orderId, rzpOrderId, rzpPaymentId, rzpSig);
        return ResponseEntity.ok(ApiResponse.success("Payment verified and completed", payment));
    }
}
