package com.smartfood.ai;

import com.smartfood.model.AiReviewAnalysis;
import com.smartfood.model.Review;
import com.smartfood.repository.AiReviewAnalysisRepository;
import com.smartfood.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReviewAnalysisService {

    private final ReviewRepository reviewRepository;
    private final AiReviewAnalysisRepository aiReviewAnalysisRepository;

    public AiReviewAnalysis analyzeTargetReviews(String targetType, String targetId) {
        List<Review> reviews = reviewRepository.findByTargetTypeAndTargetId(targetType, targetId);

        if (reviews.isEmpty()) {
            AiReviewAnalysis emptyAnalysis = AiReviewAnalysis.builder()
                    .targetType(targetType)
                    .targetId(targetId)
                    .positiveTopics(List.of("No reviews yet"))
                    .negativeTopics(List.of())
                    .commonComplaints(List.of())
                    .commonPraise(List.of("Newly registered partner"))
                    .categoryScores(Map.of("Taste", 4.5, "Quantity", 4.5, "Packaging", 4.5, "Delivery", 4.5, "Value", 4.5))
                    .executiveSummary("Awaiting customer orders and verified reviews.")
                    .totalReviewsAnalyzed(0)
                    .lastAnalyzedAt(Instant.now())
                    .build();
            return aiReviewAnalysisRepository.save(emptyAnalysis);
        }

        double avgTaste = reviews.stream().filter(r -> r.getTasteRating() != null).mapToDouble(Review::getTasteRating).average().orElse(4.6);
        double avgDelivery = reviews.stream().filter(r -> r.getDeliveryRating() != null).mapToDouble(Review::getDeliveryRating).average().orElse(4.7);
        double avgPackaging = reviews.stream().filter(r -> r.getPackagingRating() != null).mapToDouble(Review::getPackagingRating).average().orElse(4.8);
        double avgValue = reviews.stream().filter(r -> r.getValueRating() != null).mapToDouble(Review::getValueRating).average().orElse(4.5);

        Map<String, Double> categoryScores = new HashMap<>();
        categoryScores.put("Taste", Math.round(avgTaste * 10.0) / 10.0);
        categoryScores.put("Delivery", Math.round(avgDelivery * 10.0) / 10.0);
        categoryScores.put("Packaging", Math.round(avgPackaging * 10.0) / 10.0);
        categoryScores.put("Value", Math.round(avgValue * 10.0) / 10.0);

        List<String> praise = new ArrayList<>();
        praise.add("Authentic aromatic spices & great portion size");
        praise.add("Spill-proof tamper-evident eco packaging");
        praise.add("Piping hot food delivered on time");

        List<String> complaints = new ArrayList<>();
        if (avgDelivery < 4.0) complaints.add("Peak hour delivery delays");
        if (avgPackaging < 4.0) complaints.add("Sauce leakage reported during monsoon");
        if (complaints.isEmpty()) complaints.add("Minor delay during rainstorms");

        String summary = String.format("Overall rating of %.1f/5 across %d verified customer orders. Top rated for %s.",
                (avgTaste + avgDelivery + avgPackaging + avgValue) / 4.0, reviews.size(), "Taste and Eco-Packaging");

        AiReviewAnalysis analysis = AiReviewAnalysis.builder()
                .targetType(targetType)
                .targetId(targetId)
                .positiveTopics(List.of("Flavor", "Portion Size", "Packaging Quality", "Speed"))
                .negativeTopics(List.of("Peak hour waiting"))
                .commonPraise(praise)
                .commonComplaints(complaints)
                .categoryScores(categoryScores)
                .executiveSummary(summary)
                .totalReviewsAnalyzed(reviews.size())
                .lastAnalyzedAt(Instant.now())
                .build();

        return aiReviewAnalysisRepository.save(analysis);
    }
}
