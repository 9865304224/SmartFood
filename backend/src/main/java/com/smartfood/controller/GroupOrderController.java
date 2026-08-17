package com.smartfood.controller;

import com.smartfood.dto.cart.AddToCartRequest;
import com.smartfood.dto.response.ApiResponse;
import com.smartfood.model.GroupOrder;
import com.smartfood.security.UserPrincipal;
import com.smartfood.service.GroupOrderService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/group-orders")
@RequiredArgsConstructor
public class GroupOrderController {

    private final GroupOrderService groupOrderService;

    @Data
    public static class CreateGroupDto {
        private String restaurantId;
        private String hotelId;
    }

    @PostMapping("/create")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<GroupOrder>> createGroup(@AuthenticationPrincipal UserPrincipal user,
                                                               @RequestBody CreateGroupDto dto) {
        return ResponseEntity.ok(ApiResponse.success("Group order room created", 
                groupOrderService.createGroupOrder(user.getId(), dto.getRestaurantId(), dto.getHotelId())));
    }

    @PostMapping("/join")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<GroupOrder>> joinGroup(@AuthenticationPrincipal UserPrincipal user,
                                                             @RequestParam String joinCode) {
        return ResponseEntity.ok(ApiResponse.success("Joined group successfully", 
                groupOrderService.joinGroupOrder(user.getId(), joinCode)));
    }

    @GetMapping("/{joinCode}")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<GroupOrder>> getGroup(@PathVariable String joinCode) {
        return ResponseEntity.ok(ApiResponse.success(groupOrderService.getGroupByJoinCode(joinCode)));
    }

    @PostMapping("/{joinCode}/items")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<GroupOrder>> addItem(@AuthenticationPrincipal UserPrincipal user,
                                                           @PathVariable String joinCode,
                                                           @RequestBody AddToCartRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Item added to group order", 
                groupOrderService.addItemToGroup(user.getId(), joinCode, request)));
    }
}
