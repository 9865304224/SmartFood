package com.smartfood.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "carts")
public class Cart {

    @Id
    private String id;

    @Indexed(unique = true)
    private String userId;

    private String restaurantId;
    private String hotelId;
    private String businessName;

    @Builder.Default
    private List<CartItem> items = new ArrayList<>();

    @Builder.Default
    private Double subtotal = 0.0;

    @Builder.Default
    private Double deliveryFee = 35.0;

    @Builder.Default
    private Double platformFee = 5.0;

    @Builder.Default
    private Double taxes = 0.0;

    @Builder.Default
    private Double discount = 0.0;

    @Builder.Default
    private Double finalTotal = 0.0;

    private String appliedCouponCode;
    private String specialInstructions;

    private Instant updatedAt;

    public void recalculateTotals(double baseDeliveryFee, double perKmFee, double distanceKm, double platformFeeAmount, double gstPct) {
        this.subtotal = items.stream().mapToDouble(i -> i.getPrice() * i.getQuantity()).sum();
        this.subtotal = Math.round(this.subtotal * 100.0) / 100.0;
        this.deliveryFee = Math.round((baseDeliveryFee + (distanceKm * perKmFee)) * 100.0) / 100.0;
        this.platformFee = platformFeeAmount;
        this.taxes = Math.round((subtotal * (gstPct / 100.0)) * 100.0) / 100.0;
        
        double totalBeforeDiscount = subtotal + deliveryFee + platformFee + taxes;
        this.finalTotal = Math.max(0.0, Math.round((totalBeforeDiscount - (discount != null ? discount : 0.0)) * 100.0) / 100.0);
    }
}
