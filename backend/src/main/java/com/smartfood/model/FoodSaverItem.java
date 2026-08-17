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
@Document(collection = "food_saver_items")
public class FoodSaverItem {

    @Id
    private String id;

    @Indexed
    private String restaurantId;

    @Indexed
    private String hotelId;

    private String foodItemId;
    private String foodName;
    private String category;
    private Double normalPrice;
    private Double discountedPrice; // e.g. 50-70% off

    private Integer quantityAvailable;
    private Integer initialQuantity;

    @Indexed
    private Instant availableUntil; // Auto expiry

    @Builder.Default
    private boolean pickupAvailable = true;

    @Builder.Default
    private boolean deliveryAvailable = true;

    private String description;
    private String imageUrl;

    @Builder.Default
    private boolean isVeg = true;

    @Builder.Default
    private boolean isExpired = false;

    @CreatedDate
    private Instant createdAt;

    public boolean isCurrentlyActive() {
        return !isExpired && quantityAvailable != null && quantityAvailable > 0 &&
               availableUntil != null && availableUntil.isAfter(Instant.now());
    }
}
