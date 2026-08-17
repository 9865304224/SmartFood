package com.smartfood.repository;

import com.smartfood.model.HotelProfile;
import com.smartfood.model.enums.ApprovalStatus;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface HotelProfileRepository extends MongoRepository<HotelProfile, String> {
    Optional<HotelProfile> findByUserId(String userId);
    List<HotelProfile> findByApprovalStatus(ApprovalStatus approvalStatus);
    List<HotelProfile> findByApprovalStatusAndIsOpenTrue(ApprovalStatus approvalStatus);
    long countByApprovalStatus(ApprovalStatus approvalStatus);
}
