package com.smartfood.repository;

import com.smartfood.model.Order;
import com.smartfood.model.enums.OrderStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRepository extends MongoRepository<Order, String> {
    Optional<Order> findByOrderNumber(String orderNumber);

    List<Order> findByCustomerIdOrderByCreatedAtDesc(String customerId);
    Page<Order> findByCustomerIdOrderByCreatedAtDesc(String customerId, Pageable pageable);

    List<Order> findByRestaurantIdOrderByCreatedAtDesc(String restaurantId);
    List<Order> findByHotelIdOrderByCreatedAtDesc(String hotelId);

    List<Order> findByDeliveryPersonIdOrderByCreatedAtDesc(String deliveryPersonId);
    List<Order> findByDeliveryPersonIdAndStatusIn(String deliveryPersonId, List<OrderStatus> statuses);

    List<Order> findByStatus(OrderStatus status);
    List<Order> findByStatusIn(List<OrderStatus> statuses);

    long countByStatus(OrderStatus status);
    long countByCustomerId(String customerId);

    @Query("{ 'createdAt': { $gte: ?0, $lte: ?1 } }")
    List<Order> findOrdersBetweenDates(Instant startDate, Instant endDate);

    @Query("{ 'status': 'DELIVERED', 'createdAt': { $gte: ?0, $lte: ?1 } }")
    List<Order> findDeliveredOrdersBetweenDates(Instant startDate, Instant endDate);
}
