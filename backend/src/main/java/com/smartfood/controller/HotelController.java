package com.smartfood.controller;

import com.smartfood.dto.response.ApiResponse;
import com.smartfood.model.FoodItem;
import com.smartfood.model.FoodSaverItem;
import com.smartfood.model.HotelProfile;
import com.smartfood.model.Order;
import com.smartfood.security.UserPrincipal;
import com.smartfood.service.HotelService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/hotels")
@RequiredArgsConstructor
public class HotelController {

    private final HotelService hotelService;

    @GetMapping("/public")
    public ResponseEntity<ApiResponse<List<HotelProfile>>> getPublicHotels() {
        return ResponseEntity.ok(ApiResponse.success(hotelService.getApprovedHotels()));
    }

    @GetMapping("/public/{id}")
    public ResponseEntity<ApiResponse<HotelProfile>> getHotelDetails(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success(hotelService.getHotelById(id)));
    }

    @GetMapping("/public/{id}/menu")
    public ResponseEntity<ApiResponse<List<FoodItem>>> getHotelPublicMenu(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.success(hotelService.getActiveHotelMenu(id)));
    }

    @GetMapping("/profile")
    @PreAuthorize("hasRole('HOTEL')")
    public ResponseEntity<ApiResponse<HotelProfile>> getMyHotelProfile(@AuthenticationPrincipal UserPrincipal user) {
        return ResponseEntity.ok(ApiResponse.success(hotelService.getHotelByUserId(user.getId())));
    }

    @PutMapping("/profile")
    @PreAuthorize("hasRole('HOTEL')")
    public ResponseEntity<ApiResponse<HotelProfile>> updateProfile(@AuthenticationPrincipal UserPrincipal user,
                                                                   @RequestBody HotelProfile profile) {
        return ResponseEntity.ok(ApiResponse.success("Hotel profile updated", hotelService.updateProfile(user.getId(), profile)));
    }

    @PostMapping("/bulk-menu")
    @PreAuthorize("hasRole('HOTEL')")
    public ResponseEntity<ApiResponse<FoodItem>> addBulkMenuItem(@AuthenticationPrincipal UserPrincipal user,
                                                                 @RequestBody FoodItem item) {
        return ResponseEntity.ok(ApiResponse.success("Bulk menu item added", hotelService.addBulkMenuItem(user.getId(), item)));
    }

    @GetMapping("/orders")
    @PreAuthorize("hasRole('HOTEL')")
    public ResponseEntity<ApiResponse<List<Order>>> getHotelOrders(@AuthenticationPrincipal UserPrincipal user) {
        return ResponseEntity.ok(ApiResponse.success(hotelService.getHotelOrders(user.getId())));
    }
}
