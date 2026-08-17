# SmartFood Setup & Execution Guide

## Prerequisites
- Java 21+ (`java -version`)
- Maven 3.8+ (`mvn -version`)
- Flutter 3.22+ (`flutter --version`)
- Node.js 18+ & npm (`node -v`, `npm -v`)
- MongoDB (Local instance running on `localhost:27017` or MongoDB Atlas URI)

---

## 1. Backend Setup & Startup

1. Open a terminal in the `backend/` directory:
   ```bash
   cd backend
   ```
2. Build and run the Spring Boot application:
   ```bash
   mvn spring-boot:run
   ```
3. The server will start on port `8080` (`http://localhost:8080`).
4. On initial startup, `SeedDataService` will automatically populate the database with complete sample accounts, menus, active deals, coupons, and orders.

---

## 2. Admin Web Dashboard Setup & Startup

1. Open a terminal in the `admin-web/` directory:
   ```bash
   cd admin-web
   ```
2. Install dependencies (if not already installed):
   ```bash
   npm install
   ```
3. Run the development server:
   ```bash
   npm run dev
   ```
4. Open your browser at `http://localhost:3000`.
5. Login with `admin@smartfood.com` / `Admin@123`.

---

## 3. Flutter Mobile Application Setup & Startup

1. Open a terminal in the `mobile/` directory:
   ```bash
   cd mobile
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the Flutter application on your connected device or Chrome:
   ```bash
   flutter run -d chrome
   ```
4. Use the quick-role switcher chips on the login screen to switch between Customer, Restaurant, Hotel, and Delivery Rider accounts.

---

## 4. Pre-Configured Seed Demo Credentials

| Role | Email | Password | Description |
| :--- | :--- | :--- | :--- |
| **ADMIN** | `admin@smartfood.com` | `Admin@123` | Full dashboard, approvals, live order monitor, AI assistant |
| **CUSTOMER** | `customer@smartfood.com` | `Customer@123` | Orders, Smart Budget, Live Tracking, Food Saver |
| **RESTAURANT** | `restaurant@smartfood.com` | `Restaurant@123` | Paradise Biryani Palace kitchen orders & menu |
| **RESTAURANT 2** | `greenleaf@smartfood.com` | `GreenLeaf@123` | Green Leaf Pure Veg kitchen |
| **HOTEL** | `hotel@smartfood.com` | `Hotel@123` | Grand Orchid Resort (Bulk orders & Catering) |
| **DELIVERY RIDER** | `delivery@smartfood.com` | `Delivery@123` | Rahul Verma (Motorcycle) |
| **DELIVERY RIDER 2** | `priya.delivery@smartfood.com` | `Delivery@123` | Priya Patel (Green EV Fleet) |
