package com.smartfood.dto.ai;

import com.smartfood.model.FoodItem;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SmartBudgetResponse {

    private Double userBudget;
    private int combinationsFound;
    @Builder.Default
    private List<BudgetComboOption> recommendations = new ArrayList<>();

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BudgetComboOption {
        private String comboTitle; // e.g. "Complete Biryani Feast" or "Saver Meal Deal"
        private String restaurantId;
        private String restaurantName;
        private Double restaurantDistanceKm;
        private List<FoodItem> items;
        private Double itemsTotal;
        private Double deliveryFee;
        private Double platformFee;
        private Double taxes;
        private Double estimatedDiscount;
        private Double grandTotal;
        private Double savingsVsBudget;
        private String smartReason; // e.g. "Fits exactly within ₹250 with ₹18 change!"
    }
}
