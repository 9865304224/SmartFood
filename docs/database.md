# SmartFood Database Schema & Collections

MongoDB Database: `smartfood_db` (or MongoDB Atlas URI)

## Core Collections & Indexes

### 1. `users`
- **Fields**: `id`, `email`, `phone`, `passwordHash`, `fullName`, `role`, `approvalStatus`, `isEmailVerified`, `isPhoneVerified`, `currentOtp`, `createdAt`, `updatedAt`
- **Indexes**:
  - `email` (Unique)
  - `phone` (Unique)
  - `role`
  - `approvalStatus`

### 2. `restaurant_profiles`
- **Fields**: `id`, `userId`, `businessName`, `description`, `ownerName`, `phone`, `email`, `address`, `location` (GeoLocation), `cuisineTypes`, `fssaiLicenseNumber`, `rating`, `totalReviews`, `isOpen`, `isPureVeg`, `preparationTimeMinutes`, `approvalStatus`
- **Indexes**:
  - `userId` (Unique)
  - `approvalStatus`

### 3. `hotel_profiles`
- **Fields**: `id`, `userId`, `businessName`, `description`, `address`, `location`, `cuisineTypes`, `allowsBulkOrders`, `minBulkOrderAmount`, `bulkDiscountPercentage`, `approvalStatus`
- **Indexes**: `userId` (Unique), `approvalStatus`

### 4. `delivery_profiles`
- **Fields**: `id`, `userId`, `fullName`, `phone`, `vehicleType`, `vehicleNumber`, `drivingLicenseNumber`, `currentStatus` (AVAILABLE, BUSY, OFFLINE), `currentLocation`, `totalDeliveries`, `rating`, `ecoScore`, `totalCo2SavedKg`, `approvalStatus`
- **Indexes**: `userId` (Unique), `approvalStatus`, `currentStatus`

### 5. `food_items`
- **Fields**: `id`, `restaurantId`, `hotelId`, `name`, `description`, `category`, `price`, `isVeg`, `isAvailable`, `preparationTimeMinutes`, `rating`, `tags`, `isBulkAvailable`, `bulkPrice`
- **Indexes**: `restaurantId`, `hotelId`, `category`, `isAvailable`, `price`

### 6. `food_saver_items`
- **Fields**: `id`, `restaurantId`, `hotelId`, `foodName`, `category`, `normalPrice`, `discountedPrice`, `quantityAvailable`, `availableUntil`, `isVeg`, `isExpired`
- **Indexes**: `availableUntil`, `isExpired`, `restaurantId`

### 7. `orders`
- **Fields**: `id`, `orderNumber`, `customerId`, `restaurantId`, `hotelId`, `deliveryPersonId`, `items`, `deliveryAddress`, `status`, `subtotal`, `deliveryFee`, `platformFee`, `taxes`, `discount`, `finalTotal`, `paymentMethod`, `paymentStatus`, `deliveryOtp`, `isEcoDelivery`, `estimatedDistanceKm`, `estimatedCo2SavingKg`, `createdAt`
- **Indexes**: `orderNumber` (Unique), `customerId`, `restaurantId`, `hotelId`, `deliveryPersonId`, `status`, `createdAt`

### 8. `order_status_history`
- **Fields**: `id`, `orderId`, `previousStatus`, `newStatus`, `changedByUserId`, `changedByUserRole`, `note`, `timestamp`
- **Indexes**: `orderId`, `timestamp`

### 9. `coupons`
- **Fields**: `id`, `code`, `description`, `discountPercentage`, `flatDiscountAmount`, `minOrderValue`, `maxDiscountAmount`, `restaurantId`, `isActive`
- **Indexes**: `code` (Unique), `isActive`

### 10. `reviews`, `complaints`, `fraud_flags`, `audit_logs`
- Full indexed collections for auditability, dispute tickets, and security oversight.
