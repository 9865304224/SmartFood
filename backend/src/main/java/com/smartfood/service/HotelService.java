package com.smartfood.service;

import com.smartfood.exception.BadRequestException;
import com.smartfood.exception.ResourceNotFoundException;
import com.smartfood.model.FoodItem;
import com.smartfood.model.FoodSaverItem;
import com.smartfood.model.HotelProfile;
import com.smartfood.model.Order;
import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.repository.FoodItemRepository;
import com.smartfood.repository.FoodSaverItemRepository;
import com.smartfood.repository.HotelProfileRepository;
import com.smartfood.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class HotelService {

    private final HotelProfileRepository hotelProfileRepository;
    private final FoodItemRepository foodItemRepository;
    private final FoodSaverItemRepository foodSaverItemRepository;
    private final OrderRepository orderRepository;

    public List<HotelProfile> getApprovedHotels() {
        return hotelProfileRepository.findByApprovalStatusAndIsOpenTrue(ApprovalStatus.APPROVED);
    }

    public List<HotelProfile> getAllApprovedHotels() {
        return hotelProfileRepository.findByApprovalStatus(ApprovalStatus.APPROVED);
    }

    public HotelProfile getHotelById(String id) {
        return hotelProfileRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Hotel", "id", id));
    }

    public HotelProfile getHotelByUserId(String userId) {
        return hotelProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("HotelProfile", "userId", userId));
    }

    public HotelProfile updateProfile(String userId, HotelProfile update) {
        HotelProfile profile = getHotelByUserId(userId);
        if (update.getBusinessName() != null) profile.setBusinessName(update.getBusinessName());
        if (update.getDescription() != null) profile.setDescription(update.getDescription());
        if (update.getAddress() != null) profile.setAddress(update.getAddress());
        if (update.getLocation() != null) profile.setLocation(update.getLocation());
        if (update.getCuisineTypes() != null) profile.setCuisineTypes(update.getCuisineTypes());
        if (update.getBusinessHours() != null) profile.setBusinessHours(update.getBusinessHours());
        if (update.getCoverImageUrl() != null) profile.setCoverImageUrl(update.getCoverImageUrl());
        if (update.getLogoUrl() != null) profile.setLogoUrl(update.getLogoUrl());
        if (update.getMinBulkOrderAmount() != null) profile.setMinBulkOrderAmount(update.getMinBulkOrderAmount());
        if (update.getBulkDiscountPercentage() != null) profile.setBulkDiscountPercentage(update.getBulkDiscountPercentage());
        if (update.getCorporateDiscountPercentage() != null) profile.setCorporateDiscountPercentage(update.getCorporateDiscountPercentage());
        profile.setAllowsBulkOrders(update.isAllowsBulkOrders());
        profile.setAllowsEventCatering(update.isAllowsEventCatering());
        profile.setAllowsScheduledOrders(update.isAllowsScheduledOrders());
        profile.setOpen(update.isOpen());
        profile.setUpdatedAt(Instant.now());
        return hotelProfileRepository.save(profile);
    }

    public FoodItem addBulkMenuItem(String userId, FoodItem item) {
        HotelProfile profile = getHotelByUserId(userId);
        if (profile.getApprovalStatus() != ApprovalStatus.APPROVED) {
            throw new BadRequestException("Cannot manage hotel menu items until approved");
        }
        item.setHotelId(profile.getId());
        item.setRestaurantId(null);
        item.setBulkAvailable(true);
        if (item.getBulkMinQuantity() == null) item.setBulkMinQuantity(10);
        if (item.getBulkPrice() == null) item.setBulkPrice(item.getPrice() * 0.85); // 15% bulk discount by default
        item.setCreatedAt(Instant.now());
        item.setUpdatedAt(Instant.now());
        return foodItemRepository.save(item);
    }

    public List<FoodItem> getHotelMenu(String hotelId) {
        return foodItemRepository.findByHotelId(hotelId);
    }

    public List<FoodItem> getActiveHotelMenu(String hotelId) {
        return foodItemRepository.findByHotelIdAndIsAvailableTrue(hotelId);
    }

    public FoodSaverItem createFoodSaverListing(String userId, FoodSaverItem listing) {
        HotelProfile profile = getHotelByUserId(userId);
        if (profile.getApprovalStatus() != ApprovalStatus.APPROVED) {
            throw new BadRequestException("Cannot create Food Saver listing until approved");
        }
        listing.setHotelId(profile.getId());
        listing.setRestaurantId(null);
        listing.setInitialQuantity(listing.getQuantityAvailable());
        listing.setExpired(false);
        listing.setCreatedAt(Instant.now());
        return foodSaverItemRepository.save(listing);
    }

    public List<Order> getHotelOrders(String userId) {
        HotelProfile profile = getHotelByUserId(userId);
        return orderRepository.findByHotelIdOrderByCreatedAtDesc(profile.getId());
    }
}
