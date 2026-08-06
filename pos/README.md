# 🏪 POS System - Modern Point of Sale & Retail Management Application

A state-of-the-art, high-performance Point of Sale (POS) system engineered with **Flutter** and **Firebase**. Built with an **in-house native services architecture** and a refined **Material 3 Design System**, this application delivers lightning-fast checkout workflows, vector barcode/QR scanning & rendering, smart cash tender calculation, customer loyalty CRM, thermal receipt generation, and real-time inventory management.

---

## 📋 Key Features & Modules

### 🛒 1. Point of Sale & Checkout Register
* **Universal Scanning Integration:** Instantly scan and add items to cart using the built-in device camera for both **1D Barcodes** (Code 128, EAN-13, UPC) and **2D QR Codes**.
* **Multiple Input Methods:** High-speed camera scanner, voice-to-text recognition, and instant in-memory search with debouncing.
* **Park & Resume Orders (Held Orders):** Hold active customer carts to attend other customers and resume them anytime with items, discounts, customer info, and notes intact.
* **Smart Cash Tender & Change Calculator:** Quick-tap denomination chips ($5, $10, $20, $50, $100, and Exact Amount) with real-time change calculation and validation.
* **Quick Custom Items on the Fly:** Add ad-hoc or unlisted products/services to the cart with custom name and price without creating a catalog item first.
* **Item-Level & Order-Level Discounts:** Flexible percentage or fixed monetary discounts.
* **Multiple Payment Channels:** Cash, Credit/Debit Card, Mobile Payment, and Customer Store Credit.
* **Live Financial Calculations:** Subtotal, dynamic tax rates, discounts, net profits, and change due computed in real time.

---

### 🖨️ 2. Thermal Receipts & Vector Barcode Generation
* **Thermal Receipt Engine:** Formatted for standard **80mm** and **58mm** POS thermal printers with ESC/POS byte conversion and printable PDF layout.
* **In-House Vector Barcode & QR Generator:** Native `CustomPainter` rendering of **Code 128**, **EAN-13**, and **QR Matrix** codes directly on screen, in print layouts, and on product forms without external rendering packages.
* **Instant Reprint & Digital Receipt Sharing:** Look up receipts by number or barcode to reprint or view itemized breakdowns.

---

### 📦 3. Inventory & Stock Management
* **Rapid Stock Entry & Barcode Preview:** Scan existing barcodes or generate new vector barcodes live during product creation.
* **Real-Time Cloud Synchronization:** Instant multi-device inventory synchronization with Cloud Firestore.
* **Intelligent Low-Stock Alerts:** Visual status badges and warning filters for stock below safety thresholds.
* **Grid & List Views:** Responsive product grid or compact list view with category filter pills.
* **Inline Stock Adjustments:** Quick restock or quantity edits directly from inventory cards.
* **Native CSV Exporter:** Export complete catalog data, stock levels, and valuations to CSV with zero external bloat.
* **One-Tap Demo Catalog Seeder:** Instantly populate a rich demo retail catalog (Beverages, Bakery, Coffee, Snacks) with barcodes, cost prices, and stock for testing.

---

### 👥 4. Customer Relationship Management (CRM) & Loyalty Program
* **Automated Loyalty Tiers:** Automatic progression across **Bronze, Silver, Gold, and Platinum** tiers based on lifetime spending.
* **Loyalty Points System:** Configurable reward point calculations awarded on completed checkouts.
* **Customer Analytics:** Real-time tracking of Lifetime Spend, Average Order Value (AOV), total order count, and visit frequency.
* **Purchase Ledger & History:** Complete itemized transaction history per customer.
* **Direct Communication Shortcuts:** 1-tap Phone Call, SMS, and Email launcher directly from the customer profile.

---

### 📊 5. Executive Dashboard & Analytics
* **Real-Time KPI Cards:** Today's Revenue, Net Profit Margin, Sales Volume, and Average Basket Size.
* **7-Day Sales Trend Visual:** Interactive daily revenue trend chart with week-over-week performance tracking.
* **Top Selling Products Leaderboard:** Visual breakdown of highest revenue and volume generators.
* **Urgent Restock Action Center:** Immediate visibility into out-of-stock and low-stock inventory.

---

### 👥 6. Role-Based Access Control & Staff Management
* **Role Separation:** Dedicated permission boundaries for **Owner**, **Manager**, and **Cashier / Worker**.
* **Role Guard Protection:** Secure widget-level and route-level access control.
* **Staff Controls (Owner Only):** Add new employees, assign roles, and activate/deactivate accounts.

---

### ⚙️ 7. Store Settings & Personalization
* **Location-Based Currency:** Automatic currency detection with manual override for all major world currencies (USD, PKR, EUR, GBP, INR, CAD, etc.).
* **Hardware & Feedback Controls:** Audio chime cues and physical haptic vibration feedback toggles.
* **Tax & Receipt Customization:** Custom tax rates, store header, footer notes, and auto-print preferences.
* **Theme Modes:** Sleek **Obsidian Dark Mode** (`#0F172A`), **Crisp Light Mode**, and System Default.
* **Offline Resiliency:** Local caching with automatic background synchronization when internet connectivity resumes.

---

## ⚡ Native In-House Services Architecture

To maximize application speed and eliminate heavy third-party package dependencies, the app relies on lightweight, custom in-house Dart services:

| In-House Service | Location | Purpose |
|---|---|---|
| `ValidationService` | `lib/services/validation_service.dart` | RFC 5322 regex validation for emails, phone numbers, barcodes, SKUs, and credentials. |
| `FormatService` | `lib/services/format_service.dart` | High-speed currency, date parsing, relative time ("2 hrs ago"), and compact number formatting. |
| `BarcodeService` | `lib/services/barcode_service.dart` | Native vector math and pattern encoders for Code 128, EAN-13, and QR Matrix codes. |
| `CacheService` | `lib/services/cache_service.dart` | In-memory LRU cache with TTL expiration for instant sub-millisecond catalog searches. |
| `FeedbackService` | `lib/services/feedback_service.dart` | Native physical haptic feedback and acoustic cues on user interactions. |
| `ReceiptService` | `lib/services/receipt_service.dart` | Thermal receipt formatting, ESC/POS byte conversion, and PDF document printing. |
| `ExportService` | `lib/services/export_service.dart` | In-memory CSV and report generation for stock valuations and sales records. |
| `CustomerService` | `lib/services/customer_service.dart` | Customer data store with automated loyalty tier progression and lifetime value analytics. |
| `SampleDataService` | `lib/services/sample_data_service.dart` | One-click retail catalog generator with SKUs, barcodes, categories, and cost margins. |

---

## 🏗️ Tech Stack

* **Framework:** Flutter 3.x (Dart 3.x)
* **Design System:** Material 3 with Custom Color Tokens (`AppColors`, `AppTheme`, `PosCard`)
* **Backend:** Firebase (Cloud Firestore, Firebase Authentication)
* **State Management:** Provider Architecture
* **Hardware & Native Integrations:** `mobile_scanner`, `speech_to_text`, `pdf`, `printing`
* **Static Analysis:** Strict Dart Linting Rules (0 Warnings / 0 Errors)

---

## 📁 Project Structure

```text
lib/
├── models/             # Data entities (Product, CartItem, Sale, Customer, HeldOrder, Settings)
├── providers/          # State managers (AuthProvider, SettingsProvider, ThemeProvider)
├── screens/            # Application views
│   ├── home.dart               # POS Register & Checkout Screen
│   ├── dashboard_screen.dart   # KPI & Sales Analytics Dashboard
│   ├── inventory_screen.dart   # Stock Management & Catalog
│   ├── sales_history_screen.dart # Transaction Records & Refunds
│   ├── crm_screen.dart         # Customer Directory & Loyalty
│   ├── customer_detail_screen.dart # Customer Profile & Ledger
│   ├── settings_screen.dart    # System & Store Configuration
│   ├── product_form_page.dart  # Product Creation / Barcode Preview
│   ├── login_screen.dart       # User Sign In
│   ├── signup_screen.dart      # Business Registration
│   └── user_management_screen.dart # Staff Permissions
├── services/           # In-house native services & Firebase APIs
├── theme/              # AppColors, AppTheme (Material 3 Dark/Light)
├── utils/              # Helper utilities & validators
└── widgets/            # Reusable UI components (PosCard, StatBadge, BarcodeWidget, AppDrawer)
```

---

## 🚀 Getting Started

### Prerequisites
1. **Flutter SDK** (>= 3.0.0) installed and added to PATH.
2. **Firebase Project** with Cloud Firestore and Firebase Authentication enabled.
3. Android Studio / VS Code with Flutter extensions.
4. *Physical device recommended for camera-based barcode/QR scanning.*

### Installation & Run

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/your-username/pos-system.git
   cd pos-system
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   * Place `google-services.json` in `android/app/`
   * Place `GoogleService-Info.plist` in `ios/Runner/`

4. **Verify Code Quality:**
   ```bash
   flutter analyze
   ```

5. **Run the Application:**
   ```bash
   flutter run
   ```
