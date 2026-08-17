package com.smartfood.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderItem {
    private String foodItemId;
    private String foodName;
    private Double price;
    private Integer quantity;
    private Double itemTotal;
    private boolean isVeg;
    private String imageUrl;
    private String notes;
    private boolean isBulkItem;
    private boolean isFoodSaverItem;
}
