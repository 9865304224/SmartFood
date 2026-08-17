package com.smartfood.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "delivery_assignments")
public class DeliveryAssignment {

    @Id
    private String id;

    @Indexed
    private String orderId;

    @Indexed
    private String deliveryPersonId;

    private Double score;
    private Map<String, Double> scoreBreakdown;

    @Builder.Default
    private String status = "PENDING"; // PENDING, ACCEPTED, REJECTED, EXPIRED

    @CreatedDate
    private Instant assignedAt;
    private Instant respondedAt;
}
