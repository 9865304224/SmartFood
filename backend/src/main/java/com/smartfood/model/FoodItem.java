package com.smartfood.model;

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
@Document(collection = "food_items")
public class FoodItem {

    @Id
    private String id;

    @Indexed
    private String restaurantId;

    @Indexed
    private String hotelId;

    @Indexed
    private String name;

    private String description;

    @Indexed
    private String category; // category name or id

    private Double price;
    private Double originalPrice; // optional crossed-out MRP

    @Builder.Default
    private boolean isVeg = true;

    @Builder.Default
    private boolean isAvailable = true;

    @Builder.Default
    private Integer preparationTimeMinutes = 20;

    private String imageUrl;

    @Builder.Default
    private Double rating = 4.6;

    @Builder.Default
    private Integer totalOrders = 0;

    @Builder.Default
    private List<String> tags = new ArrayList<>(); // e.g. ["Bestseller", "Spicy", "Chef's Special"]

    private String spiceLevel; // "MILD", "MEDIUM", "HOT"

    // Bulk / Hotel features
    @Builder.Default
    private boolean isBulkAvailable = false;

    private Integer bulkMinQuantity;
    private Double bulkPrice;

    @Builder.Default
    private boolean isFoodSaverDiscounted = false;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;
}
