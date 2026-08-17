package com.smartfood.controller;

import com.smartfood.dto.response.ApiResponse;
import com.smartfood.exception.ResourceNotFoundException;
import com.smartfood.model.CustomerProfile;
import com.smartfood.model.Order;
import com.smartfood.model.SavedAddress;
import com.smartfood.repository.CustomerProfileRepository;
import com.smartfood.repository.OrderRepository;
import com.smartfood.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/customers")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomerProfileRepository customerProfileRepository;
    private final OrderRepository orderRepository;
    private final com.smartfood.repository.UserRepository userRepository;

    @GetMapping("/profile")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<CustomerProfile>> getProfile(@AuthenticationPrincipal UserPrincipal userPrincipal) {
        CustomerProfile profile = customerProfileRepository.findByUserId(userPrincipal.getId())
                .orElseThrow(() -> new ResourceNotFoundException("CustomerProfile", "userId", userPrincipal.getId()));
        userRepository.findById(userPrincipal.getId()).ifPresent(u -> {
            profile.setFullName(u.getFullName());
            profile.setPhone(u.getPhone());
            profile.setEmail(u.getEmail());
        });
        return ResponseEntity.ok(ApiResponse.success(profile));
    }

    @lombok.Data
    public static class CustomerProfileUpdateDto {
        private String fullName;
        private String phone;
        private List<String> dietaryPreferences;
    }

    @org.springframework.web.bind.annotation.PutMapping("/profile")
    @PreAuthorize("hasRole('CUSTOMER') or hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<CustomerProfile>> updateProfile(@AuthenticationPrincipal UserPrincipal userPrincipal,
                                                                      @RequestBody CustomerProfileUpdateDto dto) {
        CustomerProfile profile = customerProfileRepository.findByUserId(userPrincipal.getId())
                .orElseThrow(() -> new ResourceNotFoundException("CustomerProfile", "userId", userPrincipal.getId()));

        if (dto.getDietaryPreferences() != null) {
            profile.setDietaryPreferences(dto.getDietaryPreferences());
        }

        if (dto.getFullName() != null) {
            profile.setFullName(dto.getFullName());
        }
        if (dto.getPhone() != null) {
            profile.setPhone(dto.getPhone());
        }

        userRepository.findById(userPrincipal.getId()).ifPresent(u -> {
            if (dto.getFullName() != null) u.setFullName(dto.getFullName());
            if (dto.getPhone() != null) u.setPhone(dto.getPhone());
            userRepository.save(u);
        });

        userRepository.findById(userPrincipal.getId()).ifPresent(u -> profile.setEmail(u.getEmail()));

        CustomerProfile savedProfile = customerProfileRepository.save(profile);
        return ResponseEntity.ok(ApiResponse.success("Profile updated successfully", savedProfile));
    }

    @PostMapping("/addresses")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<CustomerProfile>> addAddress(@AuthenticationPrincipal UserPrincipal userPrincipal,
                                                                   @RequestBody SavedAddress address) {
        CustomerProfile profile = customerProfileRepository.findByUserId(userPrincipal.getId())
                .orElseThrow(() -> new ResourceNotFoundException("CustomerProfile", "userId", userPrincipal.getId()));

        if (address.getId() == null) {
            address.setId("addr-" + UUID.randomUUID().toString().substring(0, 8));
        }

        if (address.isDefault()) {
            profile.getSavedAddresses().forEach(a -> a.setDefault(false));
        }

        profile.getSavedAddresses().add(address);
        profile = customerProfileRepository.save(profile);
        return ResponseEntity.ok(ApiResponse.success("Address saved successfully", profile));
    }

    @GetMapping("/orders")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<ApiResponse<List<Order>>> getMyOrders(@AuthenticationPrincipal UserPrincipal userPrincipal) {
        List<Order> orders = orderRepository.findByCustomerIdOrderByCreatedAtDesc(userPrincipal.getId());
        return ResponseEntity.ok(ApiResponse.success("Customer orders retrieved", orders));
    }
}
