package com.smartfood.repository;

import com.smartfood.model.DeliveryLocationLog;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryLocationLogRepository extends MongoRepository<DeliveryLocationLog, String> {
    List<DeliveryLocationLog> findByOrderIdOrderByTimestampAsc(String orderId);
    Optional<DeliveryLocationLog> findTopByDeliveryPersonIdOrderByTimestampDesc(String deliveryPersonId);
}
