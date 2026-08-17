package com.smartfood.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "food_categories")
public class FoodCategory {

    @Id
    private String id;

    @Indexed(unique = true)
    private String name; // e.g. "Biryani", "Pizza", "Burgers", "North Indian", "Chinese", "Desserts", "Healthy", "Beverages"

    private String description;
    private String iconUrl;
    private String bannerImageUrl;

    @Builder.Default
    private Integer displayOrder = 0;

    @Builder.Default
    private boolean isActive = true;
}
