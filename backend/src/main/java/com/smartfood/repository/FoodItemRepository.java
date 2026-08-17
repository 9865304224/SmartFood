package com.smartfood.repository;

import com.smartfood.model.FoodItem;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FoodItemRepository extends MongoRepository<FoodItem, String> {
    List<FoodItem> findByRestaurantIdAndIsAvailableTrue(String restaurantId);
    List<FoodItem> findByHotelIdAndIsAvailableTrue(String hotelId);
    List<FoodItem> findByRestaurantId(String restaurantId);
    List<FoodItem> findByHotelId(String hotelId);
    List<FoodItem> findByCategoryAndIsAvailableTrue(String category);
    List<FoodItem> findByIsAvailableTrue();
    List<FoodItem> findByNameContainingIgnoreCaseAndIsAvailableTrue(String name);

    @Query("{ 'isAvailable': true, 'price': { $lte: ?0 } }")
    List<FoodItem> findByPriceLessThanEqual(Double maxPrice);

    @Query("{ 'isAvailable': true, 'isVeg': true, 'price': { $lte: ?0 } }")
    List<FoodItem> findVegItemsUnderBudget(Double maxPrice);

    List<FoodItem> findTop10ByIsAvailableTrueOrderByRatingDesc();
    List<FoodItem> findTop10ByIsAvailableTrueOrderByTotalOrdersDesc();
}
