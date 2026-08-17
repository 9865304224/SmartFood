package com.smartfood.controller;

import com.smartfood.dto.response.ApiResponse;
import com.smartfood.model.DeliveryProfile;
import com.smartfood.model.Order;
import com.smartfood.model.enums.DeliveryStatus;
import com.smartfood.security.UserPrincipal;
import com.smartfood.service.DeliveryService;
import com.smartfood.service.OrderService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/delivery")
@RequiredArgsConstructor
public class DeliveryController {

    private final DeliveryService deliveryService;
    private final OrderService orderService;

    @GetMapping("/profile")
    @PreAuthorize("hasRole('DELIVERY_PERSON')")
    public ResponseEntity<ApiResponse<DeliveryProfile>> getProfile(@AuthenticationPrincipal UserPrincipal user) {
        return ResponseEntity.ok(ApiResponse.success(deliveryService.getDeliveryProfileByUserId(user.getId())));
    }

    @PutMapping("/profile")
    @PreAuthorize("hasRole('DELIVERY_PERSON')")
    public ResponseEntity<ApiResponse<DeliveryProfile>> updateProfile(@AuthenticationPrincipal UserPrincipal user,
                                                                      @RequestBody DeliveryProfile profile) {
        return ResponseEntity.ok(ApiResponse.success("Profile updated successfully", deliveryService.updateProfile(user.getId(), profile)));
    }

    @PutMapping("/status")
    @PreAuthorize("hasRole('DELIVERY_PERSON')")
    public ResponseEntity<ApiResponse<DeliveryProfile>> updateStatus(@AuthenticationPrincipal UserPrincipal user,
                                                                    @RequestParam DeliveryStatus status) {
        return ResponseEntity.ok(ApiResponse.success("Status updated", deliveryService.updateStatus(user.getId(), status)));
    }

    @Data
    public static class LocationUpdateDto {
        private Double latitude;
        private Double longitude;
        private Double speedKmh;
        private Double headingDegrees;
        private String currentOrderId;
    }

    @PostMapping("/location")
    @PreAuthorize("hasRole('DELIVERY_PERSON')")
    public ResponseEntity<ApiResponse<DeliveryProfile>> updateLocation(@AuthenticationPrincipal UserPrincipal user,
                                                                       @RequestBody LocationUpdateDto dto) {
        DeliveryProfile profile = deliveryService.updateLiveLocation(
                user.getId(),
                dto.getLatitude(),
                dto.getLongitude(),
                dto.getSpeedKmh() != null ? dto.getSpeedKmh() : 25.0,
                dto.getHeadingDegrees() != null ? dto.getHeadingDegrees() : 0.0,
                dto.getCurrentOrderId()
        );
        return ResponseEntity.ok(ApiResponse.success("Location updated and broadcasted", profile));
    }

    @GetMapping("/active-orders")
    @PreAuthorize("hasRole('DELIVERY_PERSON')")
    public ResponseEntity<ApiResponse<List<Order>>> getActiveOrders(@AuthenticationPrincipal UserPrincipal user) {
        return ResponseEntity.ok(ApiResponse.success(deliveryService.getActiveAssignments(user.getId())));
    }

    @GetMapping("/available-orders")
    @PreAuthorize("hasRole('DELIVERY_PERSON')")
    public ResponseEntity<ApiResponse<List<Order>>> getAvailableOrders(@AuthenticationPrincipal UserPrincipal user) {
        return ResponseEntity.ok(ApiResponse.success(deliveryService.getAvailableOrdersPool()));
    }

    @PostMapping("/orders/{orderId}/claim")
    @PreAuthorize("hasRole('DELIVERY_PERSON')")
    public ResponseEntity<ApiResponse<Order>> claimOrder(@AuthenticationPrincipal UserPrincipal user,
                                                         @PathVariable String orderId) {
        return ResponseEntity.ok(ApiResponse.success("Order claimed successfully", deliveryService.claimOrder(user.getId(), orderId)));
    }

    @GetMapping("/history")
    @PreAuthorize("hasRole('DELIVERY_PERSON')")
    public ResponseEntity<ApiResponse<List<Order>>> getHistory(@AuthenticationPrincipal UserPrincipal user) {
        return ResponseEntity.ok(ApiResponse.success(deliveryService.getDeliveryHistory(user.getId())));
    }

    @PostMapping("/orders/{orderId}/verify-otp")
    @PreAuthorize("hasRole('DELIVERY_PERSON')")
    public ResponseEntity<ApiResponse<Order>> verifyDeliveryOtp(@AuthenticationPrincipal UserPrincipal user,
                                                                @PathVariable String orderId,
                                                                @RequestParam(name = "otp", required = false) String queryOtp,
                                                                @RequestBody(required = false) java.util.Map<String, String> body) {
        String otp = (queryOtp != null && !queryOtp.isEmpty()) ? queryOtp : (body != null ? body.get("otp") : "");
        Order order = orderService.verifyDeliveryOtp(orderId, user.getId(), otp);
        return ResponseEntity.ok(ApiResponse.success("Delivery confirmed via OTP", order));
    }
}
