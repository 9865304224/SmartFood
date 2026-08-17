package com.smartfood.ai;

import com.smartfood.model.CustomerProfile;
import com.smartfood.model.FoodItem;
import com.smartfood.model.Order;
import com.smartfood.model.OrderItem;
import com.smartfood.model.RestaurantProfile;
import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.repository.CustomerProfileRepository;
import com.smartfood.repository.FoodItemRepository;
import com.smartfood.repository.OrderRepository;
import com.smartfood.repository.RestaurantProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class RecommendationService {

    private final FoodItemRepository foodItemRepository;
    private final OrderRepository orderRepository;
    private final CustomerProfileRepository customerProfileRepository;
    private final RestaurantProfileRepository restaurantProfileRepository;
    private final GeminiAiService geminiAiService;

    public record RecommendationSection(String title, String subtitle, String reason, List<FoodItem> items) {}

    public record CustomerAiAssistantResponse(
            String query,
            String answer,
            String intent,
            List<FoodItem> recommendedItems,
            String aiTip
    ) {}

    public List<RecommendationSection> getPersonalizedRecommendations(String customerId) {
        List<RecommendationSection> sections = new ArrayList<>();

        List<FoodItem> allAvailable = foodItemRepository.findByIsAvailableTrue();
        if (allAvailable.isEmpty()) {
            return sections;
        }

        // 1. Time of Day dynamic section
        LocalTime now = LocalTime.now();
        String timeSectionTitle;
        String timeCategory;
        if (now.isBefore(LocalTime.of(11, 30))) {
            timeSectionTitle = "Energizing Breakfast & Chai";
            timeCategory = "Breakfast";
        } else if (now.isBefore(LocalTime.of(16, 0))) {
            timeSectionTitle = "Popular Lunch Specials";
            timeCategory = "Biryani";
        } else if (now.isBefore(LocalTime.of(19, 30))) {
            timeSectionTitle = "Evening Snacks & Quick Bites";
            timeCategory = "Burgers";
        } else {
            timeSectionTitle = "Top Picks for Dinner";
            timeCategory = "North Indian";
        }

        List<FoodItem> timeItems = allAvailable.stream()
                .filter(i -> i.getCategory() != null && i.getCategory().toLowerCase().contains(timeCategory.toLowerCase()))
                .limit(6)
                .toList();

        if (!timeItems.isEmpty()) {
            sections.add(new RecommendationSection(timeSectionTitle, "Freshly prepared for right now", "TIMING_BASED", timeItems));
        }

        // 2. Previous Order History Analysis
        if (customerId != null) {
            List<Order> userOrders = orderRepository.findByCustomerIdOrderByCreatedAtDesc(customerId);
            if (!userOrders.isEmpty()) {
                Set<String> pastFoodNames = userOrders.stream()
                        .flatMap(o -> o.getItems().stream())
                        .map(OrderItem::getFoodName)
                        .collect(Collectors.toSet());

                String samplePrevious = pastFoodNames.iterator().next();

                List<FoodItem> similarItems = allAvailable.stream()
                        .filter(i -> !pastFoodNames.contains(i.getName()))
                        .limit(6)
                        .toList();

                if (!similarItems.isEmpty()) {
                    sections.add(new RecommendationSection(
                            "Because you ordered " + samplePrevious,
                            "Similar tastes you will love",
                            "COLLABORATIVE_FILTERING",
                            similarItems
                    ));
                }
            }
        }

        // 3. Best Value Under ₹200
        List<FoodItem> budgetPicks = allAvailable.stream()
                .filter(i -> i.getPrice() != null && i.getPrice() <= 200.0)
                .sorted((a, b) -> Double.compare(b.getRating(), a.getRating()))
                .limit(6)
                .toList();

        if (!budgetPicks.isEmpty()) {
            sections.add(new RecommendationSection(
                    "Pocket-Friendly Feasts (Under ₹200)",
                    "High ratings without breaking the bank",
                    "BUDGET_OPTIMIZED",
                    budgetPicks
            ));
        }

        // 4. Chef's Highest Rated
        List<FoodItem> topRated = allAvailable.stream()
                .sorted((a, b) -> Double.compare(b.getRating(), a.getRating()))
                .limit(6)
                .toList();

        sections.add(new RecommendationSection(
                "Trending & Bestsellers Near You",
                "Loved by foodies in your neighborhood",
                "POPULARITY_TREND",
                topRated
        ));

        return sections;
    }

    public CustomerAiAssistantResponse askAiFoodAssistant(String query, String customerId) {
        List<FoodItem> all = foodItemRepository.findByIsAvailableTrue();

        // 1. Try Gemini AI First
        if (geminiAiService.isConfigured()) {
            CustomerAiAssistantResponse geminiRes = geminiAiService.askGeminiFoodAssistant(query, all, customerId);
            if (geminiRes != null) {
                return geminiRes;
            }
        }

        // 2. Smart Deterministic Fallback Engine
        String lower = query.toLowerCase().trim();

        boolean isVeg = lower.contains("veg") && !lower.contains("non-veg") && !lower.contains("nonveg");
        boolean isSpicy = lower.contains("spicy") || lower.contains("hot") || lower.contains("masala");
        boolean isDessert = lower.contains("sweet") || lower.contains("dessert") || lower.contains("ice cream") || lower.contains("cake");
        boolean isHealthy = lower.contains("healthy") || lower.contains("salad") || lower.contains("protein") || lower.contains("diet") || lower.contains("gym");

        Double budget = null;
        for (String word : lower.split("\\s+")) {
            String clean = word.replaceAll("[^0-9]", "");
            if (!clean.isBlank()) {
                try {
                    double val = Double.parseDouble(clean);
                    if (val >= 50 && val <= 5000) {
                        budget = val;
                        break;
                    }
                } catch (Exception ignored) {}
            }
        }

        final boolean fVeg = isVeg;
        final Double fBudget = budget;

        List<FoodItem> matches = all.stream()
                .filter(i -> !fVeg || i.isVeg())
                .filter(i -> fBudget == null || (i.getPrice() != null && i.getPrice() <= fBudget))
                .filter(i -> {
                    if (isDessert) return i.getCategory() != null && i.getCategory().equalsIgnoreCase("Desserts");
                    if (isHealthy) return i.isVeg() || (i.getCategory() != null && i.getCategory().contains("Healthy"));
                    if (lower.contains("biryani")) return i.getName().toLowerCase().contains("biryani");
                    if (lower.contains("pizza")) return i.getName().toLowerCase().contains("pizza");
                    if (lower.contains("burger")) return i.getName().toLowerCase().contains("burger");
                    return true;
                })
                .sorted((a, b) -> Double.compare(b.getRating(), a.getRating()))
                .limit(5)
                .toList();

        if (matches.isEmpty()) {
            matches = all.stream().limit(4).toList();
        }

        String answer;
        String tip;
        if (isDessert) {
            answer = "Here are the top-rated artisanal desserts and sweet cravings prepared fresh near you!";
            tip = "Pro-tip: Pair warm Gulab Jamuns with chilled ice cream for the ultimate treat.";
        } else if (isHealthy) {
            answer = "Great healthy choices! Here are high-protein, nutrient-rich bowls and clean meals matching your taste.";
            tip = "Pro-tip: Opt for salads and whole grains for sustained afternoon energy.";
        } else if (budget != null) {
            answer = String.format("Found fantastic culinary combos fitting your ₹%d budget with guaranteed fast delivery!", budget.intValue());
            tip = "Pro-tip: Apply coupons at checkout to save an extra 20% on these items.";
        } else if (isSpicy) {
            answer = "Craving bold and fiery flavors? Check out these rich aromatic delicacies with authentic spices!";
            tip = "Pro-tip: Add raita or butter naan to balance the spice perfectly.";
        } else {
            answer = "Based on top ratings in your neighborhood, here are the chef's most recommended signature dishes!";
            tip = "Pro-tip: You can tap 'Add to Cart' to start your order instantly.";
        }

        return new CustomerAiAssistantResponse(query, answer, isHealthy ? "HEALTHY" : (isDessert ? "DESSERT" : "MEAL_DISCOVERY"), matches, tip);
    }
}
