package com.smartfood.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CartItem {
    private String foodItemId;
    private String foodName;
    private Double price;
    private Integer quantity;
    private boolean isVeg;
    private String imageUrl;
    private String notes;
    private boolean isBulkItem;
    private boolean isFoodSaverItem;
}
