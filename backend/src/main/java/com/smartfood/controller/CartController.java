package com.smartfood.controller;

import com.smartfood.dto.cart.AddToCartRequest;
import com.smartfood.dto.response.ApiResponse;
import com.smartfood.model.Cart;
import com.smartfood.security.UserPrincipal;
import com.smartfood.service.CartService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/cart")
@RequiredArgsConstructor
public class CartController {

    private final CartService cartService;

    @GetMapping
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Cart>> getCart(@AuthenticationPrincipal UserPrincipal user) {
        return ResponseEntity.ok(ApiResponse.success(cartService.getCart(user.getId())));
    }

    @PostMapping("/add")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Cart>> addToCart(@AuthenticationPrincipal UserPrincipal user,
                                                       @Valid @RequestBody AddToCartRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Item added to cart", cartService.addToCart(user.getId(), request)));
    }

    @PutMapping("/item")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Cart>> updateQuantity(@AuthenticationPrincipal UserPrincipal user,
                                                            @RequestParam String foodItemId,
                                                            @RequestParam int quantity) {
        return ResponseEntity.ok(ApiResponse.success("Cart updated", cartService.updateItemQuantity(user.getId(), foodItemId, quantity)));
    }

    @PostMapping("/coupon")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Cart>> applyCoupon(@AuthenticationPrincipal UserPrincipal user,
                                                         @RequestParam String couponCode) {
        return ResponseEntity.ok(ApiResponse.success("Coupon applied", cartService.applyCoupon(user.getId(), couponCode)));
    }

    @DeleteMapping("/coupon")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Cart>> removeCoupon(@AuthenticationPrincipal UserPrincipal user) {
        return ResponseEntity.ok(ApiResponse.success("Coupon removed", cartService.removeCoupon(user.getId())));
    }

    @DeleteMapping
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> clearCart(@AuthenticationPrincipal UserPrincipal user) {
        cartService.clearCart(user.getId());
        return ResponseEntity.ok(ApiResponse.success("Cart cleared", null));
    }
}
