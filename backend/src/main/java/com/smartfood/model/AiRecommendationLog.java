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
@Document(collection = "ai_recommendation_logs")
public class AiRecommendationLog {

    @Id
    private String id;

    @Indexed
    private String customerId;

    @Builder.Default
    private List<String> recommendedItemIds = new ArrayList<>();

    private String recommendationReason; // e.g. "Because you ordered Hyderabadi Biryani recently", "Trending for dinner"

    @CreatedDate
    private Instant generatedAt;
}
