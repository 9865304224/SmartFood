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

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "audit_logs")
public class AuditLog {

    @Id
    private String id;

    @Indexed
    private String adminId;
    private String adminEmail;

    @Indexed
    private String action; // e.g., "PARTNER_APPROVED", "PARTNER_REJECTED", "ORDER_REFUNDED", "FRAUD_ACTION"

    private String targetResource;
    private String targetId;
    private String details;
    private String ipAddress;

    @CreatedDate
    @Indexed
    private Instant timestamp;
}
