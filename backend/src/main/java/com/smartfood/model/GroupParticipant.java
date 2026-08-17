package com.smartfood.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GroupParticipant {
    private String userId;
    private String userName;
    @Builder.Default
    private List<CartItem> items = new ArrayList<>();
    @Builder.Default
    private Double participantSubtotal = 0.0;
    @Builder.Default
    private boolean isReady = false;
}
