package com.smartfood.model;

import com.smartfood.model.enums.ApprovalStatus;
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
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "hotel_profiles")
public class HotelProfile {

    @Id
    private String id;

    @Indexed(unique = true)
    private String userId;

    private String businessName;
    private String description;
    private String ownerName;
    private String phone;
    private String email;
    private String address;

    private GeoLocation location;

    @Builder.Default
    private List<String> cuisineTypes = new ArrayList<>();

    @Builder.Default
    private List<BusinessHours> businessHours = new ArrayList<>();

    private String fssaiLicenseNumber;
    private String gstNumber;

    @Builder.Default
    private List<PartnerDocument> documents = new ArrayList<>();

    @Builder.Default
    private Double rating = 4.7;

    @Builder.Default
    private Integer totalReviews = 0;

    @Builder.Default
    private boolean isOpen = true;

    // Hotel-specific capabilities
    @Builder.Default
    private boolean allowsBulkOrders = true;

    @Builder.Default
    private boolean allowsEventCatering = true;

    @Builder.Default
    private boolean allowsScheduledOrders = true;

    @Builder.Default
    private Double minBulkOrderAmount = 1500.0;

    @Builder.Default
    private Double bulkDiscountPercentage = 15.0;

    @Builder.Default
    private Double corporateDiscountPercentage = 10.0;

    @Builder.Default
    private Integer standardPrepTimeMinutes = 45;

    @Builder.Default
    @Indexed
    private ApprovalStatus approvalStatus = ApprovalStatus.PENDING;

    private String rejectionReason;
    private String coverImageUrl;
    private String logoUrl;

    @Builder.Default
    private Double totalRevenue = 0.0;

    @Builder.Default
    private Integer totalOrdersCount = 0;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;
}
