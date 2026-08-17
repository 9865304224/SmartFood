package com.smartfood.model;

import com.smartfood.model.enums.ComplaintCategory;
import com.smartfood.model.enums.ComplaintStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "complaints")
public class Complaint {

    @Id
    private String id;

    @Indexed(unique = true)
    private String ticketNumber; // e.g. "CMP-2026-104"

    @Indexed
    private String orderId;

    @Indexed
    private String customerId;
    private String customerName;

    @Indexed
    private ComplaintCategory category;
    private String description;

    @Builder.Default
    @Indexed
    private ComplaintStatus status = ComplaintStatus.OPEN;

    private String adminNotes;
    private String resolutionDetails;
    private String resolvedByAdminId;

    @CreatedDate
    @Indexed
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;

    private Instant resolvedAt;
}
