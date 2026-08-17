package com.smartfood.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "customer_profiles")
public class CustomerProfile {

    @Id
    private String id;

    @Indexed(unique = true)
    private String userId;

    private String fullName;
    private String phone;
    private String email;

    @Builder.Default
    private List<SavedAddress> savedAddresses = new ArrayList<>();

    @Builder.Default
    private List<String> favoriteRestaurantIds = new ArrayList<>();

    @Builder.Default
    private List<String> favoriteFoodIds = new ArrayList<>();

    @Builder.Default
    private List<String> dietaryPreferences = new ArrayList<>(); // e.g. "VEG", "VEGAN", "HALAL", "GLUTEN_FREE"

    @Builder.Default
    private Double walletBalance = 0.0;

    @Builder.Default
    private Integer ecoDeliveriesCount = 0;

    @Builder.Default
    private Double totalCo2SavedKg = 0.0;
}
