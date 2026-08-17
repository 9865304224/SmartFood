package com.smartfood.ai;

import com.smartfood.dto.ai.SmartBudgetRequest;
import com.smartfood.dto.ai.SmartBudgetResponse;
import com.smartfood.dto.ai.SmartBudgetResponse.BudgetComboOption;
import com.smartfood.model.FoodItem;
import com.smartfood.model.GeoLocation;
import com.smartfood.model.RestaurantProfile;
import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.repository.FoodItemRepository;
import com.smartfood.repository.RestaurantProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class SmartBudgetService {

    private final FoodItemRepository foodItemRepository;
    private final RestaurantProfileRepository restaurantProfileRepository;

    public SmartBudgetResponse findOptimalFoodForBudget(SmartBudgetRequest request) {
        double budget = request.getBudgetAmount();
        log.info("Computing Smart Budget recommendations for budget: ₹{}", budget);

        List<RestaurantProfile> openRestaurants = restaurantProfileRepository.findByApprovalStatusAndIsOpenTrue(ApprovalStatus.APPROVED);
        Map<String, RestaurantProfile> resMap = openRestaurants.stream()
                .collect(Collectors.toMap(RestaurantProfile::getId, r -> r));

        List<FoodItem> availableItems = foodItemRepository.findByIsAvailableTrue();
        if (request.isVegOnly()) {
            availableItems = availableItems.stream().filter(FoodItem::isVeg).toList();
        }

        // Group food items by restaurant
        Map<String, List<FoodItem>> itemsByRestaurant = availableItems.stream()
                .filter(i -> i.getRestaurantId() != null && resMap.containsKey(i.getRestaurantId()))
                .collect(Collectors.groupingBy(FoodItem::getRestaurantId));

        List<BudgetComboOption> options = new ArrayList<>();

        for (var entry : itemsByRestaurant.entrySet()) {
            String resId = entry.getKey();
            RestaurantProfile res = resMap.get(resId);
            List<FoodItem> resItems = entry.getValue();

            double distanceKm = 2.5;
            if (request.getUserLatitude() != null && request.getUserLongitude() != null && res.getLocation() != null) {
                GeoLocation userLoc = GeoLocation.builder().latitude(request.getUserLatitude()).longitude(request.getUserLongitude()).build();
                distanceKm = userLoc.distanceTo(res.getLocation());
                if (distanceKm == 0.0) distanceKm = 2.5;
            }

            double deliveryFee = 30.0 + (distanceKm * 5.0); // Discounted delivery for budget
            double platformFee = 5.0;
            double gstPct = 0.05;

            // Strategy 1: Single Satisfying Meal (Main Dish)
            for (FoodItem item : resItems) {
                double itemsTotal = item.getPrice();
                double taxes = itemsTotal * gstPct;
                double discount = itemsTotal > 150 ? 20.0 : 0.0; // Simulated coupon discount
                double grandTotal = Math.round((itemsTotal + deliveryFee + platformFee + taxes - discount) * 100.0) / 100.0;

                if (grandTotal <= budget) {
                    options.add(BudgetComboOption.builder()
                            .comboTitle("Complete " + item.getName() + " Meal")
                            .restaurantId(resId)
                            .restaurantName(res.getBusinessName())
                            .restaurantDistanceKm(Math.round(distanceKm * 10.0) / 10.0)
                            .items(List.of(item))
                            .itemsTotal(itemsTotal)
                            .deliveryFee(Math.round(deliveryFee * 100.0) / 100.0)
                            .platformFee(platformFee)
                            .taxes(Math.round(taxes * 100.0) / 100.0)
                            .estimatedDiscount(discount)
                            .grandTotal(grandTotal)
                            .savingsVsBudget(Math.round((budget - grandTotal) * 100.0) / 100.0)
                            .smartReason("Fits perfectly within ₹" + (int)budget + " with all fees included!")
                            .build());
                }
            }

            // Strategy 2: Multi-Item Combo (Main + Side/Beverage)
            if (resItems.size() >= 2) {
                for (int i = 0; i < resItems.size(); i++) {
                    for (int j = i + 1; j < resItems.size(); j++) {
                        FoodItem item1 = resItems.get(i);
                        FoodItem item2 = resItems.get(j);

                        double itemsTotal = item1.getPrice() + item2.getPrice();
                        double taxes = itemsTotal * gstPct;
                        double discount = itemsTotal > 180 ? 30.0 : 10.0;
                        double grandTotal = Math.round((itemsTotal + deliveryFee + platformFee + taxes - discount) * 100.0) / 100.0;

                        if (grandTotal <= budget) {
                            options.add(BudgetComboOption.builder()
                                    .comboTitle(item1.getName() + " + " + item2.getName())
                                    .restaurantId(resId)
                                    .restaurantName(res.getBusinessName())
                                    .restaurantDistanceKm(Math.round(distanceKm * 10.0) / 10.0)
                                    .items(List.of(item1, item2))
                                    .itemsTotal(itemsTotal)
                                    .deliveryFee(Math.round(deliveryFee * 100.0) / 100.0)
                                    .platformFee(platformFee)
                                    .taxes(Math.round(taxes * 100.0) / 100.0)
                                    .estimatedDiscount(discount)
                                    .grandTotal(grandTotal)
                                    .savingsVsBudget(Math.round((budget - grandTotal) * 100.0) / 100.0)
                                    .smartReason("2-Item Value Combo remaining under ₹" + (int)budget)
                                    .build());
                        }
                    }
                }
            }
        }

        // Sort by highest rating and closest distance
        options.sort(Comparator.comparingDouble(BudgetComboOption::getGrandTotal).reversed());
        List<BudgetComboOption> topRecommendations = options.stream().limit(8).toList();

        return SmartBudgetResponse.builder()
                .userBudget(budget)
                .combinationsFound(topRecommendations.size())
                .recommendations(topRecommendations)
                .build();
    }
}
