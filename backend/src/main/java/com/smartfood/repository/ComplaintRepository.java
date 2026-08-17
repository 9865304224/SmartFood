package com.smartfood.repository;

import com.smartfood.model.Complaint;
import com.smartfood.model.enums.ComplaintStatus;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ComplaintRepository extends MongoRepository<Complaint, String> {
    Optional<Complaint> findByTicketNumber(String ticketNumber);
    List<Complaint> findByCustomerIdOrderByCreatedAtDesc(String customerId);
    List<Complaint> findByOrderId(String orderId);
    List<Complaint> findByStatusOrderByCreatedAtDesc(ComplaintStatus status);
    long countByStatus(ComplaintStatus status);
}
