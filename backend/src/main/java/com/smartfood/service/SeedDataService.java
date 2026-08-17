package com.smartfood.service;

import com.smartfood.model.BusinessHours;
import com.smartfood.model.Coupon;
import com.smartfood.model.CustomerProfile;
import com.smartfood.model.DeliveryProfile;
import com.smartfood.model.FoodCategory;
import com.smartfood.model.FoodItem;
import com.smartfood.model.FoodSaverItem;
import com.smartfood.model.GeoLocation;
import com.smartfood.model.HotelProfile;
import com.smartfood.model.Order;
import com.smartfood.model.OrderItem;
import com.smartfood.model.OrderStatusHistory;
import com.smartfood.model.PartnerDocument;
import com.smartfood.model.RestaurantProfile;
import com.smartfood.model.Review;
import com.smartfood.model.SavedAddress;
import com.smartfood.model.User;
import com.smartfood.model.enums.AddressType;
import com.smartfood.model.enums.ApprovalStatus;
import com.smartfood.model.enums.DeliveryStatus;
import com.smartfood.model.enums.OrderStatus;
import com.smartfood.model.enums.PaymentMethod;
import com.smartfood.model.enums.PaymentStatus;
import com.smartfood.model.enums.UserRole;
import com.smartfood.model.enums.VehicleType;
import com.smartfood.repository.CouponRepository;
import com.smartfood.repository.CustomerProfileRepository;
import com.smartfood.repository.DeliveryProfileRepository;
import com.smartfood.repository.FoodCategoryRepository;
import com.smartfood.repository.FoodItemRepository;
import com.smartfood.repository.FoodSaverItemRepository;
import com.smartfood.repository.HotelProfileRepository;
import com.smartfood.repository.OrderRepository;
import com.smartfood.repository.OrderStatusHistoryRepository;
import com.smartfood.repository.RestaurantProfileRepository;
import com.smartfood.repository.ReviewRepository;
import com.smartfood.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class SeedDataService implements CommandLineRunner {

    private final UserRepository userRepository;
    private final CustomerProfileRepository customerProfileRepository;
    private final RestaurantProfileRepository restaurantProfileRepository;
    private final HotelProfileRepository hotelProfileRepository;
    private final DeliveryProfileRepository deliveryProfileRepository;
    private final FoodCategoryRepository foodCategoryRepository;
    private final FoodItemRepository foodItemRepository;
    private final FoodSaverItemRepository foodSaverItemRepository;
    private final CouponRepository couponRepository;
    private final OrderRepository orderRepository;
    private final OrderStatusHistoryRepository orderStatusHistoryRepository;
    private final ReviewRepository reviewRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${smartfood.admin.email:admin@smartfood.com}")
    private String adminEmail;

    @Value("${smartfood.admin.password:Admin@123}")
    private String adminPassword;

    @Override
    public void run(String... args) {
        // Always ensure configured Admin account exists and is updated
        ensureAdminUser();

        if (userRepository.count() > 1) {
            log.info("Database already seeded with data. Skipping initial seeding.");
            return;
        }

        log.info("Starting SmartFood Database Seeding...");

        // 1. Seed Categories
        List<FoodCategory> categories = List.of(
                FoodCategory.builder().name("Biryani").description("Aromatic basmati rice layered with rich spices and choice cuts").displayOrder(1).isActive(true).build(),
                FoodCategory.builder().name("North Indian").description("Rich buttery curries, tandoori breads and paneer delicacies").displayOrder(2).isActive(true).build(),
                FoodCategory.builder().name("Pizza").description("Wood-fired crusts topped with gooey mozzarella and fresh herbs").displayOrder(3).isActive(true).build(),
                FoodCategory.builder().name("Burgers").description("Crispy patties stacked with fresh lettuce, sauces, and melted cheese").displayOrder(4).isActive(true).build(),
                FoodCategory.builder().name("Healthy & Bowls").description("Nutrient-rich protein bowls, fresh salads and whole grains").displayOrder(5).isActive(true).build(),
                FoodCategory.builder().name("Desserts").description("Artisanal sweets, warm gulab jamuns, and chilled pastries").displayOrder(6).isActive(true).build(),
                FoodCategory.builder().name("Beverages").description("Fresh juices, iced brews, lassis, and masala chai").displayOrder(7).isActive(true).build()
        );
        foodCategoryRepository.saveAll(categories);

        // 2. Seed Customer
        User customerUser = User.builder()
                .fullName("Aarav Sharma")
                .email("customer@smartfood.com")
                .phone("9876543211")
                .passwordHash(passwordEncoder.encode("Customer@123"))
                .role(UserRole.CUSTOMER)
                .approvalStatus(ApprovalStatus.APPROVED)
                .isEmailVerified(true)
                .isPhoneVerified(true)
                .isActive(true)
                .build();
        customerUser = userRepository.save(customerUser);

        CustomerProfile customerProfile = CustomerProfile.builder()
                .userId(customerUser.getId())
                .walletBalance(250.0)
                .savedAddresses(List.of(
                        SavedAddress.builder()
                                .id("addr-1")
                                .label("College Hostel")
                                .type(AddressType.COLLEGE)
                                .building("Aryabhatta Hall")
                                .block("Block B")
                                .floor("3rd Floor")
                                .room("Room 304")
                                .landmark("Near Main Library")
                                .formattedAddress("Aryabhatta Hall, Block B Room 304, Campus Rd, Bengaluru")
                                .location(GeoLocation.builder().latitude(12.9716).longitude(77.5946).build())
                                .isDefault(true)
                                .build(),
                        SavedAddress.builder()
                                .id("addr-2")
                                .label("Home")
                                .type(AddressType.HOME)
                                .building("Palm Meadows")
                                .floor("Flat 402")
                                .landmark("Opposite City Park")
                                .formattedAddress("Palm Meadows 402, Indiranagar, Bengaluru")
                                .location(GeoLocation.builder().latitude(12.9780).longitude(77.6400).build())
                                .isDefault(false)
                                .build()
                ))
                .build();
        customerProfileRepository.save(customerProfile);

        // 4. Seed Restaurant 1: Paradise Biryani Palace
        User res1User = User.builder()
                .fullName("Mohammad Tariq")
                .email("restaurant@smartfood.com")
                .phone("9876543212")
                .passwordHash(passwordEncoder.encode("Restaurant@123"))
                .role(UserRole.RESTAURANT)
                .approvalStatus(ApprovalStatus.APPROVED)
                .isEmailVerified(true)
                .isPhoneVerified(true)
                .isActive(true)
                .build();
        res1User = userRepository.save(res1User);

        RestaurantProfile res1Profile = RestaurantProfile.builder()
                .userId(res1User.getId())
                .businessName("Paradise Royal Biryani & Kebabs")
                .description("Authentic slow-dum cooked Biryani with secret royal Mughlai spices")
                .ownerName("Mohammad Tariq")
                .phone("9876543212")
                .email("restaurant@smartfood.com")
                .address("104 Brigade Road, Bengaluru")
                .location(GeoLocation.builder().latitude(12.9730).longitude(77.6070).formattedAddress("Brigade Road, Bengaluru").build())
                .cuisineTypes(List.of("Biryani", "North Indian", "Mughlai", "Kebabs"))
                .fssaiLicenseNumber("11223344556677")
                .gstNumber("29AABCU9603R1ZM")
                .rating(4.8)
                .totalReviews(142)
                .isOpen(true)
                .isPureVeg(false)
                .preparationTimeMinutes(20)
                .averageCostForTwo(400.0)
                .approvalStatus(ApprovalStatus.APPROVED)
                .build();
        res1Profile = restaurantProfileRepository.save(res1Profile);

        // 5. Seed Restaurant 2: Green Leaf Pure Veg
        User res2User = User.builder()
                .fullName("Suresh Prabhu")
                .email("greenleaf@smartfood.com")
                .phone("9876543213")
                .passwordHash(passwordEncoder.encode("GreenLeaf@123"))
                .role(UserRole.RESTAURANT)
                .approvalStatus(ApprovalStatus.APPROVED)
                .isEmailVerified(true)
                .isPhoneVerified(true)
                .isActive(true)
                .build();
        res2User = userRepository.save(res2User);

        RestaurantProfile res2Profile = RestaurantProfile.builder()
                .userId(res2User.getId())
                .businessName("Green Leaf Pure Veg Kitchen")
                .description("Wholesome vegetarian delicacies, paneer gravies and fresh tandoor rotis")
                .ownerName("Suresh Prabhu")
                .phone("9876543213")
                .email("greenleaf@smartfood.com")
                .address("45 Commercial Street, Bengaluru")
                .location(GeoLocation.builder().latitude(12.9810).longitude(77.6100).formattedAddress("Commercial Street, Bengaluru").build())
                .cuisineTypes(List.of("North Indian", "Healthy & Bowls", "Desserts"))
                .fssaiLicenseNumber("22334455667788")
                .gstNumber("29BBCDU8802R1ZK")
                .rating(4.6)
                .totalReviews(98)
                .isOpen(true)
                .isPureVeg(true)
                .preparationTimeMinutes(15)
                .averageCostForTwo(300.0)
                .approvalStatus(ApprovalStatus.APPROVED)
                .build();
        res2Profile = restaurantProfileRepository.save(res2Profile);

        // 6. Seed Hotel: Grand Orchid Resort
        User hotelUser = User.builder()
                .fullName("Vikram Singhania")
                .email("hotel@smartfood.com")
                .phone("9876543214")
                .passwordHash(passwordEncoder.encode("Hotel@123"))
                .role(UserRole.HOTEL)
                .approvalStatus(ApprovalStatus.APPROVED)
                .isEmailVerified(true)
                .isPhoneVerified(true)
                .isActive(true)
                .build();
        hotelUser = userRepository.save(hotelUser);

        HotelProfile hotelProfile = HotelProfile.builder()
                .userId(hotelUser.getId())
                .businessName("Grand Orchid Resort & Banquets")
                .description("Luxury hospitality kitchen catering bulk corporate lunches, grand event feasts and gourmet platters")
                .ownerName("Vikram Singhania")
                .phone("9876543214")
                .email("hotel@smartfood.com")
                .address("77 Outer Ring Road, Marathahalli, Bengaluru")
                .location(GeoLocation.builder().latitude(12.9560).longitude(77.7010).formattedAddress("Outer Ring Road, Bengaluru").build())
                .cuisineTypes(List.of("North Indian", "Biryani", "Desserts", "Chinese"))
                .fssaiLicenseNumber("33445566778899")
                .rating(4.9)
                .totalReviews(64)
                .isOpen(true)
                .allowsBulkOrders(true)
                .allowsEventCatering(true)
                .minBulkOrderAmount(1200.0)
                .bulkDiscountPercentage(20.0)
                .standardPrepTimeMinutes(35)
                .approvalStatus(ApprovalStatus.APPROVED)
                .build();
        hotelProfile = hotelProfileRepository.save(hotelProfile);

        // 7. Seed Delivery Persons (Rahul - Motorcycle, Priya - EV Scooter)
        User del1User = User.builder()
                .fullName("Rahul Verma")
                .email("delivery@smartfood.com")
                .phone("9876543215")
                .passwordHash(passwordEncoder.encode("Delivery@123"))
                .role(UserRole.DELIVERY_PERSON)
                .approvalStatus(ApprovalStatus.APPROVED)
                .isEmailVerified(true)
                .isPhoneVerified(true)
                .isActive(true)
                .build();
        del1User = userRepository.save(del1User);

        DeliveryProfile del1Profile = DeliveryProfile.builder()
                .userId(del1User.getId())
                .fullName("Rahul Verma")
                .phone("9876543215")
                .email("delivery@smartfood.com")
                .vehicleType(VehicleType.MOTORCYCLE)
                .vehicleNumber("KA-01-AB-1234")
                .drivingLicenseNumber("DL-KA-2019-009182")
                .currentStatus(DeliveryStatus.AVAILABLE)
                .currentLocation(GeoLocation.builder().latitude(12.9725).longitude(77.6050).formattedAddress("Brigade Rd Junction, Bengaluru").build())
                .rating(4.9)
                .totalDeliveries(340)
                .ecoScore(88.0)
                .approvalStatus(ApprovalStatus.APPROVED)
                .build();
        deliveryProfileRepository.save(del1Profile);

        User del2User = User.builder()
                .fullName("Priya Patel")
                .email("priya.delivery@smartfood.com")
                .phone("9876543216")
                .passwordHash(passwordEncoder.encode("Delivery@123"))
                .role(UserRole.DELIVERY_PERSON)
                .approvalStatus(ApprovalStatus.APPROVED)
                .isEmailVerified(true)
                .isPhoneVerified(true)
                .isActive(true)
                .build();
        del2User = userRepository.save(del2User);

        DeliveryProfile del2Profile = DeliveryProfile.builder()
                .userId(del2User.getId())
                .fullName("Priya Patel (EV Green Fleet)")
                .phone("9876543216")
                .email("priya.delivery@smartfood.com")
                .vehicleType(VehicleType.ELECTRIC_VEHICLE)
                .vehicleNumber("KA-03-EV-5678")
                .drivingLicenseNumber("DL-KA-2021-004312")
                .currentStatus(DeliveryStatus.AVAILABLE)
                .currentLocation(GeoLocation.builder().latitude(12.9740).longitude(77.6080).formattedAddress("MG Road Metro, Bengaluru").build())
                .rating(4.95)
                .totalDeliveries(210)
                .ecoScore(98.0)
                .totalCo2SavedKg(42.5)
                .approvalStatus(ApprovalStatus.APPROVED)
                .build();
        deliveryProfileRepository.save(del2Profile);

        // 8. Seed Menu Items
        List<FoodItem> foodItems = List.of(
                // Paradise Biryani items
                FoodItem.builder().restaurantId(res1Profile.getId()).name("Special Hyderabadi Dum Biryani").category("Biryani").price(240.0).isVeg(false).isAvailable(true).preparationTimeMinutes(20).rating(4.9).tags(List.of("Bestseller", "Royal Recipe")).description("Signature long-grain basmati rice with succulent spices and raita").build(),
                FoodItem.builder().restaurantId(res1Profile.getId()).name("Royal Veg Dum Biryani").category("Biryani").price(180.0).isVeg(true).isAvailable(true).preparationTimeMinutes(15).rating(4.7).tags(List.of("Top Veg Pick")).description("Layered basmati rice with fresh garden vegetables and aromatic saffron").build(),
                FoodItem.builder().restaurantId(res1Profile.getId()).name("Chicken Seekh Kebab (4 pcs)").category("North Indian").price(190.0).isVeg(false).isAvailable(true).preparationTimeMinutes(15).rating(4.8).description("Tender minced chicken skewers char-grilled in tandoor").build(),
                FoodItem.builder().restaurantId(res1Profile.getId()).name("Butter Naan (2 pcs)").category("North Indian").price(60.0).isVeg(true).isAvailable(true).preparationTimeMinutes(8).rating(4.6).description("Fluffy clay oven baked bread brushed with fresh butter").build(),
                FoodItem.builder().restaurantId(res1Profile.getId()).name("Gulab Jamun with Rabri").category("Desserts").price(80.0).isVeg(true).isAvailable(true).preparationTimeMinutes(5).rating(4.9).description("Soft golden dumplings soaked in sugar syrup served with rich condensed milk rabri").build(),
                FoodItem.builder().restaurantId(res1Profile.getId()).name("Tandoori Chicken Full").category("North Indian").price(340.0).isVeg(false).isAvailable(true).preparationTimeMinutes(25).rating(4.85).tags(List.of("Must Try")).description("Whole roasted chicken marinated in yogurt and fiery Kashmiri spices").build(),
                FoodItem.builder().restaurantId(res1Profile.getId()).name("Cold Brew Iced Coffee").category("Beverages").price(95.0).isVeg(true).isAvailable(true).preparationTimeMinutes(3).rating(4.7).description("Smooth 18-hour cold brew Arabica coffee over ice").build(),

                // Green Leaf items
                FoodItem.builder().restaurantId(res2Profile.getId()).name("Paneer Tikka Butter Masala").category("North Indian").price(210.0).isVeg(true).isAvailable(true).preparationTimeMinutes(15).rating(4.8).tags(List.of("Chef's Special")).description("Tandoor-charred cottage cheese cubes in velvety tomato cashew gravy").build(),
                FoodItem.builder().restaurantId(res2Profile.getId()).name("Dal Makhani Royale").category("North Indian").price(160.0).isVeg(true).isAvailable(true).preparationTimeMinutes(12).rating(4.7).description("Slow-simmered black lentils and kidney beans enriched with pure butter & cream").build(),
                FoodItem.builder().restaurantId(res2Profile.getId()).name("High-Protein Quinoa Buddha Bowl").category("Healthy & Bowls").price(195.0).isVeg(true).isAvailable(true).preparationTimeMinutes(10).rating(4.9).tags(List.of("Diet Friendly")).description("Organic quinoa, roasted chickpeas, avocado, edamame and lemon tahini dressing").build(),
                FoodItem.builder().restaurantId(res2Profile.getId()).name("Fresh Mango Lassi (400ml)").category("Beverages").price(70.0).isVeg(true).isAvailable(true).preparationTimeMinutes(5).rating(4.8).description("Creamy churned yogurt blended with sweet Alphonso mango pulp").build(),
                FoodItem.builder().restaurantId(res2Profile.getId()).name("Farmhouse Gourmet Pizza (10 inch)").category("Pizza").price(260.0).isVeg(true).isAvailable(true).preparationTimeMinutes(18).rating(4.8).tags(List.of("Crispy Crust")).description("Topped with bell peppers, sweet corn, mushrooms, olives and melted mozzarella").build(),
                FoodItem.builder().restaurantId(res2Profile.getId()).name("Crispy Veg Crunch Burger with Fries").category("Burgers").price(140.0).isVeg(true).isAvailable(true).preparationTimeMinutes(10).rating(4.6).description("Crispy herb patty with smoky chipotle mayo, lettuce, and seasoned fries").build(),
                FoodItem.builder().restaurantId(res2Profile.getId()).name("Belgian Chocolate Fudge Brownie").category("Desserts").price(110.0).isVeg(true).isAvailable(true).preparationTimeMinutes(4).rating(4.95).description("Warm gooey dark chocolate brownie drizzled with rich chocolate ganache").build(),

                // Hotel Bulk items & Catering Banquets
                FoodItem.builder().hotelId(hotelProfile.getId()).name("Executive Corporate Feast Platter").category("North Indian").price(1200.0).isVeg(true).isAvailable(true).isBulkAvailable(true).bulkMinQuantity(5).bulkPrice(950.0).preparationTimeMinutes(35).rating(4.9).description("Multi-course banquet spread: 2 curries, jeera rice, 10 naans, salad, raita & dessert for 5-6 people").build(),
                FoodItem.builder().hotelId(hotelProfile.getId()).name("Grand Mughlai Biryani Handi (Serves 8-10)").category("Biryani").price(1800.0).isVeg(false).isAvailable(true).isBulkAvailable(true).bulkMinQuantity(2).bulkPrice(1500.0).preparationTimeMinutes(40).rating(4.95).description("Jumbo sealed clay pot filled with royal aromatic dum biryani, boiled eggs, mirchi ka salan and raita").build(),
                FoodItem.builder().hotelId(hotelProfile.getId()).name("Grand Campus Student Party Buffet").category("North Indian").price(350.0).isVeg(true).isAvailable(true).isBulkAvailable(true).bulkMinQuantity(10).bulkPrice(280.0).preparationTimeMinutes(45).rating(4.88).tags(List.of("Campus Favorite")).description("All-you-can-eat campus buffet: Paneer Lababdar, Dal Tadka, Pulao, Tandoori Rotis, Gulab Jamun & Cold Drinks").build(),
                FoodItem.builder().hotelId(hotelProfile.getId()).name("Royal Wedding & Event Platter (Per Person)").category("North Indian").price(450.0).isVeg(false).isAvailable(true).isBulkAvailable(true).bulkMinQuantity(15).bulkPrice(380.0).preparationTimeMinutes(60).rating(4.92).tags(List.of("VIP Catering")).description("Luxury 5-course catering package: Kebabs, Butter Chicken / Paneer, Mutton Biryani, Assorted Breads & Kulfi").build()
        );
        foodItemRepository.saveAll(foodItems);

        // 9. Seed Food Saver Item (Food waste reduction marketplace)
        FoodSaverItem saver1 = FoodSaverItem.builder()
                .restaurantId(res1Profile.getId())
                .foodName("Royal Veg Dum Biryani (Food Saver Deal)")
                .category("Biryani")
                .normalPrice(180.0)
                .discountedPrice(89.0) // 50% discount
                .quantityAvailable(8)
                .initialQuantity(10)
                .availableUntil(Instant.now().plus(4, ChronoUnit.HOURS))
                .isVeg(true)
                .description("Freshly prepared afternoon batch surplus. 100% hot and fresh! Save food & save money.")
                .build();

        FoodSaverItem saver2 = FoodSaverItem.builder()
                .restaurantId(res2Profile.getId())
                .foodName("Paneer Butter Masala Combo (Food Saver Deal)")
                .category("North Indian")
                .normalPrice(210.0)
                .discountedPrice(99.0)
                .quantityAvailable(5)
                .initialQuantity(6)
                .availableUntil(Instant.now().plus(3, ChronoUnit.HOURS))
                .isVeg(true)
                .description("Freshly cooked evening batch surplus ready for immediate eco-friendly pickup or express delivery.")
                .build();
        foodSaverItemRepository.saveAll(List.of(saver1, saver2));

        // 10. Seed Platform Coupons
        List<Coupon> coupons = List.of(
                Coupon.builder().code("SMART50").description("Get 50% off up to ₹100 on all orders").discountPercentage(50.0).maxDiscountAmount(100.0).minOrderValue(149.0).isActive(true).build(),
                Coupon.builder().code("WELCOME100").description("Flat ₹100 off on your first order").flatDiscountAmount(100.0).minOrderValue(299.0).isActive(true).build(),
                Coupon.builder().code("FEAST20").description("20% off on premium meals").discountPercentage(20.0).maxDiscountAmount(150.0).minOrderValue(199.0).isActive(true).build()
        );
        couponRepository.saveAll(coupons);

        // 11. Seed Sample Delivered Order & Verified Review
        Order sampleOrder = Order.builder()
                .orderNumber("SF-2026-1001")
                .customerId(customerUser.getId())
                .customerName(customerUser.getFullName())
                .customerPhone(customerUser.getPhone())
                .restaurantId(res1Profile.getId())
                .businessName(res1Profile.getBusinessName())
                .pickupLocation(res1Profile.getLocation())
                .deliveryPersonId(del1User.getId())
                .deliveryPersonName(del1Profile.getFullName())
                .deliveryPersonPhone(del1Profile.getPhone())
                .items(List.of(
                        OrderItem.builder().foodName("Special Hyderabadi Dum Biryani").price(240.0).quantity(1).itemTotal(240.0).isVeg(false).build(),
                        OrderItem.builder().foodName("Gulab Jamun with Rabri").price(80.0).quantity(1).itemTotal(80.0).isVeg(true).build()
                ))
                .deliveryAddress(customerProfile.getSavedAddresses().getFirst())
                .status(OrderStatus.DELIVERED)
                .subtotal(320.0)
                .deliveryFee(30.0)
                .platformFee(5.0)
                .taxes(16.0)
                .discount(50.0)
                .finalTotal(321.0)
                .paymentMethod(PaymentMethod.MOCK_DEV)
                .paymentStatus(PaymentStatus.PAID)
                .deliveryOtp("8492")
                .isEcoDelivery(true)
                .estimatedDistanceKm(2.4)
                .estimatedCo2SavingKg(0.29)
                .ecoScore(94.0)
                .createdAt(Instant.now().minus(2, ChronoUnit.DAYS))
                .deliveredAt(Instant.now().minus(2, ChronoUnit.DAYS).plus(28, ChronoUnit.MINUTES))
                .build();
        sampleOrder = orderRepository.save(sampleOrder);

        // Seed Review
        Review sampleReview = Review.builder()
                .orderId(sampleOrder.getId())
                .customerId(customerUser.getId())
                .customerName(customerUser.getFullName())
                .targetType("RESTAURANT")
                .targetId(res1Profile.getId())
                .rating(5.0)
                .tasteRating(5.0)
                .deliveryRating(5.0)
                .packagingRating(5.0)
                .valueRating(5.0)
                .comment("Incredible authentic biryani! Piping hot, tamper-proof eco packaging, and super fast delivery by Rahul.")
                .sentiment("POSITIVE")
                .sentimentScore(1.0)
                .isVerifiedOrder(true)
                .createdAt(Instant.now().minus(2, ChronoUnit.DAYS).plus(1, ChronoUnit.HOURS))
                .build();
        reviewRepository.save(sampleReview);

        log.info("SmartFood Database Seeding Completed Successfully! Seed accounts created.");
    }

    private void ensureAdminUser() {
        String email = (adminEmail != null && !adminEmail.isBlank()) ? adminEmail.toLowerCase().trim() : "admin@smartfood.com";
        String password = (adminPassword != null && !adminPassword.isBlank()) ? adminPassword : "Admin@123";

        userRepository.findByEmail(email).ifPresentOrElse(
                admin -> {
                    admin.setRole(UserRole.ADMIN);
                    admin.setApprovalStatus(ApprovalStatus.APPROVED);
                    admin.setActive(true);
                    admin.setEmailVerified(true);
                    admin.setPhoneVerified(true);
                    admin.setPasswordHash(passwordEncoder.encode(password));
                    userRepository.save(admin);
                    log.info("Admin account verified & synchronized: {}", email);
                },
                () -> {
                    User newAdmin = User.builder()
                            .fullName("SmartFood System Admin")
                            .email(email)
                            .phone("9876543210")
                            .passwordHash(passwordEncoder.encode(password))
                            .role(UserRole.ADMIN)
                            .approvalStatus(ApprovalStatus.APPROVED)
                            .isEmailVerified(true)
                            .isPhoneVerified(true)
                            .isActive(true)
                            .build();
                    userRepository.save(newAdmin);
                    log.info("Admin account created successfully: {}", email);
                }
        );
    }
}
