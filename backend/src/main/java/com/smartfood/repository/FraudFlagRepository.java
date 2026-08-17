package com.smartfood.repository;

import com.smartfood.model.FraudFlag;
import com.smartfood.model.enums.FraudRiskLevel;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FraudFlagRepository extends MongoRepository<FraudFlag, String> {
    List<FraudFlag> findByUserIdOrderByCreatedAtDesc(String userId);
    List<FraudFlag> findByStatusOrderByCreatedAtDesc(String status);
    List<FraudFlag> findByRiskLevel(FraudRiskLevel riskLevel);
}
