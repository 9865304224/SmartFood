package com.smartfood.repository;

import com.smartfood.model.DeliveryAssignment;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryAssignmentRepository extends MongoRepository<DeliveryAssignment, String> {
    List<DeliveryAssignment> findByOrderId(String orderId);
    List<DeliveryAssignment> findByDeliveryPersonIdAndStatus(String deliveryPersonId, String status);
    Optional<DeliveryAssignment> findByOrderIdAndDeliveryPersonId(String orderId, String deliveryPersonId);
}
