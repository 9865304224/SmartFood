package com.smartfood.repository;

import com.smartfood.model.OrderStatusHistory;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderStatusHistoryRepository extends MongoRepository<OrderStatusHistory, String> {
    List<OrderStatusHistory> findByOrderIdOrderByTimestampAsc(String orderId);
}
