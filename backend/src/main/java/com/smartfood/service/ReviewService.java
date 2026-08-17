package com.smartfood.service;

import com.smartfood.ai.ReviewAnalysisService;
import com.smartfood.exception.BadRequestException;
import com.smartfood.exception.ResourceNotFoundException;
import com.smartfood.model.Order;
import com.smartfood.model.RestaurantProfile;
import com.smartfood.model.Review;
import com.smartfood.model.User;
import com.smartfood.model.enums.OrderStatus;
import com.smartfood.repository.OrderRepository;
import com.smartfood.repository.RestaurantProfileRepository;
import com.smartfood.repository.ReviewRepository;
import com.smartfood.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final RestaurantProfileRepository restaurantProfileRepository;
    private final ReviewAnalysisService reviewAnalysisService;

    @Transactional
    public Review createReview(String customerId, String orderId, String targetType, String targetId,
                               Double rating, String comment, Double taste, Double delivery, Double packaging, Double value) {
        User customer = userRepository.findById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", customerId));

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order", "id", orderId));

        // Critical Business Rule: Only verified, completed orders can create reviews
        if (order.getStatus() != OrderStatus.DELIVERED) {
            throw new BadRequestException("You can only review an order after it has been successfully delivered");
        }

        // Prevent duplicate reviews for the same order
        if (reviewRepository.existsByOrderId(orderId)) {
            throw new BadRequestException("You have already reviewed this order");
        }

        Review review = Review.builder()
                .orderId(order.getId())
                .customerId(customer.getId())
                .customerName(customer.getFullName())
                .targetType(targetType)
                .targetId(targetId)
                .rating(rating)
                .comment(comment)
                .tasteRating(taste != null ? taste : rating)
                .deliveryRating(delivery != null ? delivery : rating)
                .packagingRating(packaging != null ? packaging : rating)
                .valueRating(value != null ? value : rating)
                .sentiment(rating >= 4.0 ? "POSITIVE" : (rating >= 3.0 ? "NEUTRAL" : "NEGATIVE"))
                .sentimentScore(rating / 5.0)
                .isVerifiedOrder(true)
                .createdAt(Instant.now())
                .build();

        review = reviewRepository.save(review);

        // Update target restaurant rating
        if ("RESTAURANT".equalsIgnoreCase(targetType)) {
            restaurantProfileRepository.findById(targetId).ifPresent(res -> {
                int total = res.getTotalReviews() != null ? res.getTotalReviews() : 0;
                double currentRating = res.getRating() != null ? res.getRating() : 4.5;
                double newAvg = ((currentRating * total) + rating) / (total + 1);
                res.setRating(Math.round(newAvg * 10.0) / 10.0);
                res.setTotalReviews(total + 1);
                restaurantProfileRepository.save(res);
            });

            // Trigger asynchronous / cached AI sentiment aggregation
            try {
                reviewAnalysisService.analyzeTargetReviews(targetType, targetId);
            } catch (Exception ex) {
                log.error("Failed to run AI sentiment analysis on new review: ", ex);
            }
        }

        return review;
    }

    public List<Review> getTargetReviews(String targetType, String targetId) {
        return reviewRepository.findByTargetTypeAndTargetId(targetType, targetId);
    }
}
