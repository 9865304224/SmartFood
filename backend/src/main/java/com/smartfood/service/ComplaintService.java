package com.smartfood.service;

import com.smartfood.exception.ResourceNotFoundException;
import com.smartfood.model.Complaint;
import com.smartfood.model.Order;
import com.smartfood.model.User;
import com.smartfood.model.enums.ComplaintCategory;
import com.smartfood.model.enums.ComplaintStatus;
import com.smartfood.repository.ComplaintRepository;
import com.smartfood.repository.OrderRepository;
import com.smartfood.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.Random;

@Slf4j
@Service
@RequiredArgsConstructor
public class ComplaintService {

    private final ComplaintRepository complaintRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public Complaint createComplaint(String customerId, String orderId, ComplaintCategory category, String description) {
        User customer = userRepository.findById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", customerId));

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order", "id", orderId));

        String ticketNumber = "CMP-" + (1000 + new Random().nextInt(9000));

        Complaint complaint = Complaint.builder()
                .ticketNumber(ticketNumber)
                .orderId(order.getId())
                .customerId(customer.getId())
                .customerName(customer.getFullName())
                .category(category)
                .description(description)
                .status(ComplaintStatus.OPEN)
                .createdAt(Instant.now())
                .build();

        complaint = complaintRepository.save(complaint);
        log.info("Complaint ticket created: {} for order: {}", ticketNumber, order.getOrderNumber());

        notificationService.sendNotification(customerId, "Complaint Ticket #" + ticketNumber, 
                "We received your issue regarding order #" + order.getOrderNumber() + ". Our support team will investigate shortly.", "COMPLAINT");

        return complaint;
    }

    public List<Complaint> getCustomerComplaints(String customerId) {
        return complaintRepository.findByCustomerIdOrderByCreatedAtDesc(customerId);
    }

    public List<Complaint> getAllComplaints(ComplaintStatus status) {
        if (status != null) {
            return complaintRepository.findByStatusOrderByCreatedAtDesc(status);
        }
        return complaintRepository.findAll();
    }

    public Complaint resolveComplaint(String complaintId, String adminId, ComplaintStatus newStatus, String resolutionDetails, String adminNotes) {
        Complaint complaint = complaintRepository.findById(complaintId)
                .orElseThrow(() -> new ResourceNotFoundException("Complaint", "id", complaintId));

        complaint.setStatus(newStatus);
        complaint.setResolutionDetails(resolutionDetails);
        complaint.setAdminNotes(adminNotes);
        complaint.setResolvedByAdminId(adminId);
        complaint.setResolvedAt(Instant.now());
        complaint.setUpdatedAt(Instant.now());

        complaint = complaintRepository.save(complaint);

        notificationService.sendNotification(complaint.getCustomerId(), "Complaint #" + complaint.getTicketNumber() + " " + newStatus.name(), 
                "Your issue has been updated: " + resolutionDetails, "COMPLAINT_UPDATE");

        return complaint;
    }
}
