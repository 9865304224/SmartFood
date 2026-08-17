package com.smartfood.repository;

import com.smartfood.model.AiReviewAnalysis;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AiReviewAnalysisRepository extends MongoRepository<AiReviewAnalysis, String> {
    Optional<AiReviewAnalysis> findByTargetTypeAndTargetId(String targetType, String targetId);
}
