package com.smartfood.repository;

import com.smartfood.model.Review;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ReviewRepository extends MongoRepository<Review, String> {
    List<Review> findByTargetTypeAndTargetId(String targetType, String targetId);
    Optional<Review> findByOrderId(String orderId);
    boolean existsByOrderId(String orderId);
    List<Review> findByCustomerId(String customerId);
}
