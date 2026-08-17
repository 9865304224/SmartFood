package com.smartfood.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "ai_review_analyses")
public class AiReviewAnalysis {

    @Id
    private String id;

    @Indexed
    private String targetType; // "RESTAURANT" or "HOTEL"

    @Indexed(unique = true)
    private String targetId;

    @Builder.Default
    private List<String> positiveTopics = new ArrayList<>();

    @Builder.Default
    private List<String> negativeTopics = new ArrayList<>();

    @Builder.Default
    private List<String> commonComplaints = new ArrayList<>();

    @Builder.Default
    private List<String> commonPraise = new ArrayList<>();

    @Builder.Default
    private Map<String, Double> categoryScores = new HashMap<>(); // Taste, Quantity, Packaging, Delivery, Value

    private String executiveSummary;

    private Integer totalReviewsAnalyzed;

    private Instant lastAnalyzedAt;
}
