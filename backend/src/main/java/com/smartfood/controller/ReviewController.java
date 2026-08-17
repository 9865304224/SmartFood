package com.smartfood.controller;

import com.smartfood.ai.ReviewAnalysisService;
import com.smartfood.dto.response.ApiResponse;
import com.smartfood.model.AiReviewAnalysis;
import com.smartfood.model.Review;
import com.smartfood.security.UserPrincipal;
import com.smartfood.service.ReviewService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/reviews")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;
    private final ReviewAnalysisService reviewAnalysisService;

    @Data
    public static class CreateReviewDto {
        private String orderId;
        private String targetType; // "RESTAURANT", "HOTEL", "DELIVERY_PERSON"
        private String targetId;
        private Double rating;
        private String comment;
        private Double tasteRating;
        private Double deliveryRating;
        private Double packagingRating;
        private Double valueRating;
    }

    @PostMapping
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<Review>> createReview(@AuthenticationPrincipal UserPrincipal user,
                                                            @RequestBody CreateReviewDto dto) {
        Review review = reviewService.createReview(
                user.getId(),
                dto.getOrderId(),
                dto.getTargetType(),
                dto.getTargetId(),
                dto.getRating(),
                dto.getComment(),
                dto.getTasteRating(),
                dto.getDeliveryRating(),
                dto.getPackagingRating(),
                dto.getValueRating()
        );
        return ResponseEntity.ok(ApiResponse.success("Review submitted successfully", review));
    }

    @GetMapping("/{targetType}/{targetId}")
    public ResponseEntity<ApiResponse<List<Review>>> getReviews(@PathVariable String targetType,
                                                                @PathVariable String targetId) {
        return ResponseEntity.ok(ApiResponse.success(reviewService.getTargetReviews(targetType, targetId)));
    }

    @GetMapping("/{targetType}/{targetId}/ai-insights")
    public ResponseEntity<ApiResponse<AiReviewAnalysis>> getAiInsights(@PathVariable String targetType,
                                                                       @PathVariable String targetId) {
        return ResponseEntity.ok(ApiResponse.success(reviewAnalysisService.analyzeTargetReviews(targetType, targetId)));
    }
}
