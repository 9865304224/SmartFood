package com.smartfood.service;

import com.smartfood.exception.BadRequestException;
import com.smartfood.exception.ResourceNotFoundException;
import com.smartfood.model.FoodCategory;
import com.smartfood.model.FoodItem;
import com.smartfood.model.FoodSaverItem;
import com.smartfood.model.Order;
import com.smartfood.model.RestaurantProfile;
import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.model.enums.OrderStatus;
import com.smartfood.repository.FoodCategoryRepository;
import com.smartfood.repository.FoodItemRepository;
import com.smartfood.repository.FoodSaverItemRepository;
import com.smartfood.repository.OrderRepository;
import com.smartfood.repository.RestaurantProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class RestaurantService {

    private final RestaurantProfileRepository restaurantProfileRepository;
    private final FoodItemRepository foodItemRepository;
    private final FoodSaverItemRepository foodSaverItemRepository;
    private final FoodCategoryRepository foodCategoryRepository;
    private final OrderRepository orderRepository;

    public List<RestaurantProfile> getApprovedRestaurants() {
        return restaurantProfileRepository.findByApprovalStatusAndIsOpenTrue(ApprovalStatus.APPROVED);
    }

    public List<RestaurantProfile> getAllApprovedRestaurants() {
        return restaurantProfileRepository.findByApprovalStatus(ApprovalStatus.APPROVED);
    }

    public RestaurantProfile getRestaurantById(String id) {
        return restaurantProfileRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurant", "id", id));
    }

    public RestaurantProfile getRestaurantByUserId(String userId) {
        return restaurantProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("RestaurantProfile", "userId", userId));
    }

    public RestaurantProfile updateProfile(String userId, RestaurantProfile update) {
        RestaurantProfile profile = getRestaurantByUserId(userId);
        if (update.getBusinessName() != null) profile.setBusinessName(update.getBusinessName());
        if (update.getDescription() != null) profile.setDescription(update.getDescription());
        if (update.getAddress() != null) profile.setAddress(update.getAddress());
        if (update.getLocation() != null) profile.setLocation(update.getLocation());
        if (update.getCuisineTypes() != null) profile.setCuisineTypes(update.getCuisineTypes());
        if (update.getBusinessHours() != null) profile.setBusinessHours(update.getBusinessHours());
        if (update.getCoverImageUrl() != null) profile.setCoverImageUrl(update.getCoverImageUrl());
        if (update.getLogoUrl() != null) profile.setLogoUrl(update.getLogoUrl());
        if (update.getPreparationTimeMinutes() != null) profile.setPreparationTimeMinutes(update.getPreparationTimeMinutes());
        profile.setOpen(update.isOpen());
        profile.setPureVeg(update.isPureVeg());
        profile.setUpdatedAt(Instant.now());
        return restaurantProfileRepository.save(profile);
    }

    public FoodItem addFoodItem(String userId, FoodItem item) {
        RestaurantProfile profile = getRestaurantByUserId(userId);
        if (profile.getApprovalStatus() != ApprovalStatus.APPROVED) {
            throw new BadRequestException("Cannot manage menu items until restaurant is approved by Admin");
        }
        item.setRestaurantId(profile.getId());
        item.setHotelId(null);
        item.setCreatedAt(Instant.now());
        item.setUpdatedAt(Instant.now());
        return foodItemRepository.save(item);
    }

    public FoodItem updateFoodItem(String userId, String itemId, FoodItem item) {
        RestaurantProfile profile = getRestaurantByUserId(userId);
        FoodItem existing = foodItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("FoodItem", "id", itemId));

        if (!profile.getId().equals(existing.getRestaurantId())) {
            throw new BadRequestException("You do not own this menu item");
        }

        if (item.getName() != null) existing.setName(item.getName());
        if (item.getDescription() != null) existing.setDescription(item.getDescription());
        if (item.getCategory() != null) existing.setCategory(item.getCategory());
        if (item.getPrice() != null) existing.setPrice(item.getPrice());
        if (item.getImageUrl() != null) existing.setImageUrl(item.getImageUrl());
        if (item.getPreparationTimeMinutes() != null) existing.setPreparationTimeMinutes(item.getPreparationTimeMinutes());
        if (item.getTags() != null) existing.setTags(item.getTags());
        existing.setVeg(item.isVeg());
        existing.setAvailable(item.isAvailable());
        existing.setUpdatedAt(Instant.now());
        return foodItemRepository.save(existing);
    }

    public void deleteFoodItem(String userId, String itemId) {
        RestaurantProfile profile = getRestaurantByUserId(userId);
        FoodItem existing = foodItemRepository.findById(itemId)
                .orElseThrow(() -> new ResourceNotFoundException("FoodItem", "id", itemId));

        if (!profile.getId().equals(existing.getRestaurantId())) {
            throw new BadRequestException("You do not own this menu item");
        }
        foodItemRepository.delete(existing);
    }

    public List<FoodItem> getMenu(String restaurantId) {
        return foodItemRepository.findByRestaurantId(restaurantId);
    }

    public List<FoodItem> getActiveMenu(String restaurantId) {
        return foodItemRepository.findByRestaurantIdAndIsAvailableTrue(restaurantId);
    }

    public FoodSaverItem createFoodSaverListing(String userId, FoodSaverItem listing) {
        RestaurantProfile profile = getRestaurantByUserId(userId);
        if (profile.getApprovalStatus() != ApprovalStatus.APPROVED) {
            throw new BadRequestException("Cannot create Food Saver listing until approved");
        }
        listing.setRestaurantId(profile.getId());
        listing.setHotelId(null);
        listing.setInitialQuantity(listing.getQuantityAvailable());
        listing.setExpired(false);
        listing.setCreatedAt(Instant.now());
        return foodSaverItemRepository.save(listing);
    }

    public List<FoodSaverItem> getRestaurantFoodSaverListings(String restaurantId) {
        return foodSaverItemRepository.findByRestaurantId(restaurantId);
    }

    public List<Order> getRestaurantOrders(String userId) {
        RestaurantProfile profile = getRestaurantByUserId(userId);
        return orderRepository.findByRestaurantIdOrderByCreatedAtDesc(profile.getId());
    }
}
