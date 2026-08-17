package com.smartfood;

import com.smartfood.ai.SmartBudgetService;
import com.smartfood.dto.ai.SmartBudgetRequest;
import com.smartfood.dto.ai.SmartBudgetResponse;
import com.smartfood.dto.auth.LoginRequest;
import com.smartfood.dto.auth.RegisterRequest;
import com.smartfood.model.Coupon;
import com.smartfood.model.CustomerProfile;
import com.smartfood.model.FoodItem;
import com.smartfood.model.GeoLocation;
import com.smartfood.model.Order;
import com.smartfood.model.OrderStatusHistory;
import com.smartfood.model.RestaurantProfile;
import com.smartfood.model.User;
import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.model.enums.OrderStatus;
import com.smartfood.model.enums.UserRole;
import com.smartfood.repository.CustomerProfileRepository;
import com.smartfood.repository.DeliveryProfileRepository;
import com.smartfood.repository.FoodItemRepository;
import com.smartfood.repository.HotelProfileRepository;
import com.smartfood.repository.OrderRepository;
import com.smartfood.repository.OrderStatusHistoryRepository;
import com.smartfood.repository.RestaurantProfileRepository;
import com.smartfood.repository.UserRepository;
import com.smartfood.security.JwtTokenProvider;
import com.smartfood.service.AuthService;
import com.smartfood.service.OrderService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SmartFoodBackendTests {

    @Mock
    private UserRepository userRepository;

    @Mock
    private CustomerProfileRepository customerProfileRepository;

    @Mock
    private RestaurantProfileRepository restaurantProfileRepository;

    @Mock
    private HotelProfileRepository hotelProfileRepository;

    @Mock
    private DeliveryProfileRepository deliveryProfileRepository;

    @Mock
    private FoodItemRepository foodItemRepository;

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private OrderStatusHistoryRepository orderStatusHistoryRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenProvider jwtTokenProvider;

    @InjectMocks
    private AuthService authService;

    @InjectMocks
    private SmartBudgetService smartBudgetService;

    @Test
    @DisplayName("Test 1: User Registration creates user and returns JWT tokens")
    void testUserRegistration() {
        RegisterRequest request = RegisterRequest.builder()
                .fullName("Test Customer")
                .email("test@smartfood.com")
                .phone("9999999999")
                .password("Password@123")
                .role(UserRole.CUSTOMER)
                .build();

        when(userRepository.existsByEmail(anyString())).thenReturn(false);
        when(userRepository.existsByPhone(anyString())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("encodedPassword");

        User savedUser = User.builder()
                .id("usr-123")
                .fullName(request.getFullName())
                .email(request.getEmail())
                .phone(request.getPhone())
                .role(request.getRole())
                .approvalStatus(ApprovalStatus.APPROVED)
                .build();

        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        when(customerProfileRepository.save(any(CustomerProfile.class))).thenReturn(CustomerProfile.builder().id("cp-123").userId("usr-123").build());
        when(jwtTokenProvider.generateAccessToken(any(User.class))).thenReturn("mockAccessToken");
        when(jwtTokenProvider.generateRefreshToken(any(User.class))).thenReturn("mockRefreshToken");

        var response = authService.register(request);

        assertNotNull(response);
        assertEquals("usr-123", response.getUserId());
        assertEquals("mockAccessToken", response.getAccessToken());
        assertEquals(UserRole.CUSTOMER, response.getRole());
    }

    @Test
    @DisplayName("Test 2: Coupon calculation enforces minimum order and caps")
    void testCouponValidationAndCalculation() {
        Coupon coupon = Coupon.builder()
                .code("SMART50")
                .discountPercentage(50.0)
                .maxDiscountAmount(100.0)
                .minOrderValue(150.0)
                .isActive(true)
                .build();

        // Valid order exceeding min order value
        assertTrue(coupon.isValidForOrder(250.0, "res-1", null));

        // Invalid order below min order value
        assertFalse(coupon.isValidForOrder(100.0, "res-1", null));

        // 50% of 300 is 150, but max discount cap is 100
        assertEquals(100.0, coupon.calculateDiscount(300.0));

        // 50% of 160 is 80, which is below max cap of 100
        assertEquals(80.0, coupon.calculateDiscount(160.0));
    }

    @Test
    @DisplayName("Test 3: Smart Budget strictly filters out combinations exceeding budget")
    void testSmartBudgetStrictUpperLimit() {
        RestaurantProfile res = RestaurantProfile.builder()
                .id("res-1")
                .businessName("Biryani Zone")
                .approvalStatus(ApprovalStatus.APPROVED)
                .isOpen(true)
                .location(GeoLocation.builder().latitude(12.9716).longitude(77.5946).build())
                .build();

        FoodItem item1 = FoodItem.builder()
                .id("f-1")
                .restaurantId("res-1")
                .name("Veg Dum Biryani")
                .price(140.0)
                .isVeg(true)
                .isAvailable(true)
                .build();

        FoodItem item2 = FoodItem.builder()
                .id("f-2")
                .restaurantId("res-1")
                .name("Royal Kebab Platter")
                .price(350.0)
                .isVeg(false)
                .isAvailable(true)
                .build();

        when(restaurantProfileRepository.findByApprovalStatusAndIsOpenTrue(ApprovalStatus.APPROVED)).thenReturn(List.of(res));
        when(foodItemRepository.findByIsAvailableTrue()).thenReturn(List.of(item1, item2));

        SmartBudgetRequest req = SmartBudgetRequest.builder()
                .budgetAmount(200.0) // Budget limit ₹200
                .userLatitude(12.9716)
                .userLongitude(77.5946)
                .build();

        SmartBudgetResponse response = smartBudgetService.findOptimalFoodForBudget(req);

        assertNotNull(response);
        for (var combo : response.getRecommendations()) {
            assertTrue(combo.getGrandTotal() <= 200.0, "Grand total " + combo.getGrandTotal() + " must never exceed budget 200.0");
        }
    }
}
