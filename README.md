# SmartFood — Full-Stack AI Food Delivery Platform

[![Spring Boot 3](https://img.shields.io/badge/Spring%20Boot-3.3+-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Java 21](https://img.shields.io/badge/Java-21-orange.svg)](https://www.oracle.com/java/)
[![Flutter](https://img.shields.io/badge/Flutter-3.22+-blue.svg)](https://flutter.dev/)
[![MongoDB](https://img.shields.io/badge/MongoDB-7.0-green.svg)](https://www.mongodb.com/)
[![License](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

SmartFood is a complete, production-grade, AI-augmented food delivery platform designed to rival modern commercial food delivery applications while introducing groundbreaking features such as:

* 🤖 **AI-Powered Personalized Food Discovery** — Time-of-day, past order collaborative filtering, and taste profiling.
* 💰 **Smart Budget Feature** — Strict spending cap guarantee with complete breakdown (Items + Delivery + Taxes - Discounts $\le$ Budget).
* 🛵 **Intelligent Delivery Person Assignment** — Multi-factor weighted scoring (proximity, workload, rating, eco vehicle bonus).
* 🗺️ **Live OpenStreetMap Tracking** — Real-time driver GPS tracking via STOMP WebSocket channels using `flutter_map`.
* 🛡️ **Delivery OTP Verification** — 4-digit security code generated on pickup, verified server-side on drop-off.
* 🌿 **Eco-Friendly Delivery & Multi-Order Grouping** — Route optimization engine pairing compatible campus deliveries to reduce vehicle mileage and carbon footprint.
* 🍲 **Food Waste Reduction Marketplace** — Food Saver listings allowing restaurants and hotels to offer surplus batches at 50–70% off.
* 👥 **Group Ordering Rooms** — Shareable room join code for friends and colleagues to aggregate items into a single checkout.
* 🏢 **College & Office Structured Deliveries** — Multi-tier address tags (Hostel, Block, Room, Landmark).
* 🏨 **Hotels & Corporate Bulk Orders** — Large-quantity catering packages with custom tiered discounts.
* 📊 **Admin AI Command Center** — Natural language operational intelligence for real-time querying of platform metrics and partner approvals.

---

## Monorepo Project Structure

```
SmartFood/
├── mobile/                 # Flutter mobile application (Material 3, Riverpod, flutter_map)
├── backend/                # Spring Boot 3.3.x / Java 21 REST & WebSocket backend
├── admin-web/              # Vite + React Operations & Admin Dashboard
├── docs/                   # Full technical specifications
│   ├── architecture.md
│   ├── api.md
│   ├── database.md
│   ├── setup.md
│   └── testing.md
├── docker/                 # Containerization & docker-compose configuration
│   ├── Dockerfile.backend
│   ├── Dockerfile.admin
│   └── docker-compose.yml
├── .env.example            # Environment variables reference
└── README.md
```

---

## Quick Start

### 1. Start the Backend (Spring Boot 3 + Java 21)
```bash
cd backend
mvn spring-boot:run
```
*Backend runs on `http://localhost:8080` and auto-seeds test accounts.*

### 2. Start the Admin Web Dashboard (Vite + React)
```bash
cd admin-web
npm install
npm run dev
```
*Admin Dashboard runs on `http://localhost:3000`.*

### 3. Run the Mobile App (Flutter)
```bash
cd mobile
flutter pub get
flutter run -d chrome
```

---

## Pre-Configured Demo Accounts

| Role | Email | Password |
| :--- | :--- | :--- |
| **Admin** | `admin@smartfood.com` | `Admin@123` |
| **Customer** | `customer@smartfood.com` | `Customer@123` |
| **Restaurant** | `restaurant@smartfood.com` | `Restaurant@123` |
| **Hotel** | `hotel@smartfood.com` | `Hotel@123` |
| **Delivery Rider** | `delivery@smartfood.com` | `Delivery@123` |
