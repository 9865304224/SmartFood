package com.smartfood.service;

import com.smartfood.model.DeliveryAssignment;
import com.smartfood.model.DeliveryProfile;
import com.smartfood.model.GeoLocation;
import com.smartfood.model.Order;
import com.smartfood.model.OrderStatusHistory;
import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.model.enums.DeliveryStatus;
import com.smartfood.model.enums.OrderStatus;
import com.smartfood.model.enums.UserRole;
import com.smartfood.repository.DeliveryAssignmentRepository;
import com.smartfood.repository.DeliveryProfileRepository;
import com.smartfood.repository.OrderRepository;
import com.smartfood.repository.OrderStatusHistoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class DeliveryAssignmentService {

    private final DeliveryProfileRepository deliveryProfileRepository;
    private final DeliveryAssignmentRepository deliveryAssignmentRepository;
    private final OrderRepository orderRepository;
    private final OrderStatusHistoryRepository orderStatusHistoryRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public Optional<DeliveryProfile> assignDeliveryPerson(Order order) {
        log.info("Starting Smart Delivery Assignment for Order: {}", order.getOrderNumber());

        // Find approved delivery persons who are AVAILABLE or have <= 2 active orders (for multi-order routing)
        List<DeliveryProfile> candidates = deliveryProfileRepository.findByApprovalStatus(ApprovalStatus.APPROVED)
                .stream()
                .filter(d -> d.getCurrentStatus() != DeliveryStatus.OFFLINE && d.getActiveOrdersCount() < 3)
                .toList();

        if (candidates.isEmpty()) {
            log.info("No approved online delivery candidates found. Checking all registered delivery profiles in database...");
            List<DeliveryProfile> allProfiles = deliveryProfileRepository.findAll();
            if (!allProfiles.isEmpty()) {
                DeliveryProfile fallback = allProfiles.getFirst();
                fallback.setApprovalStatus(ApprovalStatus.APPROVED);
                fallback.setCurrentStatus(DeliveryStatus.AVAILABLE);
                deliveryProfileRepository.save(fallback);
                candidates = List.of(fallback);
            } else {
                log.warn("No delivery profiles exist in database for order: {}", order.getOrderNumber());
                return Optional.empty();
            }
        }

        GeoLocation pickup = order.getPickupLocation();
        if (pickup == null) {
            pickup = GeoLocation.builder().latitude(12.9716).longitude(77.5946).build();
        }

        // Score each candidate
        final GeoLocation restaurantLocation = pickup;
        record CandidateScore(DeliveryProfile profile, double totalScore, Map<String, Double> breakdown) {}

        List<CandidateScore> scoredCandidates = candidates.stream().map(driver -> {
            Map<String, Double> breakdown = new HashMap<>();

            // 1. Distance Score (0-40 points): Closer is better
            double distanceKm = (driver.getCurrentLocation() != null) 
                    ? driver.getCurrentLocation().distanceTo(restaurantLocation) : 5.0;
            double distanceScore = Math.max(0, 40.0 - (distanceKm * 5.0));
            breakdown.put("distanceScore", distanceScore);

            // 2. Workload Score (0-30 points): 0 active orders = 30 pts, 1 = 15 pts, 2 = 5 pts
            double workloadScore = switch (driver.getActiveOrdersCount()) {
                case 0 -> 30.0;
                case 1 -> 15.0;
                default -> 5.0;
            };
            breakdown.put("workloadScore", workloadScore);

            // 3. Driver Rating Score (0-20 points): rating 5.0 = 20 pts
            double rating = driver.getRating() != null ? driver.getRating() : 4.0;
            double ratingScore = (rating / 5.0) * 20.0;
            breakdown.put("ratingScore", ratingScore);

            // 4. Eco Score Bonus (0-10 points)
            double ecoBonus = (driver.getEcoScore() != null ? driver.getEcoScore() / 100.0 : 0.8) * 10.0;
            breakdown.put("ecoBonus", ecoBonus);

            double totalScore = distanceScore + workloadScore + ratingScore + ecoBonus;
            return new CandidateScore(driver, totalScore, breakdown);
        }).sorted(Comparator.comparingDouble(CandidateScore::totalScore).reversed()).toList();

        CandidateScore bestCandidate = scoredCandidates.getFirst();
        DeliveryProfile selectedDriver = bestCandidate.profile();

        log.info("Assigned Delivery Person: {} with score: {} (breakdown: {}) for Order: {}", 
                selectedDriver.getFullName(), bestCandidate.totalScore(), bestCandidate.breakdown(), order.getOrderNumber());

        // Update Order
        order.setDeliveryPersonId(selectedDriver.getUserId());
        order.setDeliveryPersonName(selectedDriver.getFullName());
        order.setDeliveryPersonPhone(selectedDriver.getPhone());
        order.setStatus(OrderStatus.DELIVERY_ASSIGNED);
        order.setUpdatedAt(Instant.now());
        orderRepository.save(order);

        // Update Driver Status & Active Orders
        selectedDriver.setActiveOrdersCount(selectedDriver.getActiveOrdersCount() + 1);
        if (selectedDriver.getActiveOrdersCount() >= 2) {
            selectedDriver.setCurrentStatus(DeliveryStatus.BUSY);
        }
        deliveryProfileRepository.save(selectedDriver);

        // Save Assignment Record
        DeliveryAssignment assignment = DeliveryAssignment.builder()
                .orderId(order.getId())
                .deliveryPersonId(selectedDriver.getUserId())
                .score(bestCandidate.totalScore())
                .scoreBreakdown(bestCandidate.breakdown())
                .status("ASSIGNED")
                .build();
        deliveryAssignmentRepository.save(assignment);

        // Record Status History
        OrderStatusHistory history = OrderStatusHistory.builder()
                .orderId(order.getId())
                .previousStatus(OrderStatus.READY_FOR_PICKUP)
                .newStatus(OrderStatus.DELIVERY_ASSIGNED)
                .changedByUserId("SYSTEM_AI_ASSIGNMENT")
                .changedByUserRole(UserRole.ADMIN)
                .note("Auto-assigned to " + selectedDriver.getFullName() + " (Score: " + Math.round(bestCandidate.totalScore()) + ")")
                .build();
        orderStatusHistoryRepository.save(history);

        // Send WebSocket alert to Driver
        try {
            messagingTemplate.convertAndSend("/topic/delivery/" + selectedDriver.getUserId() + "/assignments", order);
            messagingTemplate.convertAndSend("/topic/orders/" + order.getId() + "/status", order);
        } catch (Exception ignored) {}

        return Optional.of(selectedDriver);
    }
}
