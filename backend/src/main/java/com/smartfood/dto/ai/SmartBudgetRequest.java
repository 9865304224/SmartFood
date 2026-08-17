package com.smartfood.dto.ai;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SmartBudgetRequest {

    @NotNull(message = "Budget amount is required")
    @Min(value = 50, message = "Minimum budget is ₹50")
    private Double budgetAmount; // e.g. 250.0

    private Double userLatitude;
    private Double userLongitude;

    @Builder.Default
    private boolean isVegOnly = false;

    private String preferredCategory; // e.g. "Biryani", "Healthy", "Desserts"
    private Integer numberOfPeople;   // default 1
}
