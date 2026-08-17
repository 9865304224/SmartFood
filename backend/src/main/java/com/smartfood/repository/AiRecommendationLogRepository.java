package com.smartfood.repository;

import com.smartfood.model.AiRecommendationLog;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AiRecommendationLogRepository extends MongoRepository<AiRecommendationLog, String> {
    Optional<AiRecommendationLog> findTopByCustomerIdOrderByGeneratedAtDesc(String customerId);
}
