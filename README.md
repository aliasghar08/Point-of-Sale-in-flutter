# 🏪 POS System - Point of Sale Application

A modern Point of Sale (POS) system built with Flutter and Firebase. This application streamlines checkout and inventory management with **built-in support for both QR code and barcode scanning**, allowing for rapid product identification, real-time sales tracking, and seamless role-based access control.

## 📋 Features

### 🛒 Point of Sale
* **Universal Scanning Integration:** Instantly add products to the cart using the built-in device camera to scan both **1D Barcodes** and **2D QR Codes**.
* **Multiple Input Methods:** QR/Barcode Scanner, Voice Input, and Manual Search.
* **Cart Management:** Add/Remove items, Update quantities, Swipe to delete.
* **Checkout System:** Multiple payment methods (Cash, Card, Mobile Payment, Credit).
* **Real-time Calculations:** Total amount, Profit tracking.
* **Receipt Generation:** Auto-generated receipts with a physical print option.

### 📦 Inventory Management
* **Rapid Stock Entry:** Use the device camera to scan existing barcodes or QR codes to quickly input and register new products into the inventory.
* **Real-time Tracking:** Live product synchronization with Firestore.
* **Low Stock Alerts:** Customizable thresholds with automated warnings.
* **Product CRUD:** Full operations (Add, Edit, Delete) linked to scannable SKUs.
* **Search and Filter:** Find items manually or by scanning.
* **Stock Statistics:** Comprehensive dashboard for inventory health.

### 👥 User Management (Owner Only)
* **Role-Based Access Control:** Distinct interfaces and permissions for Owner, Manager, and Worker.
* **Account Controls:** User activation/deactivation and profile management.

### ⚙️ Settings
* **Hardware Integration:** Toggle auto-scanning features and camera flash controls.
* **Theme & UI:** Light, Dark, System default.
* **Currency:** Multiple currency support (PKR, INR, USD, EUR, GBP, etc.).
* **POS Settings:** Toggle profit display, Auto-print receipt.
* **Notifications:** Sound effects and vibration feedback on successful scans.
* **Data & Sync:** Offline mode support with auto-sync capability.

### 📊 Reports
* **Sales History:** Full transaction details including timestamp and payment method.
* **Daily Analytics:** Daily sales summaries and profit tracking per transaction.

## 🏗️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase (Firestore, Auth)
* **State Management:** Provider
* **Local Storage:** SharedPreferences
* **Key Libraries:** `mobile_scanner` (for QR/Barcode processing), `speech_to_text`, `intl`, `email_validator`

## 🚀 Quick Start

### Prerequisites
* Flutter SDK (>=3.0.0)
* Firebase Account
* Android Studio / VS Code
* *Note: A physical device is recommended to test the camera-based barcode and QR scanning features.*
