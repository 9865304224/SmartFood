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
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "group_orders")
public class GroupOrder {

    @Id
    private String id;

    @Indexed(unique = true)
    private String joinCode; // e.g. "SMART-7892"

    @Indexed
    private String creatorUserId;
    private String creatorName;

    private String restaurantId;
    private String hotelId;
    private String businessName;

    @Builder.Default
    private String status = "ACTIVE"; // "ACTIVE", "LOCKED", "ORDER_PLACED", "CANCELLED"

    @Builder.Default
    private List<GroupParticipant> participants = new ArrayList<>();

    private SavedAddress deliveryAddress;

    @Builder.Default
    private Double finalTotal = 0.0;

    private String combinedOrderId;

    @CreatedDate
    private Instant createdAt;

    private Instant expiresAt;
}
