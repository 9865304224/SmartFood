package com.smartfood.repository;

import com.smartfood.model.FoodSaverItem;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface FoodSaverItemRepository extends MongoRepository<FoodSaverItem, String> {
    List<FoodSaverItem> findByRestaurantId(String restaurantId);
    List<FoodSaverItem> findByHotelId(String hotelId);

    @Query("{ 'isExpired': false, 'quantityAvailable': { $gt: 0 }, 'availableUntil': { $gt: ?0 } }")
    List<FoodSaverItem> findActiveItems(Instant now);

    @Query("{ 'isExpired': false, 'availableUntil': { $lte: ?0 } }")
    List<FoodSaverItem> findItemsToExpire(Instant now);
}
