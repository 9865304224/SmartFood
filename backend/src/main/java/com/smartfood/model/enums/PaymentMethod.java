package com.smartfood.model.enums;

import com.fasterxml.jackson.annotation.JsonCreator;

public enum PaymentMethod {
    RAZORPAY,
    CASH_ON_DELIVERY,
    UPI,
    CARD,
    WALLET,
    NET_BANKING,
    MOCK_DEV;

    @JsonCreator
    public static PaymentMethod fromString(String key) {
        if (key == null || key.trim().isEmpty()) {
            return MOCK_DEV;
        }
        for (PaymentMethod method : PaymentMethod.values()) {
            if (method.name().equalsIgnoreCase(key.trim())) {
                return method;
            }
        }
        return MOCK_DEV;
    }
}
