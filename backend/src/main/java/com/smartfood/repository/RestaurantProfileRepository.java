package com.smartfood.repository;

import com.smartfood.model.RestaurantProfile;
import com.smartfood.model.enums.ApprovalStatus;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RestaurantProfileRepository extends MongoRepository<RestaurantProfile, String> {
    Optional<RestaurantProfile> findByUserId(String userId);
    List<RestaurantProfile> findByApprovalStatus(ApprovalStatus approvalStatus);
    List<RestaurantProfile> findByApprovalStatusAndIsOpenTrue(ApprovalStatus approvalStatus);
    List<RestaurantProfile> findByCuisineTypesContainingIgnoreCaseAndApprovalStatus(String cuisine, ApprovalStatus approvalStatus);
    long countByApprovalStatus(ApprovalStatus approvalStatus);
}
