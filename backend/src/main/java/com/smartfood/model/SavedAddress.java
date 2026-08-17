package com.smartfood.model;

import com.smartfood.model.enums.AddressType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SavedAddress {
    private String id;
    private String label; // e.g. "My College Hostel", "Office 4th Floor"
    private AddressType type;
    private String building;
    private String block;
    private String floor;
    private String room;
    private String landmark;
    private String formattedAddress;
    private GeoLocation location;
    @Builder.Default
    private boolean isDefault = false;
}
