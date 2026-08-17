package com.smartfood.controller;

import com.smartfood.ai.MenuScannerService;
import com.smartfood.dto.response.ApiResponse;
import com.smartfood.model.FoodItem;
import com.smartfood.model.FoodSaverItem;
import com.smartfood.model.Order;
import com.smartfood.model.RestaurantProfile;
import com.smartfood.security.UserPrincipal;
import com.smartfood.service.RestaurantService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/restaurants")
@RequiredArgsConstructor
public class RestaurantController {

    private final RestaurantService restaurantService;
    private final MenuScannerService menuScannerService;

    @GetMapping("/public")
    public ResponseEntity<ApiResponse<List<RestaurantProfile>>> getPublicRestaurants() {
        return ResponseEntity.ok(ApiResponse.success(restaurantService.getApprovedRestaurants()));
    }

    @GetMapping("/public/{id}")
    public ResponseEntity<ApiResponse<RestaurantProfile>> getRestaurantDetails(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success(restaurantService.getRestaurantById(id)));
    }

    @GetMapping("/public/{id}/menu")
    public ResponseEntity<ApiResponse<List<FoodItem>>> getRestaurantPublicMenu(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success(restaurantService.getActiveMenu(id)));
    }

    @GetMapping("/public/{id}/food-saver")
    public ResponseEntity<ApiResponse<List<FoodSaverItem>>> getRestaurantFoodSaverDeals(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success(restaurantService.getRestaurantFoodSaverListings(id)));
    }

    @GetMapping("/profile")
    @PreAuthorize("hasRole('RESTAURANT')")
    public ResponseEntity<ApiResponse<RestaurantProfile>> getMyRestaurantProfile(@AuthenticationPrincipal UserPrincipal user) {
        return ResponseEntity.ok(ApiResponse.success(restaurantService.getRestaurantByUserId(user.getId())));
    }

    @PutMapping("/profile")
    @PreAuthorize("hasRole('RESTAURANT')")
    public ResponseEntity<ApiResponse<RestaurantProfile>> updateProfile(@AuthenticationPrincipal UserPrincipal user,
                                                                        @RequestBody RestaurantProfile profile) {
        return ResponseEntity.ok(ApiResponse.success("Profile updated", restaurantService.updateProfile(user.getId(), profile)));
    }

    @PostMapping("/menu")
    @PreAuthorize("hasRole('RESTAURANT')")
    public ResponseEntity<ApiResponse<FoodItem>> addMenuItem(@AuthenticationPrincipal UserPrincipal user,
                                                             @RequestBody FoodItem item) {
        return ResponseEntity.ok(ApiResponse.success("Menu item added", restaurantService.addFoodItem(user.getId(), item)));
    }

    @PutMapping("/menu/{itemId}")
    @PreAuthorize("hasRole('RESTAURANT')")
    public ResponseEntity<ApiResponse<FoodItem>> updateMenuItem(@AuthenticationPrincipal UserPrincipal user,
                                                                @PathVariable String itemId,
                                                                @RequestBody FoodItem item) {
        return ResponseEntity.ok(ApiResponse.success("Menu item updated", restaurantService.updateFoodItem(user.getId(), itemId, item)));
    }

    @DeleteMapping("/menu/{itemId}")
    @PreAuthorize("hasRole('RESTAURANT')")
    public ResponseEntity<ApiResponse<Void>> deleteMenuItem(@AuthenticationPrincipal UserPrincipal user,
                                                            @PathVariable String itemId) {
        restaurantService.deleteFoodItem(user.getId(), itemId);
        return ResponseEntity.ok(ApiResponse.success("Menu item deleted", null));
    }

    @PostMapping("/food-saver")
    @PreAuthorize("hasRole('RESTAURANT')")
    public ResponseEntity<ApiResponse<FoodSaverItem>> createFoodSaverListing(@AuthenticationPrincipal UserPrincipal user,
                                                                             @RequestBody FoodSaverItem listing) {
        return ResponseEntity.ok(ApiResponse.success("Food Saver listing published", restaurantService.createFoodSaverListing(user.getId(), listing)));
    }

    @GetMapping("/orders")
    @PreAuthorize("hasRole('RESTAURANT')")
    public ResponseEntity<ApiResponse<List<Order>>> getRestaurantOrders(@AuthenticationPrincipal UserPrincipal user) {
        return ResponseEntity.ok(ApiResponse.success(restaurantService.getRestaurantOrders(user.getId())));
    }

    @PostMapping("/ai-menu-scan")
    @PreAuthorize("hasRole('RESTAURANT') or hasRole('HOTEL')")
    public ResponseEntity<ApiResponse<MenuScannerService.ScannedMenuResponse>> scanMenu(
            @RequestParam(required = false) String fileName,
            @RequestBody(required = false) String rawOcrText) {
        var scanned = menuScannerService.scanMenuTextOrImage(fileName, rawOcrText);
        return ResponseEntity.ok(ApiResponse.success("Menu scanned successfully", scanned));
    }
}
