# SmartFood — Technical Architecture Documentation

## 1. System Overview

SmartFood is a full-stack, AI-augmented food delivery platform designed with clean architecture principles, real database persistence (MongoDB), Spring Boot 3 backend (Java 21), a responsive Flutter mobile client, and a React/Vite Admin Web Operations Console.

```
+------------------------------------------------------------------------------------+
|                                    CLIENT TIER                                     |
|  +--------------------------------------------+  +-------------------------------+ |
|  |             Flutter Mobile App             |  |      Admin Web Dashboard      | |
|  |  (Customer / Restaurant / Hotel / Driver)  |  |      (React 18 + Vite SPA)    | |
|  +--------------------------------------------+  +-------------------------------+ |
+------------------------------------------------------------------------------------+
                                      | HTTPS & WSS
                                      v
+------------------------------------------------------------------------------------+
|                         SPRING BOOT 3 BACKEND APPLICATION                          |
|                                                                                    |
|  [Security & Auth]  -- Spring Security 6, JWT, BCrypt, RBAC (5 Roles)              |
|  [REST Controllers] -- Auth, Customer, Restaurant, Hotel, Delivery, Order, Cart    |
|  [WebSocket Broker] -- STOMP over WebSocket (/topic, /queue) for Live GPS Tracking |
|                                                                                    |
|  +-----------------------------------+  +---------------------------------------+  |
|  |           Core Engines            |  |              AI Services              |  |
|  | - Order Lifecycle State Machine   |  | - Personalized Recommendation Engine  |  |
|  | - Smart Delivery Scoring Engine   |  | - Smart Budget Constraint Optimizer   |  |
|  | - Multi-Order Route Optimizer     |  | - AI Menu OCR / Extraction Service    |  |
|  | - Real-time ETA Predictor         |  | - Review Sentiment Analysis Engine    |  |
|  | - Eco-Delivery Carbon Calculator  |  | - Rule-Based Fraud Detection Engine   |  |
|  | - Payment & Mock Gateway Provider |  | - Admin AI Operations Assistant       |  |
|  +-----------------------------------+  +---------------------------------------+  |
+------------------------------------------------------------------------------------+
                                      |
                                      v
+------------------------------------------------------------------------------------+
|                                  PERSISTENCE TIER                                  |
|                            MongoDB / MongoDB Atlas Cluster                         |
|   25+ Indexed Collections (Users, Profiles, Menus, Orders, History, Logs, etc.)    |
+------------------------------------------------------------------------------------+
```

---

## 2. Role-Based Access Control Matrix

| Role | Allowed API Endpoints & Capabilities |
| :--- | :--- |
| `CUSTOMER` | `/api/customers/**`, `/api/cart/**`, `/api/group-orders/**`, `/api/orders/checkout`, `/api/reviews`, `/api/complaints` |
| `RESTAURANT` | `/api/restaurants/**` (Profile update, menu CRUD, Food Saver deals, incoming order progression) |
| `HOTEL` | `/api/hotels/**` (Bulk item pricing, event catering packages, corporate scheduled orders) |
| `DELIVERY_PERSON` | `/api/delivery/**` (Available/Busy status toggle, GPS coordinates streaming, Customer OTP delivery completion) |
| `ADMIN` | `/api/admin/**` (Partner approvals, live order monitor, dispute resolution, AI command center, audit logs) |

---

## 3. Algorithmic Highlights

### A. Smart Delivery Assignment Algorithm
When an order transitions to `READY_FOR_PICKUP`, candidates are scored based on:
$$\text{Score} = \text{DistanceScore}(0\text{--}40) + \text{WorkloadScore}(0\text{--}30) + \text{RatingScore}(0\text{--}20) + \text{EcoBonus}(0\text{--}10)$$
The highest scoring driver is automatically assigned with live WebSocket notifications.

### B. Smart Budget Guarantee
Given a spending limit (e.g. ₹250), the system evaluates:
$$\text{Grand Total} = \text{Subtotal} + \text{DeliveryFee}(\text{distance}) + \text{PlatformFee} + \text{GST} - \text{Discount} \le \text{Budget}$$
Ensuring the customer's cart never overflows their budget.

### C. Multi-Order Route Optimization
Combines proximate orders with pickup distance $\le 1.5\text{ km}$ and dropoff distance $\le 3.5\text{ km}$ under the constraint:
$$\text{Extra Delay} \le \text{MAX\_EXTRA\_DELAY\_MINUTES (15 mins)}$$
Reducing combined vehicle distance by ~25% and cutting CO2 emissions.
