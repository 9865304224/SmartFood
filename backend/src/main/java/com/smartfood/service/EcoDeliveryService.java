package com.smartfood.service;

import com.smartfood.model.DeliveryProfile;
import com.smartfood.model.Order;
import com.smartfood.model.enums.VehicleType;
import org.springframework.stereotype.Service;

@Service
public class EcoDeliveryService {

    public record EcoScoreResult(double ecoScore, double co2SavedKg, String ecoBadge, String summary) {}

    public EcoScoreResult calculateOrderEcoMetrics(Order order, DeliveryProfile driver) {
        double distanceKm = order.getEstimatedDistanceKm() != null ? order.getEstimatedDistanceKm() : 2.5;

        // Baseline emissions: 120g CO2 / km for standard petrol motorcycle
        double standardCo2Kg = (distanceKm * 120.0) / 1000.0;

        double actualCo2Kg = standardCo2Kg;
        double ecoScore = 70.0;
        String ecoBadge = "Standard Route";

        VehicleType vType = (driver != null && driver.getVehicleType() != null) 
                ? driver.getVehicleType() : VehicleType.MOTORCYCLE;

        switch (vType) {
            case BICYCLE -> {
                actualCo2Kg = 0.0;
                ecoScore = 100.0;
                ecoBadge = "Zero-Emission (Bicycle)";
            }
            case ELECTRIC_VEHICLE, SCOOTER -> {
                actualCo2Kg = standardCo2Kg * 0.25; // 75% emission reduction
                ecoScore = 95.0;
                ecoBadge = "Green EV Delivery";
            }
            case MOTORCYCLE -> {
                actualCo2Kg = standardCo2Kg;
                ecoScore = order.isEcoDelivery() ? 85.0 : 70.0;
                ecoBadge = order.isEcoDelivery() ? "Grouped Route Saver" : "Standard Route";
            }
            case CAR -> {
                actualCo2Kg = standardCo2Kg * 1.8;
                ecoScore = 55.0;
                ecoBadge = "Standard Vehicle";
            }
        }

        // If batch route, additional 30% savings
        if (order.getBatchRouteId() != null) {
            actualCo2Kg *= 0.70;
            ecoScore = Math.min(100.0, ecoScore + 10.0);
            ecoBadge = "Optimized Multi-Order Route";
        }

        double co2SavedKg = Math.max(0.0, Math.round((standardCo2Kg - actualCo2Kg) * 100.0) / 100.0);
        String summary = String.format("Estimated Eco Score: %.0f/100 | ~%.2f kg CO2 reduced vs individual standard trips", ecoScore, co2SavedKg);

        return new EcoScoreResult(ecoScore, co2SavedKg, ecoBadge, summary);
    }
}
