# SmartFood Automated & Manual Testing Guide

## 1. Automated Backend Unit & Integration Tests

Run the complete Maven test suite:
```bash
cd backend
mvn clean test
```

### Verified Test Cases:
- `testUserRegistration`: Validates BCrypt encoding, JWT token generation, role assignment, and profile creation.
- `testCouponValidationAndCalculation`: Verifies percentage discounts, minimum order threshold validation, and maximum discount caps.
- `testSmartBudgetStrictUpperLimit`: Confirms that the Smart Budget optimization engine never allows combinations to exceed the specified budget limit.

---

## 2. Automated Flutter Mobile Tests

Run the Flutter test suite:
```bash
cd mobile
flutter test
```

### Verified Test Cases:
- `FoodItem deserialization from JSON`: Confirms model parsing for menus and dietary flags.
- `CartModel pricing and item count calculation`: Validates fee arithmetic, discounts, and item quantities.

---

## 3. End-to-End Primary Demo Flow

To verify the platform end-to-end:
1. **Customer**:
   - Log in as `customer@smartfood.com` / `Customer@123`.
   - Open **Smart Budget Discovery** and test `₹250` budget slider.
   - Add a combo meal or menu item from Paradise Royal Biryani.
   - Apply coupon `SMART50` in the cart.
   - Checkout with Eco-Delivery enabled.
   - You will receive a 4-digit Delivery OTP (e.g. `8492`) and a live OpenStreetMap route.

2. **Restaurant**:
   - Log in as `restaurant@smartfood.com` / `Restaurant@123`.
   - View the incoming order in the live kitchen panel.
   - Click `Accept Order` -> `Start Preparing` -> `Mark Food Ready`.

3. **Delivery Rider**:
   - Log in as `delivery@smartfood.com` / `Delivery@123`.
   - View assigned order -> Click `Confirm Pickup` -> `Start Delivery`.
   - Click `Enter Delivery OTP` -> Input customer's 4-digit OTP.
   - Order transitions to `DELIVERED` and rider earnings are credited.

4. **Admin Web Console**:
   - Open `http://localhost:3000` and sign in as `admin@smartfood.com` / `Admin@123`.
   - View live Gross Revenue, completed deliveries, and active orders.
   - Open **AI Command Center** and ask: *"Which food categories are most popular?"*.
   - Review immutable system audit logs in the **Security & Audit Logs** tab.
