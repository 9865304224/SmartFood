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
@Document(collection = "delivery_location_logs")
public class DeliveryLocationLog {

    @Id
    private String id;

    @Indexed
    private String deliveryPersonId;

    @Indexed
    private String orderId;

    private GeoLocation location;
    private Double speedKmh;
    private Double headingDegrees;

    @CreatedDate
    @Indexed
    private Instant timestamp;
}
