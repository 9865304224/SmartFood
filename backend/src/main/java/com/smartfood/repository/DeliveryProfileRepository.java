package com.smartfood.repository;

import com.smartfood.model.DeliveryProfile;
import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.model.enums.DeliveryStatus;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryProfileRepository extends MongoRepository<DeliveryProfile, String> {
    Optional<DeliveryProfile> findByUserId(String userId);
    List<DeliveryProfile> findByApprovalStatus(ApprovalStatus approvalStatus);
    List<DeliveryProfile> findByApprovalStatusAndCurrentStatus(ApprovalStatus approvalStatus, DeliveryStatus currentStatus);
    long countByApprovalStatus(ApprovalStatus approvalStatus);
}
