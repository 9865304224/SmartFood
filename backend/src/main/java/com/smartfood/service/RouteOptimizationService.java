package com.smartfood.service;

import com.smartfood.model.GeoLocation;
import com.smartfood.model.Order;
import com.smartfood.model.enums.OrderStatus;
import com.smartfood.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class RouteOptimizationService {

    private final OrderRepository orderRepository;

    @Value("${smartfood.delivery.max-extra-delay-minutes:15}")
    private int maxExtraDelayMinutes;

    @Value("${smartfood.delivery.max-group-distance-km:3.5}")
    private double maxGroupDistanceKm;

    public record RouteBatch(String batchId, List<Order> orders, double totalDistanceKm, double estimatedCo2SavedKg) {}

    public List<RouteBatch> findOptimizedBatches() {
        // Find all orders ready for pickup or placed that have not been assigned
        List<Order> unassignedOrders = orderRepository.findByStatusIn(List.of(OrderStatus.PREPARING, OrderStatus.READY_FOR_PICKUP))
                .stream()
                .filter(o -> o.getBatchRouteId() == null)
                .toList();

        List<RouteBatch> batches = new ArrayList<>();
        List<Order> visited = new ArrayList<>();

        for (int i = 0; i < unassignedOrders.size(); i++) {
            Order o1 = unassignedOrders.get(i);
            if (visited.contains(o1)) continue;

            List<Order> currentGroup = new ArrayList<>();
            currentGroup.add(o1);
            visited.add(o1);

            GeoLocation drop1 = (o1.getDeliveryAddress() != null) ? o1.getDeliveryAddress().getLocation() : null;

            for (int j = i + 1; j < unassignedOrders.size(); j++) {
                Order o2 = unassignedOrders.get(j);
                if (visited.contains(o2)) continue;

                // Check same restaurant or restaurants within 1.5 km
                double pickupDistance = 0.0;
                if (o1.getPickupLocation() != null && o2.getPickupLocation() != null) {
                    pickupDistance = o1.getPickupLocation().distanceTo(o2.getPickupLocation());
                }

                // Check dropoff proximity
                double dropDistance = 0.0;
                GeoLocation drop2 = (o2.getDeliveryAddress() != null) ? o2.getDeliveryAddress().getLocation() : null;
                if (drop1 != null && drop2 != null) {
                    dropDistance = drop1.distanceTo(drop2);
                }

                // If pickup distance <= 1.5km and drop distance <= maxGroupDistanceKm
                if (pickupDistance <= 1.5 && dropDistance <= maxGroupDistanceKm) {
                    currentGroup.add(o2);
                    visited.add(o2);
                    if (currentGroup.size() >= 3) break; // Max 3 orders per batch
                }
            }

            if (currentGroup.size() > 1) {
                String batchId = "BATCH-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
                double totalDistance = currentGroup.stream()
                        .mapToDouble(o -> o.getEstimatedDistanceKm() != null ? o.getEstimatedDistanceKm() : 2.5)
                        .sum() * 0.75; // 25% distance reduction from route chaining

                double co2Saved = Math.round((currentGroup.size() * 0.28) * 100.0) / 100.0;

                // Mark orders with batch ID
                for (Order o : currentGroup) {
                    o.setBatchRouteId(batchId);
                    o.setEcoDelivery(true);
                    o.setEstimatedCo2SavingKg(co2Saved / currentGroup.size());
                    orderRepository.save(o);
                }

                batches.add(new RouteBatch(batchId, currentGroup, totalDistance, co2Saved));
                log.info("Formed Optimized Delivery Batch: {} with {} orders. Estimated CO2 saved: {} kg", 
                        batchId, currentGroup.size(), co2Saved);
            }
        }

        return batches;
    }
}
