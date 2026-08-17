package com.smartfood.service;

import com.smartfood.dto.cart.AddToCartRequest;
import com.smartfood.exception.BadRequestException;
import com.smartfood.exception.ResourceNotFoundException;
import com.smartfood.model.Cart;
import com.smartfood.model.CartItem;
import com.smartfood.model.Coupon;
import com.smartfood.model.FoodItem;
import com.smartfood.model.FoodSaverItem;
import com.smartfood.model.GeoLocation;
import com.smartfood.model.HotelProfile;
import com.smartfood.model.RestaurantProfile;
import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.repository.CartRepository;
import com.smartfood.repository.CouponRepository;
import com.smartfood.repository.FoodItemRepository;
import com.smartfood.repository.FoodSaverItemRepository;
import com.smartfood.repository.HotelProfileRepository;
import com.smartfood.repository.RestaurantProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class CartService {

    private final CartRepository cartRepository;
    private final FoodItemRepository foodItemRepository;
    private final FoodSaverItemRepository foodSaverItemRepository;
    private final RestaurantProfileRepository restaurantProfileRepository;
    private final HotelProfileRepository hotelProfileRepository;
    private final CouponRepository couponRepository;

    @Value("${smartfood.delivery.base-delivery-fee:30.0}")
    private double baseDeliveryFee;

    @Value("${smartfood.delivery.per-km-fee:8.0}")
    private double perKmFee;

    @Value("${smartfood.delivery.platform-fee:5.0}")
    private double platformFee;

    @Value("${smartfood.delivery.gst-percentage:5.0}")
    private double gstPercentage;

    public Cart getCart(String userId) {
        return cartRepository.findByUserId(userId)
                .orElseGet(() -> Cart.builder()
                        .userId(userId)
                        .items(new ArrayList<>())
                        .build());
    }

    public Cart addToCart(String userId, AddToCartRequest request) {
        Cart cart = getCart(userId);

        String itemRestaurantId = request.getRestaurantId();
        String itemHotelId = request.getHotelId();
        String foodName;
        Double price;
        boolean isVeg = true;
        String imageUrl = null;

        if (request.isFoodSaverItem()) {
            FoodSaverItem saverItem = foodSaverItemRepository.findById(request.getFoodItemId())
                    .orElseThrow(() -> new ResourceNotFoundException("FoodSaverItem", "id", request.getFoodItemId()));
            if (!saverItem.isCurrentlyActive()) {
                throw new BadRequestException("This Food Saver deal has expired or is out of stock");
            }
            if (saverItem.getQuantityAvailable() < request.getQuantity()) {
                throw new BadRequestException("Only " + saverItem.getQuantityAvailable() + " items available for this deal");
            }
            itemRestaurantId = saverItem.getRestaurantId();
            itemHotelId = saverItem.getHotelId();
            foodName = saverItem.getFoodName();
            price = saverItem.getDiscountedPrice();
            isVeg = saverItem.isVeg();
            imageUrl = saverItem.getImageUrl();
        } else {
            FoodItem foodItem = foodItemRepository.findById(request.getFoodItemId())
                    .orElseThrow(() -> new ResourceNotFoundException("FoodItem", "id", request.getFoodItemId()));
            if (!foodItem.isAvailable()) {
                throw new BadRequestException("Food item is currently unavailable");
            }
            itemRestaurantId = foodItem.getRestaurantId();
            itemHotelId = foodItem.getHotelId();
            foodName = foodItem.getName();
            price = request.isBulkItem() && foodItem.getBulkPrice() != null ? foodItem.getBulkPrice() : foodItem.getPrice();
            isVeg = foodItem.isVeg();
            imageUrl = foodItem.getImageUrl();
        }

        // Validate Single-Restaurant/Hotel Cart Constraint
        if (!cart.getItems().isEmpty()) {
            boolean mismatch = false;
            if (itemRestaurantId != null && cart.getRestaurantId() != null && !cart.getRestaurantId().equals(itemRestaurantId)) {
                mismatch = true;
            }
            if (itemHotelId != null && cart.getHotelId() != null && !cart.getHotelId().equals(itemHotelId)) {
                mismatch = true;
            }
            if ((itemRestaurantId != null && cart.getHotelId() != null) || (itemHotelId != null && cart.getRestaurantId() != null)) {
                mismatch = true;
            }

            if (mismatch) {
                throw new BadRequestException("Your cart contains items from a different restaurant/hotel. Please clear your cart first.");
            }
        } else {
            // Set cart restaurant/hotel
            cart.setRestaurantId(itemRestaurantId);
            cart.setHotelId(itemHotelId);
            final String finalResId = itemRestaurantId;
            final String finalHotelId = itemHotelId;
            if (finalResId != null) {
                RestaurantProfile res = restaurantProfileRepository.findById(finalResId)
                        .orElseThrow(() -> new ResourceNotFoundException("Restaurant", "id", finalResId));
                if (res.getApprovalStatus() != ApprovalStatus.APPROVED) {
                    throw new BadRequestException("Restaurant is currently not accepting orders");
                }
                cart.setBusinessName(res.getBusinessName());
            } else if (finalHotelId != null) {
                HotelProfile hotel = hotelProfileRepository.findById(finalHotelId)
                        .orElseThrow(() -> new ResourceNotFoundException("Hotel", "id", finalHotelId));
                if (hotel.getApprovalStatus() != ApprovalStatus.APPROVED) {
                    throw new BadRequestException("Hotel is currently not accepting orders");
                }
                cart.setBusinessName(hotel.getBusinessName());
            }
        }

        // Check if item already exists in cart
        final String targetFoodItemId = request.getFoodItemId();
        Optional<CartItem> existingItem = cart.getItems().stream()
                .filter(i -> i.getFoodItemId().equals(targetFoodItemId))
                .findFirst();

        if (existingItem.isPresent()) {
            existingItem.get().setQuantity(existingItem.get().getQuantity() + request.getQuantity());
            if (request.getNotes() != null) existingItem.get().setNotes(request.getNotes());
        } else {
            cart.getItems().add(CartItem.builder()
                    .foodItemId(targetFoodItemId)
                    .foodName(foodName)
                    .price(price)
                    .quantity(request.getQuantity())
                    .isVeg(isVeg)
                    .imageUrl(imageUrl)
                    .notes(request.getNotes())
                    .isBulkItem(request.isBulkItem())
                    .isFoodSaverItem(request.isFoodSaverItem())
                    .build());
        }

        cart.setUpdatedAt(Instant.now());
        recalculateCart(cart, 2.5); // Default estimated 2.5 km distance
        return cartRepository.save(cart);
    }

    public Cart updateItemQuantity(String userId, String foodItemId, int quantity) {
        Cart cart = getCart(userId);
        if (quantity <= 0) {
            cart.getItems().removeIf(i -> i.getFoodItemId().equals(foodItemId));
            if (cart.getItems().isEmpty()) {
                cart.setRestaurantId(null);
                cart.setHotelId(null);
                cart.setBusinessName(null);
                cart.setAppliedCouponCode(null);
                cart.setDiscount(0.0);
            }
        } else {
            cart.getItems().stream()
                    .filter(i -> i.getFoodItemId().equals(foodItemId))
                    .findFirst()
                    .ifPresent(i -> i.setQuantity(quantity));
        }

        cart.setUpdatedAt(Instant.now());
        recalculateCart(cart, 2.5);
        return cartRepository.save(cart);
    }

    public Cart applyCoupon(String userId, String couponCode) {
        Cart cart = getCart(userId);
        if (cart.getItems().isEmpty()) {
            throw new BadRequestException("Cannot apply coupon to an empty cart");
        }

        Coupon coupon = couponRepository.findByCodeIgnoreCase(couponCode.trim())
                .orElseThrow(() -> new ResourceNotFoundException("Coupon", "code", couponCode));

        if (!coupon.isValidForOrder(cart.getSubtotal(), cart.getRestaurantId(), cart.getHotelId())) {
            throw new BadRequestException("Coupon is invalid, expired, or does not meet minimum order value");
        }

        double discount = coupon.calculateDiscount(cart.getSubtotal());
        cart.setAppliedCouponCode(coupon.getCode());
        cart.setDiscount(discount);
        recalculateCart(cart, 2.5);
        return cartRepository.save(cart);
    }

    public Cart removeCoupon(String userId) {
        Cart cart = getCart(userId);
        cart.setAppliedCouponCode(null);
        cart.setDiscount(0.0);
        recalculateCart(cart, 2.5);
        return cartRepository.save(cart);
    }

    public void clearCart(String userId) {
        cartRepository.deleteByUserId(userId);
    }

    public void recalculateCart(Cart cart, double distanceKm) {
        cart.recalculateTotals(baseDeliveryFee, perKmFee, distanceKm, platformFee, gstPercentage);
    }
}
