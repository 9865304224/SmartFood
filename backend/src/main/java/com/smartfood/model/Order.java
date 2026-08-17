package com.smartfood.model;

import com.smartfood.model.enums.OrderStatus;
import com.smartfood.model.enums.PaymentMethod;
import com.smartfood.model.enums.PaymentStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "orders")
public class Order {

    @Id
    private String id;

    @Indexed(unique = true)
    private String orderNumber; // e.g. "SF-2026-8941"

    @Indexed
    private String customerId;
    private String customerName;
    private String customerPhone;

    @Indexed
    private String restaurantId;

    @Indexed
    private String hotelId;

    private String businessName;
    private GeoLocation pickupLocation;

    @Indexed
    private String deliveryPersonId;
    private String deliveryPersonName;
    private String deliveryPersonPhone;

    @Builder.Default
    private List<OrderItem> items = new ArrayList<>();

    private SavedAddress deliveryAddress;

    @Indexed
    private OrderStatus status;

    private Double subtotal;
    private Double deliveryFee;
    private Double platformFee;
    private Double taxes;
    private Double discount;
    private Double finalTotal;

    private String appliedCouponCode;

    private PaymentMethod paymentMethod;
    private PaymentStatus paymentStatus;
    private String paymentId;

    // Delivery Verification OTP (generated on pickup, validated server-side on drop-off)
    private String deliveryOtp;

    // Eco-Friendly Delivery Metrics
    @Builder.Default
    private boolean isEcoDelivery = false;
    private Double estimatedDistanceKm;
    private Double estimatedCo2SavingKg;
    private Double ecoScore;

    // Group & Bulk flags
    @Builder.Default
    private boolean isGroupOrder = false;
    private String groupOrderId;

    @Builder.Default
    private boolean isBulkHotelOrder = false;

    private String specialInstructions;

    private Instant estimatedDeliveryTime;
    private Integer preparationTimeMinutes;

    // Multi-Order batch grouping ID
    private String batchRouteId;

    @CreatedDate
    @Indexed
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;

    private Instant deliveredAt;
}
