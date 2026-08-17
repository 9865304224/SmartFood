package com.smartfood.model.enums;

import com.fasterxml.jackson.annotation.JsonCreator;

public enum AddressType {
    HOME,
    WORK,
    COLLEGE,
    OFFICE,
    HOSTEL,
    CURRENT_LOCATION,
    CUSTOM,
    CAMPUS,
    APARTMENT,
    HOTEL,
    OTHER;

    @JsonCreator
    public static AddressType fromString(String key) {
        if (key == null || key.trim().isEmpty()) {
            return OTHER;
        }
        for (AddressType type : AddressType.values()) {
            if (type.name().equalsIgnoreCase(key.trim())) {
                return type;
            }
        }
        return OTHER;
    }
}
