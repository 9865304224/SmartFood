package com.smartfood.model;

import com.smartfood.model.enums.FraudRiskLevel;
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
@Document(collection = "fraud_flags")
public class FraudFlag {

    @Id
    private String id;

    @Indexed
    private String userId;

    @Indexed
    private String orderId;

    @Indexed
    private FraudRiskLevel riskLevel;

    private String reason;

    @Builder.Default
    private List<String> detectedPatterns = new ArrayList<>();

    @Builder.Default
    @Indexed
    private String status = "FLAGGED"; // FLAGGED, UNDER_REVIEW, RESOLVED_CLEAN, ACTION_TAKEN

    private String adminDecision;
    private String resolvedByAdminId;

    @CreatedDate
    @Indexed
    private Instant createdAt;
}
