package com.smartfood.repository;

import com.smartfood.model.Coupon;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CouponRepository extends MongoRepository<Coupon, String> {
    Optional<Coupon> findByCodeIgnoreCase(String code);
    List<Coupon> findByIsActiveTrue();
    List<Coupon> findByRestaurantIdAndIsActiveTrue(String restaurantId);
    List<Coupon> findByHotelIdAndIsActiveTrue(String hotelId);
    boolean existsByCodeIgnoreCase(String code);
}
