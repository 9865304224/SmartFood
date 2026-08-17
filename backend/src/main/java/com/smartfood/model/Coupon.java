package com.smartfood.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "coupons")
public class Coupon {

    @Id
    private String id;

    @Indexed(unique = true)
    private String code; // e.g. "SMART50", "WELCOME100", "FEAST20"

    private String description;

    private Double discountPercentage; // e.g. 50%
    private Double flatDiscountAmount;  // e.g. ₹50 flat

    private Double minOrderValue;       // e.g. ₹199
    private Double maxDiscountAmount;   // e.g. ₹120 cap for percentage

    @Indexed
    private String restaurantId; // null if universal platform coupon

    @Indexed
    private String hotelId;

    private Instant startDate;
    private Instant expiryDate;

    @Builder.Default
    private Integer usageLimit = 1000;

    @Builder.Default
    private Integer userUsageLimit = 3;

    @Builder.Default
    private Integer timesUsed = 0;

    @Builder.Default
    private boolean isActive = true;

    @CreatedDate
    private Instant createdAt;

    public boolean isValidForOrder(double orderSubtotal, String targetRestaurantId, String targetHotelId) {
        if (!isActive) return false;
        Instant now = Instant.now();
        if (startDate != null && now.isBefore(startDate)) return false;
        if (expiryDate != null && now.isAfter(expiryDate)) return false;
        if (timesUsed != null && usageLimit != null && timesUsed >= usageLimit) return false;
        if (minOrderValue != null && orderSubtotal < minOrderValue) return false;
        if (restaurantId != null && !restaurantId.equals(targetRestaurantId)) return false;
        if (hotelId != null && !hotelId.equals(targetHotelId)) return false;
        return true;
    }

    public double calculateDiscount(double subtotal) {
        double discount = 0.0;
        if (flatDiscountAmount != null && flatDiscountAmount > 0) {
            discount = flatDiscountAmount;
        } else if (discountPercentage != null && discountPercentage > 0) {
            discount = subtotal * (discountPercentage / 100.0);
            if (maxDiscountAmount != null && discount > maxDiscountAmount) {
                discount = maxDiscountAmount;
            }
        }
        return Math.min(discount, subtotal);
    }
}
