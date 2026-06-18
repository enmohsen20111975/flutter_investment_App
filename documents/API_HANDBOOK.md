# 📚 دليل الاستثمار - Mobile Application API Handbook

> **Platform Name:** دليل الاستثمار (EGX Investment Platform)
> **Version:** 18.0 (Phase 11 Audit Edition) | **Last Updated:** June 2026
> **Audience:** Mobile developers (iOS / Android / Flutter / React Native / .NET MAUI)
>
> **Base URLs:**
>
> | Environment | URL |
> |-------------|-----|
> | 🌐 Production | `https://invist.m2y.net` |
> | 🛠️ Development | `http://localhost:3000` |
> | 🧠 Python Backend (THE BRAIN) | `http://localhost:8010` |
> | 📊 Data Engine | `http://localhost:5000` |
>
> **Default Headers for all authenticated requests:**
> ```
> Authorization: Bearer <token>
> Content-Type: application/json
> Accept: application/json
> User-Agent: <YourAppName>/<Version> (Android 14; Pixel 7)
> X-Forwarded-For: <device_ip>   # optional
> ```

---

## 📋 Table of Contents

1. [🏗️ Architecture Overview](#-architecture-overview)
2. [🔐 Authentication APIs](#-authentication-apis)
3. [📊 Stock Market APIs](#-stock-market-apis)
4. [📈 Chart & Price History APIs](#-chart--price-history-apis)
5. [🎯 Analysis APIs](#-analysis-apis)
6. [📋 Predictions APIs](#-predictions-apis)
7. [💼 Portfolio APIs](#-portfolio-apis)
8. [👁️ Watchlist APIs](#-watchlist-apis)
9. [🪙 Crypto APIs](#-crypto-apis)
10. [🌍 Multi-Market APIs](#-multi-market-apis)
11. [💰 Payment & Subscription APIs](#-payment--subscription-apis)
12. [📰 News & Content APIs](#-news--content-apis)
13. [🤖 AI Chat APIs](#-ai-chat-apis)
14. [🏹 Hunter APIs](#-hunter-apis)
15. [📱 Mobile-Specific Endpoints](#-mobile-specific-endpoints)
16. [📋 Phase 11 Mobile API Audit (Complete Documentation)](#-phase-11-mobile-api-audit-complete-documentation)
17. [🔐 Authentication Requirements](#-authentication-requirements)
18. [🔔 Alerts & Notifications APIs](#-alerts--notifications-apis)
19. [📚 Learning APIs](#-learning-apis)
20. [⚙️ Admin APIs (brief)](#-admin-apis-brief)
21. [❌ Error Handling](#-error-handling)
22. [⏱️ Rate Limits & Timeouts](#-rate-limits--timeouts)
23. [📝 Common JSON Schemas](#-common-json-schemas)
24. [🚀 Mobile Integration Guide](#-mobile-integration-guide)

---

## 🏗️ Architecture Overview

`دليل الاستثمار` هو منصة استثمار عربية موجهة للمستخدم العربي. البنية مبنية على مبدأ بسيط:
**بايثون هو العقل، نود جي إس هو العرض** (Python = THE BRAIN, Node.js = DISPLAY ONLY).

### System Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       📱 MOBILE APPLICATION                                  │
│              (Flutter / React Native / Native iOS / Android)                │
│                                                                             │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│   │  Auth/Login  │  │  Stocks/Chart│  │  Portfolio   │  │   Payments   │ │
│   └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │
│          └──────────────────┴─────────────────┴─────────────────┘          │
│                              Bearer Token                                   │
└──────────────────────────────┬──────────────────────────────────────────────┘
                               │ HTTPS
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                  🌐 NEXT.JS API GATEWAY (Port 3000 / invist.m2y.net)        │
│                                                                             │
│   • 360 REST endpoints under /api/**                                        │
│   • Validates Bearer tokens against SQLite (api_tokens table)               │
│   • Hybrid proxy: tries VPS first, falls back to local DB                  │
│   • Caches responses in-memory (60s - 5min depending on endpoint)          │
│                                                                             │
│   ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐      │
│   │ /api/mobile/*    │   │ /api/auth/*      │   │ /api/stocks/*    │      │
│   │ Mobile-first     │   │ Login/Register/  │   │ List/Detail/    │      │
│   │ endpoints        │   │ Me/Logout/Google │   │ Search/History  │      │
│   └────────┬─────────┘   └────────┬─────────┘   └────────┬─────────┘      │
│            └─────────────────────┴─────────────────────┘                   │
│                              │                                             │
└──────────────────────────────┼─────────────────────────────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────────────┐
│  🧠 Python Brain │  │ 📊 Data Engine   │  │  💾 SQLite Databases         │
│   Port 8010      │  │   Port 5000      │  │                              │
│                  │  │                  │  │  • auth.db (users, tokens)   │
│  • Analysis      │  │  • Stocks        │  │  • stocks.db                 │
│  • Predictions   │  │  • Crypto        │  │  • predictions.db            │
│  • AI Models     │  │  • Forex         │  │  • price_history.db          │
│  • Pattern Recog │  │  • Gold/Silver   │  │  • data_engine.db            │
│  • Fibonacci     │  │  • Multi-Market  │  │  • portfolio.db              │
│  • Risk Engine   │  │                  │  │  • finance.db (alerts)       │
└────────┬─────────┘  └────────┬─────────┘  └──────────────────────────────┘
         │                     │
         └──────────┬──────────┘
                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       EXTERNAL DATA SOURCES                                 │
│                                                                             │
│   • EGXPilot API      → EGX news & stock data                              │
│   • CoinGecko API     → Crypto prices & market data                        │
│   • Alternative.me    → Fear & Greed Index                                 │
│   • Paymob            → Payment gateway (EGP)                              │
│   • Google OAuth      → Google Sign-In                                     │
│   • DeepSeek / Z.AI   → AI chat & analysis                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Architecture Principles

| Principle | Description | Implication for Mobile |
|-----------|-------------|------------------------|
| **Python = THE BRAIN** | كل التحليلات والحسابات في Python Backend | استخدم `/api/python/*` proxy للوصول المباشر للـ Brain |
| **Node.js = DISPLAY ONLY** | الـ Next.js بيجمع البيانات فقط | ما تحاولش تعمل logic في الـ mobile - اللي يرجع من الـ API هو الصح |
| **No Mock Data** | كل البيانات حقيقية | لو رجع `[]` يبقى السوق فاضي فعلاً، مش خطأ |
| **Bearer Token** | كل الـ mobile APIs بـ `Authorization: Bearer <token>` | احفظ الـ token في Secure Storage |
| **30-day Token Expiry** | الـ token بيفضل شغال 30 يوم | اعمل refresh تلقائي قبل ما ينتهي |
| **Hybrid Sources** | الـ Next.js بيجرب VPS الأول ثم local | شوف حقل `source` في الـ response |

### Data Flow for Mobile Login → Stocks List

```
1. User opens app
   └─> GET /api/auth/me  (with stored token)
       ├─ 200 OK → continue to home
       └─ 401   → show login screen

2. User enters credentials
   └─> POST /api/auth/login
       { username_or_email, password }
       └─> Save token in SecureStorage

3. Home screen loads
   └─> GET /api/mobile/dashboard  (one call, returns everything)
       ├─ market_status
       ├─ indices
       ├─ top_movers (gainers, losers, most_active)
       ├─ gold_prices
       └─ currency_rates

4. User taps a stock
   └─> GET /api/stocks/{ticker}?live=1&indicators=1
       └─> Show detail screen with price + technical indicators

5. User opens chart tab
   └─> GET /api/chart/{ticker}?period=1m&asset=stock
       └─> Render candlestick chart
```

---

## 🔐 Authentication APIs

كل الـ mobile endpoints بتطلب `Authorization: Bearer <token>` (ماعدا `/login`, `/register`, `/google`).

### 1. POST `/api/auth/login` — تسجيل الدخول

**الوصف:** يسجل دخول المستخدم ويرجع Bearer token صالح لمدة 30 يوم.

**Request Body:**
```json
{
  "username_or_email": "user@example.com",
  "password": "MyPassword123"
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "message": "Login successful",
  "message_ar": "تم تسجيل الدخول بنجاح",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "username": "username",
    "name": "User Name",
    "image": null,
    "subscription_tier": "free",
    "is_admin": false
  },
  "token": "egx_550e8400-e29b-41d4-a716-446655440000_a1b2c3d4-..._1705312200000",
  "token_type": "Bearer",
  "expires_in": 2592000
}
```

**Response 401 Invalid Credentials:**
```json
{ "success": false, "error": "كلمة المرور غير صحيحة", "error_en": "Invalid password" }
```

**Response 403 Account Deactivated:**
```json
{ "success": false, "error": "الحساب غير مفعل", "error_en": "Account is deactivated" }
```

**Response 503 Database Down:**
```json
{ "success": false, "error": "قاعدة البيانات غير متاحة حالياً", "error_en": "Database temporarily unavailable" }
```

**📱 ملاحظة للجوال:** احفظ الـ `token` في `flutter_secure_storage` / `Keychain` / `EncryptedSharedPreferences`. لو رجع 503 اعمل retry 3 مرات بـ exponential backoff.

---

### 2. POST `/api/auth/register` — إنشاء حساب جديد

**الوصف:** بينشئ حساب جديد ويرجع API key (غير متاح للتطبيقات القديمة - استخدم login بعد الـ register).

**Request Body:**
```json
{
  "email": "newuser@example.com",
  "username": "newuser",
  "password": "SecurePassword123",
  "risk_tolerance": "medium"
}
```

**Validation Rules:**
- `email`: صيغة بريد إلكتروني صحيح
- `username`: 3 أحرف على الأقل، alphanumeric + underscore
- `password`: 8 أحرف على الأقل
- `risk_tolerance`: `low` | `medium` | `high` (اختياري، default `medium`)

**Response 201 Created:**
```json
{
  "success": true,
  "message": "تم إنشاء الحساب بنجاح",
  "user": {
    "id": "550e8400-...",
    "email": "newuser@example.com",
    "username": "newuser",
    "default_risk_tolerance": "medium"
  },
  "api_key": "egx_550e8400-..._1705312200000"
}
```

**Response 409 Conflict:**
```json
{ "success": false, "error": "البريد الإلكتروني مستخدم بالفعل" }
```

**📱 ملاحظة للجوال:** بعد الـ register ناجح، اطلب من المستخدم يعمل login بالـ credentials اللي سجلهم عشان ياخد `Bearer token` (الـ `api_key` اللي بيرجع مش نفس الـ `token`).

---

### 3. POST `/api/auth/google` — تسجيل الدخول عبر Google

**الوصف:** بيقبل Google ID Token من الـ Google Sign-In SDK على الموبايل ويرجع Bearer token.

**Request Body:**
```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIs...google_id_token..."
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "message": "Google login successful",
  "message_ar": "تم تسجيل الدخول عبر جوجل بنجاح",
  "user": {
    "id": "550e8400-...",
    "email": "user@gmail.com",
    "username": "user",
    "name": "User Name",
    "image": "https://lh3.googleusercontent.com/...",
    "subscription_tier": "free",
    "is_admin": false
  },
  "token": "egx_550e8400-..._uuid_1705312200000",
  "token_type": "Bearer",
  "expires_in": 2592000,
  "is_new_user": false
}
```

**📱 ملاحظة للجوال:**
1. استخدم `google_sign_in` package في Flutter أو `GoogleSignIn` في Android
2. خد الـ `idToken` من الـ result
3. بعت الـ `idToken` للـ endpoint ده
4. الـ `aud` في الـ token لازم يكون مطابق للـ `GOOGLE_CLIENT_ID` على السيرفر

---

### 4. GET `/api/auth/me` — بيانات المستخدم الحالي

**الوصف:** بيرجع بيانات المستخدم بناءً على الـ Bearer token.

**Headers:** `Authorization: Bearer <token>`

**Response 200 OK:**
```json
{
  "success": true,
  "user": {
    "id": "550e8400-...",
    "email": "user@example.com",
    "username": "username",
    "name": "User Name",
    "image": "https://...",
    "subscription_tier": "premium",
    "default_risk_tolerance": "medium",
    "is_admin": false,
    "is_active": true,
    "email_verified": true,
    "last_login": "2026-01-15T10:30:00.000Z",
    "created_at": "2024-01-01T00:00:00.000Z"
  }
}
```

**Response 401:**
```json
{ "success": false, "error": "Token منتهي الصلاحية", "error_en": "Token expired" }
```

**📱 ملاحظة للجوال:** استخدم الـ endpoint ده في `splash screen` للتأكد إن الـ session لسه شغالة. لو رجع 401 امسح الـ token وروح لـ login screen.

---

### 5. GET `/api/mobile/auth/me` — نسخة mobile محسنة

**الوصف:** نفس `/api/auth/me` بس أسرع ومكتوبة خصيصاً للموبايل (تستخدم `token-helper`).

**Response:** نفس `/api/auth/me` بالظبط.

**📱 ملاحظة:** استخدم ده بدلاً من `/api/auth/me` في الـ mobile app لأنه بيتعامل بشكل أفضل مع الـ tokens المنتهية.

---

### 6. POST `/api/auth/logout` — تسجيل الخروج

**الوصف:** بيلغي الـ token من قاعدة البيانات.

**Headers:** `Authorization: Bearer <token>`

**Response 200 OK:**
```json
{
  "success": true,
  "message": "Logged out successfully",
  "message_ar": "تم تسجيل الخروج بنجاح"
}
```

**📱 ملاحظة:** بعد الـ logout امسح الـ token من `SecureStorage` وروح لـ login screen.

---

### 7. GET `/api/auth/config` — إعدادات المصادقة

**الوصف:** بيرجع إعدادات الـ OAuth والـ providers المتاحة.

**Response:**
```json
{
  "success": true,
  "google_client_id": "123456789-xxxx.apps.googleusercontent.com",
  "google_enabled": true,
  "nextauth_enabled": true
}
```

---

### 8. POST `/api/auth/google-signin` — بديل لـ Google login

**الوصف:** نفس `/api/auth/google` لكن بصيغة مختلفة لبعض الـ SDKs.

---

## 📊 Stock Market APIs

### 1. GET `/api/stocks` — قائمة الأسهم

**الوصف:** بيرجع قائمة بكل الأسهم (EGX + TADAWUL + KSE + QSE) مع pagination.

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `market` | string | (all) | `EGX`, `KSA` (=TADAWUL), `TADAWUL`, `KSE`, `QSE`, `DFM`, `ADX`, `BSE` |
| `limit` / `page_size` | int | 500 | عدد النتائج في الصفحة |
| `offset` | int | 0 | إزاحة من بداية النتائج |
| `page` | int | 1 | رقم الصفحة (يستخدم مع `limit`) |
| `query` / `q` | string | (empty) | بحث في ticker / name / name_ar |

**Example:** `GET /api/stocks?market=EGX&page=1&limit=50`

**Response 200 OK:**
```json
{
  "success": true,
  "stocks": [
    {
      "id": 1,
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "name_ar": "البنك التجاري الدولي",
      "market": "EGX",
      "sector": "Banks",
      "current_price": 65.45,
      "previous_close": 64.20,
      "change_percent": 1.95,
      "volume": 12500000,
      "market_cap": 132500000000,
      "pe_ratio": 5.8,
      "pb_ratio": 1.2,
      "dividend_yield": 4.5,
      "eps": 11.28,
      "is_egx30": 1,
      "is_egx70": 0,
      "is_egx100": 1
    }
  ],
  "total": 245,
  "page": 1,
  "page_size": 50,
  "markets": [
    { "code": "EGX", "count": 245, "frontend_code": "EGX" },
    { "code": "TADAWUL", "count": 220, "frontend_code": "KSA" },
    { "code": "KSE", "count": 165, "frontend_code": "KSE" },
    { "code": "QSE", "count": 50, "frontend_code": "QSE" }
  ]
}
```

**📱 ملاحظة للجوال:** استخدم `page=1&limit=50` للـ Home screen، و`limit=500` للـ search. الـ pagination default 500 لأن أغلب الأسواق فيها أقل من 500 سهم.

---

### 2. GET `/api/stocks/[ticker]` — تفاصيل سهم

**الوصف:** بيرجع تفاصيل سهم معين. بيحاول VPS الأول ثم local DB.

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `live` | 0/1 | 0 | جلب السعر اللحظي من APIs خارجية |
| `history` | int | 0 | عدد أيام تاريخ الأسعار |
| `indicators` | 0/1 | 0 | جلب المؤشرات الفنية |
| `prediction` | 0/1 | 0 | جلب توقع السعر من VPS |
| `force_local` | 0/1 | 0 | إجبار استخدام local DB فقط |

**Example:** `GET /api/stocks/COMI?live=1&indicators=1&history=30`

**Response 200 OK:**
```json
{
  "data": {
    "ticker": "COMI",
    "name": "Commercial International Bank",
    "name_ar": "البنك التجاري الدولي",
    "sector": "Banks",
    "current_price": 65.45,
    "previous_close": 64.20,
    "open": 64.50,
    "high": 65.80,
    "low": 64.30,
    "volume": 12500000,
    "market_cap": 132500000000,
    "pe_ratio": 5.8,
    "pb_ratio": 1.2,
    "dividend_yield": 4.5,
    "eps": 11.28,
    "price_change": 1.947,
    "value_traded": 818125000,
    "source": "vps"
  },
  "technicalIndicators": {
    "rsi": 58.4,
    "ma_50": 62.10,
    "ma_200": 58.50,
    "macd": 0.45,
    "macd_signal": 0.30,
    "bollinger_upper": 67.20,
    "bollinger_lower": 61.80,
    "stoch_k": 75.4,
    "stoch_d": 70.2
  },
  "history": [
    { "date": "2026-01-15", "open": 64.50, "high": 65.80, "low": 64.30, "close": 65.45, "volume": 12500000 }
  ],
  "source": "vps"
}
```

**Response 404:**
```json
{ "error": "Stock not found", "detail": "No stock found with ticker: INVALID" }
```

**📱 ملاحظة للجوال:** استخدم `live=1&indicators=1` للـ Stock Detail screen. لو الـ VPS بطيء استخدم `force_local=1`.

---

### 3. GET `/api/stocks/search` — بحث سريع في الأسهم

**الوصف:** بحث lightweight بيرجع max 30 نتيجة.

**Query Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `q` | string | كلمة البحث (يفضل 2+ حروف) |

**Example:** `GET /api/stocks/search?q=comi`

**Response 200 OK:**
```json
{
  "success": true,
  "stocks": [
    {
      "id": 1,
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "name_ar": "البنك التجاري الدولي",
      "sector": "Banks",
      "current_price": 65.45,
      "previous_close": 64.20,
      "volume": 12500000,
      "is_egx30": 1,
      "is_egx70": 0,
      "is_egx100": 1,
      "price_change": 1.95
    }
  ]
}
```

**📱 ملاحظة للجوال:** استخدم ده في `SearchBar` مع debounce 300ms. لو `q` فاضي بيرجع أعلى 30 سهم by volume.

---

### 4. GET `/api/mobile/stocks/[ticker]` — تفاصيل سهم محسّن للجوال

**الوصف:** نسخة محسنة من `/api/stocks/[ticker]` بتستخدم Python Backend أولاً.

**Response:**
```json
{
  "success": true,
  "source": "python_backend",
  "data": {
    "ticker": "COMI",
    "name_ar": "البنك التجاري الدولي",
    "name": "Commercial International Bank",
    "sector": "Banks",
    "current_price": 65.45,
    "previous_close": 64.20,
    "open": 64.50,
    "high": 65.80,
    "low": 64.30,
    "volume": 12500000,
    "market_cap": 132500000000,
    "pe_ratio": 5.8,
    "pb_ratio": 1.2,
    "dividend_yield": 4.5,
    "eps": 11.28,
    "roe": 22.4,
    "is_active": true,
    "last_update": "2026-01-15T14:30:00.000Z"
  }
}
```

---

### 5. GET `/api/market/overview` — نظرة عامة على السوق

**الوصف:** بيرجع ملخص شامل للسوق (gainers, losers, indices).

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `market` | string | `EGX` | `EGX`, `TADAWUL`, `KSE`, `QSE`, `DFM`, `BSE`, `CRYPTO` |

**Response 200 OK:**
```json
{
  "success": true,
  "timestamp": "2026-01-15T14:30:00.000Z",
  "database": "data_engine.db",
  "market": "EGX",
  "market_name": "مصر",
  "market_status": {
    "is_open": true,
    "status": "open",
    "next_open": null,
    "next_close": null,
    "current_session": "trading"
  },
  "summary": {
    "total_stocks": 245,
    "gainers": 145,
    "losers": 87,
    "unchanged": 13,
    "egx30_stocks": 0,
    "egx70_stocks": 0,
    "egx100_stocks": 0,
    "egx30_value": 0
  },
  "indices": [],
  "top_gainers": [
    {
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "name_ar": null,
      "current_price": 65.45,
      "change_percent": 9.95,
      "volume": 12500000
    }
  ],
  "top_losers": [
    {
      "ticker": "HRHO",
      "name": "EFG Hermes",
      "name_ar": null,
      "current_price": 24.10,
      "change_percent": -5.20,
      "volume": 3200000
    }
  ],
  "most_active": [
    {
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "current_price": 65.45,
      "change_percent": 1.95,
      "volume": 12500000
    }
  ],
  "market_breakdown": [
    { "market": "مصر", "count": 245 },
    { "market": "السعودية", "count": 220 }
  ],
  "source": "data_engine_db"
}
```

---

### 6. GET `/api/market/status` — حالة السوق (مفتوح/مقفل)

**الوصف:** بيرجع حالة السوق المصرية بالظبط مع التوقيت بالقاهرة.

**Response 200 OK:**
```json
{
  "is_market_hours": true,
  "isMarketOpen": true,
  "status": "open",
  "statusAr": "السوق مفتوح",
  "cairo_time": "01/15/2026, 14:30:00",
  "cairoTime": {
    "day": "الإثنين",
    "hour": 14,
    "minute": 30,
    "formatted": "14:30"
  },
  "next_open": "2026-01-16T08:30:00.000Z",
  "time_until_open": "السوق مفتوح الآن",
  "minutes_until_open": null,
  "minutes_until_close": 90,
  "market_hours": {
    "open": "10:0",
    "close": "14:30",
    "timezone": "Africa/Cairo",
    "tradingDays": ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس"],
    "weekendDays": ["الجمعة", "السبت"],
    "tradingHoursAr": "من 10:00 صباحاً حتى 2:30 مساءً (توقيت القاهرة)"
  },
  "should_refresh_data": true,
  "data_source": "live_calculations",
  "checked_at": "2026-01-15T12:30:00.000Z"
}
```

**📱 ملاحظة للجوال:** استخدم `is_market_hours` لتحديد هل تعمل poll للأسعار اللحظية. لو `false` اعتمد على cached data.

---

### 7. GET `/api/mobile/market/overview` — نسخة موبايل محسنة

**الوصف:** نفس `/api/market/overview` لكن بيستخدم Python Backend أولاً ثم local DB. بيرجع نفس الـ format بالظبط.

---

### 8. GET `/api/market/indices` — مؤشرات السوق

**الوصف:** بيرجع قيم مؤشرات EGX 30/70/100.

---

### 9. GET `/api/market/sectors` — تصنيف الأسهم بالقطاعات

**الوصف:** بيرجع قائمة بالقطاعات وعدد الأسهم في كل قطاع.

---

### 10. GET `/api/market/top-movers` — أكبر الحركات

**الوصف:** بيرجع top gainers, losers, and most active stocks.

**Query Parameters:** `market`, `limit`

---

### 11. GET `/api/stocks/fundamentals` — الأساسيات

**الوصف:** بيرجع P/E, P/B, ROE, Net Margin, Dividend Yield لكل الأسهم.

---

### 12. GET `/api/stocks/movement-classification` — تصنيف الحركة

**الوصف:** بيرجع تصنيف حركة كل سهم (Strong Buy / Buy / Hold / Sell).

---

## 📈 Chart & Price History APIs

### 1. GET `/api/chart/[ticker]` — بيانات الرسم البياني (Intraday + Daily)

**الوصف:** بيرجع بيانات الرسم البياني من Python Backend. بيدعم 3 أنواع أصول (stock, crypto, commodity).

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `period` | string | `1w` | `1d`, `1w`, `1m` |
| `asset` | string | auto | `stock`, `crypto`, `commodity` (auto-detect if empty) |

**Behavior:**
- `1d` / `1w` → بيانات 5 دقائق (intraday)
- `1m` → بيانات يومية (fallback من price_history)

**Example:** `GET /api/chart/COMI?period=1m&asset=stock`

**Response 200 OK:**
```json
{
  "success": true,
  "ticker": "COMI",
  "period": "1m",
  "asset": "stock",
  "source": "intraday",
  "note": "بيانات لحظية (5 دقائق)",
  "count": 22,
  "data": [
    {
      "timestamp": "2026-01-15T10:00:00",
      "price": 64.50,
      "volume": 1200000,
      "source": "intraday"
    },
    {
      "timestamp": "2026-01-15T10:05:00",
      "price": 64.55,
      "volume": 850000,
      "source": "intraday"
    }
  ],
  "stats": {
    "first_price": 64.50,
    "last_price": 65.45,
    "max_price": 65.80,
    "min_price": 64.30,
    "change_pct": 1.47,
    "avg_price": 65.10
  }
}
```

**Response 502 Python Backend Unavailable:**
```json
{
  "success": false,
  "error": "فشل في الاتصال بـ Python Backend",
  "details": "fetch failed"
}
```

**📱 ملاحظة للجوال:**
- `1d` للـ chart في الـ Trading View (شاشة السهم)
- `1w` للـ chart الأسبوعي
- `1m` للـ chart الشهري (daily candles)
- اعمل poll كل 5 دقايق في وقت السوق المفتوح

---

### 2. GET `/api/stocks/[ticker]/history` — تاريخ الأسعار

**الوصف:** بيرجع تاريخ أسعار سهم معين مع RSI وstats. بيحاول VPS → Heavy DB → New DB → auto-seed → synthetic.

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `days` | int | 90 | عدد الأيام |

**Example:** `GET /api/stocks/COMI/history?days=30`

**Response 200 OK:**
```json
{
  "success": true,
  "ticker": "COMI",
  "data": [
    {
      "date": "2025-12-15",
      "open": 60.10,
      "high": 61.50,
      "low": 59.80,
      "close": 61.20,
      "volume": 8500000,
      "rsi": 52.4
    },
    {
      "date": "2025-12-16",
      "open": 61.20,
      "high": 62.80,
      "low": 60.90,
      "close": 62.50,
      "volume": 9200000,
      "rsi": 58.7
    }
  ],
  "summary": {
    "highest": 65.80,
    "lowest": 59.80,
    "avg_price": 62.40,
    "total_volume": 285000000,
    "start_price": 60.10,
    "end_price": 65.45,
    "change_percent": 8.90
  },
  "days": 30,
  "source": "vps",
  "data_points": 30
}
```

**Response Headers:**
```
Cache-Control: no-store, no-cache, must-revalidate, proxy-revalidate, s-maxage=0
Pragma: no-cache
Expires: 0
```

**📱 ملاحظة للجوال:** استخدم `days=30` لـ default chart, `days=90` لـ 3 months, `days=365` لـ yearly view.

---

### 3. GET `/api/crypto/ohlc` — OHLC data للكريبتو

**الوصف:** بيرجع بيانات OHLC للعملات الرقمية.

**Query Parameters:** `coin_id`, `days`

---

### 4. GET `/api/crypto/[id]/history` — تاريخ عملة رقمية

**الوصف:** بيرجع تاريخ سعر عملة معينة.

**Path Parameters:** `id` = CoinGecko coin id (e.g., `bitcoin`, `ethereum`)

---

## 🎯 Analysis APIs

### 1. GET `/api/advanced-analysis` — التحليل المتقدم (Python proxy)

**الوصف:** proxy للـ Python endpoints للتحليل الفني المتقدم.

**Query Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `action` | string | `status`, `golden`, `analyze` (default) |
| `ticker` | string | مطلوب لـ `action=analyze` |
| `limit` | int | لـ `action=golden` (default 10) |
| `days` | int | default 30 |

**Examples:**
- `GET /api/advanced-analysis?action=status`
- `GET /api/advanced-analysis?action=golden&limit=20`
- `GET /api/advanced-analysis?ticker=COMI`

**Response (action=golden):**
```json
{
  "success": true,
  "golden_stocks": [
    {
      "ticker": "COMI",
      "name_ar": "البنك التجاري الدولي",
      "current_price": 65.45,
      "score": 85,
      "signals": ["MACD crossover", "RSI bullish", "MA50 above MA200"],
      "recommendation": "STRONG_BUY"
    }
  ],
  "total": 5
}
```

---

### 2. POST `/api/advanced-analysis` — تحليل شامل

**Request Body:**
```json
{
  "action": "comprehensive",  // candlesticks | patterns | comprehensive | confluence | quick-signal | support-resistance
  "ticker": "COMI",
  "price_history": [...],
  "timeframe": "daily"
}
```

**Response (action=comprehensive):**
```json
{
  "success": true,
  "ticker": "COMI",
  "trend": "bullish",
  "signals": {
    "candlestick": { "pattern": "Bullish Engulfing", "confidence": 0.85 },
    "patterns": ["Double Bottom", "Inverse Head & Shoulders"],
    "indicators": {
      "rsi": 58.4,
      "macd": "bullish_crossover",
      "ma_trend": "uptrend"
    }
  },
  "support_resistance": {
    "supports": [62.50, 60.00, 58.00],
    "resistances": [66.00, 68.00, 70.00]
  },
  "recommendation": "BUY",
  "confidence": 0.78
}
```

---

### 3. GET `/api/ai-analysis` — تحليل الذكاء الاصطناعي

**Query Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `action` | string | `health`, `recommendations`, `analyze`, `summary` |
| `ticker` | string | مطلوب لـ `action=analyze` |
| `limit` | int | default 20 |

**Example:** `GET /api/ai-analysis?action=analyze&ticker=COMI`

**Response:**
```json
{
  "success": true,
  "ticker": "COMI",
  "ai_analysis": {
    "recommendation": "BUY",
    "confidence": 0.82,
    "reasons": [
      "مؤشر RSI عند 58 يدل على زخم صاعد بدون تشبع",
      "MACD crossover إيجابي",
      "السعر فوق MA50 و MA200"
    ],
    "risks": [
      "اقتراب السعر من مقاومة 66",
      "حجم التداول أقل من المتوسط"
    ],
    "target_price": 72.00,
    "stop_loss": 62.00,
    "time_horizon": "2-4 weeks"
  }
}
```

---

### 4. GET `/api/stocks/[ticker]/professional-analysis` — التحليل الاحترافي

**الوصف:** بيرجع تحليل فني وأساسي احترافي للسهم.

---

### 5. GET `/api/stocks/[ticker]/recommendation` — توصية السهم

**الوصف:** بيرجع توصية واحدة محددة للسهم.

---

### 6. GET `/api/unified-analysis/[symbol]` — التحليل الموحد

**الوصف:** بيجمع التحليل الفني والأساسي والـ AI في استدعاء واحد.

---

### 7. GET `/api/analysis/status` — حالة نظام التحليل

**Response:**
```json
{
  "success": true,
  "status": "operational",
  "python_backend": "online",
  "analyzers": {
    "technical": true,
    "fundamental": true,
    "patterns": true,
    "fibonacci": true,
    "risk": true
  }
}
```

---

### 8. GET `/api/stocks/analysis` — تحليل سريع

**Query Parameters:** `ticker`, `days`

---

### 9. POST `/api/stocks/batch-analysis` — تحليل جماعي

**Request Body:**
```json
{
  "tickers": ["COMI", "HRHO", "SWDY"],
  "analysis_type": "comprehensive"
}
```

---

### 10. GET `/api/unified-analysis/recommendations` — توصيات موحدة

**الوصف:** بيرجع كل التوصيات من كل المصادر (AI + Technical + Fundamental).

---

## 📋 Predictions APIs

### 1. GET `/api/mobile/predictions` — التوقعات (Mobile)

**الوصف:** بيرجع التوقعات من Prisma DB (نفس مصدر الموقع).

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | int | 50 | عدد النتائج |
| `status` | string | (all) | filter by status: `SUCCESS`, `FAIL`, `PENDING` |

**Response 200 OK:**
```json
{
  "success": true,
  "predictions": [
    {
      "id": "pred_001",
      "symbol": "COMI",
      "market": "EGX",
      "signal": "STRONG_BUY",
      "confidence": 85,
      "entry_price": 65.45,
      "target_price": 72.00,
      "stop_loss": 62.00,
      "reasoning": "زخم صاعد قوي مع تأكيد من MACD و RSI",
      "indicators": {
        "rsi": 58.4,
        "macd": "bullish",
        "ma_trend": "uptrend"
      },
      "news_summary": "أخبار إيجابية عن قطاع البنوك",
      "created_at": "2026-01-15T10:00:00.000Z",
      "verify_date": "2026-01-29",
      "verified": false,
      "result": null,
      "final_price": null,
      "profit_loss_pct": null
    }
  ],
  "stats": {
    "total_predictions": 245,
    "verified_predictions": 180,
    "successful": 142,
    "failed": 38,
    "success_rate": 78.9
  }
}
```

**📱 ملاحظة للجوال:** استخدم ده للـ Predictions tab في الـ bottom navigation.

---

### 2. GET `/api/predictions` — التوقعات (legacy)

**الوصف:** نفس الـ mobile predictions لكن بصيغة مختلفة. بيـ redirect لـ `/api/unified/predictions`.

**Query Parameters:** `type` (signal type), `limit`

---

### 3. GET `/api/predictions/performance` — أداء التوقعات

**الوصف:** بيرجع التوقعات مع actual return محسوب من price history.

**Query Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `month` | string | صيغة `YYYY-MM` (مثلاً `2026-01`) |
| `market` | string | `EGX`, `KSA` (=TADAWUL), `KSE`, `QSE` |
| `limit` | int | default 100 |

**Response 200 OK:**
```json
{
  "success": true,
  "predictions": [
    {
      "id": "pred_001",
      "symbol": "COMI",
      "name": "البنك التجاري الدولي",
      "signal": "STRONG_BUY",
      "signal_ar": "شراء قوي",
      "entry_price": 65.45,
      "target_price": 72.00,
      "stop_loss": 62.00,
      "confidence": 85,
      "score": 82,
      "prediction_date": "2026-01-10",
      "status": "TARGET_HIT",
      "status_ar": "🎯 تم",
      "final_price": 72.50,
      "actual_return": 10.8,
      "days_held": 5,
      "close_date": "2026-01-15",
      "market": "EGX",
      "market_ar": "🇪🇬 مصر"
    }
  ],
  "summary": {
    "total": 45,
    "closed": 28,
    "pending": 12,
    "expired": 5,
    "wins": 22,
    "losses": 6,
    "win_rate": 78.6,
    "avg_profit": 12.4,
    "avg_loss": -4.8
  },
  "by_market": { "EGX": 25, "TADAWUL": 12, "KSE": 5, "QSE": 3 }
}
```

---

### 4. GET `/api/predictions/credibility` — مصداقية التوقعات

**الوصف:** بيرجع توقعات من `platform_recommendations` table مع credibility scores.

**Query Parameters:** `month`, `market`

**Response:**
```json
{
  "success": true,
  "predictions": [
    {
      "id": "1",
      "ticker": "COMI",
      "name_ar": "البنك التجاري الدولي",
      "recommendation": "BUY",
      "recommendation_ar": "شراء",
      "confidence": 85,
      "entry_price": 65.45,
      "target_price": 72.00,
      "stop_loss": 62.00,
      "current_price": 65.45,
      "market": "EGX",
      "status": "PENDING",
      "actual_return": null,
      "days_held": 0,
      "created_at": "2026-01-10 10:00:00",
      "closed_at": null,
      "recommendation_date": "2026-01-10"
    }
  ],
  "summary": {
    "total": 50,
    "verified": 30,
    "successful": 22,
    "failed": 8,
    "success_rate": 73.3,
    "avg_return": 5.4
  }
}
```

---

### 5. GET `/api/predictions/tracking` — تتبع التوقعات

**الوصف:** بيرجع التوقعات النشطة مع تتبع live price.

---

### 6. GET `/api/predictions/live` — التوقعات اللحظية

**الوصف:** بيرجع التوقعات مع سعر لحظي محدث.

---

### 7. GET `/api/predictions/verify` — التحقق من التوقعات

**الوصف:** بيتحقق من التوقعات القديمة ويحدد نجاح/فشل.

---

### 8. POST `/api/predictions/generate` — توليد توقعات جديدة

**Request Body:**
```json
{
  "tickers": ["COMI", "HRHO"],
  "market": "EGX"
}
```

---

### 9. POST `/api/predictions/generate-all` — توليد توقعات لكل الأسهم

---

### 10. GET `/api/predictions/export-pdf` — تصدير PDF

**الوصف:** بينشئ PDF فيه التوقعات. بيرجع `application/pdf` binary stream.

**📱 ملاحظة:** استخدم `download` بدلاً من `display` في الـ HTTP client.

---

### 11. GET `/api/prediction-performance` — أداء التوقعات (v2)

---

### 12. GET `/api/ai-predictions/extract` — استخراج توقعات AI

---

### 13. POST `/api/ai-predictions/evaluate` — تقييم توقعات AI

---

### 14. GET `/api/real-predictions` — توقعات حقيقية (DeepSeek)

**الوصف:** بيرجع توقعات من DeepSeek AI model.

---

### 15. GET `/api/global-predictions` — توقعات لكل الأسواق

**الوصف:** بيرجع توقعات من كل الأسواق (EGX + TADAWUL + KSE + QSE + CRYPTO).

---

### 16. GET `/api/predictions/eid` — توقعات خاصة بمناسبة

**📱 ملاحظة:** بيستخدم لعرض توقعات خاصة في المناسبات.

---

## 💼 Portfolio APIs

### 1. GET `/api/mobile/portfolio` — محفظة المستخدم (Mobile)

**الوصف:** بيرجع كل أصول المستخدم (أسهم، ذهب، شهادات، صناديق).

**Headers:** `Authorization: Bearer <token>`

**Response 200 OK:**
```json
{
  "success": true,
  "items": [
    {
      "id": 1,
      "type": "stock",
      "name": "البنك التجاري الدولي",
      "ticker": "COMI",
      "stock_name": "البنك التجاري الدولي",
      "sector": "Banks",
      "quantity": 1000,
      "avg_cost": 60.00,
      "current_price": 65.45,
      "market_value": 65450.00,
      "cost_basis": 60000.00,
      "unrealized_pnl": 5450.00,
      "unrealized_pnl_percent": 9.08,
      "change_percent": 1.95,
      "status": "slight_gain",
      "status_ar": "ربح بسيط",
      "added_at": "2025-12-01 10:00:00"
    },
    {
      "id": 2,
      "type": "gold",
      "name": "ذهب 21 عيار",
      "weight_grams": 50,
      "karat": 21,
      "purchase_price_per_gram": 1850,
      "market_value": 105000,
      "cost_basis": 92500,
      "unrealized_pnl": 12500,
      "unrealized_pnl_percent": 13.51,
      "status": "moderate_gain",
      "status_ar": "ربح جيد"
    },
    {
      "id": 3,
      "type": "certificate",
      "name": "شهادة استثمار - البنك الأهلي",
      "bank_name": "البنك الأهلي المصري",
      "interest_rate": 27,
      "certificate_duration_months": 36,
      "certificate_return_rate": 27,
      "certificate_maturity_date": "2028-12-01",
      "annual_return": 27000,
      "monthly_return": 2250,
      "market_value": 100000,
      "cost_basis": 100000,
      "total_invested": 100000
    }
  ],
  "positions": [...],  // backward compatibility - same as items filtered by type=stock
  "summary": {
    "total_items": 3,
    "total_positions": 1,
    "total_invested": 252500,
    "total_market_value": 270450,
    "total_unrealized_pnl": 17950,
    "total_unrealized_pnl_percent": 7.11,
    "stocks_count": 1,
    "gold_items": 1,
    "certificates_count": 1,
    "winning_positions": 2,
    "losing_positions": 0
  },
  "by_type": {
    "stocks": [...],
    "gold": [...],
    "certificates": [...],
    "funds": []
  }
}
```

**Response 401:**
```json
{ "success": false, "error": "Unauthorized", "error_ar": "يجب تسجيل الدخول" }
```

---

### 2. POST `/api/mobile/portfolio` — إضافة أصل للمحفظة

**Request Body (Stock):**
```json
{
  "type": "stock",
  "stock_symbol": "COMI",
  "shares": 1000,
  "avg_cost": 60.00,
  "name": "البنك التجاري الدولي"
}
```

**Request Body (Gold):**
```json
{
  "type": "gold",
  "weight_grams": 50,
  "karat": 21,
  "purchase_price_per_gram": 1850,
  "name": "ذهب 21 عيار"
}
```

**Request Body (Certificate):**
```json
{
  "type": "certificate",
  "bank_name": "البنك الأهلي المصري",
  "interest_rate": 27,
  "certificate_duration_months": 36,
  "certificate_return_rate": 27,
  "certificate_maturity_date": "2028-12-01",
  "total_invested": 100000,
  "name": "شهادة استثمار - البنك الأهلي"
}
```

**Response 201:**
```json
{
  "success": true,
  "message": "تم إضافة الأصل للمحفظة بنجاح",
  "data": {
    "user_id": "550e8400-...",
    "type": "stock",
    "stock_ticker": "COMI",
    "quantity": 1000,
    "avg_buy_price": 60.00,
    "total_invested": 60000
  }
}
```

---

### 3. DELETE `/api/mobile/portfolio?id=<asset_id>` — حذف أصل

**Response 200:**
```json
{ "success": true, "message": "تم حذف الأصل" }
```

---

### 4. GET `/api/portfolio` — محفظة الويب (legacy)

**Headers:** Session-based (NextAuth) - **لا يستخدم للموبايل**.

---

### 5. POST `/api/portfolio` — إضافة لمحفظة الويب

**ملاحظة:** استخدم `/api/mobile/portfolio` بدلاً منه للموبايل.

---

### 6. GET `/api/portfolio/analyze` — تحليل المحفظة

**الوصف:** بيرجع تحليل ذكي للمحفظة (تنويع، مخاطر، توصيات).

---

### 7. GET `/api/mobile/portfolio/analyze` — تحليل محفظة mobile

---

### 8. GET `/api/mobile/portfolio/intelligence` — ذكاء المحفظة

**الوصف:** بيرجع تحليل عميق للمحفظة مع توصيات لتحسين العوائد.

---

### 9. GET `/api/portfolio/intelligence` — نفس اللي فوق (web version)

---

### 10. GET `/api/portfolio/assets` — أصول المحفظة (web)

---

### 11. POST `/api/portfolio/check` — فحص صحة المحفظة

---

### 12. POST `/api/portfolio/import-real` — استيراد محفظة حقيقية

---

### 13. POST `/api/portfolio/priority-sync` — مزامنة بأولوية

---

## 👁️ Watchlist APIs

### 1. GET `/api/watchlist` — قائمة المراقبة

**الوصف:** بيرجع أسهم قائمة المراقبة للمستخدم.

**Headers:** Session-based أو Bearer token

**Response 200 OK:**
```json
{
  "success": true,
  "items": [
    {
      "id": 1,
      "stock_id": 1,
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "name_ar": "البنك التجاري الدولي",
      "current_price": 65.45,
      "previous_close": 64.20,
      "price_change": 1.95,
      "sector": "Banks",
      "volume": 12500000,
      "market_cap": 132500000000,
      "pe_ratio": 5.8,
      "pb_ratio": 1.2,
      "dividend_yield": 4.5,
      "eps": 11.28,
      "rsi": 58.4,
      "ma_50": 62.10,
      "ma_200": 58.50,
      "alert_price_above": 70.00,
      "alert_price_below": 60.00,
      "alert_change_percent": 5,
      "notes": "مراقبة لاختراق 70",
      "added_at": "2026-01-10 10:00:00",
      "stock": {
        "id": 1,
        "ticker": "COMI",
        "current_price": 65.45,
        "egx30_member": true,
        "egx70_member": false,
        "egx100_member": true
      }
    }
  ],
  "total": 1
}
```

**📱 ملاحظة للجوال:** لو الـ user مش مسجل دخول بيرجع `items: []`.

---

### 2. POST `/api/watchlist` — إضافة سهم لقائمة المراقبة

**Request Body:**
```json
{
  "ticker": "COMI",
  "alert_price_above": 70.00,
  "alert_price_below": 60.00,
  "alert_change_percent": 5,
  "notes": "مراقبة لاختراق 70"
}
```

**Response 201:**
```json
{
  "success": true,
  "message": "تمت إضافة السهم إلى قائمة المراقبة بنجاح",
  "id": 5,
  "stock_id": 1
}
```

**Response 409 Conflict:**
```json
{
  "success": false,
  "error": "هذا السهم موجود بالفعل في قائمة المراقبة",
  "watchlist_id": 5
}
```

---

### 3. DELETE `/api/watchlist/[id]` — حذف من قائمة المراقبة

**Response 200:**
```json
{ "success": true, "message": "تم حذف السهم من قائمة المراقبة" }
```

---

### 4. GET `/api/mobile/watchlist/intelligence` — ذكاء قائمة المراقبة

**الوصف:** بيرجع تحليل ذكي لقائمة المراقبة (فرص، مخاطر، توصيات).

---

### 5. GET `/api/watchlist-enhanced` — قائمة مراقبة محسنة

---

### 6. GET `/api/finance/smart-watchlist` — قائمة المراقبة الذكية

---

### 7. GET `/api/crypto/watchlist` — قائمة مراقبة الكريبتو

---

## 🪙 Crypto APIs

### 1. GET `/api/crypto` — قائمة العملات الرقمية

**الوصف:** بيرجع قائمة العملات مع تحليل Python Backend (primary) و CoinGecko (fallback).

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `per_page` / `perPage` | int | 50 | عدد النتائج |

**Response 200 OK (from Python):**
```json
{
  "success": true,
  "source": "python_backend",
  "data": [
    {
      "id": "bitcoin",
      "symbol": "BTC",
      "name": "Bitcoin",
      "current_price": 95000,
      "price_change_percentage_24h": 2.5,
      "market_cap": 1850000000000,
      "market_cap_rank": 1,
      "total_volume": 45000000000,
      "ath": 108000,
      "ath_change_percentage": -12,
      "atl": 67.81,
      "atl_change_percentage": 14000000,
      "technical_score": 78,
      "confidence": 85,
      "recommendation": {
        "action": "strong_buy",
        "action_ar": "شراء قوي",
        "confidence": 85
      },
      "strength": "strong",
      "opportunity_type": "momentum",
      "reasons": ["MACD bullish crossover", "Above MA200", "Volume surge"],
      "warnings": ["Approaching ATH resistance"]
    }
  ],
  "total": 50,
  "page": 1,
  "per_page": 50,
  "market_regime": "bull",
  "summary": {
    "total_coins": 50,
    "bullish": 32,
    "bearish": 10,
    "neutral": 8
  },
  "categories": {
    "defi": 12,
    "layer1": 15,
    "meme": 5
  }
}
```

**Response 200 OK (from CoinGecko fallback):**
```json
{
  "success": true,
  "source": "coingecko",
  "data": [...],
  "warning": "Python backend unavailable - using CoinGecko directly - LIMITED ANALYSIS"
}
```

**📱 ملاحظة:** لو `source` = `coingecko` اعرف إن التحليل محدود (basic only). لو `python_backend` يبقى التحليل كامل.

---

### 2. GET `/api/crypto/[id]` — تفاصيل عملة

**الوصف:** بيرجع تفاصيل عملة معينة من CoinGecko.

**Path Parameters:** `id` = CoinGecko coin id (e.g., `bitcoin`)

**Response 200 OK:**
```json
{
  "success": true,
  "data": {
    "id": "bitcoin",
    "symbol": "BTC",
    "name": "Bitcoin",
    "image": {
      "thumb": "https://...",
      "small": "https://...",
      "large": "https://..."
    },
    "description": "Bitcoin is the first successful internet...",
    "market_data": {
      "current_price": 95000,
      "ath": 108000,
      "ath_change_percentage": -12,
      "ath_date": "2025-12-17T00:00:00.000Z",
      "atl": 67.81,
      "atl_change_percentage": 14000000,
      "atl_date": "2013-07-06T00:00:00.000Z",
      "market_cap": 1850000000000,
      "market_cap_rank": 1,
      "total_volume": 45000000000,
      "high_24h": 96000,
      "low_24h": 94000,
      "price_change_24h": 2325,
      "price_change_percentage_24h": 2.5,
      "price_change_percentage_7d": 5.2,
      "price_change_percentage_30d": 8.4,
      "price_change_percentage_1y": 145,
      "circulating_supply": 19500000,
      "total_supply": 21000000,
      "max_supply": 21000000
    },
    "sparkline_in_7d": [92000, 93500, 94200, 95000],
    "links": {
      "homepage": ["https://bitcoin.org"],
      "blockchain_site": ["https://blockchain.com/btc"],
      "twitter_screen_name": "Bitcoin",
      "telegram_channel_identifier": "bitcoin"
    },
    "categories": ["Cryptocurrency", "Layer 1"],
    "last_updated": "2026-01-15T14:00:00.000Z"
  },
  "cached": false,
  "timestamp": "2026-01-15T14:30:00.000Z"
}
```

---

### 3. GET `/api/crypto/recommendations` — توصيات الكريبتو

**الوصف:** بيرجع توصيات الكريبتو من Python Backend (quick-scan).

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | int | 20 | عدد التوصيات |
| `risk` | string | `moderate` | `conservative` / `low`, `moderate`, `aggressive` / `high` |

**Response 200 OK:**
```json
{
  "success": true,
  "source": "python_backend",
  "count": 10,
  "risk_level": "moderate",
  "recommendations": [
    {
      "id": "bitcoin",
      "symbol": "BTC",
      "name": "Bitcoin",
      "current_price": 95000,
      "signal": "strong_buy",
      "signal_ar": "شراء قوي",
      "confidence": 88,
      "maestro_score": 82,
      "entry_price": 95000,
      "target_price": 105000,
      "stop_loss": 89000,
      "risk_reward": 1.67,
      "position_size_pct": 5,
      "reasons": ["Bullish MACD", "Above MA200", "Volume surge"],
      "warnings": ["Approaching ATH"],
      "risk_level": "low",
      "market_regime": "bull",
      "fear_greed": 72
    }
  ],
  "timestamp": "2026-01-15T14:30:00.000Z"
}
```

---

### 4. GET `/api/crypto/analyze` — تحليل عملة

---

### 5. GET `/api/crypto/portfolio` — محفظة الكريبتو

---

### 6. GET `/api/crypto/stats` — إحصائيات سوق الكريبتو

---

### 7. GET `/api/crypto/status` — حالة جمع البيانات

---

### 8. GET `/api/mobile/crypto` — نسخة mobile محسنة

---

### 9. GET `/api/mobile/crypto/[id]` — تفاصيل عملة (mobile)

---

### 10. GET `/api/mobile/crypto/recommendations` — توصيات (mobile)

---

### 11. GET `/api/mobile/crypto/analysis` — تحليل (mobile)

---

### 12. GET `/api/mobile/crypto/learning` — محتوى تعليمي للكريبتو

---

### 13. GET `/api/mobile/crypto/portfolio` — محفظة كريبتو (mobile)

---

### 14. GET `/api/mobile/crypto/watchlist` — قائمة مراقبة كريبتو (mobile)

---

### 15. GET `/api/crypto-predictions` — توقعات الكريبتو

---

### 16. GET `/api/crypto-backtesting` — Backtesting للكريبتو

---

### 17. POST `/api/crypto/simulation` — محاكاة تداول كريبتو

---

### 18. GET `/api/unified-crypto` — كريبتو موحد

---

## 🌍 Multi-Market APIs

`دليل الاستثمار` بيدعم 4 أسواق عربية رئيسية + 4 أسواق إضافية:

| Code | Market | Country | Hours (Cairo) |
|------|--------|---------|---------------|
| `EGX` | 🇪🇬 البورصة المصرية | Egypt | 10:00 - 14:30 |
| `TADAWUL` / `KSA` | 🇸🇦 تداول | Saudi Arabia | 10:00 - 15:00 |
| `KSE` | 🇰🇼 بورصة الكويت | Kuwait | 9:00 - 13:15 |
| `QSE` | 🇶🇦 بورصة قطر | Qatar | 9:30 - 13:15 |
| `DFM` | 🇦🇪 دبي المالي | UAE | 10:00 - 14:00 |
| `ADX` | 🇦🇪 أبوظبي المالي | UAE | 10:00 - 14:00 |
| `BSE` | 🇧🇭 البحرين | Bahrain | 9:30 - 13:00 |

### 1. GET `/api/stocks?market=EGX` — أسهم مصر

**Example:** `GET /api/stocks?market=EGX&page=1&limit=50`

---

### 2. GET `/api/stocks?market=KSA` — أسهم السعودية (TADAWUL)

**Example:** `GET /api/stocks?market=KSA&page=1&limit=50`

**ملاحظة:** `KSA` بيتـ map لـ `TADAWUL` تلقائياً في الـ backend.

---

### 3. GET `/api/stocks?market=KSE` — أسهم الكويت

---

### 4. GET `/api/stocks?market=QSE` — أسهم قطر

---

### 5. GET `/api/multi-market/sync` — مزامنة كل الأسواق

**الوصف:** بيـ trigger مزامنة لكل الأسواق.

---

### 6. GET `/api/market/connections` — اتصالات الأسواق

**الوصف:** بيرجع حالة اتصال كل سوق.

---

### 7. GET `/api/market/incremental-sync` — مزامنة تدريجية

---

### 8. POST `/api/market/sync-live` — مزامنة لحظية

---

### 9. POST `/api/market/sync` — مزامنة عامة

---

### 10. GET `/api/unified-stocks` — أسهم موحدة

**الوصف:** بيرجع أسهم من كل الأسواق في استدعاء واحد.

---

### 11. GET `/api/data-engine/stocks` — أسهم من Data Engine

---

### 12. GET `/api/data-engine/crypto` — كريبتو من Data Engine

---

### 13. GET `/api/data-engine/forex` — فوركس

---

### 14. GET `/api/data-engine/gold` — ذهب

---

### 15. GET `/api/data-engine/silver` — فضة

---

## 💰 Payment & Subscription APIs

### 1. GET `/api/subscription/plans` — خطط الاشتراك

**الوصف:** بيرجع خطط الاشتراك المتاحة.

**Response 200 OK:**
```json
{
  "success": true,
  "plans": [
    {
      "id": "free",
      "name": "free",
      "name_ar": "مجانى",
      "price": 0,
      "price_yearly": 0,
      "trial_days": 0,
      "features": [
        "بيانات السوق الأساسية",
        "5 أسهم في قائمة المراقبة",
        "محفظة استثمارية واحدة",
        "3 تنبيهات يومياً",
        "عرض الأسهم والمؤشرات"
      ],
      "max_watchlist": 5,
      "max_portfolio": 1,
      "max_alerts": 3,
      "ai_analysis": false,
      "deep_analysis": false,
      "priority_support": false
    },
    {
      "id": "normal",
      "name": "normal",
      "name_ar": "عادى",
      "price": 99,
      "price_yearly": 990,
      "trial_days": 7,
      "features": [
        "جميع ميزات المجانى",
        "25 سهم في قائمة المراقبة",
        "5 محافظ استثمارية",
        "تنبيهات غير محدودة",
        "تتبع المحفظة الاستثمارية",
        "تحليلات أساسية متقدمة",
        "تصدير التقارير PDF",
        "التحليل الفني للأسهم"
      ],
      "max_watchlist": 25,
      "max_portfolio": 5,
      "max_alerts": 9999,
      "ai_analysis": false,
      "deep_analysis": true,
      "priority_support": false
    },
    {
      "id": "premium",
      "name": "premium",
      "name_ar": "مميز",
      "price": 199,
      "price_yearly": 1990,
      "trial_days": 14,
      "features": [
        "جميع ميزات عادى",
        "قائمة مراقبة غير محدودة",
        "محافظ استثمارية غير محدودة",
        "تحليل بالذكاء الاصطناعي",
        "تحليلات ذكية مخصصة",
        "دعم أولوي على مدار الساعة",
        "تقارير مخصصة",
        "إشعارات فورية للأسعار",
        "تحليل عميق للأسهم"
      ],
      "max_watchlist": 9999,
      "max_portfolio": 9999,
      "max_alerts": 9999,
      "ai_analysis": true,
      "deep_analysis": true,
      "priority_support": true
    }
  ],
  "source": "local"
}
```

**📱 ملاحظة:** الأسعار بالجنيه المصري (EGP). استخدم `price` للشهري و `price_yearly` للسنوي.

---

### 2. POST `/api/paymob/create-payment` — إنشاء عملية دفع

**الوصف:** بينشئ payment session على Paymob.

**Request Body:**
```json
{
  "plan_id": "normal",  // أو "premium"
  "billing_period": "monthly"  // أو "yearly"
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "payment_url": "https://accept.paymob.com/api/acceptance/iframes/1039291?payment_token=...",
  "order_id": 12345678,
  "merchant_order_id": "GLM-550e8400-...-normal-1705312200000"
}
```

**📱 ملاحظة للجوال:**
1. بعت POST للـ endpoint ده
2. خد الـ `payment_url` من الـ response
3. افتحه في `WebView` أو External Browser
4. بعد الدفع ناجح، Paymob هيـ redirect لـ `/api/paymob/callback` على السيرفر
5. اعمل poll على `/api/subscription/current` كل 5 ثواني للتأكد إن الاشتراك اتـ activate

---

### 3. POST `/api/paymob/callback` — استدعاء Paymob (server-side)

**الوصف:** الـ endpoint ده بيتـ استدعى من Paymob بعد كل معاملة. **مش للموبايل**.

---

### 4. GET `/api/paymob/callback` — redirect بعد الدفع

**الوصف:** بيرجع redirect لـ `/?payment=success` أو `/?payment=failed`.

---

### 5. POST `/api/subscription/activate` — تفعيل الاشتراك

**Request Body:**
```json
{
  "plan": "normal",
  "transaction_id": "txn_123",
  "payment_gateway": "paymob",
  "billing_period": "monthly"
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "message": "تم تفعيل الاشتراك بنجاح",
  "data": {
    "plan": "normal",
    "subscription": {
      "id": "sub_001",
      "plan_id": "normal",
      "status": "active",
      "started_at": "2026-01-15T14:30:00.000Z",
      "expires_at": "2026-02-15T14:30:00.000Z",
      "auto_renew": true,
      "payment_method": "paymob"
    },
    "user": {
      "id": "550e8400-...",
      "subscription_tier": "normal"
    },
    "start_date": "2026-01-15T14:30:00.000Z",
    "expiry_date": "2026-02-15T14:30:00.000Z",
    "status": "active"
  }
}
```

---

### 6. GET `/api/subscription/current` — الاشتراك الحالي

**Response 200 OK (active):**
```json
{
  "success": true,
  "subscription": {
    "id": "sub_001",
    "plan_id": "normal",
    "plan_name": "normal",
    "plan_name_ar": "عادى",
    "status": "active",
    "started_at": "2026-01-15T14:30:00.000Z",
    "expires_at": "2026-02-15T14:30:00.000Z",
    "trial_started_at": null,
    "trial_ends_at": null,
    "is_in_trial": false,
    "is_trial_expired": false,
    "auto_renew": true,
    "payment_method": "paymob",
    "plan": {
      "features": [...],
      "max_watchlist": 25,
      "max_portfolio": 5,
      "max_alerts": 9999,
      "ai_analysis": false,
      "deep_analysis": true,
      "priority_support": false
    }
  }
}
```

**Response 200 OK (no subscription):**
```json
{
  "success": true,
  "subscription": null,
  "tier": "free",
  "message": "لا يوجد اشتراك نشط"
}
```

---

### 7. POST `/api/subscription/upgrade` — ترقية الاشتراك

**Request Body:**
```json
{
  "plan": "premium",
  "billing_period": "yearly"
}
```

---

### 8. POST `/api/subscription/start-trial` — بدء فترة تجريبية

**Request Body:**
```json
{ "plan": "normal" }
```

---

### 9. POST `/api/subscription/deactivate` — إلغاء الاشتراك

---

### 10. GET `/api/subscription/check-access` — فحص صلاحيات المستخدم

**Query Parameters:** `feature` (e.g., `ai_analysis`, `deep_analysis`)

---

### 11. POST `/api/subscribe/[plan]` — اشتراك مباشر في خطة

**Path Parameters:** `plan` = `normal` / `premium`

---

### 12. GET `/api/payments/result` — نتيجة الدفع

**Query Parameters:** `order`, `success`

---

### 13. POST `/api/google-play/verify-receipt` — التحقق من Google Play receipt

**الوصف:** للتحقق من عمليات الدفع داخل التطبيق عبر Google Play.

**Request Body:**
```json
{
  "receipt": "google_play_receipt_data",
  "product_id": "premium_monthly"
}
```

---

### 14. POST `/api/instapay` — دفع عبر InstaPay

---

### 15. POST `/api/instapay/approve` — اعتماد InstaPay

---

### 16. POST `/api/instapay/verify` — التحقق من InstaPay

---

### 17. GET `/api/mobile/subscription` — خطط الاشتراك (mobile)

نفس `/api/subscription/plans` بالظبط.

---

## 📰 News & Content APIs

### 1. GET `/api/news-feed` — آخر الأخبار (unified)

**الوصف:** بيجمع أخبار من EGXPilot + CoinGecko + Alternative.me في استدعاء واحد.

**Response 200 OK:**
```json
{
  "success": true,
  "cached": false,
  "timestamp": "2026-01-15T14:30:00.000Z",
  "news": [
    {
      "id": "egx-123",
      "title": "موافقة البورصة المصرية على زيادة رأس مال شركة CFI",
      "summary": "أعلنت البورصة المصرية عن موافقتها على زيادة رأس مال...",
      "source": "EGXPilot",
      "timestamp": "2026-01-15T13:00:00.000Z",
      "category": "egx",
      "importance": "high",
      "url": "https://egxpilot.com/news/123",
      "tickers": ["CFI"]
    },
    {
      "id": "fear-greed-index",
      "title": "مؤشر الخوف والطمع: 72 (Greed)",
      "summary": "الطمع في السوق - حذر من البيع العاطفي",
      "source": "Alternative.me",
      "timestamp": "2026-01-15T14:30:00.000Z",
      "category": "sentiment",
      "importance": "medium"
    },
    {
      "id": "btc-price",
      "title": "Bitcoin: $95,000 (+2.5%)",
      "summary": "البيتكوين صاعد في آخر 24 ساعة",
      "source": "CoinGecko",
      "timestamp": "2026-01-15T14:30:00.000Z",
      "category": "crypto",
      "importance": "low"
    }
  ],
  "summary": {
    "total": 13,
    "egx": 10,
    "crypto": 2,
    "sentiment": 1
  },
  "cache_duration": 300
}
```

**📱 ملاحظة:** الـ response بيتـ cached لمدة 5 دقايق على السيرفر.

---

### 2. POST `/api/news-feed` — force refresh

**الوصف:** بيمسح الـ cache ويعمل fetch جديد.

---

### 3. GET `/api/mobile/news` — أخبار (mobile)

نفس `/api/news-feed` بالظبط.

---

### 4. GET `/api/news` — أخبار (legacy)

---

### 5. GET `/api/egxpilot/news` — أخبار EGXPilot

---

### 6. GET `/api/egxpilot/stocks` — أسهم EGXPilot

---

### 7. GET `/api/egxpilot/analysis/[ticker]` — تحليل EGXPilot

---

### 8. GET `/api/stocks/[ticker]/news` — أخبار سهم معين

---

### 9. GET `/api/maestro/news` — أخبار الـ Maestro

---

### 10. GET `/api/news/apikeys` — إدارة API keys للأخبار

---

### 11. POST `/api/news/apikeys/verify` — التحقق من API keys

---

## 🤖 AI Chat APIs

### 1. POST `/api/ai/chat` — محادثة AI

**الوصف:** محادثة مع DeepSeek AI مع memory و web search.

**Request Body:**
```json
{
  "message": "ايه رأيك في سهم COMI؟",
  "context": {
    "page": "stock_detail",
    "ticker": "COMI"
  }
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "reply": "بناءً على تحليلي لسهم COMI، الشركة تظهر قوة في الزخم الفني...",
  "model": "deepseek-chat",
  "tool_used": "deepseek-v3",
  "confidence": "high",
  "reasoning": null,
  "memory_used": true,
  "response_time_ms": 1250
}
```

**Response 200 (complex analysis - uses R1):**
```json
{
  "success": true,
  "reply": "تحليلي المتعمق لـ COMI يظهر إشارات إيجابية...",
  "model": "deepseek-reasoner",
  "tool_used": "deepseek-r1",
  "confidence": "high",
  "reasoning": "MACD shows bullish divergence, RSI at 58.4 indicates room for upside...",
  "memory_used": true,
  "response_time_ms": 8400
}
```

**📱 ملاحظة للجوال:**
- الأسئلة البسيطة → DeepSeek V3 (سريع، 1-2 ثانية)
- التحليل المعقد → DeepSeek R1 (بطيء، 5-15 ثانية) - اعرض loading indicator
- لو `tool_used` = `web_search` يبقى الـ response فيه معلومات محدثة

---

### 2. GET `/api/ai/chat` — حالة الـ AI

**Response:**
```json
{
  "success": true,
  "model": "deepseek-v3 + deepseek-r1",
  "ollama_running": true,
  "tools_available": ["deepseek-chat", "deepseek-reasoner", "web_search", "market_sentiment", "memory"],
  "memory": {
    "conversations": 245,
    "decisions": 89,
    "metrics": 18,
    "accuracy": 78.5
  }
}
```

---

### 3. GET `/api/ai-analysis` — تحليل AI (action-based)

شوف قسم [Analysis APIs](#-analysis-apis).

---

### 4. POST `/api/ai-proxy` — proxy لـ AI APIs

---

### 5. GET `/api/ai-performance` — أداء الـ AI

---

### 6. GET `/api/mobile/ai/recommendations` — توصيات AI (mobile)

---

## 🏹 Hunter APIs

### 1. GET `/api/hunter/screener` — شاشة الفرص (Stock Screener)

**الوصف:** بيرجع أفضل الفرص بناءً على معايير متقدمة.

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `market` | string | `all` | `EGX`, `TADAWUL`, `KSE`, `QSE`, `all` |
| `limit` | int | 10 | عدد النتائج |

**Response 200 OK:**
```json
{
  "success": true,
  "results": [
    {
      "ticker": "COMI",
      "name_ar": "البنك التجاري الدولي",
      "market": "EGX",
      "current_price": 65.45,
      "score": 92,
      "signals": ["MACD_buy", "RSI_bullish", "Volume_surge"],
      "potential_return": 18.5,
      "target_price": 77.50,
      "stop_loss": 60.00,
      "risk_reward": 2.18,
      "match_reasons": [
        "P/E under 10",
        "ROE > 15%",
        "RSI < 60",
        "Above MA200"
      ]
    }
  ],
  "total": 10,
  "scan_time_ms": 1200
}
```

**Response 504 Timeout:**
```json
{ "success": false, "error": "انتهت مهلة الطلب" }
```

---

### 2. GET `/api/finance/screener` — شاشة متقدمة

**Query Parameters:** `min_pe`, `max_pe`, `min_roe`, `min_dividend_yield`, `sector`

---

### 3. GET `/api/finance/smart-confluence` — Confluence ذكي

**الوصف:** بيجمع عدة استراتيجيات تحليلية لإيجاد فرص قوية.

---

### 4. GET `/api/confluence/daily-picks` — اختيارات يومية

---

### 5. GET `/api/finance/smart-analysis` — تحليل ذكي

---

### 6. GET `/api/finance/smart-alerts` — تنبيهات ذكية

---

### 7. GET `/api/finance/portfolio-analysis` — تحليل المحفظة

---

### 8. GET `/api/seasonality-signals` — إشارات الموسمية

---

### 9. GET `/api/stock-seasonality` — موسمية سهم معين

---

### 10. GET `/api/indicator-trust-scores` — درجات ثقة المؤشرات

---

### 11. GET `/api/stocks/data-coverage` — تغطية البيانات

---

### 12. GET `/api/stocks/advanced-analysis` — تحليل متقدم

---------------------------------------------------------------------------

## 📱 Mobile-Specific Endpoints

ده قسم مهم جداً - كل الـ endpoints هنا مصممة خصيصاً للموبايل.

### 1. GET `/api/mobile/auth/me` — بيانات المستخدم

شوف [Authentication APIs](#-authentication-apis).

---

### 2. GET `/api/mobile/dashboard` — لوحة التحكم الشاملة

**الوصف:** أهم endpoint للجوال - بيرجع كل بيانات الـ Home screen في طلب واحد.

**Response 200 OK:**
```json
{
  "success": true,
  "timestamp": "2026-01-15T14:30:00.000Z",
  "market_status": {
    "is_open": true,
    "status": "open",
    "session": "trading",
    "next_open": "غداً 10:00 صباحاً",
    "current_time": "14:30:00"
  },
  "summary": {
    "total_stocks": 245,
    "gainers": 145,
    "losers": 87,
    "unchanged": 13
  },
  "indices": [
    { "name": "EGX 30", "name_ar": "مؤشر EGX 30", "value": 28500, "change": 1.2 },
    { "name": "EGX 70", "name_ar": "مؤشر EGX 70", "value": 4200, "change": -0.5 },
    { "name": "EGX 100", "name_ar": "مؤشر EGX 100", "value": 8500, "change": 0.8 }
  ],
  "top_movers": {
    "gainers": [
      {
        "ticker": "COMI",
        "name_ar": "البنك التجاري الدولي",
        "price": 65.45,
        "change_percent": 9.95,
        "volume": 12500000,
        "change_type": "gainer"
      }
    ],
    "losers": [
      {
        "ticker": "HRHO",
        "name_ar": "EFG Hermes",
        "price": 24.10,
        "change_percent": -5.20,
        "volume": 3200000,
        "change_type": "loser"
      }
    ],
    "most_active": [...]
  },
  "gold_prices": {
    "karat_24": 2200,
    "karat_21": 1925,
    "karat_18": 1650,
    "change_24k": 25,
    "silver": 28,
    "last_updated": "2026-01-15T14:00:00.000Z"
  },
  "currency_rates": {
    "USD": { "buy": 50.5, "sell": 50.7 },
    "EUR": { "buy": 54.2, "sell": 54.6 },
    "SAR": { "buy": 13.4, "sell": 13.5 }
  },
  "market_overview": { ... },
  "source": "mobile_dashboard_api"
}
```

**📱 ملاحظة للجوال:** ده أهم endpoint - استخدمه في الـ Home screen. اعمل poll كل 5 دقايق في وقت السوق المفتوح، وكل 30 دقيقة لو مقفل.

---

### 3. GET `/api/mobile/summary` — ملخص سريع

**الوصف:** بيرجع ملخص سريع للسوق والمحفظة (أقل تفصيلاً من dashboard).

---

### 4. GET `/api/mobile/predictions` — التوقعات

شوف [Predictions APIs](#-predictions-apis).

---

### 5. GET `/api/mobile/recommendations` — التوصيات

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `persona` | string | `balanced` | `conservative`, `balanced`, `gambler` |
| `limit` | int | 10 | عدد النتائج |

**Response 200 OK:**
```json
{
  "success": true,
  "source": "python_backend",
  "timestamp": "2026-01-15T14:30:00.000Z",
  "persona": "balanced",
  "threshold": 65,
  "recommendations": [
    {
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "name_ar": "البنك التجاري الدولي",
      "sector": "Banks",
      "current_price": 65.45,
      "change_percent": 1.95,
      "score": 85,
      "recommendation": "buy",
      "signals": ["positive_momentum", "high_liquidity"],
      "target_price": 75.27,
      "stop_loss": 60.21
    }
  ],
  "total_analyzed": 245,
  "passed_filter": 32
}
```

**📱 ملاحظة:** الـ `persona` بيتحكم في الـ threshold:
- `conservative` → 75 (only top quality)
- `balanced` → 65 (default)
- `gambler` → 50 (more risky picks)

---

### 6. GET `/api/mobile/stocks/EGX/professional-analysis` — تحليل احترافي EGX

---

### 7. GET `/api/mobile/stocks/EGX/recommendation` — توصية EGX

---

### 8. GET `/api/mobile/stocks/[ticker]/professional-analysis` — تحليل احترافي لسهم

---

### 9. GET `/api/mobile/stocks/[ticker]/recommendation` — توصية لسهم

---

### 10. GET `/api/mobile/analysis/EGX` — تحليل سوق EGX

---

### 11. GET `/api/mobile/analysis/[ticker]` — تحليل سهم

---

### 12. GET `/api/mobile/expert-recommendations` — توصيات الخبراء

---

### 13. GET `/api/mobile/zakat-calculator` — حاسبة الزكاة

**Query Parameters:** `gold_value`, `cash`, `stocks_value`, `debts`

**Response:**
```json
{
  "success": true,
  "zakat_due": 2500,
  "nisab": 215000,
  "eligible_for_zakat": true,
  "details": {
    "gold_value": 105000,
    "cash": 100000,
    "stocks_value": 50000,
    "debts": 0,
    "total_assets": 255000,
    "zakat_rate": 0.025
  }
}
```

---

### 14. GET `/api/mobile/seasonality` — موسمية الأسهم

---

### 15. GET `/api/mobile/risk` — تحليل المخاطر

---

### 16. GET `/api/mobile/signals` — إشارات التداول

---

### 17. GET `/api/mobile/reports` — تقارير

---

### 18. GET `/api/mobile/community` — مجتمع المستخدمين

---

### 19. GET `/api/mobile/currency` — أسعار العملات

---

### 20. GET `/api/mobile/gold` — أسعار الذهب

---

### 21. GET `/api/mobile/learning` — محتوى تعليمي

---

### 22. GET `/api/mobile/maestro` — Maestro Insights

---

### 23. GET `/api/mobile/market/recommendations/ai-insights` — AI insights

---

## 📋 Phase 11 Mobile API Audit (Complete Documentation)

> **Audit Date:** June 2026 (Task #14)
> **Audited by:** Code Agent
> **Scope:** All 9 Phase 11 mobile endpoints + fixed endpoints + POST endpoints
> **Live Test Status:** ✅ All free (no-auth) endpoints returned 200 OK on `localhost:3000`

### 🧪 Live Audit Test Results

| Endpoint | Method | HTTP Status | Response Time | Notes |
|----------|--------|-------------|---------------|-------|
| `/api/mobile/dashboard` | GET | ✅ 200 | 0.54s | Real gold 24K = 3756.37 EGP |
| `/api/mobile/market/overview` | GET | ✅ 200 | 0.24s | 858 stocks, 246 gainers / 465 losers |
| `/api/mobile/recommendations?limit=3` | GET | ✅ 200 | 0.23s | 858 analyzed, 221 passed filter |
| `/api/mobile/predictions?limit=3` | GET | ✅ 200 | 0.24s | Empty list (no predictions in DB) |
| `/api/mobile/news` | GET | ✅ 200 | 0.94s | EGXPilot + CoinGecko + Fear/Greed |
| `/api/mobile/gold` | GET | ✅ 200 | 0.24s | 6 karats + silver = 44.95 EGP |
| `/api/mobile/currency` | GET | ✅ 200 | 0.23s | 6 currencies, source=fallback |
| `/api/mobile/stocks/COMI` | GET | ✅ 200 | 0.51s | Real price = 132.39 EGP |
| `/api/mobile/market/recommendations/ai-insights` | GET | ✅ 200 | 0.22s | Neutral sentiment, confidence 50 |
| `/api/auth/me` (no token) | GET | ✅ 401 | 0.25s | Correctly rejects unauthenticated |

> ⚠️ **Python Backend (port 8010) was offline during the audit** — all endpoints successfully fell back to local DBs (`data_engine.db`, `egx.db`, Prisma). This proves the fallback chain is healthy.

---

### 🟢 Free (No-Auth) Mobile Endpoints

#### 1. GET `/api/mobile/dashboard`

**الوصف:** لوحة التحكم الشاملة للموبايل - بيرجع كل بيانات الـ Home screen في طلب واحد (market overview + gold + currency + top movers + indices).

**Auth:** غير مطلوب (free)

**Query params:** none

**Response 200 OK:**
```json
{
  "success": true,
  "timestamp": "2026-06-18T17:50:19.443Z",
  "market_status": {
    "is_open": false,
    "status": "closed",
    "session": "closed",
    "next_open": "غداً 10:00 صباحاً",
    "current_time": "٨:٥٠:١٩ م"
  },
  "summary": { "total_stocks": 858, "gainers": 246, "losers": 465, "unchanged": 147 },
  "indices": [
    { "name": "EGX 30", "name_ar": "مؤشر EGX 30", "value": 0, "change": 0, "change_percent": 0 }
  ],
  "top_movers": {
    "gainers": [{ "ticker": "COMI", "name_ar": "البنك التجاري الدولي", "price": 65.45, "change_percent": 9.95, "volume": 12500000, "change_type": "gainer" }],
    "losers": [{ "ticker": "HRHO", "name_ar": "EFG Hermes", "price": 24.10, "change_percent": -5.20, "volume": 3200000, "change_type": "loser" }],
    "most_active": [...]
  },
  "gold_prices": {
    "karat_24": 3756.37,
    "karat_21": 3286.82,
    "karat_18": 2817.28,
    "change_24k": 0,
    "silver": 44.948,
    "last_updated": "2026-06-18 11:32:44"
  },
  "currency_rates": { "USD": { "buy": 50.5, "sell": 50.7 }, "EUR": { "buy": 54.2, "sell": 54.6 } },
  "market_overview": { "...": "full python /api/market/overview payload" },
  "source": "mobile_dashboard_api"
}
```

**Fallback chain:**
1. Python Backend `/api/market/overview` (timeout 10s)
2. `data_engine.db` for top movers (`getTopMovers`, `getStocksByMarket`)
3. `data_engine.db` for gold (`getLatestGoldPrices`, `getLatestSilverPrices`) - filters `country === 'مصر'`
4. Python Backend `/api/currency/list` (timeout 5s)
5. Market status computed locally (Egypt timezone, weekend = Fri/Sat, hours 10:00–14:30)

**Errors:**
- `500` `{ "success": false, "error": "<message>", "timestamp": "..." }` — only if everything fails catastrophically (graceful degradation: missing sections are `null`).

**📱 ملاحظة:** اعمل poll كل 5 دقايق وقت السوق المفتوح، وكل 30 دقيقة لو مقفل.

---

#### 2. GET `/api/mobile/market/overview`

**الوصف:** نفس بيانات `/api/market/overview` بتاع الويب - بيضمن إن الموبايل والويب يعرضوا نفس البيانات.

**Auth:** غير مطلوب (free)

**Query params:** none

**Response 200 OK:**
```json
{
  "success": true,
  "timestamp": "2026-06-18T17:50:19.691Z",
  "market_status": { "is_open": false, "status": "closed", "next_open": null, "next_close": null, "current_session": "closed" },
  "summary": {
    "total_stocks": 858,
    "gainers": 246,
    "losers": 465,
    "unchanged": 147,
    "egx30_stocks": 0,
    "egx70_stocks": 0,
    "egx100_stocks": 0,
    "egx30_value": 17342
  },
  "indices": [],
  "top_gainers": [{ "ticker": "COMI", "name": "...", "name_ar": "...", "current_price": 65.45, "change_percent": 9.95, "volume": 12500000 }],
  "top_losers": [...],
  "most_active": [...],
  "last_updated": "2026-06-18T17:50:19.691Z",
  "source": "python_backend"
}
```

**Fallback chain:**
1. Python Backend `/api/market/overview` (timeout 15s) → `source: "python_backend"`
2. `data_engine.db` `SELECT symbol, name, price, change_percent, volume, market FROM stocks WHERE price > 0` → `source: "local_fallback"`

**Errors:**
- `503` `{ "success": false, "error": "No stocks found in database" }` — only when DB has 0 stocks
- `500` `{ "success": false, "error": "Failed to get market overview" }` — generic catch-all

---

#### 3. GET `/api/mobile/recommendations`

**الوصف:** توصيات الأسهم بناءً على persona. بيستخدم Python Backend أولاً وبعدين local DB.

**Auth:** غير مطلوب (free) — ⚠️ **ملاحظة:** الكود الحالي **مش بيفرض** حد 3 عناصر للمستخدمين المجانيين، فلازم العميل يبعت `limit=3` بنفسه. (شوف قسم [Rate Limits & Quotas](#-rate-limits--timeouts))

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `persona` | string | `balanced` | `conservative` (threshold 75), `balanced` (65), `gambler` (50) |
| `limit` | int | 10 | عدد النتائج. للمستخدم المجاني استخدم `limit=3` |

**Response 200 OK:**
```json
{
  "success": true,
  "source": "python_backend",
  "timestamp": "2026-06-18T17:50:21.363Z",
  "persona": "balanced",
  "threshold": 65,
  "recommendations": [
    {
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "name_ar": "البنك التجاري الدولي",
      "sector": "Banks",
      "current_price": 65.45,
      "change_percent": 1.95,
      "score": 85,
      "recommendation": "buy",
      "signals": ["positive_momentum", "high_liquidity"],
      "target_price": 75.27,
      "stop_loss": 60.21
    }
  ],
  "total_analyzed": 858,
  "passed_filter": 221
}
```

**Fallback chain:**
1. Python Backend `/api/recommendations?persona=&limit=` via `pythonFetch` → `source: "python_backend"`
2. `data_engine.db` stocks table + local scoring algorithm (change_percent + volume heuristic) → `source: "local_db"`. Recommendations derived:
   - score ≥ 85 → `strong_buy`
   - score ≥ 70 → `buy`
   - score ≥ 50 → `hold`
   - else → `avoid`

**Errors:**
- `500` `{ "success": false, "error": "Failed to get recommendations", "detail": "..." }`

---

#### 4. GET `/api/mobile/predictions`

**الوصف:** التوقعات - بيرجع نفس بيانات `/api/predictions` بتاع الويب من Prisma DB.

**Auth:** غير مطلوب (free) — ⚠️ **ملاحظة:** الكود الحالي **مش بيفرض** حد 3 عناصر للمستخدمين المجانيين، فلازم العميل يبعت `limit=3`.

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | int | 50 | عدد النتائج. للمستخدم المجاني استخدم `limit=3` |
| `status` | string | (none) | فلتر بـ `result`: `SUCCESS`, `FAIL` |

**Response 200 OK:**
```json
{
  "success": true,
  "predictions": [
    {
      "id": "pred_001",
      "symbol": "COMI",
      "market": "EGX",
      "signal": "STRONG_BUY",
      "confidence": 85,
      "entry_price": 65.45,
      "target_price": 72.00,
      "stop_loss": 62.00,
      "reasoning": "text",
      "indicators": { "rsi": 58.4, "macd": "bullish", "ma_trend": "uptrend" },
      "news_summary": "text",
      "created_at": "2026-01-15T14:30:00.000Z",
      "verify_date": "2026-01-22",
      "verified": false,
      "result": null,
      "final_price": null,
      "profit_loss_pct": null
    }
  ],
  "stats": {
    "total_predictions": 145,
    "verified_predictions": 89,
    "successful": 71,
    "failed": 18,
    "success_rate": 79.8
  }
}
```

**Fallback chain:**
1. Prisma `db.deepSeekPrediction.findMany()` — same DB as website
2. On any error → returns `success: true` with **empty** predictions and zeroed stats (graceful, never throws 500). هذا يضمن إن الـ mobile app ما يكسرش لو DB فيه مشكلة.

**Errors:**
- لا يوجد 500 — الكود بيلت catch-all بيارجع `success: true` مع empty array.

---

#### 5. GET `/api/mobile/news`

**الوصف:** آخر الأخبار الموحدة - بيجمع أخبار EGX + crypto prices + Fear & Greed Index.

**Auth:** غير مطلوب (free)

**Query params:** none

**Response 200 OK:**
```json
{
  "success": true,
  "cached": false,
  "timestamp": "2026-06-18T17:50:19.000Z",
  "news": [
    {
      "id": "egx-123",
      "title": "خبر من البورصة المصرية",
      "summary": "...",
      "source": "EGXPilot",
      "timestamp": "2026-06-18T14:00:00.000Z",
      "category": "egx",
      "importance": "high",
      "url": "https://...",
      "tickers": ["COMI"]
    },
    {
      "id": "fear-greed-index",
      "title": "مؤشر الخوف والطمع: 42 (Fear)",
      "summary": "الخوف في السوق - حذر من الشراء العاطفي",
      "source": "Alternative.me",
      "timestamp": "2026-06-18T17:50:00.000Z",
      "category": "sentiment",
      "importance": "medium"
    },
    {
      "id": "btc-price",
      "title": "Bitcoin: $67,500 (+2.3%)",
      "summary": "البيتكوين صاعد",
      "source": "CoinGecko",
      "timestamp": "2026-06-18T17:50:00.000Z",
      "category": "crypto",
      "importance": "low"
    }
  ],
  "summary": { "total": 12, "egx": 10, "crypto": 2, "sentiment": 1 }
}
```

**Fallback chain:**
1. EGXPilot API `https://egxpilot.com/api/news/` (timeout 15s) — top 10 EGX news
2. Alternative.me Fear & Greed `https://api.alternative.me/fng/?limit=1` (timeout 10s)
3. CoinGecko `https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana` (timeout 10s)
4. All fetched in parallel via `Promise.all`
5. In-memory cache for 5 minutes (`CACHE_DURATION = 300`) — `cached: true` flag indicates cache hit

**POST variant:** `POST /api/mobile/news` بيفرض الكاش ويعيد التحميل (force refresh).

**Errors:**
- `500` `{ "success": false, "error": "<message>", "news": [] }` — every error returns empty news, never breaks the client

---

#### 6. GET `/api/mobile/gold`

**الوصف:** أسعار الذهب والفضة في مصر - بيستخدم `data_engine.db`.

**Auth:** غير مطلوب (free)

**Query params:** none

**Response 200 OK:**
```json
{
  "success": true,
  "timestamp": "2026-06-18T17:50:19.934Z",
  "last_updated": "2026-06-18 11:32:44",
  "source": "data_engine.db",
  "prices": {
    "karats": [
      { "key": "24", "name_ar": "عيار 24", "price_per_gram": 3756.37, "change": null, "currency": "EGP" },
      { "key": "22", "name_ar": "عيار 22", "price_per_gram": 3443.46, "change": null, "currency": "EGP" },
      { "key": "21", "name_ar": "عيار 21", "price_per_gram": 3286.82, "change": null, "currency": "EGP" },
      { "key": "18", "name_ar": "عيار 18", "price_per_gram": 2817.28, "change": null, "currency": "EGP" },
      { "key": "14", "name_ar": "عيار 14", "price_per_gram": 2191.09, "change": null, "currency": "EGP" },
      { "key": "10", "name_ar": "عيار 10", "price_per_gram": 1565.28, "change": null, "currency": "EGP" }
    ],
    "ounce": null,
    "silver": { "price_per_gram": 44.948, "change": null, "currency": "EGP", "name_ar": "فضة" },
    "silver_ounce": null,
    "bullion": []
  },
  "summary": {
    "gold_24k": 3756.37,
    "gold_21k": 3286.82,
    "gold_18k": 2817.28,
    "silver": 44.948
  }
}
```

**Fallback chain:** Single source — `data_engine.db` (`getLatestGoldPrices`, `getLatestSilverPrices`). يتم فلتر البيانات بـ `country === 'مصر'` والـ karat يكون في `[24, 22, 21, 18, 14, 12, 10, 8]`.

**Errors:**
- `404` `{ "success": false, "error": "لا توجد بيانات أسعار الذهب", "timestamp": "..." }` — when no gold rows
- `500` `{ "success": false, "error": "<message>" }`

---

#### 7. GET `/api/mobile/currency`

**الوصف:** أسعار العملات مقابل الجنيه المصري.

**Auth:** غير مطلوب (free)

**Query params:** none

**Response 200 OK:**
```json
{
  "success": true,
  "timestamp": "2026-06-18T17:50:20.171Z",
  "count": 6,
  "rates": [
    { "code": "USD", "name": "US Dollar", "name_ar": "دولار أمريكي", "symbol": "$", "rate_to_egp": 50.5 },
    { "code": "EUR", "name": "Euro", "name_ar": "يورو", "symbol": "€", "rate_to_egp": 54.8 },
    { "code": "GBP", "name": "British Pound", "name_ar": "جنيه إسترليني", "symbol": "£", "rate_to_egp": 64.2 },
    { "code": "SAR", "name": "Saudi Riyal", "name_ar": "ريال سعودي", "symbol": "﷼", "rate_to_egp": 13.5 },
    { "code": "AED", "name": "UAE Dirham", "name_ar": "درهم إماراتي", "symbol": "د.إ", "rate_to_egp": 13.8 },
    { "code": "KWD", "name": "Kuwaiti Dinar", "name_ar": "دينار كويتي", "symbol": "د.ك", "rate_to_egp": 165 }
  ],
  "base_currency": "EGP",
  "source": "python_backend"
}
```

**Fallback chain:**
1. Python Backend `/api/currency/list` (timeout 10s) → `source: "python_backend"`
2. Static fallback with 6 common currencies → `source: "fallback"`. الـ rates هنا تقريبية (USD=50.5, EUR=54.8, ...)

**Errors:** لا يوجد 500 — دايماً بيرجع static fallback حتى لو Python مش شغّال.

---

#### 8. GET `/api/mobile/stocks/[ticker]`

**الوصف:** بيانات سهم معين للجوال.

**Auth:** غير مطلوب (free)

**Path params:** `ticker` (string, required) - رمز السهم (case-insensitive)

**Query params:** none

**Response 200 OK:**
```json
{
  "success": true,
  "source": "local_db",
  "data": {
    "ticker": "COMI",
    "name_ar": "البنك التجاري الدولي",
    "name": "البنك التجاري الدولي",
    "sector": "القطاع المالي",
    "current_price": 132.39,
    "previous_close": 132.39,
    "open": 132.97,
    "high": 133.5,
    "low": 131.62,
    "volume": "1.37 M",
    "market_cap": "447.58 B EGP",
    "pe_ratio": null,
    "pb_ratio": 1.7,
    "dividend_yield": 6.37,
    "eps": 5.77,
    "roe": 18,
    "is_active": 1,
    "last_update": "2026-06-18T11:32:43.044891"
  }
}
```

**Fallback chain:**
1. Python Backend `/api/stocks/{TICKER}` via `pythonFetch` (timeout default) → `source: "python_backend"`
2. `egx.db` SQLite `SELECT * FROM stocks WHERE ticker = ? COLLATE NOCASE` → `source: "local_db"`

**Errors:**
- `404` `{ "success": false, "error": "Stock not found", "ticker": "COMI" }` — stock not in DB
- `500` `{ "success": false, "error": "Failed to load stock data" }` — generic catch

---

#### 9. GET `/api/mobile/market/recommendations/ai-insights`

**الوصف:** رؤى AI للسوق - sentiment + recommendation. بيستخدم Python Backend أولاً وبعدين local DB fallback.

**Auth:** غير مطلوب (free)

**Query params:** none

**Response 200 OK:**
```json
{
  "success": true,
  "source": "local_db",
  "overall_sentiment": "neutral",
  "sentiment_ar": "محايد",
  "confidence": 50,
  "key_factors": ["السوق متوازن"],
  "recommendation": "hold",
  "recommendation_ar": "احتفاظ"
}
```

**Sentiment values:**
- `bullish` → `صعودي` (لو >40% من الأسهم صاعدة >2%)
- `bearish` → `هبوطي` (لو >40% من الأسهم هابطة >2%)
- `neutral` → `محايد`

**Recommendation logic:**
- `bullish` + confidence > 60 → `buy` / `شراء`
- `bearish` + confidence > 60 → `sell` / `بيع`
- else → `hold` / `احتفاظ`

**Fallback chain:**
1. Python Backend `/api/market/recommendations/ai-insights` via `pythonFetch` → `source: "python_backend"`
2. `data_engine.db` stocks table — يحسب bullish/bearish counts من change_percent → `source: "local_db"`
3. On error → `success: true` with neutral sentiment (graceful, never throws 500)

**Errors:** لا يوجد 500 — دايماً بيرجع safe default بـ neutral sentiment.

---

### 🔒 Auth-Required Mobile Endpoints

#### 10. GET `/api/mobile/portfolio`

**الوصف:** محفظة المستخدم - بترجع الأسهم + الذهب + الشهادات + الصناديق.

**Auth:** مطلوب - `Authorization: Bearer <token>`

**Headers:**
```
Authorization: Bearer egx_<user_id>_<uuid>_<timestamp>
```

**Response 200 OK:**
```json
{
  "success": true,
  "items": [
    {
      "id": 1,
      "type": "stock",
      "name": "البنك التجاري الدولي",
      "ticker": "COMI",
      "quantity": 100,
      "avg_cost": 60.00,
      "current_price": 132.39,
      "market_value": 13239.00,
      "cost_basis": 6000.00,
      "unrealized_pnl": 7239.00,
      "unrealized_pnl_percent": 120.65,
      "change_percent": 0,
      "status": "heavy_gain",
      "status_ar": "ربح كبير",
      "added_at": "2026-01-10 10:00:00"
    }
  ],
  "positions": [...],
  "summary": {
    "total_items": 1,
    "total_positions": 1,
    "total_invested": 6000,
    "total_market_value": 13239,
    "total_unrealized_pnl": 7239,
    "total_unrealized_pnl_percent": 120.65,
    "stocks_count": 1,
    "gold_items": 0,
    "certificates_count": 0,
    "winning_positions": 1,
    "losing_positions": 0
  },
  "by_type": {
    "stocks": [...],
    "gold": [...],
    "certificates": [...],
    "funds": []
  }
}
```

**Status values (computed from pnl %):**
| Range | Status | Status AR |
|-------|--------|-----------|
| `<= -15%` | `heavy_loss` | خسارة كبيرة |
| `<= -5%` | `moderate_loss` | خسارة متوسطة |
| `< 0%` | `slight_loss` | تحت التكلفة |
| `< 10%` | `slight_gain` | ربح بسيط |
| `< 25%` | `moderate_gain` | ربح جيد |
| `>= 25%` | `heavy_gain` | ربح كبير |

**POST variant:** `POST /api/mobile/portfolio` — لإضافة أصل (stock/gold/certificate/fund).

**DELETE variant:** `DELETE /api/mobile/portfolio?id=<asset_id>` — لحذف أصل.

**Fallback chain:**
1. Prisma `db.$queryRaw` على `portfolio_assets` table
2. `egx.db` للأسعار الحالية للأسهم
3. لو السهم مش موجود في `egx.db` → بيستخدم `avg_buy_price` كـ current price

**Errors:**
- `401` `{ "success": false, "error": "Unauthorized", "error_ar": "يجب تسجيل الدخول" }` — token missing or expired
- `500` `{ "success": false, "error": "Failed to fetch portfolio", "detail": "...", "items": [], "positions": [] }`

---

#### 11. GET `/api/auth/me`

**الوصف:** بيانات المستخدم الحالي باستخدام Bearer token.

**Auth:** مطلوب - `Authorization: Bearer <token>`

**Response 200 OK:**
```json
{
  "success": true,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "username",
    "name": "User Name",
    "image": "https://...|null",
    "subscription_tier": "free|normal|premium|admin",
    "default_risk_tolerance": "low|medium|high",
    "is_admin": false,
    "is_active": true,
    "email_verified": true,
    "last_login": "2026-01-15T10:30:00Z",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

**Fallback chain:**
1. Prisma `db.apiToken.findUnique({ where: { token }, include: { User: true } })`
2. `db.userSubscription.findUnique` للـ subscription info — لو مش موجود، بيرجع `user.subscription_tier`
3. بينشّط `last_used` لكل token valid

**Errors:**
- `401` `{ "success": false, "error": "Authorization header مطلوب" }` — no header
- `401` `{ "success": false, "error": "Token غير موجود", "error_en": "Token not found" }` — invalid token
- `401` `{ "success": false, "error": "Token منتهي الصلاحية", "error_en": "Token expired" }` — expired (auto-deleted)
- `403` `{ "success": false, "error": "الحساب غير مفعل", "error_en": "Account is deactivated" }` — inactive user
- `500` `{ "success": false, "error": "حدث خطأ أثناء جلب بيانات المستخدم" }`

---

### 🔧 Phase 11 Fixed Endpoints (Non-Mobile)

#### 12. GET `/api/predictions`

**الوصف:** التوقعات من Python Backend مع fallback لـ predictions.db.

**Auth:** غير مطلوب

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `type` | string | `all` | فلترة بـ signal: `STRONG_BUY`, `BUY`, `SELL`, etc. |
| `limit` | int | 50 | عدد النتائج |
| `market` | string | (none) | فلتر بـ `EGX`, `TADAWUL`, `KSE`, `QSE` |

**Response 200 OK:**
```json
{
  "success": true,
  "data": [{ "id": "pred_001", "symbol": "COMI", "signal": "BUY", "confidence": 85, "..." : "..." }],
  "stats": { "total": 50, "avgScore": 78 },
  "source": "python_backend"
}
```

**Fallback chain (3 levels):**
1. Python Backend `/api/v2/predictions?limit=&signal=&market=` (timeout 8s) → `source: "python_backend"`
2. `predictions.db` (`getLightDb`) `SELECT * FROM predictions ORDER BY created_at DESC LIMIT ?` → `source: "local_db"`
3. Empty success → `source: "empty"` with note `"لا توجد توقعات متاحة حالياً"`

**POST variant:** `POST /api/predictions` — بيحوّل لـ Python `/api/v2/predictions` (timeout 15s). بيارجع 500 لو Python مش شغّال.

---

#### 13. GET `/api/stocks/movement-classification`

**الوصف:** تصنيف حركة الأسهم (alive/slow/dead) من `data_engine.db`.

**Auth:** غير مطلوب

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `ticker` | string | (none) | سهم محدد (case-insensitive) |
| `min_score` | int | (none) | أقل درجة حركة (0-100) |
| `type` | string | (none) | فلتر بـ `alive`, `slow`, `dead` |

**Response 200 OK:**
```json
{
  "success": true,
  "data": [
    {
      "ticker": "COMI",
      "name": "البنك التجاري الدولي",
      "change_percent": 1.95,
      "volume": 12500000,
      "movement_type": "alive",
      "movement_score": 78,
      "movement_label": "نشط"
    }
  ],
  "count": 245,
  "total_analyzed": 500,
  "source": "data_engine"
}
```

**Fallback chain:**
1. `data_engine.db` `SELECT symbol, name, price, change_percent, volume FROM stocks WHERE price > 0 LIMIT 500`
2. `classifyStockMovement()` per stock (uses change_percent + volume heuristic)
3. If classifier throws → `getTopMovers('EGX', 50)` fallback → `source: "top_movers_fallback"`

**Errors:**
- `404` `{ "error": "Stock not found", "ticker": "..." }` — ticker param not found
- `500` `{ "success": false, "error": "Failed to classify stocks", "detail": "..." }` — both DB and fallback failed

---

#### 14. GET `/api/market/investing`

**الوصف:** بيانات السوق بأسلوب Investing.com - بيستخدم `data_engine.db` (الأصل كان بيعمل scrape من investing.com).

**Auth:** غير مطلوب

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `market` | string | `EGX` | `EGX`, `TADAWUL`, `KSE`, `QSE` |
| `limit` | int | 50 | عدد الأسهم |

**Response 200 OK:**
```json
{
  "success": true,
  "market": "EGX",
  "source": "data_engine",
  "fetched_at": "2026-06-18T17:50:19.000Z",
  "summary": {
    "total_stocks": 858,
    "gainers": 246,
    "losers": 465,
    "unchanged": 147,
    "market_breadth": 28.7
  },
  "top_gainers": [...],
  "top_losers": [...],
  "most_active": [...]
}
```

**Fallback chain:**
1. `data_engine.db` stocks + `getMarketStats(market)` + `getTopMovers(market, min(limit, 20))` → `source: "data_engine"`
2. On error → `getTopMovers('EGX', 10)` → `source: "fallback"` (EGX only)
3. Final → `500` `{ "success": false, "error": "Failed to fetch market data" }`

---

#### 15. GET `/api/mobile/maestro`

**الوصف:** نظام المايسترو - التنسيق والتحليل المتقدم.

**Auth:** غير مطلوب

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `action` | string | `status` | `status`, `signals`, `config`, `personas` |

**Response 200 OK (action=status):**
```json
{
  "success": true,
  "timestamp": "2026-06-18T17:50:19.000Z",
  "status": "active",
  "mode": "balanced",
  "personas": [
    { "id": "conservative", "name": "محافظ", "name_en": "Conservative", "risk_level": 1 },
    { "id": "balanced", "name": "متوازن", "name_en": "Balanced", "risk_level": 2 },
    { "id": "aggressive", "name": "عدواني", "name_en": "Aggressive", "risk_level": 3 }
  ],
  "signals": [],
  "config": { "max_signals_per_day": 10, "min_confidence": 60, "risk_per_trade": 5, "max_open_positions": 5 },
  "last_run": "2026-06-18T17:50:19.000Z",
  "source": "fallback"
}
```

**POST variant:** `POST /api/mobile/maestro` — بيحوّل لـ Python `/api/maestro/run` (timeout 30s).

**Fallback chain:**
1. Python Backend `/api/maestro/{action}` (timeout 15s) → `source: "python_backend"`
2. Default personas + config → `source: "fallback"`. لو `action=signals`، بيقرأ من `egx.db` (`getHeavyDb`) ويصنف إشارات BUY/SELL/HOLD بناءً على change_percent.

---

#### 16. GET `/api/currency`

**الوصف:** أسعار العملات (compatibility endpoint).

**Auth:** غير مطلوب

**Query params:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `action` | string | `list` | `list`, `convert`, etc. |

**Response 200 OK:**
```json
{
  "success": true,
  "rates": [{ "code": "USD", "rate_to_egp": 50.5 }],
  "count": 8,
  "source": "data_engine",
  "timestamp": "2026-06-18T17:50:19.000Z"
}
```

**Fallback chain (3 levels):**
1. Python Backend `/api/currency/{action}` (timeout 8s)
2. `data_engine.db` `getLatestExchangeRates()` → `source: "data_engine"`
3. Empty success → `source: "empty"` مع note `"بيانات العملات غير متاحة حالياً"`

---

#### 17. GET `/api/market/gold`

**الوصف:** أسعار الذهب (compatibility endpoint - نفس `/api/mobile/gold`).

**Auth:** غير مطلوب

**Response 200 OK:**
```json
{
  "success": true,
  "gold_prices": {
    "karat_24": 3756.37,
    "karat_22": 3443.46,
    "karat_21": 3286.82,
    "karat_18": 2817.28,
    "silver": 44.948,
    "last_updated": "2026-06-18 11:32:44"
  },
  "all_countries": { "مصر": { "عيار 24": 3756.37, "عيار 21": 3286.82 }, "السعودية": { "..." : "..." } },
  "source": "data_engine",
  "timestamp": "2026-06-18T17:50:19.000Z"
}
```

**Fallback chain:** Single source — `data_engine.db` (`getLatestGoldPrices`, `getLatestSilverPrices`). بيفلتر `country === 'مصر'` للـ gold_prices وبيرجع كل الدول في `all_countries`.

**Errors:**
- `500` `{ "success": false, "error": "فشل في جلب أسعار الذهب", "gold_prices": null }`

---

### 💳 POST Endpoints (Payments, AI, Backtest)

#### 18. POST `/api/instapay` (Create Payment Request)

**الوصف:** إنشاء طلب دفع InstaPay جديد.

**Auth:** مطلوب (user_id in body)

**Request Body:**
```json
{
  "user_id": "uuid",
  "package_id": "pkg_3",
  "custom_amount": 100
}
```

**Response 200 OK:**
```json
{
  "payment": { "id": "pay_001", "user_id": "uuid", "amount": 85, "points_amount": 1150, "status": "pending", "expires_at": "..." },
  "instapay_link": "https://ipn.eg/S/enmohsen20111975/instapay/0JMx6z",
  "instapay_email": "enmohsen20111975@instapay",
  "instructions": { "ar": ["المبلغ المطلوب: 85 جنيه", "النقاط التي ستستلمها: 1150", "..."] }
}
```

**GET variant:** `GET /api/instapay?user_id=<id>` — بيرجع الإعدادات + packages + pending payments.

**Fallback chain:** Prisma `db.pointsPackage.findMany` — لو مفيش packages، بيرجع 5 default packages (Starter 10 EGP → Ultimate 380 EGP).

---

#### 19. POST `/api/instapay/verify`

**الوصف:** إرسال بيانات التحويل للتحقق (بعد ما المستخدم يحوّل عبر InstaPay).

**Auth:** مطلوب (user_id in body - matching payment.user_id)

**Request Body:**
```json
{
  "payment_id": "pay_001",
  "user_id": "uuid",
  "sender_name": "Ahmed Ali",
  "sender_phone": "01012345678",
  "instapay_ref": "IPX123456789",
  "notes": "تم التحويل من حسابي"
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "message": "تم إرسال بيانات التحويل بنجاح",
  "note": "سيتم مراجعة طلبك وإضافة النقاط خلال دقائق"
}
```

**GET variant:** `GET /api/instapay/verify?admin_id=<id>&status=pending` — للأدمن، بيرجع المدفوعات المعلقة.

**Fallback chain:**
1. Prisma `db.instaPayPayment.findUnique`
2. لو Prisma فشل → `better-sqlite3` direct على `db/auth.db` مع `CREATE TABLE IF NOT EXISTS instaPayPayment`
3. Update عبر Prisma → fallback لـ SQLite raw UPDATE

**Errors:**
- `400` `{ "error": "البيانات غير مكتملة" }` — missing payment_id or user_id
- `403` `{ "error": "غير مصرح" }` — payment.user_id !== body.user_id
- `404` `{ "error": "طلب الدفع غير موجود" }` — payment not found
- `500` `{ "error": "حدث خطأ" }`

---

#### 20. POST `/api/paymob/create-payment`

**الوصف:** إنشاء session دفع Paymob (card payment).

**Auth:** مطلوب (NextAuth session, not Bearer token)

**Request Body:**
```json
{
  "plan_id": "normal|premium",
  "billing_period": "monthly|yearly"
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "payment_url": "https://accept.paymob.com/api/acceptance/iframes/1039291?payment_token=...",
  "order_id": 12345678,
  "merchant_order_id": "GLM-<userId>-normal-1718700000000"
}
```

**Plan prices (EGP piastres):**
| Plan | Monthly | Yearly |
|------|---------|--------|
| `normal` | 9900 (99 EGP) | 99000 (990 EGP) |
| `premium` | 19900 (199 EGP) | 199000 (1990 EGP) |

**Errors:**
- `401` `{ "success": false, "error": "يجب تسجيل الدخول أولاً" }` — no NextAuth session
- `400` `{ "success": false, "error": "الباقة غير صالحة" }` — invalid plan_id
- `404` `{ "success": false, "error": "المستخدم غير موجود" }`
- `500` `{ "success": false, "error": "حدث خطأ أثناء إنشاء عملية الدفع" }`

---

#### 21. POST `/api/subscription/upgrade`

**الوصف:** ترقية الاشتراك - بيولّد JWT payment token وبيوجّه المستخدم لـ `m2y.net/checkout`.

**Auth:** مطلوب (NextAuth session)

**Request Body:**
```json
{
  "plan_id": "normal|premium",
  "billing_period": "monthly|yearly",
  "payment_type": "card|instapay"
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "redirect_url": "https://m2y.net/checkout?token=<jwt>",
  "checkout_url": "https://m2y.net/checkout?token=<jwt>",
  "token": "<jwt>",
  "plan_info": {
    "plan_name": "normal",
    "plan_name_ar": "عادى",
    "price": 99,
    "billing_period": "monthly"
  }
}
```

**Errors:**
- `401` `{ "success": false, "error": "يجب تسجيل الدخول أولاً" }`
- `400` `{ "success": false, "error": "يرجى اختيار باقة" }` — missing plan_id
- `400` `{ "success": false, "error": "الباقة غير موجودة أو غير متاحة" }`
- `400` `{ "success": false, "error": "لا يمكن الترقية للباقة المجانية. استخدم بدء الفترة التجريبية." }`
- `404` `{ "success": false, "error": "المستخدم غير موجود" }`
- `500` `{ "success": false, "error": "حدث خطأ أثناء معالجة الترقية" }`

---

#### 22. POST `/api/ai/chat`

**الوصف:** محادثة مع DeepSeek AI مع memory و web search.

**Auth:** مطلوب (تنفيذي عبر rate limits، شوف [AI Chat APIs](#-ai-chat-apis))

**Request Body:**
```json
{
  "message": "ايه رأيك في سهم COMI؟",
  "context": { "page": "stock_detail", "ticker": "COMI" }
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "reply": "بناءً على تحليلي لسهم COMI...",
  "model": "deepseek-chat",
  "tool_used": "deepseek-v3",
  "confidence": "high",
  "reasoning": null,
  "memory_used": true,
  "response_time_ms": 1250
}
```

شوف التفاصيل الكاملة في قسم [AI Chat APIs](#-ai-chat-apis).

---

#### 23. POST `/api/ai/batch-analysis`

**الوصف:** تحليل دفعي لمجموعة من الأسهم دفعة واحدة.

**Auth:** غير مطلوب (لكن rate-limited)

**Request Body:**
```json
{
  "tickers": ["COMI", "HRHO", "EMGR"],
  "options": {
    "horizon": "short|medium|long",
    "risk_level": "low|medium|high",
    "include_fundamentals": true
  }
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "results": [
    {
      "ticker": "COMI",
      "analysis": "السهم في وضع صاعد قوي مع زخم إيجابي",
      "score": 85,
      "recommendation": "شراء قوي"
    }
  ],
  "source": "python|stub"
}
```

**Fallback chain:**
1. Python Backend `/api/v2/batch-analysis` (timeout 10s) → `source: "python"`
2. Stub per ticker (hash-based deterministic) → `source: "stub"` + message `"تم استخدام ردود افتراضية لأن Python backend غير متاح"`
3. On any error → `success: true` مع `results: []` (200 OK, never 500)

**Stub scoring:**
- score 80-99 → `شراء قوي`
- score 65-79 → `شراء`
- score 50-64 → `تجميع`
- score < 50 → `مراقبة`

**GET variant:** `GET /api/ai/batch-analysis?tickers=COMI,HRHO` — بيرجع stub فقط.

---

#### 24. POST `/api/kimi/backtest/run`

**الوصف:** تشغيل Backtest لاستراتيجية معينة باستخدام Kimi.

**Auth:** غير مطلوب

**Request Body:**
```json
{
  "strategy": "rsi_divergence",
  "start_date": "2024-01-01",
  "end_date": "2024-12-31",
  "initial_capital": 100000,
  "tickers": ["COMI", "HRHO"]
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "results": {
    "total_return": 12.5,
    "win_rate": 65.0,
    "trades_count": 24,
    "equity_curve": [
      { "date": "2024-01-01", "equity": 100000 },
      { "date": "2024-01-02", "equity": 100500 }
    ],
    "strategy": "rsi_divergence",
    "start_date": "2024-01-01",
    "end_date": "2024-12-31",
    "initial_capital": 100000,
    "final_capital": 112500
  },
  "source": "python|stub"
}
```

**Fallback chain:**
1. Python Backend `/api/kimi/backtest/run` (timeout 10s) → `source: "python"`
2. Stub with 30-day flat equity curve → `source: "stub"` + message `"تم استخدام ردود افتراضية لأن خدمة Kimi backtest غير متاحة"`. القيم: `total_return: 0, win_rate: 0, trades_count: 0`.
3. On error → `success: true` مع stub results (200 OK, never 500)

**GET variant:** بيرجع instructions + stub sample.

---

#### 25. POST `/api/walk-forward/run`

**الوصف:** تشغيل Walk-Forward Analysis لاستراتيجية وسهم معين.

**Auth:** غير مطلوب

**Request Body:**
```json
{
  "strategy": "mean_reversion",
  "ticker": "COMI",
  "start_date": "2024-01-01",
  "end_date": "2024-12-31"
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "results": {
    "periods": [
      { "name": "فترة 1", "return": 2.5, "sharpe": 1.2, "drawdown": -3.5 },
      { "name": "فترة 2", "return": -1.0, "sharpe": -0.5, "drawdown": -5.0 }
    ],
    "avg_return": 1.5,
    "sharpe_ratio": 0.8,
    "max_drawdown": -5.0,
    "strategy": "mean_reversion",
    "ticker": "COMI"
  },
  "source": "python|stub"
}
```

**Fallback chain:**
1. Python Backend `/api/walk-forward/run` (timeout 10s) → `source: "python"`
2. Stub with 6 periods of zeros → `source: "stub"`
3. On error → `success: true` مع stub results (200 OK, never 500)

---

#### 26. POST `/api/unified-learning/iterative`

**الوصف:** تشغيل دورة تعلم تكرارية.

**Auth:** غير مطلوب

**Request Body:**
```json
{
  "iterations": 10,
  "learning_rate": 0.01,
  "persona": "balanced",
  "target_win_rate": 75
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "iteration": 10,
  "accuracy": 0.78,
  "loss": 0.42,
  "source": "python|stub"
}
```

**Fallback chain:**
1. Python Backend `/api/unified-learning/iterative` (timeout 10s) → `source: "python"`
2. Stub → `iteration: 0, accuracy: 0.5, loss: 1.0` → `source: "stub"`
3. On error → `success: true` مع stub (200 OK)

---

#### 27. POST `/api/unified-learning/mine-lessons`

**الوصف:** استخراج دروس من فترة زمنية محددة.

**Auth:** غير مطلوب

**Request Body:**
```json
{
  "start_date": "2024-01-01",
  "end_date": "2024-12-31",
  "min_confidence": 0.5
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "lessons": [
    {
      "pattern": "rsi_oversold_bounce",
      "success_rate": 78.5,
      "examples_count": 24
    }
  ],
  "source": "python|stub"
}
```

**Fallback chain:**
1. Python Backend `/api/unified-learning/mine-lessons` (timeout 10s) → `source: "python"`
2. Stub → `lessons: []` → `source: "stub"`
3. On error → `success: true` مع `lessons: []` (200 OK)

---

#### 28. POST `/api/auth/login`

**الوصف:** تسجيل دخول الموبايل - بيرجع Bearer token.

**Auth:** غير مطلوب (هذا هو endpoint الـ login)

**Request Body:**
```json
{
  "username_or_email": "user@example.com",
  "password": "password123"
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "message": "Login successful",
  "message_ar": "تم تسجيل الدخول بنجاح",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "username",
    "name": "User Name",
    "image": null,
    "subscription_tier": "free",
    "is_admin": false
  },
  "token": "egx_<user_id>_<uuid>_<timestamp>",
  "token_type": "Bearer",
  "expires_in": 2592000
}
```

**Token format:** `egx_<user_id>_<uuid>_<timestamp>` — بيتبعت في `Authorization: Bearer <token>` لكل الـ endpoints المحتاجة auth.

**Token expiry:** 30 days (2,592,000 seconds)

**Errors:**
- `400` `{ "success": false, "error": "اسم المستخدم أو البريد الإلكتروني مطلوب" }` — missing field
- `400` `{ "success": false, "error": "كلمة المرور مطلوبة" }` — missing password
- `401` `{ "success": false, "error": "المستخدم غير موجود" }` — user not found
- `401` `{ "success": false, "error": "كلمة المرور غير صحيحة" }` — wrong password
- `401` `{ "success": false, "error": "يرجى تسجيل الدخول عبر جوجل" }` — Google-only account
- `403` `{ "success": false, "error": "الحساب غير مفعل" }` — inactive
- `503` `{ "success": false, "error": "قاعدة البيانات غير متاحة حالياً" }` — DB error
- `500` `{ "success": false, "error": "حدث خطأ أثناء تسجيل الدخول" }`

---

#### 29. POST `/api/auth/register`

**الوصف:** تسجيل مستخدم جديد.

**Auth:** غير مطلوب

**Request Body:**
```json
{
  "email": "user@example.com",
  "username": "username",
  "password": "password123",
  "risk_tolerance": "low|medium|high"
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "message": "تم إنشاء الحساب بنجاح",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "username",
    "default_risk_tolerance": "medium"
  },
  "api_key": "egx_<user_id>_<timestamp>"
}
```

**Validation:**
- email: required (string)
- username: required (string, ≥ 3 chars)
- password: required (string, ≥ 8 chars)

**Errors:**
- `400` `{ "success": false, "error": "<field> مطلوب" }` — missing field
- `400` `{ "success": false, "error": "اسم المستخدم يجب أن يكون 3 أحرف على الأقل" }`
- `400` `{ "success": false, "error": "كلمة المرور يجب أن تكون 8 أحرف على الأقل" }`
- `409` `{ "success": false, "error": "البريد الإلكتروني مستخدم بالفعل" }`
- `409` `{ "success": false, "error": "اسم المستخدم مستخدم بالفعل" }`
- `503` `{ "success": false, "error": "قاعدة البيانات غير متاحة حالياً. يرجى المحاولة لاحقاً." }` — DB connection failed
- `500` `{ "success": false, "error": "حدث خطأ أثناء إنشاء الحساب" }`

---

#### 30. POST `/api/auth/google`

**الوصف:** تسجيل دخول الموبايل عبر Google ID Token.

**Auth:** غير مطلوب

**Request Body:**
```json
{
  "id_token": "google_id_token_from_sdk"
}
```

**Response 200 OK:**
```json
{
  "success": true,
  "message": "Google login successful",
  "message_ar": "تم تسجيل الدخول عبر جوجل بنجاح",
  "user": {
    "id": "uuid",
    "email": "user@gmail.com",
    "username": "user",
    "name": "User Name",
    "image": "https://lh3.google...",
    "subscription_tier": "free",
    "is_admin": false
  },
  "token": "egx_<user_id>_<uuid>_<timestamp>",
  "token_type": "Bearer",
  "expires_in": 2592000,
  "is_new_user": false
}
```

**Verification:**
- بيستخدم Google OAuth `https://oauth2.googleapis.com/tokeninfo?id_token=...`
- بيقبل Web Client ID (`GOOGLE_CLIENT_ID`) أو أي من `GOOGLE_ANDROID_CLIENT_IDS` (comma-separated)

**Errors:**
- `400` `{ "success": false, "error": "Google ID token مطلوب" }` — missing id_token
- `400` `{ "success": false, "error": "لم يتم العثور على بريد إلكتروني" }` — no email in token
- `401` `{ "success": false, "error": "فشل التحقق من Google token", "error_en": "..." }` — verification failed
- `403` `{ "success": false, "error": "الحساب غير مفعل" }` — inactive user
- `500` `{ "success": false, "error": "حدث خطأ أثناء تسجيل الدخول عبر جوجل", "error_en": "..." }`

---

## 🔐 Authentication Requirements

> **مرجع سريع:** كل الـ endpoints مقسّمة لـ 3 مجموعات بناءً على نوع الـ auth المطلوب.

### 🟢 Free (No Auth Required)

الـ endpoints دي بتشتغل من غير token، أي حد ممكن يطلبها. مفياش حد أقصى للمستخدمين المجانيين على مستوى الـ API (الحدود بتكون على مستوى الـ rate limit العام).

| Endpoint | Method | Quota |
|----------|--------|-------|
| `/api/mobile/dashboard` | GET | — |
| `/api/mobile/market/overview` | GET | — |
| `/api/mobile/recommendations` | GET | ⚠️ لا يوجد حد 3 عناصر إجباري — العميل يبعت `limit=3` |
| `/api/mobile/predictions` | GET | ⚠️ لا يوجد حد 3 عناصر إجباري — العميل يبعت `limit=3` |
| `/api/mobile/news` | GET | — |
| `/api/mobile/gold` | GET | — |
| `/api/mobile/currency` | GET | — |
| `/api/mobile/stocks/[ticker]` | GET | — |
| `/api/mobile/market/recommendations/ai-insights` | GET | — |
| `/api/mobile/maestro` | GET/POST | — |
| `/api/predictions` | GET/POST | — |
| `/api/stocks/movement-classification` | GET | — |
| `/api/market/investing` | GET | — |
| `/api/market/gold` | GET | — |
| `/api/market/overview` | GET | — |
| `/api/currency` | GET | — |
| `/api/stocks` | GET | — |
| `/api/stocks/[ticker]` | GET | — |
| `/api/health` | GET | — |
| `/api/ai/batch-analysis` | POST/GET | rate-limited |
| `/api/kimi/backtest/run` | POST/GET | rate-limited (stub fallback) |
| `/api/walk-forward/run` | POST/GET | rate-limited (stub fallback) |
| `/api/unified-learning/iterative` | POST/GET | rate-limited (stub fallback) |
| `/api/unified-learning/mine-lessons` | POST/GET | rate-limited (stub fallback) |

### 🔒 Bearer Token Required (401 لو مفيش token)

الـ endpoints دي بترجع `401 Unauthorized` لو الـ `Authorization: Bearer <token>` header مش موجود أو الـ token منتهي/غير صالح.

| Endpoint | Method | Notes |
|----------|--------|-------|
| `/api/auth/me` | GET | بيانات المستخدم الحالي |
| `/api/mobile/portfolio` | GET/POST/DELETE | محفظة المستخدم (stocks, gold, certificates) |
| `/api/mobile/alerts/settings` | GET/POST/DELETE | إعدادات التنبيهات |
| `/api/mobile/notifications` | GET/POST | الإشعارات (بترجع empty لو مفيش token، مش 401 — هذه ملاحظة مهمة) |
| `/api/watchlist` | GET/POST | قائمة المراقبة |
| `/api/watchlist/[id]` | DELETE | حذف من القائمة |
| `/api/portfolio` | GET/POST | محفظة الويب |
| `/api/subscription/current` | GET | الاشتراك الحالي |
| `/api/subscription/check-access` | GET | فحص الصلاحيات |

**Token format:** `egx_<user_id>_<uuid>_<timestamp>` (يتولّد من `/api/auth/login` أو `/api/auth/google`).
**Expiry:** 30 يوم (2,592,000 ثانية).
**Storage:** في Prisma `api_tokens` table.

### 🍪 NextAuth Session Required (Not Bearer)

الـ endpoints دي بتستخدم NextAuth session (cookie-based)، مش Bearer token. مهمين للويب مش للموبايل.

| Endpoint | Method | Notes |
|----------|--------|-------|
| `/api/paymob/create-payment` | POST | إنشاء دفع Paymob |
| `/api/subscription/upgrade` | POST | ترقية الاشتراك |
| `/api/subscription/activate` | POST | تفعيل الاشتراك |
| `/api/subscription/start-trial` | POST | بدء فترة تجريبية |
| `/api/subscription/deactivate` | POST | إلغاء الاشتراك |
| `/api/admin/*` | GET/POST | كل endpoints الأدمن |

> 📱 **للموبايل:** استخدم `/api/auth/login` أو `/api/auth/google` للحصول على Bearer token، وبعدين استخدمه في كل الطلبات. الـ NextAuth session endpoints دي للويب بس.

### 🔑 Body-Based Auth (user_id in body)

الـ endpoints دي بتعتمد على `user_id` في الـ body (مش الـ header). مهمة للـ InstaPay flow.

| Endpoint | Method | Notes |
|----------|--------|-------|
| `/api/instapay` | POST | إنشاء طلب دفع (user_id + package_id) |
| `/api/instapay/verify` | POST | التحقق من التحويل (user_id + payment_id) — لازم يطابق payment.user_id |

> ⚠️ **تحذير أمان:** الـ body-based auth أقل أماناً من الـ Bearer token. يُفضّل ترحيل الـ InstaPay endpoints لاستخدام Bearer token في Phase قادمة.

### 🔑 Admin Required (subscription_tier = 'admin')

الـ endpoints دي بترجع `403 Forbidden` لو المستخدم مش admin.

| Endpoint | Method | Notes |
|----------|--------|-------|
| `/api/admin/*` | GET/POST | كل endpoints الأدمن |
| `/api/instapay/verify?admin_id=...` | GET | جلب المدفوعات المعلقة |
| `/api/instapay/approve` | POST | اعتماد InstaPay يدوياً |

**Admin check:** `user.subscription_tier === 'admin'`

---

## 🔔 Alerts & Notifications APIs

### 1. GET `/api/mobile/notifications` — الإشعارات

**Headers:** `Authorization: Bearer <token>`

**Response 200 OK:**
```json
{
  "success": true,
  "notifications": [
    {
      "id": "alert_above_5",
      "type": "price_alert",
      "title": "تنبيه سعر",
      "message": "البنك التجاري الدولي وصل للسعر المستهدف 70",
      "ticker": "COMI",
      "created_at": "2026-01-15T14:30:00.000Z",
      "read": false
    },
    {
      "id": "system_welcome",
      "type": "system",
      "title": "مرحباً بك",
      "message": "أهلاً بك في منصة الاستثمار",
      "created_at": "2026-01-15T14:30:00.000Z",
      "read": false
    }
  ],
  "unread_count": 2
}
```

---

### 2. POST `/api/mobile/notifications` — تحديث حالة الإشعارات

**Request Body:**
```json
{
  "notification_id": "alert_above_5",
  "mark_all_read": false
}
```

أو للمسح الكلي:
```json
{ "mark_all_read": true }
```

---

### 3. GET `/api/mobile/alerts/settings` — إعدادات التنبيهات

**Headers:** `Authorization: Bearer <token>`

**Response 200 OK:**
```json
{
  "success": true,
  "settings": [
    {
      "id": "alert_001",
      "ticker": "COMI",
      "alert_type": "price_above",
      "target_value": 70.00,
      "is_active": true,
      "notify_push": true,
      "notify_email": false,
      "created_at": "2026-01-10 10:00:00",
      "triggered_at": null
    }
  ],
  "recent_alerts": [
    {
      "id": "alert_hist_001",
      "ticker": "COMI",
      "alert_type": "price_above",
      "message": "COMI وصل لـ 70",
      "message_ar": "البنك التجاري الدولي وصل للسعر 70",
      "current_value": 70.5,
      "target_value": 70,
      "sent_at": "2026-01-15 14:30:00",
      "is_read": false
    }
  ],
  "alert_types": [
    { "type": "price_above", "name": "السعر أعلى من", "needs_value": true, "value_type": "price" },
    { "type": "price_below", "name": "السعر أقل من", "needs_value": true, "value_type": "price" },
    { "type": "change_percent_up", "name": "صعود بنسبة %", "needs_value": true, "value_type": "percent" },
    { "type": "change_percent_down", "name": "هبوط بنسبة %", "needs_value": true, "value_type": "percent" },
    { "type": "rsi_overbought", "name": "RSI تشبع شرائي", "needs_value": false, "value_type": null },
    { "type": "rsi_oversold", "name": "RSI تشبع بيعي", "needs_value": false, "value_type": null },
    { "type": "signal_buy", "name": "إشارة شراء", "needs_value": false, "value_type": null },
    { "type": "signal_sell", "name": "إشارة بيع", "needs_value": false, "value_type": null },
    { "type": "support_break", "name": "كسر الدعم", "needs_value": false, "value_type": null },
    { "type": "resistance_break", "name": "كسر المقاومة", "needs_value": false, "value_type": null }
  ]
}
```

---

### 4. POST `/api/mobile/alerts/settings` — إنشاء تنبيه

**Request Body:**
```json
{
  "ticker": "COMI",
  "alert_type": "price_above",
  "target_value": 70.00,
  "notify_push": true,
  "notify_email": false
}
```

**Response 201:**
```json
{
  "success": true,
  "alert": {
    "id": "alert_1705312200000_abc123",
    "ticker": "COMI",
    "alert_type": "price_above",
    "target_value": 70.00,
    "notify_push": true,
    "notify_email": false
  },
  "message": "تم إنشاء التنبيه بنجاح"
}
```

---

### 5. DELETE `/api/mobile/alerts/settings?id=<alert_id>` — حذف تنبيه

**Response 200:**
```json
{ "success": true, "message": "تم حذف التنبيه" }
```

---

### 6. GET `/api/mobile/alerts/check` — فحص التنبيهات

**الوصف:** بيتـ فحص هل في تنبيهات trigger.

---

## 📚 Learning APIs

### 1. GET `/api/learning/content` — محتوى تعليمي

**Response 200 OK:**
```json
{
  "success": true,
  "content": {
    "categories": [
      {
        "id": "basics",
        "title": "أساسيات الاستثمار",
        "title_en": "Investment Basics",
        "icon": "📚",
        "lessons": [
          {
            "id": "what-is-stock",
            "title": "ما هو السهم؟",
            "title_en": "What is a Stock?",
            "duration_minutes": 10,
            "difficulty": "beginner",
            "completed": false
          }
        ]
      },
      {
        "id": "technical-analysis",
        "title": "التحليل الفني",
        "title_en": "Technical Analysis",
        "icon": "📊",
        "lessons": [
          {
            "id": "candlestick-patterns",
            "title": "أنماط الشموع اليابانية",
            "title_en": "Candlestick Patterns",
            "duration_minutes": 20,
            "difficulty": "intermediate",
            "completed": false
          }
        ]
      },
      {
        "id": "fundamental-analysis",
        "title": "التحليل الأساسي",
        "title_en": "Fundamental Analysis",
        "icon": "📈",
        "lessons": [...]
      },
      {
        "id": "portfolio-management",
        "title": "إدارة المحفظة",
        "title_en": "Portfolio Management",
        "icon": "💼",
        "lessons": [...]
      },
      {
        "id": "crypto",
        "title": "العملات الرقمية",
        "title_en": "Cryptocurrency",
        "icon": "₿",
        "lessons": [...]
      }
    ],
    "total_lessons": 20,
    "total_duration_minutes": 302
  },
  "timestamp": "2026-01-15T14:30:00.000Z"
}
```

---

### 2. GET `/api/learning/progress` — تقدم المستخدم

**Headers:** `Authorization: Bearer <token>`

---

### 3. POST `/api/learning/progress` — تحديث التقدم

**Request Body:**
```json
{
  "lesson_id": "what-is-stock",
  "completed": true,
  "progress_percent": 100
}
```

---

### 4. GET `/api/mobile/learning` — محتوى تعليمي (mobile)

---

## ⚙️ Admin APIs (brief)

الـ Admin APIs للمشرفين فقط - مش مطلوبة من الـ mobile app لكن مذكورة هنا للكمال.

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/admin/auth` | POST | Login للأدمن |
| `/api/admin/stats` | GET | إحصائيات عامة |
| `/api/admin/analytics` | GET | تحليلات الموقع |
| `/api/admin/users` | GET | قائمة المستخدمين |
| `/api/admin/users/[id]` | GET/DELETE | تفاصيل/حذف مستخدم |
| `/api/admin/recommendations` | GET/POST | إدارة التوصيات |
| `/api/admin/market-status` | GET | حالة السوق |
| `/api/admin/db-health` | GET | صحة قواعد البيانات |
| `/api/admin/data-sources` | GET | مصادر البيانات |
| `/api/admin/currency` | POST | تحديث العملات |
| `/api/admin/gold` | POST | تحديث أسعار الذهب |
| `/api/admin/sync-vps` | POST | مزامنة VPS |
| `/api/admin/subscription/seed` | POST | تهيئة خطط الاشتراك |
| `/api/admin/subscription/set-plan` | POST | تعديل خطة مستخدم |
| `/api/admin/generate-predictions` | POST | توليد توقعات |
| `/api/admin/clean-predictions` | POST | تنظيف التوقعات |
| `/api/admin/clear-predictions` | POST | مسح التوقعات |
| `/api/admin/clear-junk-data` | POST | مسح البيانات الزائفة |
| `/api/admin/scrape-stocks` | POST | سحب الأسهم |
| `/api/admin/sync-fundamentals` | POST | مزامنة الأساسيات |
| `/api/admin/import-data` | POST | استيراد بيانات |
| `/api/admin/export-data` | GET | تصدير بيانات |
| `/api/admin/export-vps` | GET | تصدير من VPS |
| `/api/admin/fix-dates` | POST | إصلاح التواريخ |
| `/api/admin/recommendation-settings` | GET/POST | إعدادات التوصيات |
| `/api/admin/monitor` | GET | مراقبة النظام |
| `/api/admin/daily-analysis` | POST | تحليل يومي |
| `/api/admin/sync-stocks-db` | POST | مزامنة DB الأسهم |
| `/api/admin/import-stocks` | POST | استيراد أسهم |
| `/api/admin/import-egxpilot` | POST | استيراد EGXPilot |
| `/api/admin/import-snapshot` | POST | استيراد snapshot |
| `/api/admin/advanced-analysis/config` | GET/POST | إعدادات التحليل |
| `/api/admin/advanced-analysis/run` | POST | تشغيل تحليل |
| `/api/admin/ai-predictions/generate` | POST | توليد توقعات AI |
| `/api/admin/ai-predictions/evaluate-range` | POST | تقييم توقعات |
| `/api/admin/historical-backfill/run` | POST | backfill تاريخي |
| `/api/admin/historical-backfill/status` | GET | حالة backfill |
| `/api/admin/historical-backfill/results` | GET | نتائج backfill |
| `/api/admin/generate-historical-predictions` | POST | توقعات تاريخية |

---

## ❌ Error Handling

### Standard Error Format

كل الـ errors بتتبع نفس الـ format:

```json
{
  "success": false,
  "error": "الرسالة بالعربي",
  "error_en": "Message in English (optional)",
  "details": "Technical details (optional, dev only)"
}
```

### HTTP Status Codes

| Code | Description | When |
|------|-------------|------|
| `200` | OK | طلب ناجح |
| `201` | Created | إنشاء ناجح (POST register) |
| `400` | Bad Request | بيانات ناقصة أو صيغة خاطئة |
| `401` | Unauthorized | Token مفقود، غير صالح، أو منتهي |
| `403` | Forbidden | الحساب غير مفعل أو الصلاحية غير كافية |
| `404` | Not Found | السهم أو المصدر غير موجود |
| `409` | Conflict | البريد الإلكتروني أو اسم المستخدم مستخدم |
| `429` | Too Many Requests | تجاوز rate limit |
| `500` | Internal Server Error | خطأ في السيرفر |
| `502` | Bad Gateway | Python Backend unreachable |
| `503` | Service Unavailable | قاعدة البيانات غير متاحة |
| `504` | Gateway Timeout | انتهت مهلة الطلب للـ Python Backend |

### Common Error Examples

**401 - Token Expired:**
```json
{
  "success": false,
  "error": "Token منتهي الصلاحية",
  "error_en": "Token expired"
}
```

**400 - Validation Error:**
```json
{
  "success": false,
  "error": "كلمة المرور يجب أن تكون 8 أحرف على الأقل"
}
```

**502 - Python Backend Down:**
```json
{
  "success": false,
  "error": "فشل في الاتصال بـ Python Backend",
  "details": "fetch failed",
  "is_connection_error": true,
  "python_backend_url": "http://localhost:8010"
}
```

**504 - Timeout:**
```json
{
  "success": false,
  "error": "انتهت مهلة الطلب - Python Backend يستغرق وقتاً طويلاً",
  "is_timeout": true
}
```

### Mobile Error Handling Strategy

```
- 401 → امسح token, روح لـ login screen
- 403 → اعرض "الحساب غير مفعل"
- 404 → اعرض "غير موجود"
- 429 → اعرض "محاولات كتيرة, حاول بعد دقيقة" + retry after 60s
- 500 → اعرض "خطأ في السيرفر" + retry 3 مرات
- 502 → اعرض "خدمة التحليل غير متاحة" + retry 5 دقايق
- 503 → اعرض "قاعدة البيانات غير متاحة" + retry 1 دقيقة
- 504 → اعرض "انتهت المهلة" + retry 10 ثواني
```

---

## ⏱️ Rate Limits & Timeouts

### Server-Side Timeouts

| Endpoint Type | Timeout |
|---------------|---------|
| Auth endpoints | 30s |
| Stock list / detail | 15s |
| Chart data (Python) | 15s |
| AI analysis | 60s |
| AI chat (DeepSeek V3) | 30s |
| AI chat (DeepSeek R1) | 120s |
| Hunter screener | 30s |
| Advanced analysis | 60s |
| Python proxy (general) | 120s |
| Predictions generation | 120s |

### Recommended Mobile Timeouts

| Request Type | Suggested Timeout |
|--------------|-------------------|
| Quick GET (auth/me, stocks list) | 10s |
| Detail GET (stock detail, chart) | 15s |
| POST (login, register) | 30s |
| AI chat | 60s (with progress) |
| File upload | 120s |
| Polling (live prices) | 5s |

### Rate Limits

- **Anonymous:** 60 requests/minute
- **Authenticated:** 300 requests/minute
- **Premium:** 1000 requests/minute
- **AI chat:** 20 messages/minute per user

### 🆓 Free User Quotas & Limits

الـ quotas دي خاصة بـ free tier (`subscription_tier === 'free'`). مهمة لمطوري الموبايل عشان يعرفوا الحدود.

| Resource | Free Tier | Normal Tier | Premium Tier |
|----------|-----------|-------------|--------------|
| Watchlist items | 5 | 25 | 100 |
| Portfolio positions | 1 | 10 | 50 |
| Active alerts | 3 | 15 | 50 |
| AI analysis per day | 0 (blocked) | 20 | unlimited |
| Deep analysis (R1) | 0 (blocked) | 5/day | unlimited |
| Priority support | ❌ | ❌ | ✅ |
| Predictions export PDF | ❌ | ✅ | ✅ |
| Multi-market data | EGX only | EGX + TADAWUL | All 7 markets |

#### ⚠️ مهم: حدود الـ Mobile Endpoints

**`/api/mobile/recommendations` و `/api/mobile/predictions`** — الكود الحالي **لا يفرض** حد 3 عناصر إجباري على المستخدم المجاني. العميل (Flutter/React Native) لازم يبعت `limit=3` بنفسه:

```dart
// ✅ صح: حد صريح 3 عناصر للمستخدم المجاني
final response = await http.get(
  Uri.parse('$baseUrl/api/mobile/recommendations?limit=3'),
);

// ❌ غلط: الكود بيرجع 10 افتراضياً (مش 3)
final response = await http.get(
  Uri.parse('$baseUrl/api/mobile/recommendations'),
);
```

> 📌 **التوصية:** يُفضّل إضافة middleware للسيرفر يفرض `limit=3` على free users تلقائياً في Phase قادمة.

#### 🚫 Endpoints المحجوبة عن Free Users

الـ endpoints دي بترجع `403 Forbidden` للمستخدمين المجانيين (لو الـ auth middleware شغّال):

- `/api/advanced-analysis` (deep analysis)
- `/api/ai/chat` (لو `subscription_tier === 'free'` — لكن الكود الحالي مش بيفرض ده، اعتماداً على rate limits)
- `/api/predictions/export-pdf`
- `/api/finance/smart-confluence` (لو اتحطت ورا paywall)
- Multi-market data لـ TADAWUL/KSE/QSE (لو فعلتها)

### Recommended Mobile Polling Intervals

| Use Case | Interval | Endpoint |
|----------|----------|----------|
| Live prices (market open) | 5 min | `/api/mobile/dashboard` |
| Live prices (market closed) | 30 min | `/api/mobile/dashboard` |
| Stock detail (open) | 1 min | `/api/stocks/{ticker}?live=1` |
| Stock detail (closed) | 5 min | `/api/stocks/{ticker}` |
| Chart data | 5 min | `/api/chart/{ticker}?period=1d` |
| News feed | 5 min | `/api/mobile/news` |
| Notifications | 30 sec | `/api/mobile/notifications` |
| Subscription status | 5 sec (after payment) | `/api/subscription/current` |

---

## 📝 Common JSON Schemas

### User Object

```json
{
  "id": "uuid",
  "email": "user@example.com",
  "username": "username",
  "name": "User Name",
  "image": "https://...|null",
  "subscription_tier": "free|normal|premium|admin",
  "default_risk_tolerance": "low|medium|high",
  "is_admin": false,
  "is_active": true,
  "email_verified": true,
  "last_login": "ISO8601|null",
  "created_at": "ISO8601"
}
```

### Stock Object

```json
{
  "ticker": "COMI",
  "name": "Commercial International Bank",
  "name_ar": "البنك التجاري الدولي",
  "market": "EGX|TADAWUL|KSE|QSE|DFM|ADX|BSE",
  "sector": "Banks|Real Estate|...",
  "current_price": 65.45,
  "previous_close": 64.20,
  "open": 64.50,
  "high": 65.80,
  "low": 64.30,
  "volume": 12500000,
  "market_cap": 132500000000,
  "pe_ratio": 5.8,
  "pb_ratio": 1.2,
  "dividend_yield": 4.5,
  "eps": 11.28,
  "change_percent": 1.95,
  "is_egx30": 1,
  "is_egx70": 0,
  "is_egx100": 1
}
```

### Prediction Object

```json
{
  "id": "pred_001",
  "symbol": "COMI",
  "market": "EGX",
  "signal": "STRONG_BUY|BUY|ACCUMULATE|HOLD|REDUCE|SELL|STRONG_SELL",
  "confidence": 85,
  "entry_price": 65.45,
  "target_price": 72.00,
  "stop_loss": 62.00,
  "reasoning": "text",
  "indicators": {
    "rsi": 58.4,
    "macd": "bullish",
    "ma_trend": "uptrend"
  },
  "news_summary": "text",
  "created_at": "ISO8601",
  "verify_date": "YYYY-MM-DD",
  "verified": false,
  "result": "SUCCESS|FAIL|null",
  "final_price": 72.50|null,
  "profit_loss_pct": 10.8|null
}
```

### Recommendation Object

```json
{
  "ticker": "COMI",
  "name_ar": "البنك التجاري الدولي",
  "current_price": 65.45,
  "score": 85,
  "recommendation": "strong_buy|buy|hold|sell|strong_sell",
  "confidence": 85,
  "signals": ["positive_momentum", "high_liquidity"],
  "target_price": 75.27,
  "stop_loss": 60.21,
  "risk_reward": 2.18
}
```

### News Item

```json
{
  "id": "egx-123",
  "title": "title text",
  "summary": "summary text",
  "source": "EGXPilot|CoinGecko|Alternative.me",
  "timestamp": "ISO8601",
  "category": "egx|crypto|sentiment|market",
  "importance": "high|medium|low",
  "url": "https://...|null",
  "tickers": ["COMI"]
}
```

### Subscription Plan

```json
{
  "id": "free|normal|premium",
  "name": "free|normal|premium",
  "name_ar": "مجانى|عادى|مميز",
  "price": 0,
  "price_yearly": 0,
  "trial_days": 0,
  "features": ["feature1", "feature2"],
  "max_watchlist": 5,
  "max_portfolio": 1,
  "max_alerts": 3,
  "ai_analysis": false,
  "deep_analysis": false,
  "priority_support": false
}
```

---

## 🚀 Mobile Integration Guide

### 1. 🔐 Login Flow & Token Storage

**Pseudocode (Flutter):**

```dart
// 1. Login
final response = await http.post(
  Uri.parse('$baseUrl/api/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'username_or_email': email,
    'password': password,
  }),
);

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  final token = data['token'];
  
  // 2. Store in Secure Storage
  await FlutterSecureStorage().write(
    key: 'auth_token',
    value: token,
  );
  
  // 3. Store user info
  await Hive.box('user').put('user', data['user']);
  
  // 4. Navigate to home
  Navigator.pushReplacementNamed(context, '/home');
}
```

**Pseudocode (Android - Kotlin):**

```kotlin
// 1. Login
val response = api.login(LoginRequest(email, password))

if (response.isSuccessful) {
    val token = response.body()?.token
    
    // 2. Store in EncryptedSharedPreferences
    val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()
    
    val sharedPreferences = EncryptedSharedPreferences.create(
        context,
        "secret_shared_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )
    
    sharedPreferences.edit().putString("auth_token", token).apply()
}
```

**Token Validation on App Start:**

```dart
Future<bool> validateToken() async {
  final token = await FlutterSecureStorage().read(key: 'auth_token');
  if (token == null) return false;
  
  final response = await http.get(
    Uri.parse('$baseUrl/api/mobile/auth/me'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      // Token valid, update user info
      await Hive.box('user').put('user', data['user']);
      return true;
    }
  }
  
  // 401 - clear token
  await FlutterSecureStorage().delete(key: 'auth_token');
  return false;
}
```

---

### 2. 📊 Stocks List Pagination

```dart
class StocksService {
  int _currentPage = 1;
  final int _pageSize = 50;
  bool _hasMore = true;
  List<Stock> _stocks = [];
  
  Future<List<Stock>> fetchFirstPage({String? market}) async {
    _currentPage = 1;
    _stocks = [];
    _hasMore = true;
    return _fetchPage(market: market);
  }
  
  Future<List<Stock>> fetchNextPage({String? market}) async {
    if (!_hasMore) return _stocks;
    _currentPage++;
    return _fetchPage(market: market);
  }
  
  Future<List<Stock>> _fetchPage({String? market}) async {
    final queryParams = {
      'page': _currentPage.toString(),
      'limit': _pageSize.toString(),
    };
    if (market != null) queryParams['market'] = market;
    
    final uri = Uri.parse('$baseUrl/api/stocks')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(uri, headers: _authHeaders());
    final data = jsonDecode(response.body);
    
    final newStocks = (data['stocks'] as List)
        .map((s) => Stock.fromJson(s))
        .toList();
    
    _stocks.addAll(newStocks);
    
    // Check if more pages
    final total = data['total'] as int;
    _hasMore = _stocks.length < total;
    
    return _stocks;
  }
}
```

**Usage with ScrollController:**

```dart
ScrollController _scrollController = ScrollController();

@override
void initState() {
  super.initState();
  _scrollController.addListener(() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      _loadMore();  // fetch next page
    }
  });
  _loadFirstPage();
}
```

---

### 3. 📈 Live Prices Polling

```dart
class LivePricesService {
  Timer? _timer;
  final StreamController<List<Stock>> _controller = 
      StreamController.broadcast();
  
  Stream<List<Stock>> get pricesStream => _controller.stream;
  
  void startPolling() async {
    // Get market status first
    final marketStatus = await _fetchMarketStatus();
    final isOpen = marketStatus['is_market_hours'] as bool;
    
    // Poll based on market status
    final interval = isOpen ? Duration(minutes: 5) : Duration(minutes: 30);
    
    _timer = Timer.periodic(interval, (_) async {
      final stocks = await _fetchDashboardTopMovers();
      _controller.add(stocks);
    });
  }
  
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }
  
  Future<List<Stock>> _fetchDashboardTopMovers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/mobile/dashboard'),
      headers: _authHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final topMovers = data['top_movers'];
      return [
        ...(topMovers['gainers'] as List).map((s) => Stock.fromJson(s)),
        ...(topMovers['losers'] as List).map((s) => Stock.fromJson(s)),
      ];
    }
    return [];
  }
}
```

**Usage in Home Screen:**

```dart
@override
void initState() {
  super.initState();
  LivePricesService().startPolling();
  LivePricesService().pricesStream.listen((stocks) {
    setState(() {
      _liveStocks = stocks;
    });
  });
}

@override
void dispose() {
  LivePricesService().stopPolling();
  super.dispose();
}
```

---

### 4. 💾 Mobile Caching Strategy

**Three-tier caching:**

```dart
class CacheManager {
  // Tier 1: Memory (instant access)
  final Map<String, CacheEntry> _memoryCache = {};
  
  // Tier 2: Disk (Hive boxes)
  final Box _diskCache = Hive.box('api_cache');
  
  // Tier 3: Network
  final http.Client _client = http.Client();
  
  Future<dynamic> get(String endpoint, {Duration? ttl}) async {
    final cacheKey = endpoint;
    final effectiveTtl = ttl ?? Duration(minutes: 5);
    
    // Check memory
    if (_memoryCache.containsKey(cacheKey)) {
      final entry = _memoryCache[cacheKey]!;
      if (DateTime.now().difference(entry.timestamp) < effectiveTtl) {
        return entry.data;
      }
    }
    
    // Check disk
    final diskData = _diskCache.get(cacheKey);
    if (diskData != null) {
      final entry = CacheEntry.fromJson(diskData);
      if (DateTime.now().difference(entry.timestamp) < effectiveTtl) {
        _memoryCache[cacheKey] = entry;
        return entry.data;
      }
    }
    
    // Fetch from network
    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _authHeaders(),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final entry = CacheEntry(
        data: data,
        timestamp: DateTime.now(),
      );
      
      // Save to both caches
      _memoryCache[cacheKey] = entry;
      await _diskCache.put(cacheKey, entry.toJson());
      
      return data;
    }
    
    // Return stale cache if available
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!.data;
    }
    if (diskData != null) {
      return CacheEntry.fromJson(diskData).data;
    }
    
    throw Exception('Failed to fetch: ${response.statusCode}');
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  
  CacheEntry({required this.data, required this.timestamp});
  
  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    data: json['data'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}
```

**Recommended Cache TTLs:**

| Endpoint | TTL | Reason |
|----------|-----|--------|
| `/api/auth/me` | 1 hour | User data rarely changes |
| `/api/stocks` (list) | 5 min | Prices update, but list stable |
| `/api/stocks/{ticker}` | 1 min | Live prices during market |
| `/api/stocks/{ticker}/history` | 1 hour | Daily history stable |
| `/api/chart/{ticker}` | 5 min | Intraday updates |
| `/api/mobile/dashboard` | 5 min | Aggregated data |
| `/api/mobile/news` | 5 min | Server-side cache 5 min |
| `/api/predictions` | 1 hour | New predictions daily |
| `/api/subscription/plans` | 24 hours | Plans rarely change |
| `/api/subscription/current` | 1 min | After payment, refresh |

---

### 5. 🔄 Error Handling & Retries

```dart
class ApiClient {
  final http.Client _client;
  
  Future<ApiResponse> request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      attempt++;
      
      try {
        final response = await _client
            .send(http.Request(method, Uri.parse('$baseUrl$endpoint'))
              ..headers.addAll(_authHeaders())
              ..body = body != null ? jsonEncode(body) : '')
            .timeout(Duration(seconds: 15));
        
        // Success
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(await response.stream.bytesToString());
          return ApiResponse(success: true, data: data);
        }
        
        // Auth errors - no retry
        if (response.statusCode == 401 || response.statusCode == 403) {
          await _handleAuthError(response.statusCode);
          return ApiResponse(
            success: false, 
            error: 'Authentication error',
            statusCode: response.statusCode,
          );
        }
        
        // Client errors (4xx) - no retry
        if (response.statusCode >= 400 && response.statusCode < 500) {
          return ApiResponse(
            success: false,
            error: 'Client error: ${response.statusCode}',
            statusCode: response.statusCode,
          );
        }
        
        // Server errors (5xx) - retry with exponential backoff
        if (response.statusCode >= 500 && attempt < maxRetries) {
          final delay = Duration(seconds: 1 << attempt); // 2, 4, 8 seconds
          await Future.delayed(delay);
          continue;
        }
        
        return ApiResponse(
          success: false,
          error: 'Server error: ${response.statusCode}',
          statusCode: response.statusCode,
        );
        
      } on TimeoutException {
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * attempt));
          continue;
        }
        return ApiResponse(success: false, error: 'Request timeout');
        
      } on SocketException {
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * attempt));
          continue;
        }
        return ApiResponse(success: false, error: 'No internet connection');
      }
    }
    
    return ApiResponse(success: false, error: 'Max retries exceeded');
  }
  
  Future<void> _handleAuthError(int statusCode) async {
    if (statusCode == 401) {
      // Token expired or invalid
      await FlutterSecureStorage().delete(key: 'auth_token');
      // Navigate to login
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login', 
        (_) => false,
      );
    }
  }
}
```

---

### 6. 📱 Complete App Flow Example

**App Launch → Home Screen:**

```
1. App opens
   ↓
2. Splash screen
   ↓
3. Check stored token in SecureStorage
   ├─ Token exists → GET /api/mobile/auth/me
   │   ├─ 200 → Navigate to Home
   │   └─ 401 → Clear token, Navigate to Login
   └─ No token → Navigate to Login
   
4. Login Screen
   ↓
   User enters credentials OR taps Google Sign-In
   ↓
   POST /api/auth/login OR POST /api/auth/google
   ├─ 200 → Save token, Navigate to Home
   └─ 401/403 → Show error
   
5. Home Screen loads
   ↓
   Parallel calls:
   ├─ GET /api/mobile/dashboard (cached 5 min)
   ├─ GET /api/mobile/notifications (cached 1 min)
   └─ GET /api/subscription/current (cached 1 min)
   
6. Start live prices polling
   ↓
   Every 5 min (if market open):
   GET /api/mobile/dashboard → update UI
   
7. User taps Stock
   ↓
   GET /api/mobile/stocks/COMI
   ↓
   Navigate to Stock Detail Screen
   
8. Stock Detail Screen
   ↓
   Parallel calls:
   ├─ GET /api/mobile/stocks/COMI (main data)
   ├─ GET /api/chart/COMI?period=1m&asset=stock (chart)
   ├─ GET /api/stocks/COMI/history?days=30 (history)
   └─ GET /api/mobile/stocks/COMI/recommendation (recommendation)
```

---

### 7. 🌐 Network Configuration

**HTTP Client Setup (Dart/Flutter):**

```dart
class ApiConfig {
  static const String productionUrl = 'https://invist.m2y.net';
  static const String developmentUrl = 'http://localhost:3000';
  static const String pythonBackendUrl = 'http://localhost:8010';
  
  // Use production by default, dev on debug builds
  static String get baseUrl =>
      kDebugMode ? developmentUrl : productionUrl;
  
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration aiTimeout = Duration(seconds: 60);
  static const int maxRetries = 3;
}

Map<String, String> authHeaders() {
  final token = GetIt<AuthService>().token;
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
    'User-Agent': 'DalelInvestment/1.0 (Flutter ${Platform.operatingSystem})',
  };
}
```

**Dio Interceptor (Flutter):**

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = GetIt<AuthService>().token;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      GetIt<AuthService>().logout();
    }
    super.onError(err, handler);
  }
}

class RetryInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final shouldRetry = err.response?.statusCode != null &&
        err.response!.statusCode! >= 500 &&
        (err.requestOptions.extra['retries'] ?? 0) < 3;
    
    if (shouldRetry) {
      err.requestOptions.extra['retries'] =
          (err.requestOptions.extra['retries'] ?? 0) + 1;
      
      final delay = Duration(seconds: 1 << (err.requestOptions.extra['retries']));
      await Future.delayed(delay);
      
      try {
        final response = await GetIt<Dio>().fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // Continue with original error
      }
    }
    
    handler.next(err);
  }
}
```

---

### 8. 📋 Endpoint Priority for Mobile MVP

إذا كنت بتبني MVP للموبايل، ركز على الـ endpoints دي بالترتيب:

**Phase 1 (MVP - يوم 1-3):**
1. `POST /api/auth/login` + `POST /api/auth/register`
2. `GET /api/mobile/auth/me`
3. `GET /api/mobile/dashboard` (Home screen)
4. `GET /api/stocks?market=EGX&page=1&limit=50` (Stocks list)
5. `GET /api/mobile/stocks/[ticker]` (Stock detail)
6. `GET /api/chart/[ticker]?period=1m&asset=stock` (Chart)
7. `GET /api/mobile/news` (News feed)

**Phase 2 (Core Features - يوم 4-7):**
8. `GET /api/mobile/predictions` (Predictions tab)
9. `GET /api/mobile/recommendations?persona=balanced` (Recommendations)
10. `GET /api/mobile/portfolio` (Portfolio)
11. `POST /api/mobile/portfolio` (Add to portfolio)
12. `GET /api/watchlist` + `POST /api/watchlist` (Watchlist)
13. `GET /api/mobile/notifications` (Notifications)
14. `GET /api/mobile/subscription` (Subscription plans)

**Phase 3 (Advanced - يوم 8-14):**
15. `POST /api/paymob/create-payment` (Payments)
16. `GET /api/subscription/current` (Subscription status)
17. `POST /api/ai/chat` (AI chat)
18. `GET /api/crypto` + `GET /api/crypto/[id]` (Crypto)
19. `GET /api/mobile/alerts/settings` + POST/DELETE (Alerts)
20. `GET /api/learning/content` (Learning)

**Phase 4 (Polish):**
21. `POST /api/auth/google` (Google Sign-In)
22. `GET /api/market/status` (Market status banner)
23. `GET /api/hunter/screener` (Screener)
24. `GET /api/predictions/performance` (Performance tracking)
25. `GET /api/mobile/zakat-calculator` (Zakat calculator)

---

### 9. 🚨 Common Pitfalls

**❌ Don't:**
- Don't use `/api/portfolio` (web only) - use `/api/mobile/portfolio`
- Don't store token in `SharedPreferences` (use `flutter_secure_storage` / `EncryptedSharedPreferences`)
- Don't poll live prices every second - 5 min is enough
- Don't forget `Authorization: Bearer ` prefix
- Don't ignore `success: false` responses
- Don't use `force_local=1` unless debugging

**✅ Do:**
- Use `/api/mobile/*` endpoints when available
- Cache responses with proper TTLs
- Show loading states for AI chat (can take 60s+)
- Handle 401 gracefully (clear token, redirect to login)
- Use `Accept: application/json` header
- Implement exponential backoff for 5xx errors
- Send `User-Agent` header with app name and version

---

### 10. 🔍 Debugging Tips

**Enable request logging in development:**

```dart
Dio()
  ..interceptors.add(LogInterceptor(
    request: true,
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
    error: true,
    logPrint: (obj) => print('[API] $obj'),
  ))
  ..interceptors.add(AuthInterceptor())
  ..interceptors.add(RetryInterceptor());
```

**Check Python Backend health:**
```
GET https://invist.m2y.net/api/python/health
```

**Check Next.js API health:**
```
GET https://invist.m2y.net/api/health
```

**Test token validity:**
```
GET https://invist.m2y.net/api/mobile/auth/me
Authorization: Bearer <your_token>
```

---

## 📞 Support & Resources

| Resource | URL |
|----------|-----|
| Production | https://invist.m2y.net |
| API Status | https://invist.m2y.net/api/health |
| Python Backend Status | https://invist.m2y.net/api/python/health |
| GitHub Repo | (internal) |
| Documentation | /Documentation/ |
| Telegram Channel | @Arabian_investment_guide |
| Android App | https://play.google.com/store/apps/details?id=com.egx.investment |
| Support Email | support@invist.m2y.net |

---

## 📊 Statistics

- **Total API routes (Next.js):** 360
- **Python blueprints:** 42
- **Mobile-specific endpoints:** 24+
- **Phase 11 audited endpoints:** 30 (9 mobile free + 2 mobile auth + 7 fixed + 12 POST/auth)
- **Total documented endpoints:** 200+
- **Multi-market support:** 7 markets (EGX, TADAWUL, KSE, QSE, DFM, ADX, BSE)
- **Auth methods:** Email/Password, Google OAuth
- **Payment gateways:** Paymob, InstaPay, Google Play
- **AI models:** DeepSeek V3 (chat), DeepSeek R1 (analysis)

---

## 📝 Changelog

| Version | Date | Changes |
|---------|------|---------|
| 18.0 | Jun 2026 | **Phase 11 Mobile API Audit (Task #14):** Added comprehensive Phase 11 Mobile API Audit section documenting all 9 mobile endpoints + 8 fixed endpoints + 11 POST endpoints. New "Authentication Requirements" section classifying endpoints into Free / Bearer Token / NextAuth / Body-based / Admin. New "Free User Quotas & Limits" subsection in Rate Limits & Timeouts. Per-endpoint Error Handling documentation. Live audit verified all 9 free endpoints return 200 OK; `/api/auth/me` correctly returns 401 without token. |
| 17.0 | Jan 2026 | Complete rewrite for mobile app. Added Mobile Integration Guide, JSON schemas, polling intervals, caching strategy, retry logic. |
| 16.0 | Dec 2025 | Initial API Handbook |

---

**End of API Handbook** - للاستفسار تواصل مع فريق التطوير على Telegram: @Arabian_investment_guide
