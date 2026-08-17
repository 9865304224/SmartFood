# SmartFood REST & WebSocket API Specification

## Base URLs
- REST API: `http://localhost:8080/api`
- WebSocket STOMP: `ws://localhost:8080/ws-smartfood` or `/ws-smartfood-direct`

---

## Authentication Endpoints (`/api/auth/**`)

### 1. Register User
- **POST** `/api/auth/register`
- **Body**:
  ```json
  {
    "fullName": "Aarav Sharma",
    "email": "customer@smartfood.com",
    "phone": "9876543211",
    "password": "Customer@123",
    "role": "CUSTOMER"
  }
  ```

### 2. Login User
- **POST** `/api/auth/login`
- **Body**:
  ```json
  {
    "username": "customer@smartfood.com",
    "password": "Customer@123"
  }
  ```
- **Response**: JWT Access Token, Refresh Token, User Role, Profile ID.

### 3. Verify OTP
- **POST** `/api/auth/verify-otp`
- **Body**:
  ```json
  {
    "username": "customer@smartfood.com",
    "otp": "757991"
  }
  ```

---

## Image & Cloudinary Storage Endpoints (`/api/upload/**`)

### Upload Product / Restaurant Image
- **POST** `/api/upload/image?folder=products`
- **Content-Type**: `multipart/form-data`
- **Form Data**:
  - `file`: Image file (JPEG, PNG, WEBP)
  - `folder`: `products` (default), `restaurants`, `hotels`, `avatars`, or `documents`
- **Response**:
  ```json
  {
    "success": true,
    "message": "Image uploaded successfully",
    "data": {
      "url": "https://res.cloudinary.com/.../smartfood/products/sample.jpg",
      "publicId": "smartfood/products/sample.jpg",
      "format": "jpg",
      "bytes": 245100
    }
  }
  ```

---

## AI & Discovery Endpoints

### 1. AI Personalized Recommendations
- **GET** `/api/recommendations`
- Returns dynamic time-of-day, past order collaborative filtering, and best-value collections.

### 2. Smart Budget Discovery
- **POST** `/api/recommendations/smart-budget`
- **Body**:
  ```json
  {
    "budgetAmount": 250.0,
    "isVegOnly": false,
    "userLatitude": 12.9716,
    "userLongitude": 77.5946
  }
  ```

### 3. Voice Search NLU
- **GET** `/api/recommendations/voice-search?query=Show vegetarian food under 200`

---

## Order & Cart Endpoints

### 1. Add to Cart
- **POST** `/api/cart/add`
- **Body**:
  ```json
  {
    "foodItemId": "f-101",
    "quantity": 1,
    "restaurantId": "res-101"
  }
  ```

### 2. Apply Coupon
- **POST** `/api/cart/coupon?couponCode=SMART50`

### 3. Checkout Order
- **POST** `/api/orders/checkout`
- **Body**:
  ```json
  {
    "deliveryAddress": {
      "id": "addr-1",
      "label": "Hostel",
      "type": "COLLEGE",
      "building": "Aryabhatta Block B",
      "formattedAddress": "Campus Road, Bengaluru",
      "location": { "latitude": 12.9716, "longitude": 77.5946 }
    },
    "paymentMethod": "MOCK_DEV",
    "isEcoDelivery": true
  }
  ```

### 4. Order Status Update
- **PATCH** `/api/orders/{orderId}/status`
- Transitions: `PLACED` -> `ACCEPTED` -> `PREPARING` -> `READY_FOR_PICKUP` -> `DELIVERY_ASSIGNED` -> `PICKED_UP` -> `OUT_FOR_DELIVERY` -> `DELIVERED`.

### 5. Verify Delivery OTP
- **POST** `/api/delivery/orders/{orderId}/verify-otp?otp=8492`

---

## Admin Endpoints (`/api/admin/**`)

- **GET** `/api/admin/overview`: Summary platform statistics and financial metrics.
- **GET** `/api/admin/approvals`: List pending restaurant, hotel, and rider registrations.
- **POST** `/api/admin/approvals/decision`: Approve or reject partner with reason and audit log.
- **POST** `/api/admin/ai-command?query=Which restaurants had the highest cancellation rate?`: AI business analytics query.
- **GET** `/api/admin/audit-logs`: View immutable admin action trail.
