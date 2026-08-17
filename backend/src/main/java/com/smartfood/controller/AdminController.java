package com.smartfood.controller;

import com.smartfood.ai.AdminAIAssistantService;
import com.smartfood.dto.response.ApiResponse;
import com.smartfood.exception.ResourceNotFoundException;
import com.smartfood.model.AuditLog;
import com.smartfood.model.DeliveryProfile;
import com.smartfood.model.FraudFlag;
import com.smartfood.model.HotelProfile;
import com.smartfood.model.Order;
import com.smartfood.model.RestaurantProfile;
import com.smartfood.model.User;
import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.model.enums.OrderStatus;
import com.smartfood.model.enums.UserRole;
import com.smartfood.repository.AuditLogRepository;
import com.smartfood.repository.CustomerProfileRepository;
import com.smartfood.repository.DeliveryProfileRepository;
import com.smartfood.repository.FraudFlagRepository;
import com.smartfood.repository.HotelProfileRepository;
import com.smartfood.repository.OrderRepository;
import com.smartfood.repository.RestaurantProfileRepository;
import com.smartfood.repository.UserRepository;
import com.smartfood.security.UserPrincipal;
import com.smartfood.service.AuditLogService;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminController {

    private final UserRepository userRepository;
    private final RestaurantProfileRepository restaurantProfileRepository;
    private final HotelProfileRepository hotelProfileRepository;
    private final DeliveryProfileRepository deliveryProfileRepository;
    private final OrderRepository orderRepository;
    private final FraudFlagRepository fraudFlagRepository;
    private final AuditLogRepository auditLogRepository;
    private final AuditLogService auditLogService;
    private final AdminAIAssistantService adminAIAssistantService;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AdminOverviewStats {
        private long totalCustomers;
        private long totalRestaurants;
        private long totalHotels;
        private long totalDeliveryPersons;
        private long activeOrders;
        private long completedOrders;
        private long cancelledOrders;
        private double totalRevenue;
        private long pendingApprovals;
        private long activeFraudFlags;
    }

    @GetMapping("/overview")
    public ResponseEntity<ApiResponse<AdminOverviewStats>> getOverviewStats() {
        List<Order> orders = orderRepository.findAll();
        double revenue = orders.stream()
                .filter(o -> o.getStatus() == OrderStatus.DELIVERED)
                .mapToDouble(Order::getFinalTotal)
                .sum();

        long pendingRestaurants = restaurantProfileRepository.countByApprovalStatus(ApprovalStatus.PENDING);
        long pendingHotels = hotelProfileRepository.countByApprovalStatus(ApprovalStatus.PENDING);
        long pendingDrivers = deliveryProfileRepository.countByApprovalStatus(ApprovalStatus.PENDING);

        AdminOverviewStats stats = AdminOverviewStats.builder()
                .totalCustomers(userRepository.countByRole(UserRole.CUSTOMER))
                .totalRestaurants(restaurantProfileRepository.count())
                .totalHotels(hotelProfileRepository.count())
                .totalDeliveryPersons(deliveryProfileRepository.count())
                .activeOrders(orders.stream().filter(o -> o.getStatus() != OrderStatus.DELIVERED && o.getStatus() != OrderStatus.CANCELLED).count())
                .completedOrders(orders.stream().filter(o -> o.getStatus() == OrderStatus.DELIVERED).count())
                .cancelledOrders(orders.stream().filter(o -> o.getStatus() == OrderStatus.CANCELLED).count())
                .totalRevenue(Math.round(revenue * 100.0) / 100.0)
                .pendingApprovals(pendingRestaurants + pendingHotels + pendingDrivers)
                .activeFraudFlags(fraudFlagRepository.count())
                .build();

        return ResponseEntity.ok(ApiResponse.success(stats));
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PendingApprovalsDto {
        private List<RestaurantProfile> restaurants;
        private List<HotelProfile> hotels;
        private List<DeliveryProfile> deliveryPersons;
    }

    @GetMapping("/approvals")
    public ResponseEntity<ApiResponse<PendingApprovalsDto>> getPendingApprovals() {
        PendingApprovalsDto dto = PendingApprovalsDto.builder()
                .restaurants(restaurantProfileRepository.findByApprovalStatus(ApprovalStatus.PENDING))
                .hotels(hotelProfileRepository.findByApprovalStatus(ApprovalStatus.PENDING))
                .deliveryPersons(deliveryProfileRepository.findByApprovalStatus(ApprovalStatus.PENDING))
                .build();

        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @Data
    public static class ApprovalDecisionDto {
        private String partnerType; // "RESTAURANT", "HOTEL", "DELIVERY_PERSON"
        private String partnerId;
        private ApprovalStatus decision; // APPROVED, REJECTED, SUSPENDED
        private String rejectionReason;
    }

    @PostMapping("/approvals/decision")
    public ResponseEntity<ApiResponse<Void>> makeApprovalDecision(@AuthenticationPrincipal UserPrincipal admin,
                                                                 @RequestBody ApprovalDecisionDto dto) {
        String partnerName = "";
        String userId = null;

        if ("RESTAURANT".equalsIgnoreCase(dto.getPartnerType())) {
            RestaurantProfile res = restaurantProfileRepository.findById(dto.getPartnerId())
                    .orElseThrow(() -> new ResourceNotFoundException("Restaurant", "id", dto.getPartnerId()));
            res.setApprovalStatus(dto.getDecision());
            res.setRejectionReason(dto.getRejectionReason());
            restaurantProfileRepository.save(res);
            partnerName = res.getBusinessName();
            userId = res.getUserId();
        } else if ("HOTEL".equalsIgnoreCase(dto.getPartnerType())) {
            HotelProfile hotel = hotelProfileRepository.findById(dto.getPartnerId())
                    .orElseThrow(() -> new ResourceNotFoundException("Hotel", "id", dto.getPartnerId()));
            hotel.setApprovalStatus(dto.getDecision());
            hotel.setRejectionReason(dto.getRejectionReason());
            hotelProfileRepository.save(hotel);
            partnerName = hotel.getBusinessName();
            userId = hotel.getUserId();
        } else if ("DELIVERY_PERSON".equalsIgnoreCase(dto.getPartnerType())) {
            DeliveryProfile driver = deliveryProfileRepository.findById(dto.getPartnerId())
                    .orElseThrow(() -> new ResourceNotFoundException("DeliveryProfile", "id", dto.getPartnerId()));
            driver.setApprovalStatus(dto.getDecision());
            driver.setRejectionReason(dto.getRejectionReason());
            deliveryProfileRepository.save(driver);
            partnerName = driver.getFullName();
            userId = driver.getUserId();
        }

        if (userId != null) {
            userRepository.findById(userId).ifPresent(u -> {
                u.setApprovalStatus(dto.getDecision());
                u.setRejectionReason(dto.getRejectionReason());
                userRepository.save(u);
            });
        }

        // Write Audit Log
        auditLogService.logAction(admin.getId(), admin.getEmail(), "PARTNER_APPROVAL_" + dto.getDecision().name(),
                dto.getPartnerType(), dto.getPartnerId(),
                "Partner '" + partnerName + "' " + dto.getDecision().name() + (dto.getRejectionReason() != null ? " Reason: " + dto.getRejectionReason() : ""),
                "127.0.0.1");

        return ResponseEntity.ok(ApiResponse.success("Decision recorded successfully", null));
    }

    @GetMapping("/orders")
    public ResponseEntity<ApiResponse<List<Order>>> getAllOrders(@RequestParam(required = false) OrderStatus status) {
        if (status != null) {
            return ResponseEntity.ok(ApiResponse.success(orderRepository.findByStatus(status)));
        }
        return ResponseEntity.ok(ApiResponse.success(orderRepository.findAll()));
    }

    @PostMapping("/ai-command")
    public ResponseEntity<ApiResponse<AdminAIAssistantService.AdminAiQueryResponse>> queryAiAssistant(
            @RequestParam String query) {
        var response = adminAIAssistantService.answerAdminQuestion(query);
        return ResponseEntity.ok(ApiResponse.success("AI Query evaluated", response));
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<ApiResponse<List<AuditLog>>> getAuditLogs() {
        return ResponseEntity.ok(ApiResponse.success(auditLogService.getRecentLogs()));
    }

    @GetMapping("/fraud-flags")
    public ResponseEntity<ApiResponse<List<FraudFlag>>> getFraudFlags() {
        return ResponseEntity.ok(ApiResponse.success(fraudFlagRepository.findAll()));
    }
}
