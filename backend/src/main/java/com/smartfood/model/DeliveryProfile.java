package com.smartfood.model;

import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.model.enums.DeliveryStatus;
import com.smartfood.model.enums.VehicleType;
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
@Document(collection = "delivery_profiles")
public class DeliveryProfile {

    @Id
    private String id;

    @Indexed(unique = true)
    private String userId;

    private String fullName;
    private String phone;
    private String email;

    @Builder.Default
    private VehicleType vehicleType = VehicleType.MOTORCYCLE;

    private String vehicleNumber;
    private String drivingLicenseNumber;

    @Builder.Default
    private List<PartnerDocument> documents = new ArrayList<>();

    @Builder.Default
    @Indexed
    private DeliveryStatus currentStatus = DeliveryStatus.AVAILABLE;

    private GeoLocation currentLocation;
    private Instant lastLocationUpdate;

    @Builder.Default
    private Integer totalDeliveries = 0;

    @Builder.Default
    private Integer activeOrdersCount = 0;

    @Builder.Default
    private Double rating = 4.8;

    @Builder.Default
    private Integer totalReviews = 0;

    @Builder.Default
    private Double totalEarnings = 0.0;

    @Builder.Default
    private Double todayEarnings = 0.0;

    @Builder.Default
    private Double ecoScore = 92.0; // 0-100 score based on eco routes and EV/cycle usage

    @Builder.Default
    private Double totalCo2SavedKg = 0.0;

    @Builder.Default
    @Indexed
    private ApprovalStatus approvalStatus = ApprovalStatus.PENDING;

    private String rejectionReason;
    private String profilePhotoUrl;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;
}
