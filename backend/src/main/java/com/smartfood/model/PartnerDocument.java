package com.smartfood.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PartnerDocument {
    private String documentType; // e.g., "FSSAI_LICENSE", "GSTIN", "DRIVING_LICENSE", "GOVERNMENT_ID"
    private String documentNumber;
    private String documentUrl;
    private Instant uploadedAt;
    @Builder.Default
    private boolean isVerified = false;
}
