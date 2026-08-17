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
@Document(collection = "reviews")
public class Review {

    @Id
    private String id;

    @Indexed
    private String orderId;

    @Indexed
    private String customerId;
    private String customerName;

    @Indexed
    private String targetType; // "RESTAURANT", "HOTEL", "DELIVERY_PERSON", "FOOD_ITEM"

    @Indexed
    private String targetId;

    private Double rating; // 1.0 to 5.0
    private String comment;

    // Granular scores
    private Double tasteRating;
    private Double deliveryRating;
    private Double packagingRating;
    private Double valueRating;

    // AI sentiment analysis metadata
    private String sentiment; // "POSITIVE", "NEUTRAL", "NEGATIVE"
    private Double sentimentScore;

    @Builder.Default
    private boolean isVerifiedOrder = true;

    @CreatedDate
    @Indexed
    private Instant createdAt;
}
