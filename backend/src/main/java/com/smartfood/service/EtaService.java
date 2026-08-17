package com.smartfood.service;

import com.smartfood.model.GeoLocation;
import com.smartfood.model.Order;
import com.smartfood.model.RestaurantProfile;
import com.smartfood.repository.RestaurantProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

@Service
@RequiredArgsConstructor
public class EtaService {

    private final RestaurantProfileRepository restaurantProfileRepository;

    public record EtaResult(int estimatedMinutes, Instant estimatedDeliveryTime, String breakdown) {}

    public EtaResult calculateEta(Order order, GeoLocation driverCurrentLocation) {
        int prepTime = order.getPreparationTimeMinutes() != null ? order.getPreparationTimeMinutes() : 20;

        double restaurantToCustomerKm = order.getEstimatedDistanceKm() != null ? order.getEstimatedDistanceKm() : 3.0;

        // Average city travel speed: 20 km/h -> 3 minutes per km + 5 min traffic buffer
        int transitToCustomerMinutes = (int) Math.ceil(restaurantToCustomerKm * 3.0) + 5;

        int driverToRestaurantMinutes = 5;
        if (driverCurrentLocation != null && order.getPickupLocation() != null) {
            double d = driverCurrentLocation.distanceTo(order.getPickupLocation());
            driverToRestaurantMinutes = (int) Math.ceil(d * 3.0);
        }

        int totalMinutes;
        String breakdown;

        switch (order.getStatus()) {
            case PLACED, ACCEPTED, PREPARING -> {
                totalMinutes = prepTime + transitToCustomerMinutes;
                breakdown = "Preparation: ~" + prepTime + " mins + Transit: ~" + transitToCustomerMinutes + " mins";
            }
            case READY_FOR_PICKUP, DELIVERY_ASSIGNED -> {
                totalMinutes = driverToRestaurantMinutes + transitToCustomerMinutes;
                breakdown = "Driver Arrival: ~" + driverToRestaurantMinutes + " mins + Transit: ~" + transitToCustomerMinutes + " mins";
            }
            case PICKED_UP, OUT_FOR_DELIVERY -> {
                totalMinutes = transitToCustomerMinutes;
                breakdown = "Driver on the way: ~" + transitToCustomerMinutes + " mins";
            }
            case DELIVERED -> {
                totalMinutes = 0;
                breakdown = "Order has already been delivered";
            }
            default -> {
                totalMinutes = 35;
                breakdown = "Estimated: ~35 mins";
            }
        }

        Instant estimatedTime = Instant.now().plus(totalMinutes, ChronoUnit.MINUTES);
        return new EtaResult(totalMinutes, estimatedTime, breakdown);
    }
}
