package com.smartfood.controller;

import com.smartfood.dto.order.CreateOrderRequest;
import com.smartfood.dto.response.ApiResponse;
import com.smartfood.exception.BadRequestException;
import com.smartfood.exception.ResourceNotFoundException;
import com.smartfood.model.GeoLocation;
import com.smartfood.model.Order;
import com.smartfood.model.OrderStatusHistory;
import com.smartfood.model.enums.OrderStatus;
import com.smartfood.model.enums.UserRole;
import com.smartfood.repository.OrderRepository;
import com.smartfood.security.UserPrincipal;
import com.smartfood.service.EtaService;
import com.smartfood.service.OrderService;
import jakarta.validation.Valid;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;
    private final OrderRepository orderRepository;
    private final EtaService etaService;

    @PostMapping("/checkout")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<Order>> checkout(@AuthenticationPrincipal UserPrincipal user,
                                                       @Valid @RequestBody CreateOrderRequest request) {
        Order order = orderService.createOrderFromCart(user.getId(), request);
        return ResponseEntity.ok(ApiResponse.success("Order placed successfully", order));
    }

    @GetMapping("/{orderId}")
    public ResponseEntity<ApiResponse<Order>> getOrderDetails(@PathVariable String orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order", "id", orderId));
        return ResponseEntity.ok(ApiResponse.success(order));
    }

    @Data
    public static class UpdateStatusDto {
        private OrderStatus status;
        private String note;
    }

    @RequestMapping(value = "/{orderId}/status", method = {RequestMethod.PATCH, RequestMethod.PUT, RequestMethod.POST})
    public ResponseEntity<ApiResponse<Order>> updateStatus(@AuthenticationPrincipal UserPrincipal user,
                                                           @PathVariable String orderId,
                                                           @RequestBody(required = false) UpdateStatusDto dto,
                                                           @RequestParam(name = "status", required = false) String queryStatus,
                                                           @RequestParam(name = "note", required = false) String queryNote) {
        OrderStatus targetStatus = null;
        String note = queryNote != null ? queryNote : "Status updated";

        if (dto != null && dto.getStatus() != null) {
            targetStatus = dto.getStatus();
            if (dto.getNote() != null) note = dto.getNote();
        } else if (queryStatus != null && !queryStatus.isBlank()) {
            try {
                targetStatus = OrderStatus.valueOf(queryStatus.toUpperCase().trim());
            } catch (Exception e) {
                throw new BadRequestException("Invalid order status: " + queryStatus);
            }
        }

        if (targetStatus == null) {
            throw new BadRequestException("Target status is required");
        }

        String actorId = user != null ? user.getId() : "SYSTEM";
        UserRole actorRole = user != null ? user.getRole() : UserRole.ADMIN;

        Order order = orderService.updateOrderStatus(orderId, targetStatus, actorId, actorRole, note);
        return ResponseEntity.ok(ApiResponse.success("Order status updated", order));
    }

    @RequestMapping(value = {"/{orderId}/verify-otp", "/{orderId}/verify-delivery-otp"}, method = {RequestMethod.POST, RequestMethod.PUT})
    public ResponseEntity<ApiResponse<Order>> verifyDeliveryOtp(@AuthenticationPrincipal UserPrincipal user,
                                                                @PathVariable String orderId,
                                                                @RequestParam(name = "otp", required = false) String queryOtp,
                                                                @RequestBody(required = false) java.util.Map<String, String> body) {
        String actorId = user != null ? user.getId() : "DELIVERY_PERSON";
        String otp = (queryOtp != null && !queryOtp.isEmpty()) ? queryOtp : (body != null ? body.get("otp") : "");
        Order order = orderService.verifyDeliveryOtp(orderId, actorId, otp);
        return ResponseEntity.ok(ApiResponse.success("Delivery confirmed via OTP", order));
    }

    @GetMapping("/{orderId}/timeline")
    public ResponseEntity<ApiResponse<List<OrderStatusHistory>>> getTimeline(@PathVariable String orderId) {
        return ResponseEntity.ok(ApiResponse.success(orderService.getOrderTimeline(orderId)));
    }

    @GetMapping("/{orderId}/eta")
    public ResponseEntity<ApiResponse<EtaService.EtaResult>> getLiveEta(@PathVariable String orderId,
                                                                        @RequestParam(required = false) Double driverLat,
                                                                        @RequestParam(required = false) Double driverLng) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order", "id", orderId));

        GeoLocation driverLoc = (driverLat != null && driverLng != null) 
                ? GeoLocation.builder().latitude(driverLat).longitude(driverLng).build() : null;

        var eta = etaService.calculateEta(order, driverLoc);
        return ResponseEntity.ok(ApiResponse.success("Live ETA calculated", eta));
    }
}
