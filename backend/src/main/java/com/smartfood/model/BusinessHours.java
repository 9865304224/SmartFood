package com.smartfood.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BusinessHours {
    private String dayOfWeek; // e.g., "MONDAY", "ALL"
    private String openTime;  // e.g., "09:00"
    private String closeTime; // e.g., "23:00"
    @Builder.Default
    private boolean isClosed = false;
}
