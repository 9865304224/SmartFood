package com.smartfood.service;

import com.smartfood.exception.BadRequestException;
import com.smartfood.exception.ResourceNotFoundException;
import com.smartfood.model.Order;
import com.smartfood.model.Payment;
import com.smartfood.model.enums.PaymentStatus;
import com.smartfood.repository.OrderRepository;
import com.smartfood.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.SignatureException;
import java.time.Instant;
import java.util.HexFormat;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final OrderRepository orderRepository;

    @Value("${smartfood.payment.mode:MOCK}")
    private String paymentMode;

    @Value("${smartfood.payment.razorpay.key-id:rzp_test_mock_key_id}")
    private String razorpayKeyId;

    @Value("${smartfood.payment.razorpay.key-secret:rzp_test_mock_secret}")
    private String razorpayKeySecret;

    public record PaymentOrderResponse(String orderId, String paymentId, Double amount, String currency, String razorpayOrderId, String keyId, String mode) {}

    public PaymentOrderResponse initiatePayment(String orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order", "id", orderId));

        Payment payment = paymentRepository.findByOrderId(orderId)
                .orElseGet(() -> Payment.builder()
                        .orderId(orderId)
                        .customerId(order.getCustomerId())
                        .amount(order.getFinalTotal())
                        .method(order.getPaymentMethod())
                        .status(PaymentStatus.PENDING)
                        .build());

        String razorpayOrderId = "order_mock_" + UUID.randomUUID().toString().substring(0, 10);
        payment.setRazorpayOrderId(razorpayOrderId);
        payment.setStatus(PaymentStatus.PENDING);
        payment.setUpdatedAt(Instant.now());
        paymentRepository.save(payment);

        return new PaymentOrderResponse(order.getId(), payment.getId(), order.getFinalTotal(), "INR", razorpayOrderId, razorpayKeyId, paymentMode);
    }

    public Payment verifyPayment(String orderId, String razorpayOrderId, String razorpayPaymentId, String razorpaySignature) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order", "id", orderId));

        Payment payment = paymentRepository.findByOrderId(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Payment", "orderId", orderId));

        if ("MOCK".equalsIgnoreCase(paymentMode)) {
            log.info("MOCK Payment verified successfully for Order: {}", order.getOrderNumber());
            payment.setStatus(PaymentStatus.PAID);
            payment.setRazorpayPaymentId(razorpayPaymentId != null ? razorpayPaymentId : "pay_mock_" + System.currentTimeMillis());
            payment.setRazorpaySignature(razorpaySignature != null ? razorpaySignature : "sig_mock_valid");
            payment.setUpdatedAt(Instant.now());
            paymentRepository.save(payment);

            order.setPaymentStatus(PaymentStatus.PAID);
            orderRepository.save(order);
            return payment;
        }

        // Real Razorpay HMAC SHA256 Signature Verification
        try {
            String payload = razorpayOrderId + "|" + razorpayPaymentId;
            Mac sha256_HMAC = Mac.getInstance("HmacSHA256");
            SecretKeySpec secret_key = new SecretKeySpec(razorpayKeySecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            sha256_HMAC.init(secret_key);
            byte[] hash = sha256_HMAC.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            String generatedSignature = HexFormat.of().formatHex(hash);

            if (!generatedSignature.equals(razorpaySignature)) {
                payment.setStatus(PaymentStatus.FAILED);
                payment.setFailureReason("Signature mismatch");
                paymentRepository.save(payment);
                throw new BadRequestException("Payment signature verification failed");
            }

            payment.setStatus(PaymentStatus.PAID);
            payment.setRazorpayPaymentId(razorpayPaymentId);
            payment.setRazorpaySignature(razorpaySignature);
            payment.setUpdatedAt(Instant.now());
            paymentRepository.save(payment);

            order.setPaymentStatus(PaymentStatus.PAID);
            orderRepository.save(order);
            return payment;
        } catch (Exception ex) {
            log.error("Payment verification failed: ", ex);
            throw new BadRequestException("Payment verification failed: " + ex.getMessage());
        }
    }
}
