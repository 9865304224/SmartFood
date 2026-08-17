package com.smartfood.controller;

import com.smartfood.ai.RecommendationService;
import com.smartfood.ai.SmartBudgetService;
import com.smartfood.dto.ai.SmartBudgetRequest;
import com.smartfood.dto.ai.SmartBudgetResponse;
import com.smartfood.dto.response.ApiResponse;
import com.smartfood.model.FoodItem;
import com.smartfood.repository.FoodItemRepository;
import com.smartfood.security.UserPrincipal;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/recommendations")
@RequiredArgsConstructor
public class RecommendationController {

    private final RecommendationService recommendationService;
    private final SmartBudgetService smartBudgetService;
    private final FoodItemRepository foodItemRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<RecommendationService.RecommendationSection>>> getRecommendations(
            @AuthenticationPrincipal UserPrincipal user) {
        String customerId = (user != null) ? user.getId() : null;
        return ResponseEntity.ok(ApiResponse.success(recommendationService.getPersonalizedRecommendations(customerId)));
    }

    @PostMapping("/smart-budget")
    public ResponseEntity<ApiResponse<SmartBudgetResponse>> getSmartBudgetCombos(@Valid @RequestBody SmartBudgetRequest request) {
        return ResponseEntity.ok(ApiResponse.success(smartBudgetService.findOptimalFoodForBudget(request)));
    }

    @PostMapping("/ai-assistant")
    public ResponseEntity<ApiResponse<RecommendationService.CustomerAiAssistantResponse>> askAiAssistant(
            @RequestParam String query,
            @AuthenticationPrincipal UserPrincipal user) {
        String customerId = (user != null) ? user.getId() : null;
        return ResponseEntity.ok(ApiResponse.success("AI Recommendation generated", recommendationService.askAiFoodAssistant(query, customerId)));
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class VoiceSearchResult {
        private String originalQuery;
        private String interpretedIntent;
        private boolean isVegOnly;
        private Double maxBudget;
        private String category;
        private List<FoodItem> matchingItems;
    }

    @GetMapping("/voice-search")
    public ResponseEntity<ApiResponse<VoiceSearchResult>> parseVoiceSearch(@RequestParam String query) {
        String lower = query.toLowerCase().trim();
        boolean vegOnly = lower.contains("veg") && !lower.contains("non-veg") && !lower.contains("nonveg");

        Double maxBudget = null;
        String[] words = lower.split("\\s+");
        for (int i = 0; i < words.length; i++) {
            if (words[i].equals("under") || words[i].equals("below") || words[i].equals("within")) {
                if (i + 1 < words.length) {
                    try {
                        String numStr = words[i + 1].replaceAll("[^0-9.]", "");
                        if (!numStr.isBlank()) {
                            maxBudget = Double.parseDouble(numStr);
                        }
                    } catch (Exception ignored) {}
                }
            }
        }

        String category = null;
        if (lower.contains("biryani")) category = "Biryani";
        else if (lower.contains("pizza")) category = "Pizza";
        else if (lower.contains("burger")) category = "Burgers";
        else if (lower.contains("dessert") || lower.contains("sweet")) category = "Desserts";
        else if (lower.contains("north indian") || lower.contains("paneer")) category = "North Indian";

        List<FoodItem> items = foodItemRepository.findByIsAvailableTrue();
        final boolean fVeg = vegOnly;
        final Double fBudget = maxBudget;
        final String fCategory = category;

        List<FoodItem> matching = items.stream()
                .filter(i -> !fVeg || i.isVeg())
                .filter(i -> fBudget == null || (i.getPrice() != null && i.getPrice() <= fBudget))
                .filter(i -> fCategory == null || (i.getCategory() != null && i.getCategory().toLowerCase().contains(fCategory.toLowerCase())) || i.getName().toLowerCase().contains(lower))
                .limit(10)
                .toList();

        VoiceSearchResult result = VoiceSearchResult.builder()
                .originalQuery(query)
                .interpretedIntent("Searching for " + (vegOnly ? "Vegetarian " : "") + (category != null ? category + " " : "food ") + (maxBudget != null ? "under ₹" + maxBudget.intValue() : ""))
                .isVegOnly(vegOnly)
                .maxBudget(maxBudget)
                .category(category)
                .matchingItems(matching)
                .build();

        return ResponseEntity.ok(ApiResponse.success("Voice query parsed successfully", result));
    }
}
