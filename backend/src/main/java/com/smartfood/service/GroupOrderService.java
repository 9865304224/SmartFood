package com.smartfood.service;

import com.smartfood.dto.cart.AddToCartRequest;
import com.smartfood.dto.order.CreateOrderRequest;
import com.smartfood.exception.BadRequestException;
import com.smartfood.exception.ResourceNotFoundException;
import com.smartfood.model.CartItem;
import com.smartfood.model.FoodItem;
import com.smartfood.model.GroupOrder;
import com.smartfood.model.GroupParticipant;
import com.smartfood.model.Order;
import com.smartfood.model.OrderItem;
import com.smartfood.model.RestaurantProfile;
import com.smartfood.model.SavedAddress;
import com.smartfood.model.User;
import com.smartfood.model.enums.OrderStatus;
import com.smartfood.model.enums.PaymentMethod;
import com.smartfood.model.enums.PaymentStatus;
import com.smartfood.repository.FoodItemRepository;
import com.smartfood.repository.GroupOrderRepository;
import com.smartfood.repository.OrderRepository;
import com.smartfood.repository.RestaurantProfileRepository;
import com.smartfood.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Random;

@Slf4j
@Service
@RequiredArgsConstructor
public class GroupOrderService {

    private final GroupOrderRepository groupOrderRepository;
    private final RestaurantProfileRepository restaurantProfileRepository;
    private final FoodItemRepository foodItemRepository;
    private final UserRepository userRepository;
    private final OrderService orderService;
    private final SimpMessagingTemplate messagingTemplate;

    public GroupOrder createGroupOrder(String creatorUserId, String restaurantId, String hotelId) {
        User creator = userRepository.findById(creatorUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", creatorUserId));

        String businessName = "SmartFood Partner";
        if (restaurantId != null) {
            businessName = restaurantProfileRepository.findById(restaurantId)
                    .map(RestaurantProfile::getBusinessName)
                    .orElse("Partner Restaurant");
        }

        String joinCode = "GRP-" + (1000 + new Random().nextInt(9000));

        GroupParticipant creatorParticipant = GroupParticipant.builder()
                .userId(creator.getId())
                .userName(creator.getFullName())
                .items(new ArrayList<>())
                .participantSubtotal(0.0)
                .isReady(false)
                .build();

        GroupOrder groupOrder = GroupOrder.builder()
                .joinCode(joinCode)
                .creatorUserId(creator.getId())
                .creatorName(creator.getFullName())
                .restaurantId(restaurantId)
                .hotelId(hotelId)
                .businessName(businessName)
                .status("ACTIVE")
                .participants(new ArrayList<>(List.of(creatorParticipant)))
                .finalTotal(0.0)
                .expiresAt(Instant.now().plus(2, ChronoUnit.HOURS))
                .build();

        return groupOrderRepository.save(groupOrder);
    }

    public GroupOrder joinGroupOrder(String userId, String joinCode) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        GroupOrder group = groupOrderRepository.findByJoinCode(joinCode.trim().toUpperCase())
                .orElseThrow(() -> new ResourceNotFoundException("GroupOrder", "joinCode", joinCode));

        if (!"ACTIVE".equals(group.getStatus())) {
            throw new BadRequestException("This group order is " + group.getStatus() + " and no longer accepting participants");
        }

        boolean alreadyParticipant = group.getParticipants().stream()
                .anyMatch(p -> p.getUserId().equals(userId));

        if (!alreadyParticipant) {
            group.getParticipants().add(GroupParticipant.builder()
                    .userId(user.getId())
                    .userName(user.getFullName())
                    .items(new ArrayList<>())
                    .participantSubtotal(0.0)
                    .isReady(false)
                    .build());
            group = groupOrderRepository.save(group);
            broadcastGroupUpdate(group);
        }

        return group;
    }

    public GroupOrder addItemToGroup(String userId, String joinCode, AddToCartRequest request) {
        GroupOrder group = groupOrderRepository.findByJoinCode(joinCode.trim().toUpperCase())
                .orElseThrow(() -> new ResourceNotFoundException("GroupOrder", "joinCode", joinCode));

        if (!"ACTIVE".equals(group.getStatus())) {
            throw new BadRequestException("Group order is locked");
        }

        FoodItem food = foodItemRepository.findById(request.getFoodItemId())
                .orElseThrow(() -> new ResourceNotFoundException("FoodItem", "id", request.getFoodItemId()));

        GroupParticipant participant = group.getParticipants().stream()
                .filter(p -> p.getUserId().equals(userId))
                .findFirst()
                .orElseThrow(() -> new BadRequestException("You have not joined this group order"));

        CartItem item = CartItem.builder()
                .foodItemId(food.getId())
                .foodName(food.getName())
                .price(food.getPrice())
                .quantity(request.getQuantity())
                .isVeg(food.isVeg())
                .imageUrl(food.getImageUrl())
                .notes(request.getNotes())
                .build();

        participant.getItems().add(item);
        participant.setParticipantSubtotal(participant.getItems().stream()
                .mapToDouble(i -> i.getPrice() * i.getQuantity()).sum());

        double total = group.getParticipants().stream()
                .mapToDouble(GroupParticipant::getParticipantSubtotal).sum();
        group.setFinalTotal(total);

        group = groupOrderRepository.save(group);
        broadcastGroupUpdate(group);
        return group;
    }

    public GroupOrder getGroupByJoinCode(String joinCode) {
        return groupOrderRepository.findByJoinCode(joinCode.trim().toUpperCase())
                .orElseThrow(() -> new ResourceNotFoundException("GroupOrder", "joinCode", joinCode));
    }

    private void broadcastGroupUpdate(GroupOrder group) {
        try {
            messagingTemplate.convertAndSend("/topic/group-orders/" + group.getJoinCode(), group);
        } catch (Exception ignored) {}
    }
}
