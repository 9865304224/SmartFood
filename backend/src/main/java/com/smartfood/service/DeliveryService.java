package com.smartfood.service;

import com.smartfood.exception.BadRequestException;
import com.smartfood.exception.ResourceNotFoundException;
import com.smartfood.model.DeliveryLocationLog;
import com.smartfood.model.DeliveryProfile;
import com.smartfood.model.GeoLocation;
import com.smartfood.model.Order;
import com.smartfood.model.enums.DeliveryStatus;
import com.smartfood.model.enums.OrderStatus;
import com.smartfood.repository.DeliveryLocationLogRepository;
import com.smartfood.repository.DeliveryProfileRepository;
import com.smartfood.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class DeliveryService {

    private final DeliveryProfileRepository deliveryProfileRepository;
    private final DeliveryLocationLogRepository deliveryLocationLogRepository;
    private final OrderRepository orderRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public DeliveryProfile getDeliveryProfileByUserId(String userId) {
        return deliveryProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("DeliveryProfile", "userId", userId));
    }

    public DeliveryProfile updateProfile(String userId, DeliveryProfile update) {
        DeliveryProfile profile = getDeliveryProfileByUserId(userId);
        if (update.getFullName() != null) profile.setFullName(update.getFullName());
        if (update.getPhone() != null) profile.setPhone(update.getPhone());
        if (update.getVehicleType() != null) profile.setVehicleType(update.getVehicleType());
        if (update.getVehicleNumber() != null) profile.setVehicleNumber(update.getVehicleNumber());
        if (update.getDrivingLicenseNumber() != null) profile.setDrivingLicenseNumber(update.getDrivingLicenseNumber());
        profile.setUpdatedAt(Instant.now());
        return deliveryProfileRepository.save(profile);
    }

    public DeliveryProfile updateStatus(String userId, DeliveryStatus status) {
        DeliveryProfile profile = getDeliveryProfileByUserId(userId);
        profile.setCurrentStatus(status);
        profile.setUpdatedAt(Instant.now());
        return deliveryProfileRepository.save(profile);
    }

    public DeliveryProfile updateLiveLocation(String userId, Double latitude, Double longitude, Double speedKmh, Double headingDegrees, String currentOrderId) {
        DeliveryProfile profile = getDeliveryProfileByUserId(userId);

        GeoLocation loc = GeoLocation.builder()
                .latitude(latitude)
                .longitude(longitude)
                .build();

        profile.setCurrentLocation(loc);
        profile.setLastLocationUpdate(Instant.now());
        deliveryProfileRepository.save(profile);

        // Record location trace
        DeliveryLocationLog logEntry = DeliveryLocationLog.builder()
                .deliveryPersonId(userId)
                .orderId(currentOrderId)
                .location(loc)
                .speedKmh(speedKmh)
                .headingDegrees(headingDegrees)
                .build();
        deliveryLocationLogRepository.save(logEntry);

        // Broadcast to delivery tracking topic
        if (currentOrderId != null) {
            try {
                record TrackingMessage(String orderId, String deliveryPersonId, GeoLocation location, Double speed, Double heading, Instant timestamp) {}
                TrackingMessage msg = new TrackingMessage(currentOrderId, userId, loc, speedKmh, headingDegrees, Instant.now());
                messagingTemplate.convertAndSend("/topic/orders/" + currentOrderId + "/tracking", msg);
            } catch (Exception ex) {
                log.error("Failed to broadcast delivery location update: ", ex);
            }
        }

        return profile;
    }

    public List<Order> getActiveAssignments(String userId) {
        return orderRepository.findByDeliveryPersonIdAndStatusIn(userId, List.of(
                OrderStatus.DELIVERY_ASSIGNED,
                OrderStatus.PICKED_UP,
                OrderStatus.OUT_FOR_DELIVERY
        ));
    }

    public List<Order> getAvailableOrdersPool() {
        return orderRepository.findByStatusIn(List.of(
                OrderStatus.READY_FOR_PICKUP,
                OrderStatus.PREPARING,
                OrderStatus.ACCEPTED,
                OrderStatus.PLACED
        )).stream()
          .filter(o -> o.getDeliveryPersonId() == null || o.getDeliveryPersonId().isEmpty())
          .toList();
    }

    public Order claimOrder(String userId, String orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order", "id", orderId));

        if (order.getDeliveryPersonId() != null && !order.getDeliveryPersonId().isEmpty() && !order.getDeliveryPersonId().equals(userId)) {
            throw new BadRequestException("This order is already claimed by another delivery partner");
        }

        DeliveryProfile profile = getDeliveryProfileByUserId(userId);
        order.setDeliveryPersonId(profile.getUserId());
        order.setDeliveryPersonName(profile.getFullName());
        order.setDeliveryPersonPhone(profile.getPhone());
        if (order.getStatus() == OrderStatus.READY_FOR_PICKUP || order.getStatus() == OrderStatus.PREPARING || order.getStatus() == OrderStatus.ACCEPTED) {
            order.setStatus(OrderStatus.DELIVERY_ASSIGNED);
        }
        order.setUpdatedAt(Instant.now());
        Order saved = orderRepository.save(order);

        profile.setActiveOrdersCount(profile.getActiveOrdersCount() + 1);
        deliveryProfileRepository.save(profile);

        try {
            messagingTemplate.convertAndSend("/topic/orders/" + saved.getId() + "/status", saved);
        } catch (Exception ignored) {}

        return saved;
    }

    public List<Order> getDeliveryHistory(String userId) {
        return orderRepository.findByDeliveryPersonIdOrderByCreatedAtDesc(userId);
    }
}
