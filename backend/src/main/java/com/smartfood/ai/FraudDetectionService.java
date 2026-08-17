package com.smartfood.ai;

import com.smartfood.model.FraudFlag;
import com.smartfood.model.Order;
import com.smartfood.model.enums.FraudRiskLevel;
import com.smartfood.model.enums.OrderStatus;
import com.smartfood.repository.FraudFlagRepository;
import com.smartfood.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class FraudDetectionService {

    private final FraudFlagRepository fraudFlagRepository;
    private final OrderRepository orderRepository;

    public void analyzeUserOrderActivity(String userId, String currentOrderId) {
        List<Order> userOrders = orderRepository.findByCustomerIdOrderByCreatedAtDesc(userId);
        if (userOrders.size() < 3) return;

        List<String> patterns = new ArrayList<>();
        FraudRiskLevel riskLevel = FraudRiskLevel.LOW;

        // Rule 1: Excessive cancellations (>= 3 cancellations out of last 5 orders)
        long recentCancellations = userOrders.stream().limit(5)
                .filter(o -> o.getStatus() == OrderStatus.CANCELLED)
                .count();

        if (recentCancellations >= 3) {
            patterns.add("High cancellation rate: " + recentCancellations + " of last 5 orders cancelled");
            riskLevel = FraudRiskLevel.HIGH;
        }

        // Rule 2: Repeated refund requests
        long refundRequests = userOrders.stream().limit(5)
                .filter(o -> o.getStatus() == OrderStatus.REFUND_REQUESTED || o.getStatus() == OrderStatus.REFUNDED)
                .count();

        if (refundRequests >= 2) {
            patterns.add("Frequent refund requests: " + refundRequests + " refunds in recent orders");
            riskLevel = FraudRiskLevel.MEDIUM;
        }

        // Rule 3: High value orders with multiple coupon applications
        long discountAbuseCount = userOrders.stream()
                .filter(o -> o.getDiscount() != null && o.getDiscount() > 100.0)
                .count();

        if (discountAbuseCount >= 4) {
            patterns.add("Unusual high-frequency promotional coupon utilization");
        }

        if (!patterns.isEmpty()) {
            FraudFlag flag = FraudFlag.builder()
                    .userId(userId)
                    .orderId(currentOrderId)
                    .riskLevel(riskLevel)
                    .reason("Automated heuristic fraud detection trigger")
                    .detectedPatterns(patterns)
                    .status("FLAGGED")
                    .createdAt(Instant.now())
                    .build();

            fraudFlagRepository.save(flag);
            log.warn("Fraud activity flagged for user: {} with risk: {}. Patterns: {}", userId, riskLevel, patterns);
        }
    }
}
