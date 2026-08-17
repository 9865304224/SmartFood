package com.smartfood.repository;

import com.smartfood.model.GroupOrder;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface GroupOrderRepository extends MongoRepository<GroupOrder, String> {
    Optional<GroupOrder> findByJoinCode(String joinCode);
    Optional<GroupOrder> findByCreatorUserIdAndStatus(String creatorUserId, String status);
}
