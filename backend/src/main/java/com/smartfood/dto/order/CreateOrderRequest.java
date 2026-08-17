package com.smartfood.dto.order;

import com.smartfood.model.SavedAddress;
import com.smartfood.model.enums.PaymentMethod;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateOrderRequest {

    @NotNull(message = "Delivery address is required")
    private SavedAddress deliveryAddress;

    @NotNull(message = "Payment method is required")
    private PaymentMethod paymentMethod;

    private String couponCode;
    private String specialInstructions;

    @Builder.Default
    private boolean isEcoDelivery = false; // Choose green route & grouped delivery
}
