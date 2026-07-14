# 📚 دليل الاستثمار - Mobile Application API Handbook

> **Platform Name:** دليل الاستثمار (EGX Investment Platform)
> **Version:** 22.0 (Trend-Following Edition) | **Last Updated:** March 2026
> **Task ID:** 32 — API Handbook Update
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
> | 🔌 WebSocket Service | `http://localhost:3005` |
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
14. [🎯 Screener, Confluence & Dual Persona APIs](#-screener-confluence--dual-persona-apis)
15. [🆕 Market Regime & Trend-Following APIs](#-market-regime--trend-following-apis)
16. [🔫 Sniper Engine APIs](#-sniper-engine-apis)
17. [🧠 Smart Confluence APIs](#-smart-confluence-apis)
18. [⚖️ Risk Management APIs](#-risk-management-apis)
19. [📊 Data Engine APIs](#-data-engine-apis)
20. [📱 Mobile-Specific Endpoints](#-mobile-specific-endpoints)
21. [🔌 WebSocket Real-Time API](#-websocket-real-time-api)
22. [📱 Mobile App Integration Guide](#-mobile-app-integration-guide)
23. [📋 Phase 11 Mobile API Audit (Complete Documentation)](#-phase-11-mobile-api-audit-complete-documentation)
24. [🔐 Authentication Requirements](#-authentication-requirements)
25. [🔔 Alerts & Notifications APIs](#-alerts--notifications-apis)
26. [📚 Learning APIs](#-learning-apis)
27. [⚙️ Admin APIs (brief)](#-admin-apis-brief)
28. [❌ Error Codes & Troubleshooting](#-error-codes--troubleshooting)
29. [⏱️ Rate Limits & Timeouts](#-rate-limits--timeouts)
30. [📝 Common JSON Schemas](#-common-json-schemas)
31. [🚀 Mobile Integration Guide](#-mobile-integration-guide)

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
│   • 360+ REST endpoints under /api/**                                       │
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
│  • Regime Det.   │  │  • Gold/Silver   │  │  • data_engine.db            │
│  • Trend Follow  │  │  • Multi-Market  │  │  • portfolio.db              │
│  • Risk Engine   │  │                  │  │  • finance.db (alerts)       │
│  • Sniper Engine │  │                  │  │                              │
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
│   • Yahoo Finance     → EGX historical OHLCV data                          │
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
| **Regime-First** | الـ Market Regime بيحدد هل التداول مسموح | شوف `trading_allowed` و `position_modifier` |

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
       ├─ currency_rates
       └─ market_regime  ← NEW in v22

4. User taps a stock
   └─> GET /api/stocks/{ticker}?live=1&indicators=1
       └─> Show detail screen with price + technical indicators

5. User opens chart tab
   └─> GET /api/chart/{ticker}?period=1m&asset=stock
       └─> Render candlestick chart

6. User checks market regime ← NEW in v22
   └─> GET /api/regime/overview
       └─> Display Stage 1-4 badge + trading advice
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
  "user": { "id": "550e8400-...", "email": "newuser@example.com", "username": "newuser" },
  "api_key": "egx_550e8400-..._1705312200000"
}
```

---

### 3. POST `/api/auth/google` — تسجيل الدخول عبر Google

**Request Body:**
```json
{ "id_token": "eyJhbGciOiJSUzI1NiIs...google_id_token..." }
```

**Response 200 OK:**
```json
{
  "success": true,
  "message": "Google login successful",
  "message_ar": "تم تسجيل الدخول عبر جوجل بنجاح",
  "user": { "id": "550e8400-...", "email": "user@gmail.com", "name": "User Name", "image": "https://...", "subscription_tier": "free" },
  "token": "egx_550e8400-..._uuid_1705312200000",
  "token_type": "Bearer",
  "expires_in": 2592000,
  "is_new_user": false
}
```

---

### 4. GET `/api/auth/me` — بيانات المستخدم الحالي

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
    "subscription_tier": "premium",
    "is_admin": false,
    "is_active": true,
    "email_verified": true,
    "last_login": "2026-01-15T10:30:00.000Z"
  }
}
```

**📱 ملاحظة:** استخدم ده في `splash screen` للتأكد إن الـ session لسه شغالة.

---

### 5. GET `/api/mobile/auth/me` — نسخة mobile محسنة

نفس `/api/auth/me` لكن أسرع ومكتوبة خصيصاً للموبايل.

---

### 6. POST `/api/auth/logout` — تسجيل الخروج

يلغي الـ token من قاعدة البيانات. بعد الـ logout امسح الـ token من `SecureStorage`.

---

### 7. GET `/api/auth/config` — إعدادات المصادقة

```json
{ "success": true, "google_client_id": "...", "google_enabled": true, "nextauth_enabled": true }
```

---

## 📊 Stock Market APIs

### 1. GET `/api/stocks` — قائمة الأسهم

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `market` | string | (all) | `EGX`, `KSA`, `TADAWUL`, `KSE`, `QSE`, `DFM`, `ADX`, `BSE` |
| `limit` / `page_size` | int | 500 | عدد النتائج في الصفحة |
| `offset` | int | 0 | إزاحة من بداية النتائج |
| `page` | int | 1 | رقم الصفحة |
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
  "page_size": 50
}
```

---

### 2. GET `/api/stocks/[ticker]` — تفاصيل سهم

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `live` | 0/1 | 0 | جلب السعر اللحظي |
| `history` | int | 0 | عدد أيام تاريخ الأسعار |
| `indicators` | 0/1 | 0 | جلب المؤشرات الفنية |
| `prediction` | 0/1 | 0 | جلب توقع السعر |
| `force_local` | 0/1 | 0 | إجبار استخدام local DB فقط |

**Example:** `GET /api/stocks/COMI?live=1&indicators=1&history=30`

---

### 3. GET `/api/stocks/search` — بحث سريع
### 4. GET `/api/mobile/stocks/[ticker]` — تفاصيل محسّن للجوال
### 5. GET `/api/market/overview` — نظرة عامة على السوق
### 6. GET `/api/market/status` — حالة السوق (مفتوح/مقفل)
### 7. GET `/api/mobile/market/overview` — نسخة موبايل محسنة
### 8. GET `/api/market/indices` — مؤشرات السوق
### 9. GET `/api/market/sectors` — تصنيف الأسهم بالقطاعات
### 10. GET `/api/market/top-movers` — أكبر الحركات
### 11. GET `/api/stocks/fundamentals` — الأساسيات
### 12. GET `/api/stocks/movement-classification` — تصنيف الحركة

---

## 📈 Chart & Price History APIs

### 1. GET `/api/chart/[ticker]` — بيانات الرسم البياني

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `period` | string | `1w` | `1d`, `1w`, `1m` |
| `asset` | string | auto | `stock`, `crypto`, `commodity` |

### 2. GET `/api/stocks/[ticker]/history` — تاريخ الأسعار
### 3. GET `/api/crypto/ohlc` — OHLC data للكريبتو
### 4. GET `/api/crypto/[id]/history` — تاريخ عملة رقمية

---

## 🎯 Analysis APIs

### 1. GET `/api/advanced-analysis` — التحليل المتقدم (Python proxy)

| Param | Type | Description |
|-------|------|-------------|
| `action` | string | `status`, `golden`, `analyze` (default) |
| `ticker` | string | مطلوب لـ `action=analyze` |
| `limit` | int | لـ `action=golden` (default 10) |

### 2. POST `/api/advanced-analysis` — تحليل شامل
### 3. GET `/api/ai-analysis` — تحليل الذكاء الاصطناعي
### 4. GET `/api/stocks/[ticker]/professional-analysis` — التحليل الاحترافي
### 5. GET `/api/stocks/[ticker]/recommendation` — توصية السهم
### 6. GET `/api/unified-analysis/[symbol]` — التحليل الموحد
### 7. GET `/api/analysis/status` — حالة نظام التحليل
### 8. GET `/api/stocks/analysis` — تحليل سريع
### 9. POST `/api/stocks/batch-analysis` — تحليل جماعي
### 10. GET `/api/unified-analysis/recommendations` — توصيات موحدة

---

## 📋 Predictions APIs

### 1. GET `/api/mobile/predictions` — التوقعات (Mobile)

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `limit` | int | 50 | عدد النتائج |
| `status` | string | (all) | `SUCCESS`, `FAIL`, `PENDING` |

### 2. GET `/api/predictions` — التوقعات (legacy)
### 3. GET `/api/predictions/performance` — أداء التوقعات
### 4. GET `/api/predictions/credibility` — مصداقية التوقعات
### 5. GET `/api/predictions/tracking` — تتبع التوقعات
### 6. GET `/api/predictions/live` — التوقعات اللحظية
### 7. GET `/api/predictions/verify` — التحقق من التوقعات
### 8. POST `/api/predictions/generate` — توليد توقعات جديدة
### 9. POST `/api/predictions/generate-all` — توليد توقعات لكل الأسهم
### 10. GET `/api/predictions/export-pdf` — تصدير PDF
### 11. GET `/api/prediction-performance` — أداء التوقعات (v2)
### 12. GET `/api/ai-predictions/extract` — استخراج توقعات AI
### 13. POST `/api/ai-predictions/evaluate` — تقييم توقعات AI
### 14. GET `/api/real-predictions` — توقعات حقيقية (DeepSeek)
### 15. GET `/api/global-predictions` — توقعات لكل الأسواق
### 16. GET `/api/predictions/eid` — توقعات خاصة بمناسبة

---

## 💼 Portfolio APIs

### 1. GET `/api/mobile/portfolio` — محفظة المستخدم (Mobile)
### 2. POST `/api/mobile/portfolio` — إضافة أصل للمحفظة
### 3. DELETE `/api/mobile/portfolio?id=<asset_id>` — حذف أصل
### 4. GET `/api/portfolio` — محفظة الويب (legacy)
### 5. POST `/api/portfolio` — إضافة لمحفظة الويب
### 6. GET `/api/portfolio/analyze` — تحليل المحفظة
### 7. GET `/api/mobile/portfolio/analyze` — تحليل محفظة mobile
### 8. GET `/api/mobile/portfolio/intelligence` — ذكاء المحفظة
### 9. GET `/api/portfolio/intelligence` — نسخة الويب
### 10. GET `/api/portfolio/assets` — أصول المحفظة
### 11. POST `/api/portfolio/check` — فحص صحة المحفظة
### 12. POST `/api/portfolio/import-real` — استيراد محفظة حقيقية
### 13. POST `/api/portfolio/priority-sync` — مزامنة بأولوية

---

## 👁️ Watchlist APIs

### 1. GET `/api/watchlist` — قائمة المراقبة
### 2. POST `/api/watchlist` — إضافة سهم لقائمة المراقبة
### 3. DELETE `/api/watchlist/[id]` — حذف من قائمة المراقبة
### 4. GET `/api/mobile/watchlist/intelligence` — ذكاء قائمة المراقبة
### 5. GET `/api/watchlist-enhanced` — قائمة مراقبة محسنة
### 6. GET `/api/finance/smart-watchlist` — قائمة المراقبة الذكية
### 7. GET `/api/crypto/watchlist` — قائمة مراقبة الكريبتو

---

## 🪙 Crypto APIs

### 1. GET `/api/crypto` — قائمة العملات الرقمية
### 2. GET `/api/crypto/[id]` — تفاصيل عملة
### 3. GET `/api/crypto/recommendations` — توصيات الكريبتو
### 4. GET `/api/crypto/analyze` — تحليل عملة
### 5. GET `/api/crypto/portfolio` — محفظة الكريبتو
### 6. GET `/api/crypto/stats` — إحصائيات سوق الكريبتو
### 7. GET `/api/crypto/status` — حالة جمع البيانات
### 8. GET `/api/mobile/crypto` — نسخة mobile محسنة
### 9. GET `/api/mobile/crypto/[id]` — تفاصيل عملة (mobile)
### 10. GET `/api/mobile/crypto/recommendations` — توصيات (mobile)
### 11. GET `/api/mobile/crypto/analysis` — تحليل (mobile)
### 12. GET `/api/mobile/crypto/learning` — محتوى تعليمي للكريبتو
### 13. GET `/api/mobile/crypto/portfolio` — محفظة كريبتو (mobile)
### 14. GET `/api/mobile/crypto/watchlist` — قائمة مراقبة كريبتو (mobile)
### 15. GET `/api/crypto-predictions` — توقعات الكريبتو
### 16. GET `/api/crypto-backtesting` — Backtesting للكريبتو
### 17. POST `/api/crypto/simulation` — محاكاة تداول كريبتو
### 18. GET `/api/unified-crypto` — كريبتو موحد

---

## 🌍 Multi-Market APIs

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
### 2. GET `/api/stocks?market=KSA` — أسهم السعودية
### 3. GET `/api/stocks?market=KSE` — أسهم الكويت
### 4. GET `/api/stocks?market=QSE` — أسهم قطر
### 5. GET `/api/multi-market/sync` — مزامنة كل الأسواق
### 6. GET `/api/market/connections` — اتصالات الأسواق
### 7. GET `/api/market/incremental-sync` — مزامنة تدريجية
### 8. POST `/api/market/sync-live` — مزامنة لحظية
### 9. POST `/api/market/sync` — مزامنة عامة
### 10. GET `/api/unified-stocks` — أسهم موحدة
### 11. GET `/api/data-engine/stocks` — أسهم من Data Engine
### 12. GET `/api/data-engine/crypto` — كريبتو من Data Engine
### 13. GET `/api/data-engine/forex` — فوركس
### 14. GET `/api/data-engine/gold` — ذهب
### 15. GET `/api/data-engine/silver` — فضة

---

## 💰 Payment & Subscription APIs

### 1. GET `/api/subscription/plans` — خطط الاشتراك

```json
{
  "success": true,
  "plans": [
    { "id": "free", "name_ar": "مجانى", "price": 0, "max_watchlist": 5, "ai_analysis": false },
    { "id": "normal", "name_ar": "عادى", "price": 99, "max_watchlist": 25, "ai_analysis": true },
    { "id": "premium", "name_ar": "مميز", "price": 199, "max_watchlist": -1, "ai_analysis": true }
  ]
}
```

### 2. POST `/api/subscription/checkout` — بدء عملية الدفع
### 3. POST `/api/subscription/verify` — التحقق من الدفع
### 4. GET `/api/subscription/status` — حالة الاشتراك الحالي

---

## 📰 News & Content APIs

### 1. GET `/api/news` — أخبار السوق
### 2. GET `/api/news/[id]` — تفاصيل خبر
### 3. GET `/api/egksco/recommendations` — توصيات EGKSco

---

## 🤖 AI Chat APIs

### 1. POST `/api/ai/chat` — محادثة مع AI
### 2. GET `/api/ai/status` — حالة خدمة AI

---

## 🎯 Screener, Confluence & Dual Persona APIs

### 1. GET `/api/scanner/quick` — فحص سريع
### 2. GET `/api/confluence/analyze/[ticker]` — تحليل التوحيد
### 3. GET `/api/confluence/market-scan` — فحص السوق بالتوحيد
### 4. GET `/api/persona/analyze/[ticker]` — تحليل الشخصية الاستثمارية
### 5. GET `/api/persona/recommendations` — توصيات حسب الشخصية

---

## 🆕 Market Regime & Trend-Following APIs

> **NEW in v22** — These endpoints power the trend-following strategy and market regime detection.

### 1. GET `/api/regime/market` — EGX30 Market Regime

**الوصف:** يحدد حالة السوق العام (Stage 1-4) بناءً على مؤشر EGX30 باستخدام نموذج Minervini. يستخدم SMA50, SMA200, و SMA slope.

**Authentication:** None required (public endpoint).

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `market` | string | `EGX` | `EGX`, `KSA`, `TADAWUL`, `KSE`, `QSE`, `DFM`, `CRYPTO` |

**Example:** `GET /api/regime/market?market=EGX`

**Response 200 OK:**
```json
{
  "success": true,
  "data": {
    "ticker": "EGX30",
    "regime": "bull_trend",
    "regime_ar": "صاعد واضح",
    "confidence": 71.4,
    "indicators": {
      "adx": {
        "adx": 32.5,
        "plus_di": 28.3,
        "minus_di": 18.7,
        "trend_strength": "moderate",
        "direction": "bullish"
      },
      "roc": {
        "roc": 7.2,
        "status": "bullish"
      }
    },
    "timestamp": "2026-03-04T14:30:00"
  },
  "market": "EGX",
  "index": "EGX30"
}
```

**Regime Values:**

| Value | Arabic | Description | Trading Implication |
|-------|--------|-------------|---------------------|
| `bull_trend` | صاعد واضح | ADX > 25 + bullish direction | Full positions allowed |
| `bear_trend` | هابط واضح | ADX > 25 + bearish direction | No new trades |
| `ranging` | متراوح | ADX < 25 or mixed signals | Half positions, cautious |

---

### 2. GET `/api/regime/stock/<ticker>` — Stock Regime

**الوصف:** يحدد حالة السوق لسهم معين باستخدام نفس خوارزمية ADX + ROC.

**Path Parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `ticker` | string | Stock ticker (e.g., `COMI`, `HRHO`) |

**Example:** `GET /api/regime/stock/COMI`

**Response 200 OK:**
```json
{
  "success": true,
  "data": {
    "ticker": "COMI",
    "regime": "bull_trend",
    "regime_ar": "صاعد واضح",
    "confidence": 85.7,
    "indicators": {
      "adx": { "adx": 35.2, "plus_di": 30.1, "minus_di": 15.4, "trend_strength": "moderate", "direction": "bullish" },
      "roc": { "roc": 8.5, "status": "bullish" }
    },
    "timestamp": "2026-03-04T14:30:00"
  }
}
```

---

### 3. GET `/api/regime/overview` — Full Market Overview with Trading Advice

**الوصف:** يرجع حالة السوق الشاملة مع نصيحة تداول. يستخدم `MarketRegimeEngine` مع تصنيف Minervini Stage 1-4.

**Example:** `GET /api/regime/overview`

**Response 200 OK:**
```json
{
  "success": true,
  "data": {
    "market_regime": {
      "ticker": "EGX30",
      "regime": "bull_trend",
      "regime_ar": "صاعد واضح",
      "confidence": 71.4,
      "indicators": {
        "adx": { "adx": 32.5, "plus_di": 28.3, "minus_di": 18.7, "trend_strength": "moderate", "direction": "bullish" },
        "roc": { "roc": 7.2, "status": "bullish" }
      },
      "timestamp": "2026-03-04T14:30:00"
    },
    "trading_advice": {
      "action": "HOLD",
      "action_ar": "احتفاظ"
    }
  }
}
```

**📱 ملاحظة للجوال:** استخدم ده في الـ Home screen لعرض badge لحالة السوق. الـ `trading_advice.action` يحدد هل المستخدم يجب أن يتداول أم لا.

---

### Market Regime Stages (Minervini Classification)

يستخدم `MarketRegimeEngine` من `engines/market_regime.py` التصنيف التالي:

| Stage | Name | Conditions | `trading_allowed` | `position_modifier` |
|-------|------|------------|-------------------|---------------------|
| **1** | Consolidation | Price below/near SMA200, flat slope | `true` | `0.5` (half) |
| **2** | Bull Market | Price > SMA200, SMA50 > SMA200, SMA200 slope > 0.2%/20d | `true` | `1.0` (full) |
| **3** | Distribution | Price > SMA200 but weakening (death cross forming) | `true` | `0.5` (half) |
| **4** | Bear Market | Price < SMA200, SMA200 slope < -0.2%/20d | `false` | `0.0` (none) |

**RegimeResult Data Structure:**
```json
{
  "stage": 2,
  "stage_name": "Bull Market",
  "price": 28500.50,
  "sma50": 27800.00,
  "sma200": 26500.00,
  "slope_50": 0.45,
  "slope_200": 0.32,
  "adx": 32.5,
  "confidence": 78.0,
  "trading_allowed": true,
  "position_modifier": 1.0,
  "date": "2026-03-04",
  "index_ticker": "EGX30",
  "reason": "EGX30 28501 is +7.5% above SMA200 with SMA200 rising +0.320%/20d — clear uptrend"
}
```

---

## 🔫 Sniper Engine APIs

> **Updated in v22** — Sniper endpoints now include EGX30 regime gate and trend-following signals.

### 1. GET `/api/sniper/scan` — Market Scan with EGX30 Gate

**الوصف:** يفحص السوق ويجد أفضل الفرص باستخدام 5-gate filter. في v22 بيتحقق أولاً من حالة EGX30 — لو Stage 4 (Bear Market) بيرجع نتائج فارغة مع تحذير.

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `market` | string | `EGX` | السوق المستهدف |
| `persona` | string | `balanced` | `conservative`, `balanced`, `aggressive` |
| `min_gates` | int | `4` | أقل عدد gates للفلترة (1-5) |
| `limit` | int | `10` | أقصى عدد نتائج |

**Example:** `GET /api/sniper/scan?market=EGX&min_gates=4&limit=10`

**Response 200 OK:**
```json
{
  "success": true,
  "count": 3,
  "results": [
    {
      "ticker": "COMI",
      "market": "EGX",
      "signal": "STRONG_BUY",
      "signal_ar": "شراء قوي",
      "confidence": 85.0,
      "sniper_score": 88,
      "entry_price": 65.45,
      "target_price": 72.00,
      "stop_loss": 62.00,
      "risk_reward": 1.88,
      "gates_passed": 5,
      "gates": {
        "technical": true,
        "fundamental": true,
        "volume": true,
        "trend": true,
        "regime": true
      },
      "market_regime": {
        "stage": 2,
        "stage_name": "Bull Market",
        "trading_allowed": true,
        "position_modifier": 1.0
      },
      "is_trend_following": false,
      "timestamp": "2026-03-04T14:30:00"
    }
  ],
  "market": "EGX",
  "min_gates": 4,
  "egx30_stage": 2,
  "timestamp": "2026-03-04T14:30:00"
}
```

**📱 ملاحظة للجوال:**
- لو `egx30_stage` = 4 اعرض تحذير "السوق في مرحلة هبوط — لا توجد صفقات جديدة"
- لو `is_trend_following` = `true` اعرف إن الإشارة من استراتيجية Trend Following

---

### 2. GET `/api/sniper/analyze/<ticker>` — Individual Ticker Analysis

**الوصف:** يحلل سهم واحد بالكامل باستخدام SniperEngine. في v22 يشمل Donchian breakout analysis و trailing stops.

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `market` | string | `EGX` | السوق |
| `persona` | string | `balanced` | الشخصية الاستثمارية |

**Example:** `GET /api/sniper/analyze/COMI?market=EGX`

**Response 200 OK:**
```json
{
  "success": true,
  "result": {
    "ticker": "COMI",
    "market": "EGX",
    "signal": "STRONG_BUY",
    "signal_ar": "شراء قوي",
    "confidence": 85.0,
    "sniper_score": 88,
    "entry_price": 65.45,
    "target_price": 72.00,
    "stop_loss": 62.00,
    "risk_reward": 1.88,
    "donchian_score": 0.85,
    "donchian_high": 66.20,
    "trailing_stop_atr_mult": 2.0,
    "initial_stop_atr_mult": 2.0,
    "exit_type": "target",
    "is_trend_following": true,
    "market_regime": {
      "stage": 2,
      "trading_allowed": true,
      "position_modifier": 1.0
    },
    "egx30_stage": 2
  },
  "timestamp": "2026-03-04T14:30:00"
}
```

**New Trend-Following Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `donchian_score` | float | قوة اختراق Donchian Channel (0-1) |
| `donchian_high` | float | أعلى سعر في آخر 20 يوم (Donchian Upper) |
| `trailing_stop_atr_mult` | float | معامل ATR للوقف المتحرك (default: 2.0) |
| `initial_stop_atr_mult` | float | معامل ATR للوقف الأولي (default: 2.0) |
| `exit_type` | string | نوع الخروج: `trailing_stop` أو `target` |
| `is_trend_following` | bool | هل الإشارة من استراتيجية Trend Following |
| `egx30_stage` | int | مرحلة السوق EGX30 (1-4) |

---

### 3. POST `/api/sniper/track` — Track a Ticker

يحلل سهم ويحفظ التوقع كـ PENDING في قاعدة البيانات.

**Query Parameters:** `ticker` (مطلوب), `market`, `persona`

---

### 4. POST `/api/sniper/closer/run` — تشغيل Daily Closer

يغلق التوقعات المنتهية وينسخ أهداف أو وقف خسارة.

### 5. GET `/api/sniper/closer/pending` — التوقعات المعلقة

### 6. POST `/api/sniper/learning/run` — تشغيل Learning Engine

### 7. GET `/api/sniper/learning/lessons` — الدروس المستفادة

### 8. GET `/api/sniper/learning/performance` — أداء التوقعات

```json
{
  "success": true,
  "metrics": {
    "win_rate": 65.0,
    "profit_factor": 1.85,
    "avg_win_pct": 8.5,
    "avg_loss_pct": -3.2,
    "total_predictions": 45,
    "total_wins": 29,
    "total_losses": 16,
    "avg_hold_days": 7
  },
  "recent_closed": [...],
  "lessons": [...]
}
```

### 9. GET `/api/sniper/scheduler/status` — حالة Scheduler

---

## 🧠 Smart Confluence APIs

> **Updated in v22** — Smart Confluence now includes market regime gate and trend-following logic.

### 1. GET `/api/smart-confluence/status` — حالة النظام

```json
{
  "success": true,
  "table_exists": true,
  "stats": {
    "total": 500,
    "active": 50,
    "evaluated": 450,
    "wins": 320,
    "losses": 130,
    "win_rate": "71.1%",
    "date_range": { "start": "2026-01-01", "end": "2026-03-04" }
  },
  "by_market": { "EGX": { "count": 200, "wins": 150 }, "السعودية": { "count": 300, "wins": 170 } }
}
```

### 2. POST `/api/smart-confluence/generate` — توليد توقعات تاريخية

**Request Body:**
```json
{
  "start_date": "2026-01-01",
  "end_date": "2026-03-04",
  "markets": ["مصر", "السعودية"]
}
```

### 3. GET `/api/smart-confluence/progress` — متابعة تقدم التوليد

### 4. POST `/api/smart-confluence/evaluate` — تقييم التوقعات النشطة

### 5. GET `/api/smart-confluence/predictions` — عرض التوقعات

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `page` | int | 1 | رقم الصفحة |
| `limit` | int | 50 | عدد النتائج |
| `market` | string | null | فلتر بالسوق |
| `status` | string | null | فلتر بالحالة |
| `signal` | string | null | فلتر بالإشارة |

### 6. POST `/api/smart-confluence/clear` — مسح كل التوقعات

### 7. GET `/api/smart-confluence/analysis/<symbol>` — تحليل فوري لسهم (with TF Logic)

**الوصف:** يحلل سهم واحد باستخدام Smart Confluence Engine. في v22 يشمل فحص Market Regime و تكييف التحليل بناءً عليه.

**Query Parameters:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `date` | string | null | تاريخ التحليل (للـ backtesting) |

**Example:** `GET /api/smart-confluence/analysis/COMI`

**Response 200 OK:**
```json
{
  "success": true,
  "analysis": {
    "symbol": "COMI",
    "name": "Commercial International Bank",
    "market": "مصر",
    "current_price": 65.45,
    "recommendation": "BUY",
    "recommendation_ar": "شراء",
    "confidence": 82.0,
    "confluence_score": 78,
    "market_regime": {
      "stage": 2,
      "stage_name": "Bull Market",
      "trading_allowed": true,
      "position_modifier": 1.0,
      "reason": "EGX30 28501 is +7.5% above SMA200 with SMA200 rising"
    },
    "is_trend_following": false,
    "signals": {
      "technical": { "score": 85, "signal": "bullish" },
      "fundamental": { "score": 72, "signal": "neutral_bullish" },
      "seasonality": { "score": 68, "signal": "neutral" },
      "dividend": { "score": 75, "signal": "bullish" },
      "volume": { "score": 80, "signal": "bullish" }
    },
    "entry_price": 65.45,
    "target_price": 72.00,
    "stop_loss": 62.00,
    "risk_reward": 1.88,
    "trailing_stop_atr_mult": 2.0,
    "initial_stop_atr_mult": 2.0
  }
}
```

---

## ⚖️ Risk Management APIs

### 1. POST `/api/risk/position-size` — حساب حجم الصفقة

**Request Body:**
```json
{ "capital": 100000, "confidence_score": 7.5, "max_risk_percent": 2.0 }
```

### 2. POST `/api/risk/stop-loss` — حساب وقف الخسارة

**Request Body:**
```json
{ "entry_price": 65.45, "symbol": "COMI", "sector": "Banks", "market": "egx" }
```

### 3. POST `/api/risk/targets` — حساب أهداف الربح

**Request Body:**
```json
{ "entry_price": 65.45, "stop_price": 62.00, "ratios": [1.5, 3, 5] }
```

### 4. POST `/api/risk/trade-plan` — خطة تداول كاملة

**Request Body:**
```json
{ "entry_price": 65.45, "symbol": "COMI", "sector": "Banks", "capital": 100000, "confidence_score": 7.5, "market": "egx" }
```

**Response:**
```json
{
  "success": true,
  "symbol": "COMI",
  "stock_type": "blue_chip",
  "position": { "position_size": 3000, "position_size_pct": 2.0, "shares": 45 },
  "stop_loss": { "stop_price": 62.00, "stop_percent": -5.27, "stop_type": "atr_based" },
  "targets": {
    "targets": [
      { "ratio": 1.5, "price": 70.68, "profit_pct": 8.0 },
      { "ratio": 3.0, "price": 76.82, "profit_pct": 17.4 },
      { "ratio": 5.0, "price": 83.00, "profit_pct": 26.8 }
    ]
  },
  "trade_plan": {
    "entry": 65.45,
    "stop": 62.00,
    "target_1": 70.68,
    "target_2": 76.82,
    "target_3": 83.00,
    "shares": 45,
    "total_value": 2945.25
  }
}
```

### 5. POST `/api/risk/trailing-stop` — حساب الوقف المتحرك

**Request Body:**
```json
{ "entry_price": 65.45, "current_price": 70.00, "stop_price": 62.00, "target_reached": 1 }
```

### 6. POST `/api/risk/validate` — التحقق من قاعدة 2%
### 7. GET `/api/risk/trading-time` — نصيحة وقت التداول
### 8. POST `/api/risk/portfolio` — تحليل المحفظة
### 9. POST `/api/risk/egyptian-model` — النموذج المصري
### 10. POST `/api/risk/psychology` — فحص علم النفس
### 11. POST `/api/risk/leverage` — التحقق من الرافعة المالية (Crypto)
### 12. GET `/api/risk/decision-table` — جدول القرارات
### 13. GET `/api/risk/stock-types` — أنواع الأسهم ونسب الوقف

---

## 📊 Data Engine APIs

### 1. GET `/api/data-engine/health` — حالة Data Engine

**Response 200 OK:**
```json
{
  "success": true,
  "status": "operational",
  "stocks_available": true,
  "metals_available": true,
  "crypto_available": true,
  "forex_available": true,
  "timestamp": "2026-03-04T14:30:00"
}
```

### 2. GET `/api/data-engine/stocks` — أسهم من Data Engine
### 3. GET `/api/data-engine/metals` — الذهب والفضة
### 4. GET `/api/data-engine/crypto` — العملات الرقمية
### 5. GET `/api/data-engine/forex` — أسعار الصرف
### 6. GET `/api/data-engine/status` — حالة الأسواق

---

## 📱 Mobile-Specific Endpoints

### 1. GET `/api/mobile/dashboard` — لوحة التحكم (كل حاجة في call واحد)

```json
{
  "success": true,
  "market_status": { "is_open": true, "status": "open" },
  "indices": [...],
  "top_movers": { "gainers": [...], "losers": [...], "most_active": [...] },
  "gold_prices": { "gold_24k": 3200, "gold_21k": 2800, "gold_18k": 2400 },
  "currency_rates": { "USD_EGP": 50.5, "EUR_EGP": 54.8 },
  "market_regime": { "stage": 2, "stage_name": "Bull Market", "trading_allowed": true }
}
```

### 2. GET `/api/mobile/stocks/[ticker]` — تفاصيل سهم محسّن
### 3. GET `/api/mobile/market/overview` — نظرة عامة محسنة
### 4. GET `/api/mobile/predictions` — التوقعات
### 5. GET `/api/mobile/portfolio` — المحفظة
### 6. POST `/api/mobile/portfolio` — إضافة أصل
### 7. DELETE `/api/mobile/portfolio` — حذف أصل
### 8. GET `/api/mobile/portfolio/intelligence` — ذكاء المحفظة
### 9. GET `/api/mobile/auth/me` — بيانات المستخدم
### 10. GET `/api/mobile/crypto` — كريبتو محسّن
### 11. GET `/api/mobile/crypto/[id]` — تفاصيل عملة
### 12. GET `/api/mobile/crypto/recommendations` — توصيات كريبتو
### 13. GET `/api/mobile/crypto/analysis` — تحليل كريبتو
### 14. GET `/api/mobile/crypto/learning` — محتوى تعليمي
### 15. GET `/api/mobile/crypto/portfolio` — محفظة كريبتو
### 16. GET `/api/mobile/crypto/watchlist` — قائمة مراقبة
### 17. GET `/api/mobile/watchlist/intelligence` — ذكاء قائمة المراقبة

---

## 🔌 WebSocket Real-Time API

> **NEW in v22** — Documented for the first time.

The WebSocket service runs on **port 3005** using Socket.io. It polls the Python backend every 30 seconds and pushes real-time updates to connected clients.

**Connection URL:** `ws://localhost:3005` (or production equivalent)

**Socket.io Client Setup:**
```javascript
import { io } from 'socket.io-client';
const socket = io('http://localhost:3005', {
  transports: ['websocket'],
  pingTimeout: 60000,
  pingInterval: 25000
});
```

### Server → Client Events

| Event | Payload | Description |
|-------|---------|-------------|
| `market:snapshot` | `{ stocks: [...], timestamp: string }` | Full market snapshot every 30s |
| `market:status` | `{ status, is_open, gainers_count, losers_count, ... }` | Market open/close status |
| `ticker:update` | `{ ticker, name_ar, current_price, price_change, volume }` | Individual stock update (subscribed only) |
| `stock:alert` | `{ ticker, name_ar, price, change, direction, timestamp }` | Alert when movement > 3% (subscribed only) |

### Client → Server Events

| Event | Payload | Description |
|-------|---------|-------------|
| `subscribe:ticker` | `ticker` (string) | Subscribe to updates for a specific stock |
| `unsubscribe:ticker` | `ticker` (string) | Unsubscribe from stock updates |
| `getMarketOverview` | callback function | Request current market overview (ack-based) |

### Health Endpoint

`GET http://localhost:3005/health`

```json
{
  "status": "ok",
  "message": "WebSocket Service يعمل",
  "timestamp": "2026-03-04T14:30:00.000Z",
  "port": 3005,
  "connected_clients": 3,
  "last_snapshot_count": 100,
  "has_market_status": true
}
```

**📱 ملاحظة للجوال:**
- استخدم `socket.io-client` package
- اتصل بـ `subscribe:ticker` لكل سهم في قائمة المراقبة
- استمع لـ `stock:alert` لعرض push notifications
- لو الـ connection قطع، Socket.io بيعيد الاتصال تلقائياً

---

## 📱 Mobile App Integration Guide

> **NEW in v22** — Complete guide for mobile app developers.

### Authentication Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    Authentication Flow                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  App Start ──> Check SecureStorage for token                │
│       │                                                      │
│       ├── Token exists ──> GET /api/mobile/auth/me           │
│       │       │                                              │
│       │       ├── 200 OK ──> Continue to Home                │
│       │       └── 401 ──> Clear token → Login Screen        │
│       │                                                      │
│       └── No token ──> Login Screen                          │
│               │                                              │
│               ├── Email/Password ──> POST /api/auth/login    │
│               ├── Google ──> POST /api/auth/google           │
│               └── Register ──> POST /api/auth/register       │
│                       │                                      │
│                       └── Save token to SecureStorage        │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Polling Strategy for New Signals

```
┌──────────────────────────────────────────────────────────────┐
│                    Signal Polling Strategy                     │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Market CLOSED:                                              │
│    • Poll every 5 minutes (just in case)                     │
│    • Show cached data                                        │
│                                                              │
│  Market OPEN (10:00 - 14:30 Cairo):                          │
│    • GET /api/regime/overview  → every 5 min                │
│    • GET /api/sniper/scan      → every 2 min                │
│    • GET /api/stocks/{ticker}  → on demand                   │
│    • WebSocket for real-time prices                          │
│                                                              │
│  After Market Close:                                          │
│    • GET /api/sniper/closer/pending → once                  │
│    • GET /api/sniper/learning/performance → once            │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Displaying Regime Status

```dart
// Flutter example for regime display
Widget buildRegimeBadge(RegimeResult regime) {
  final colors = {
    1: Colors.orange,    // Consolidation
    2: Colors.green,     // Bull Market
    3: Colors.yellow,    // Distribution
    4: Colors.red,       // Bear Market
  };
  
  final labels = {
    1: 'تجميعي',
    2: 'صاعد',
    3: 'توزيع',
    4: 'هابط',
  };
  
  return Badge(
    color: colors[regime.stage],
    label: labels[regime.stage],
    child: Text('Stage ${regime.stage}: ${regime.stage_name}'),
  );
}
```

### Handling Trailing Stop Updates

When `is_trend_following = true`, the signal uses dynamic trailing stops:

```
Entry Price:    65.45
Initial Stop:   Entry - (2.0 × ATR) = 62.00
Trailing Stop:  Moves up as price rises

Poll for updates:
  GET /api/risk/trailing-stop
  { "entry_price": 65.45, "current_price": 70.00, "stop_price": 62.00, "target_reached": 1 }

  Response:
  { "new_stop": 67.50, "stop_moved": true, "exit_type": "trailing_stop" }
```

**Key points for mobile:**
1. Show "Trailing Stop: 67.50" instead of fixed stop loss when `exit_type = trailing_stop`
2. The stop loss moves UP but never down
3. When `target_reached >= 1`, switch from initial stop to trailing stop
4. Display `trailing_stop_atr_mult` and `initial_stop_atr_mult` in signal details

### Push Notification Integration Points

| Event | Trigger | Notification |
|-------|---------|-------------|
| New Sniper Signal | `GET /api/sniper/scan` returns new ticker | "🟢 إشارة جديدة: COMI - شراء قوي" |
| Regime Change | `GET /api/regime/overview` stage changes | "⚠️ حالة السوق تغيرت: صاعد ← توزيع" |
| Trailing Stop Hit | Price crosses trailing stop | "🔴 الوقف المتحرك: COMI عند 67.50" |
| Target Hit | Price reaches target | "🎯 الهدف: COMI وصل 72.00" |
| Market Open/Close | WebSocket `market:status` | "📊 السوق المصري فتح" |

**Implementation:**
1. Use Firebase Cloud Messaging (FCM) or APNs
2. Backend should emit WebSocket events for signal changes
3. Mobile app registers push tokens via `POST /api/mobile/push-token`
4. Handle background notifications for regime changes (critical)

### Rate Limiting Considerations

| Endpoint | Recommended Poll Interval | Max Requests/min |
|----------|--------------------------|------------------|
| `/api/regime/overview` | 5 min | 12 |
| `/api/sniper/scan` | 2 min | 30 |
| `/api/stocks` | 1 min | 60 |
| `/api/stocks/[ticker]` | 30s (live) | 120 |
| `/api/mobile/dashboard` | 1 min | 60 |
| WebSocket events | Real-time | N/A (persistent) |

**Best practices:**
- Use exponential backoff on 429 responses
- Cache regime status locally (changes slowly)
- Batch stock detail requests using `/api/stocks` with tickers
- Use WebSocket for real-time price updates instead of polling

---

## 📋 Phase 11 Mobile API Audit (Complete Documentation)

For the complete Phase 11 audit, see the sections above. All endpoints have been verified against the live route files.

---

## 🔐 Authentication Requirements

| Endpoint Category | Auth Required | Notes |
|-------------------|---------------|-------|
| `/api/auth/*` | No (login/register) | Token returned on success |
| `/api/regime/*` | No | Public market data |
| `/api/sniper/*` | No | Public analysis data |
| `/api/smart-confluence/*` | No | Public analysis data |
| `/api/stocks` | No | Public market data |
| `/api/risk/*` | No | Public risk tools |
| `/api/mobile/portfolio` | **Yes** | User-specific data |
| `/api/mobile/watchlist` | **Yes** | User-specific data |
| `/api/mobile/auth/me` | **Yes** | User-specific data |
| `/api/subscription/*` | **Yes** | Payment data |

---

## 🔔 Alerts & Notifications APIs

### 1. GET `/api/finance/alerts` — تنبيهات المستخدم
### 2. POST `/api/finance/alerts` — إنشاء تنبيه
### 3. DELETE `/api/finance/alerts/[id]` — حذف تنبيه
### 4. GET `/api/t1-signals` — إشارات T+1 اليومية
### 5. GET `/api/t1-signals/history` — تاريخ إشارات T+1
### 6. POST `/api/t1-signals/record` — تسجيل نتيجة صفقة

---

## 📚 Learning APIs

### 1. GET `/api/sniper/learning/lessons` — الدروس المستفادة
### 2. GET `/api/sniper/learning/performance` — أداء التوقعات
### 3. POST `/api/sniper/learning/run` — تشغيل Learning Engine
### 4. GET `/api/learning/modules` — الوحدات التعليمية
### 5. GET `/api/educational-cards` — البطاقات التعليمية

---

## ⚙️ Admin APIs (brief)

### 1. GET `/api/admin/stats` — إحصائيات النظام
### 2. GET `/api/monitor/health` — مراقبة الصحة
### 3. GET `/api/feature-flags` — Feature flags
### 4. POST `/api/market/publish-status-image` — نشر صورة حالة السوق على تيليجرام

---

## ❌ Error Codes & Troubleshooting

### HTTP Status Codes

| Code | Meaning | Mobile Action |
|------|---------|---------------|
| `200` | Success | Process normally |
| `201` | Created | Refresh list |
| `400` | Bad Request | Check request format |
| `401` | Unauthorized | Re-authenticate |
| `403` | Forbidden | Account deactivated / insufficient subscription |
| `404` | Not Found | Show "not available" |
| `409` | Conflict | Already exists |
| `413` | Payload Too Large | Reduce image/file size |
| `429` | Rate Limited | Retry with exponential backoff |
| `500` | Server Error | Retry 3x, then show error |
| `502` | Bad Gateway | Backend unavailable, retry later |
| `503` | Service Unavailable | Engine not loaded, retry after restart |

### Application Error Codes

| Error Key | Meaning | Arabic |
|-----------|---------|--------|
| `TOKEN_EXPIRED` | Token expired | Token منتهي الصلاحية |
| `INVALID_TOKEN` | Invalid token | Token غير صالح |
| `ACCOUNT_DEACTIVATED` | Account deactivated | الحساب غير مفعل |
| `INSUFFICIENT_SUBSCRIPTION` | Need premium | تحتاج اشتراك مميز |
| `MARKET_CLOSED` | Market is closed | السوق مقفل |
| `REGIME_BLOCKED` | Trading blocked by regime | التداول متوقف (مرحلة هبوط) |
| `NO_DATA` | No data available | لا توجد بيانات |
| `ANALYSIS_FAILED` | Analysis engine error | فشل التحليل |

### Troubleshooting Guide

| Problem | Cause | Solution |
|---------|-------|----------|
| Empty stocks list | Market closed or data not synced | Check `/api/data-engine/health` |
| All signals empty | EGX30 Stage 4 (Bear) | Check `/api/regime/overview` |
| 503 on sniper | SniperEngine not loaded | Restart Python backend |
| WebSocket disconnect | Network issue | Auto-reconnect via socket.io |
| Trailing stop not moving | `target_reached` not set | Poll `/api/risk/trailing-stop` |
| Regime shows Stage 1 always | Insufficient price history | Check `price_history.db` has EGX30 data |

---

## ⏱️ Rate Limits & Timeouts

| Setting | Value |
|---------|-------|
| Default request timeout | 30 seconds |
| Long-running analysis timeout | 60 seconds |
| WebSocket ping interval | 25 seconds |
| WebSocket ping timeout | 60 seconds |
| Data Engine poll interval | 30 seconds |
| Token expiry | 30 days |
| Max image upload | 10MB |

---

## 📝 Common JSON Schemas

### Market Regime Schema

```json
{
  "stage": "integer (1-4)",
  "stage_name": "string (Consolidation|Bull Market|Distribution|Bear Market)",
  "price": "number",
  "sma50": "number",
  "sma200": "number",
  "slope_50": "number (% change over 20 days)",
  "slope_200": "number (% change over 20 days)",
  "adx": "number (0-100)",
  "confidence": "number (0-100)",
  "trading_allowed": "boolean",
  "position_modifier": "number (0.0, 0.5, or 1.0)",
  "date": "string (YYYY-MM-DD)",
  "index_ticker": "string",
  "reason": "string"
}
```

### Trend-Following Signal Schema

```json
{
  "donchian_score": "number (0-1, breakout strength)",
  "donchian_high": "number (20-day high)",
  "donchian_lower": "number (20-day low)",
  "donchian_middle": "number (midpoint)",
  "atr": "number (14-day Average True Range)",
  "sma_50": "number",
  "price_above_sma50": "boolean",
  "trailing_stop_atr_mult": "number (default 2.0)",
  "initial_stop_atr_mult": "number (default 2.0)",
  "exit_type": "string (trailing_stop|target)",
  "is_trend_following": "boolean",
  "breakout_strength": "number (% above Donchian high)"
}
```

### Sniper Result Schema

```json
{
  "ticker": "string",
  "market": "string",
  "signal": "string (STRONG_BUY|BUY|HOLD|REDUCE|SELL|STRONG_SELL|ACCUMULATE)",
  "signal_ar": "string",
  "confidence": "number (0-100)",
  "sniper_score": "number (0-100)",
  "entry_price": "number",
  "target_price": "number",
  "stop_loss": "number",
  "risk_reward": "number",
  "gates_passed": "integer (1-5)",
  "market_regime": "RegimeResult (embedded)",
  "egx30_stage": "integer (1-4)",
  "is_trend_following": "boolean",
  "donchian_score": "number (optional)",
  "trailing_stop_atr_mult": "number (optional)",
  "exit_type": "string (optional)"
}
```

### Prediction Schema

```json
{
  "id": "integer",
  "ticker": "string",
  "market": "string",
  "signal": "string",
  "signal_ar": "string",
  "confidence": "number",
  "entry_price": "number",
  "target_price": "number",
  "stop_loss": "number",
  "risk_reward": "number",
  "persona": "string",
  "status": "string (PENDING|TARGET_HIT|STOPPED|EXPIRED)",
  "maestro_score": "number",
  "actual_return": "number (nullable)",
  "actual_exit_price": "number (nullable)",
  "highest_price": "number (nullable)",
  "lowest_price": "number (nullable)",
  "days_to_close": "integer (nullable)",
  "pnl_pct": "number (nullable)",
  "closed_at": "string (nullable)",
  "created_at": "string"
}
```

---

## 🚀 Mobile Integration Guide

### Quick Start (5 minutes)

1. **Login:** `POST /api/auth/login` → save token
2. **Dashboard:** `GET /api/mobile/dashboard` → show home
3. **Regime Badge:** `GET /api/regime/overview` → show stage
4. **Stock List:** `GET /api/stocks?market=EGX&limit=50`
5. **Stock Detail:** `GET /api/stocks/COMI?live=1&indicators=1`
6. **Chart:** `GET /api/chart/COMI?period=1m&asset=stock`

### Architecture Patterns

```
┌─────────────────────────────────────────┐
│           Mobile App Architecture       │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────┐   ┌────────────────┐  │
│  │  Auth Layer  │   │  API Client    │  │
│  │  (Token Mgmt)│   │  (Dio/Alamofire│  │
│  └──────┬──────┘   └───────┬────────┘  │
│         │                  │            │
│  ┌──────┴──────────────────┴────────┐  │
│  │         Repository Layer          │  │
│  │  (RegimeRepo, StockRepo, etc.)   │  │
│  └──────┬──────────────────┬────────┘  │
│         │                  │            │
│  ┌──────┴──────┐   ┌──────┴────────┐  │
│  │  BLoC/VM    │   │  WebSocket    │  │
│  │  (State)    │   │  (Real-time)  │  │
│  └──────┬──────┘   └──────┬────────┘  │
│         │                  │            │
│  ┌──────┴──────────────────┴────────┐  │
│  │              UI Layer             │  │
│  │  (RegimeBadge, StockCard, Chart) │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

### Key Implementation Notes

1. **Regime-First Design:** Always check regime before showing trade signals
   - If Stage 4: Show "Trading Paused" overlay
   - If Stage 1/3: Show "Cautious Mode" badge
   - If Stage 2: Show "Full Trading" badge

2. **Trend-Following Signals:**
   - When `is_trend_following = true`, display Donchian breakout indicator
   - Show trailing stop line on chart (dashed, moving up)
   - Show `donchian_high` as resistance line

3. **WebSocket Integration:**
   - Connect on app start
   - Subscribe to watchlist tickers
   - Show price changes in real-time
   - Push notifications for >3% alerts

4. **Offline Support:**
   - Cache last regime status (changes daily)
   - Cache stock list (changes every 30s during market hours)
   - Show stale data with timestamp indicator

---

*Last updated: March 2026 | Version 22.0 (Trend-Following Edition) | Task ID: 32*

---

## 📡 تحديث يوليو 2026 — APIs جديدة (إدارة الأموال + التوقعات + البيانات)

### 1. نظام إدارة الأموال للعملاء (Money Management)

#### `GET /api/money?section=overview`
ملخص شامل لمحفظة العميل.
```json
{
  "portfolio": {
    "total_assets": 14,
    "total_invested": 6459242.33,
    "total_current_value": 96000,
    "total_pnl": -6363242.33,
    "total_pnl_pct": -98.51
  },
  "watchlist": { "count": 11 },
  "alerts": { "active": 0 },
  "journal": { "total": 0, "win_rate": 0 },
  "obligations": { "count": 0, "total_remaining": 0 }
}
```

#### `GET /api/money?section=portfolio`
أصول المحفظة مع الأسعار الحية + PnL لكل أصل.

#### `GET /api/money?section=watchlist`
قائمة المراقبة مع تحليلات (RSI, signal, trend, sector).

#### `GET /api/money?section=alerts`
التنبيهات النشطة مع الأسعار الحالية.

#### `GET /api/money?section=journal`
ذاكرة التداول + إحصائيات (win_rate, total_pnl, avg_return).

---

### 2. المراقب الذكي للمحفظة (Smart Portfolio Monitor)

#### `GET /api/money/smart-monitor`
تحليل ذكي لحظي لكل سهم في محفظة العميل.
```json
{
  "summary": {
    "total_assets": 11,
    "total_invested": 208642.33,
    "total_current_value": 200092.22,
    "total_pnl": -8550.11,
    "sell_count": 3,
    "buy_more_count": 0,
    "hold_count": 8
  },
  "stock_signals": [
    {
      "ticker": "DSCW",
      "action": "STOP_LOSS",
      "action_ar": "🚨 إيقاف خسارة — بِع فوراً",
      "reason": "خسارة -9.3% — تجاوز حد الإيقاف",
      "confidence": 90,
      "stop_loss": 1.78,
      "take_profit": 2.23,
      "average_suggestion": null
    }
  ],
  "wealth_plan": {
    "recommended_allocation": { "stock": 40, "gold": 25, "bank": 20, "cash": 10, "crypto": 5 },
    "current_allocation": { "stock": 100.0 },
    "gaps": ["زيادة في stock: 100% (المثالي 40%)"],
    "recommendations": ["📤 قلّل أسهم 60%", "📥 زِد ذهب 25%"]
  },
  "alerts": ["🚨 DSCW: خسارة -9.3% — بِع فوراً"]
}
```

**إشارات ذكية:**
| الإشارة | الشرط | الإجراء |
|---------|-------|---------|
| `STOP_LOSS` | خسارة ≥ -8% | 🚨 بيع فوري |
| `TAKE_PROFIT` | ربح ≥ +15% | ✅ جني أرباح |
| `SELL` | RSI > 70 + ربح | 📤 بيع |
| `BUY_MORE` | RSI < 30 + خسارة | 📥 متوسط (averaging) |
| `HOLD` | ضمن الحدود | ⏸️ احتفظ |

**اقتراح المتوسط (Averaging):**
عند `BUY_MORE`، يرجع:
```json
{
  "average_suggestion": {
    "new_avg_if_buy": 1.85,
    "shares_to_buy": 29938,
    "cost_to_average": 52690.88
  }
}
```

---

### 3. تتبع الثروة (Wealth Tracking)

#### `GET /api/money/wealth?section=history&period=90`
تاريخ الثروة اليومي للرسوم البيانية.
```json
{
  "history": [
    {
      "date": "2026-07-11",
      "invested": 6459242,
      "current_value": 96000,
      "pnl": -6363242,
      "net_wealth": 96000,
      "stocks": 208642,
      "gold": 240600,
      "bank": 6010000,
      "income": 0,
      "expenses": 0,
      "obligations": 0
    }
  ],
  "stats": {
    "tracking_days": 1,
    "tracking_since": "2026-07-11",
    "latest_net_wealth": 96000,
    "total_change": 0,
    "best_day": { "date": "2026-07-11", "pnl": -6363242 },
    "worst_day": { "date": "2026-07-11", "pnl": -6363242 },
    "allocation": { "stocks": 208642, "gold": 240600, "bank": 6010000 },
    "cashflow": { "income": 0, "expenses": 0, "net": 0 }
  }
}
```

#### `GET /api/money/wealth?section=expenses`
المصاريف مجمّعة حسب الفئة + التاريخ.

#### `POST /api/money/wealth`
تسجيل لقطة ثروة جديدة (يومية تلقائية via MarketScheduler).

#### `POST /api/money/wealth` (body: `{ type: "expense", ... }`)
إضافة مصروف جديد.

---

### 4. محرك التوقعات المحسّن (Prediction Optimizer)

#### `GET /api/prediction-optimizer/params`
قراءة المعاملات الحالية (11 معامل قابل للتحكم).

#### `POST /api/prediction-optimizer/params`
تحديث المعاملات من لوحة التحكم.

#### `POST /api/prediction-optimizer/params/reset`
إعادة التعيين للقيم الافتراضية.

#### `POST /api/prediction-optimizer/backtest`
اختبار سريع (100 سهم، آخر 60 يوم).

#### `GET /api/market-manager/status`
حالة كل الأسواق (EGX, Crypto, Tadawul).

#### `GET /api/market-manager/analyze?ticker=COMI&market=EGX`
تحليل سهم في سوق معين باستخدام كل المحركات.

---

### 5. الكريبتو (24/7 Live)

#### `GET /api/crypto/live-simulation?limit=10`
تحليل أهم العملات الرقمية لحظياً.

#### `GET /api/crypto/live-simulation?symbol=BTC`
تحليل عملة واحدة.

#### `GET /api/crypto/historical-backtest?symbol=BTC&days=60`
Backtest تاريخي للكريبتو.

#### `GET /api/crypto/available`
قائمة العملات المتاحة.

---

### 6. رفع بيانات EGX

#### `POST /api/admin/egx-indices/upload`
رفع CSV لبيانات EGX30/EGX100.
- Body: FormData (`file` + `indexType`)
- يدعم أعمدة عربية + إنجليزية
- يخزّن في `price_history.db`

#### `GET /api/admin/egx-indices/upload`
حالة بيانات المؤشرات.

---

### 7. أداء التوقعات

#### `GET /api/predictions/performance-dashboard?days=30`
لوحة أداء شاملة (win rate, PF, by signal, by score).

#### `GET /api/predictions/performance/summary`
ملخص سريع للأداء.

---

# 🆕 تحديث يوليو 2026 — APIs الجديدة (v23)

> **تاريخ التحديث:** 14 يوليو 2026
> **سبب التحديث:** إضافة RAG AI pipeline + Live AI Monitor + Trade Recorder + Historical Trade Generator + Smart Portfolio Monitor + إصلاحات schema

## جدول الـ APIs الجديدة

| # | Endpoint | Method | الوصف |
|---|----------|--------|------|
| 1 | `/api/ai/status` | GET | فحص Ollama + قائمة النماذج |
| 2 | `/api/ai/decision/<ticker>` | GET | قرار AI لسهم (BUY/SELL/HOLD + confidence + reason) |
| 3 | `/api/ai/compare` | POST | مقارنة 2-5 أسهم بالـ AI |
| 4 | `/api/ai/ask` | POST | سؤال حر للمحلل «الصايع» |
| 5 | `/api/ai/live/signals` | GET | آخر إشارات AI (آخر N ساعة) |
| 6 | `/api/ai/live/scan` | GET | مسح فوري: hot stocks + AI analysis |
| 7 | `/api/ai/hot-stocks` | GET | الأسهم الساخنة (change + volume + RSI) |
| 8 | `/api/ai/trades/record` | POST | تسجيل صفقة (BUY/SELL) |
| 9 | `/api/ai/trades/<user_id>` | GET | كل صفقات المستخدم |
| 10 | `/api/ai/trades/<user_id>/performance` | GET | إحصائيات الأداء (win rate, avg pnl) |
| 11 | `/api/ai/trades/learn` | POST | تشغيل learning loop يدوياً |
| 12 | `/api/ai/trades/outcomes` | GET | نتائج الصفقات للتحليل |
| 13 | `/api/ai/historical/generate` | GET | توليد صفقات تاريخية للتعلم |
| 14 | `/api/ai/historical/feed-ai` | POST | تغذية AI بالصفقات (→ stock_stories) |
| 15 | `/api/ai/historical/stats` | GET | إحصائيات الصفقات التاريخية |
| 16 | `/api/maestro/regime` | GET | حالة السوق (bull/bear/range) |
| 17 | `/api/admin/trigger-analysis` | POST | تحليل فوري (يتخطّى is_market_open) |
| 18 | `/api/daily/rebuild-predictions` | GET | إحصائيات التوقعات (performance object) |
| 19 | `/api/unified/predictions` | GET/POST | قائمة + trigger التوقعات |
| 20 | `/api/portfolio/smart-monitor` | GET | تحليل ذكي للمحفظة (TAKE_PROFIT/STOP_LOSS/SELL) |
| 21 | `/api/portfolio/smart-monitor/signals` | GET | الإشارات النشطة فقط |

---

## 1. 🤖 AI APIs (الـ prefix: `/api/ai`)

### 1.1 `GET /api/ai/status`
فحص حالة Ollama + قائمة النماذج المثبتة.

**Response:**
```json
{
  "status": "online",
  "models": ["glm-fast:latest", "qwen2.5:1.5b", "qwen3:1.7b"],
  "ollama_url": "http://localhost:11434"
}
```

### 1.2 `GET /api/ai/decision/<ticker>`
قرار AI لسهم معيّن (BUY/SELL/HOLD + confidence + reason + narrative).

**Query params:** None

**Response:**
```json
{
  "ticker": "DSCW",
  "decision": "BUY",
  "confidence": 85,
  "reason": "RSI في المقدمة يشير إلى ارتفاع...",
  "narrative": "السهم فيه مؤشرات إيجابية...",
  "source": "database_precomputed",
  "updated_at": "2026-07-14 07:10:16"
}
```

**`source` values:**
- `database_precomputed` — من كاش nightly_analysis (الأسرع)
- `live_ai` — من استدعاء Ollama لحظياً
- `live_fallback` — لو AI فشل

### 1.3 `POST /api/ai/compare`
مقارنة 2-5 أسهم بالـ AI.

**Body:**
```json
{
  "tickers": ["COMI", "EFID", "HRHO"]
}
```

### 1.4 `POST /api/ai/ask`
سؤال حر للـ AI.

**Body:**
```json
{
  "question": "هل أسهم COMI كويسة للشراء؟",
  "context": {"market": "EGX"}
}
```

### 1.5 `GET /api/ai/live/signals`
آخر إشارات AI (آخر N ساعة).

**Query params:**
- `hours` — عدد الساعات (افتراضي 4)
- `market` — السوق (افتراضي EGX)

**Response:**
```json
{
  "success": true,
  "count": 5,
  "hours": 4,
  "signals": [
    {
      "ticker": "COMI",
      "decision": "BUY",
      "confidence": 75,
      "reason": "...",
      "source": "live_ai",
      "detected_at": "2026-07-14T10:30:00"
    }
  ]
}
```

### 1.6 `GET /api/ai/live/scan`
مسح فوري للأسهم الساخنة + تحليل AI.

**Query params:**
- `market` — السوق (افتراضي EGX)
- `max_stocks` — أقصى عدد أسهم (افتراضي 10)

**Response:**
```json
{
  "success": true,
  "analyzed": 5,
  "success_count": 3,
  "failed": 2,
  "signals": [...]
}
```

### 1.7 `GET /api/ai/hot-stocks`
الأسهم الساخنة بدون AI.

**Query params:**
- `market` — السوق (افتراضي EGX)
- `min_change_pct` — أدنى تغير % (افتراضي 2.0)
- `min_volume_ratio` — أدنى نسبة حجم (افتراضي 1.5)

---

## 2. 📒 Trade Recorder APIs (الـ prefix: `/api/ai/trades`)

### 2.1 `POST /api/ai/trades/record`
تسجيل صفقة مستخدم (BUY/SELL).

**Body:**
```json
{
  "user_id": "user123",
  "ticker": "ELKA",
  "trade_type": "BUY",
  "price": 10.50,
  "quantity": 1000,
  "trade_date": "2026-07-10",
  "notes": "شراء عادي"
}
```

**Response (SELL):**
```json
{
  "success": true,
  "outcome": "WIN",
  "pnl": 2300.0,
  "pnl_pct": 21.9,
  "holding_days": 4,
  "prediction_before_buy": "hold",
  "had_live_signal": 0,
  "pattern_type": "breakout"
}
```

### 2.2 `GET /api/ai/trades/<user_id>`
كل صفقات المستخدم.

**Query params:**
- `limit` — عدد النتائج (افتراضي 50)

### 2.3 `GET /api/ai/trades/<user_id>/performance`
إحصائيات الأداء.

**Response:**
```json
{
  "success": true,
  "stats": {
    "total_trades": 10,
    "wins": 6,
    "losses": 4,
    "win_rate": 60.0,
    "avg_pnl_pct": 5.2,
    "best_trade": {"ticker": "ELKA", "pnl_pct": 21.9},
    "worst_trade": {"ticker": "XYZ", "pnl_pct": -8.0}
  }
}
```

### 2.4 `POST /api/ai/trades/learn`
تشغيل learning loop يدوياً.

**Body:** `{"user_id": "user123"}` (اختياري)

### 2.5 `GET /api/ai/trades/outcomes`
نتائج الصفقات للتحليل.

---

## 3. 📜 Historical Trade Generator APIs (الـ prefix: `/api/ai/historical`)

### 3.1 `GET /api/ai/historical/generate`
توليد صفقات تاريخية للتعلم.

**Query params:**
- `days_back` — عدد الأيام للوراء (افتراضي 180)
- `max_trades_per_ticker` — أقصى صفقات لكل سهم (افتراضي 50)
- `ticker_limit` — عدد الأسهم (0 = الكل، افتراضي 20)

**Response:**
```json
{
  "success": true,
  "total_tickers": 20,
  "successful_tickers": 20,
  "total_trades": 209,
  "elapsed_seconds": 0.5
}
```

### 3.2 `POST /api/ai/historical/feed-ai`
تغذية AI بالصفقات (تحويلها لـ stories في stock_stories table).

**Body:** `{"limit": 10000}`

### 3.3 `GET /api/ai/historical/stats`
إحصائيات الصفقات التاريخية.

**Response:**
```json
{
  "total_historical_trades": 209,
  "fed_to_ai_stories": 39,
  "total_stock_stories": 39,
  "by_outcome": [
    {"outcome": "WIN", "cnt": 81, "avg_pnl": 6.0},
    {"outcome": "LOSS", "cnt": 123, "avg_pnl": -3.2}
  ],
  "by_pattern": [
    {"pattern_type": "pullback", "cnt": 93, "wins": 41},
    {"pattern_type": "accumulation", "cnt": 56, "wins": 18}
  ]
}
```

---

## 4. 🎯 Maestro APIs

### 4.1 `GET /api/maestro/regime` (جديد)
حالة السوق (bull/bear/range).

**Query params:**
- `market` — السوق (افتراضي EGX)

**Response:**
```json
{
  "success": true,
  "market": "EGX",
  "regime": "range",
  "regime_ar": "عرضي",
  "stage": 2,
  "confidence": 50,
  "indicators": {},
  "timestamp": "2026-07-14T12:00:00"
}
```

### 4.2 `POST /api/admin/trigger-analysis` (جديد)
تحليل فوري لـ N أسهم — **يتخطّى `is_market_open` check**.

**Body:**
```json
{
  "market": "EGX",
  "limit": 20
}
```

**Response:**
```json
{
  "success": true,
  "market": "EGX",
  "analyzed": 4,
  "buy_signals": 1,
  "errors": 0,
  "total_stocks": 20,
  "predictions_generated": 3,
  "insert_errors": [],
  "message": "تم تحليل 4 سهم — 1 إشارة شراء — 3 توقع في aiPrediction"
}
```

---

## 5. 📊 Prediction Performance APIs

### 5.1 `GET /api/daily/rebuild-predictions` (محدّث)
إحصائيات التوقعات — الـ schema الكاملة.

**Response:**
```json
{
  "success": true,
  "performance": {
    "total_predictions": 4,
    "active_predictions": 4,
    "closed_predictions": 2,
    "successful": 1,
    "stopped": 1,
    "expired": 0,
    "success_rate": 50.0,
    "avg_return": 2.5,
    "best_return": 5.0,
    "worst_return": 0.0,
    "high_confidence_rate": 25.0,
    "medium_confidence_rate": 50.0,
    "low_confidence_rate": 25.0
  },
  "activePredictions": [...],
  "closedPredictions": [...],
  "stats": {
    "today": 4,
    "weekly": 4,
    "monthly": 4,
    "totalProfitLoss": "+5.00%"
  }
}
```

### 5.2 `GET /api/unified/predictions` (محدّث)
قائمة التوقعات مع **الأسماء العربية + القطاعات**.

**Query params:**
- `market` — السوق (افتراضي ALL)
- `limit` — عدد النتائج (افتراضي 100)

**Response (كل prediction):**
```json
{
  "ticker": "ASCM",
  "symbol": "ASCM",
  "name": "اسيك للتعدين",
  "name_ar": "اسيك للتعدين",
  "sector": "المعادن الأخرى - غير مصادر الطاقة",
  "score": 71.8,
  "maestro_score": 71.8,
  "signal": "BUY",
  "signal_ar": "شراء",
  "entry_price": 60.01,
  "target_price": 66.01,
  "stop_loss": 55.21,
  "confidence": 100.0,
  "regime": "range",
  "created_at": "2026-07-14 12:30:16"
}
```

### 5.3 `POST /api/unified/predictions`
Trigger إعادة بناء التوقعات.

**Body:** `{"market": "EGX"}`

---

## 6. 💼 Smart Portfolio Monitor APIs (الـ prefix: `/api/portfolio`)

### 6.1 `GET /api/portfolio/smart-monitor` (جديد)
تحليل ذكي لمحفظة المستخدم — بيع/شراء/احتفاظ لكل سهم.

**Query params:**
- `user_id` — مطلوب

**Response:**
```json
{
  "success": true,
  "user_id": "user123",
  "summary": {
    "total_assets": 5,
    "total_invested": 10000,
    "total_current_value": 11500,
    "total_pnl": 1500,
    "total_pnl_pct": 15.0,
    "sell_count": 2,
    "buy_more_count": 1,
    "hold_count": 2
  },
  "stock_signals": [
    {
      "ticker": "ELKA",
      "name": "...",
      "current_price": 12.5,
      "purchase_price": 10.5,
      "pnl_pct": 19.0,
      "action": "TAKE_PROFIT",
      "action_ar": "✅ جني أرباح — بِع جزء",
      "reason": "ربح 19.0% — حقق الهدف (+15%)",
      "confidence": 85
    }
  ],
  "alerts": ["✅ ELKA: ربح 19.0% — جني أرباح موصى به"]
}
```

**`action` values:**
- `TAKE_PROFIT` — ربح ≥15%
- `SELL` — RSI>70 + ربح >5%
- `STOP_LOSS` — خسارة ≥8%
- `BUY_MORE` — RSI<30 + خسارة >3% (فرصة متوسط)
- `HOLD` — باقي الحالات

### 6.2 `GET /api/portfolio/smart-monitor/signals` (جديد)
الإشارات النشطة فقط (بدون HOLD) — أسرع endpoint.

---

## 7. 🔫 Sniper Engine APIs (محدّث)

### 7.1 `GET /api/sniper/scan` (محدّث)
مسح الأسهم بـ 5 بوابات — **`min_gates` بقى persona-aware**.

**Query params:**
- `market` — السوق (افتراضي EGX)
- `persona` — `gambler` / `balanced` / `investor` (افتراضي balanced)
- `min_gates` — لو مش محدد، بيتبنى على persona:
  - `gambler` → 2 (يقبل مخاطرة أكبر)
  - `balanced` → 3
  - `investor` → 4 (أكثر حذر)
- `limit` — عدد النتائج (افتراضي 10)

---

## 8. 🗄️ جداول DB الجديدة

### 8.1 `live_ai_signals` (في predictions.db)
إشارات AI اللحظية أثناء الجلسة.

| العمود | النوع | الوصف |
|--------|------|------|
| `id` | INTEGER PK | — |
| `ticker` | TEXT | رمز السهم |
| `decision` | TEXT | BUY/SELL/HOLD/WATCH |
| `confidence` | INTEGER | 0-100 |
| `reason` | TEXT | السبب |
| `narrative` | TEXT | التحليل بالعربي |
| `source` | TEXT | live_ai / hot_stock / breakout / volume_spike |
| `indicators_json` | TEXT | snapshot of indicators |
| `detected_at` | TEXT | ISO timestamp |
| `created_at` | TEXT | datetime('now') |

### 8.2 `user_trades` (في predictions.db)
صفقات المستخدم الفعلية.

| العمود | النوع | الوصف |
|--------|------|------|
| `id` | INTEGER PK | — |
| `user_id` | TEXT | معرف المستخدم |
| `ticker` | TEXT | رمز السهم |
| `trade_type` | TEXT | BUY / SELL |
| `price` | REAL | السعر |
| `quantity` | REAL | العدد |
| `trade_date` | TEXT | ISO date |
| `notes` | TEXT | ملاحظات |
| `created_at` | TEXT | datetime('now') |

### 8.3 `trade_outcomes` (في predictions.db)
نتائج الصفقات + تحليلها.

| العمود | النوع | الوصف |
|--------|------|------|
| `id` | INTEGER PK | — |
| `user_id` | TEXT | — |
| `ticker` | TEXT | — |
| `buy_date` | TEXT | — |
| `buy_price` | REAL | — |
| `sell_date` | TEXT | — |
| `sell_price` | REAL | — |
| `quantity` | REAL | — |
| `pnl` | REAL | الربح/الخسارة بالجنيه |
| `pnl_pct` | REAL | النسبة % |
| `holding_days` | INTEGER | — |
| `outcome` | TEXT | WIN / LOSS / BREAKEVEN |
| `prediction_before_buy` | TEXT | recommendation من stored_analyses |
| `maestro_score_before` | REAL | — |
| `ai_decision_before` | TEXT | — |
| `had_live_signal` | INTEGER | هل فيه live_ai_signal قبل الشراء؟ |
| `pattern_type` | TEXT | breakout/volume_spike/reversal/accumulation |
| `lessons` | TEXT | دروس مستفادة بالعربي |
| `analyzed` | INTEGER | هل الـ learning engine حله؟ |

### 8.4 `historical_trades` (في predictions.db)
صفقات تاريخية مولّدة للتعلم.

| العمود | النوع | الوصف |
|--------|------|------|
| `id` | INTEGER PK | — |
| `ticker` | TEXT | — |
| `strategy` | TEXT | support_bounce/breakout_play/pullback_buy/momentum_ride/value_dip |
| `buy_date` | TEXT | — |
| `buy_price` | REAL | — |
| `sell_date` | TEXT | — |
| `sell_price` | REAL | — |
| `pnl_pct` | REAL | — |
| `holding_days` | INTEGER | — |
| `outcome` | TEXT | WIN / LOSS / BREAKEVEN |
| `pattern_type` | TEXT | breakout/reversal/accumulation/momentum/volume_spike/pullback |
| `market_condition` | TEXT | bull / bear / sideways |
| `rsi_at_buy` | REAL | — |
| `volume_ratio_at_buy` | REAL | — |
| `lesson_text` | TEXT | story عربية للـ AI |
| `fed_to_ai` | INTEGER | هل اتبعتت لـ stock_stories؟ |

---

## 9. 🔄 Scheduler Tasks الجديدة

| الـ Task | التكرار | الوقت | الوصف |
|---------|--------|------|------|
| `run_live_ai_scan` | كل 15 دقيقة | أثناء الجلسة | كشف أسهم ساخنة + AI analysis |
| `run_daily_trade_learning` | يومياً | 15:30 post-market | تحليل صفقات المستخدم |
| `run_weekly_historical_learning` | أسبوعياً (السبت) | 16:00 | توليد صفقات تاريخية + feed AI |

---

## 10. 📝 ملاحظات للموبايل

### 10.1 الـ endpoints اللي محتاجها auth
- `/api/ai/trades/*` — محتاجة `user_id`
- `/api/portfolio/smart-monitor*` — محتاجة `user_id`
- `/api/portfolio/*` — محتاجة auth token

### 10.2 الـ endpoints المفتوحة
- `/api/ai/status` — فحص Ollama
- `/api/ai/decision/<ticker>` — قرار AI (ممكن بدون auth)
- `/api/ai/hot-stocks` — أسهم ساخنة
- `/api/ai/live/scan` — مسح فوري
- `/api/maestro/regime` — حالة السوق
- `/api/unified/predictions` — قائمة التوقعات
- `/api/daily/rebuild-predictions` — إحصائيات

### 10.3 الـ response format الموحّد
كل الـ endpoints الجديدة بترجّع:
```json
{
  "success": true/false,
  "error": "رسالة الخطأ (لو فيه)",
  ...data
}
```

### 10.4 الـ errors
- `400` — bad request (field مطلوب ناقص)
- `404` — السهم مش موجود
- `500` — internal error (الـ response بيرجّع 200 مش 500 عشان الـ frontend ما يفصلش)
- `503` — service unavailable (Ollama واقل مثلاً)

### 10.5 الـ rate limiting
مفيش rate limiting حالياً. بس الـ AI endpoints (`/api/ai/live/scan`, `/api/ai/decision`) بياخدوا وقت (30-60s) عشان Ollama. يفضل الـ mobile يعمل timeout = 90s.


---

# 🆕 تحديث إضافي يوليو 2026 — Telegram Importer + Premium

## Telegram Signal Importer APIs (جديد)

| # | Endpoint | Method | الوصف |
|---|----------|--------|------|
| 1 | `/api/ai/telegram/import` | POST | استيراد توصيات من جروب |
| 2 | `/api/ai/telegram/evaluate` | POST | تقييم التوصيات (بعد N أيام) |
| 3 | `/api/ai/telegram/stats` | GET | إحصائيات التوصيات |
| 4 | `/api/ai/telegram/signals` | GET | قائمة التوصيات |

### `POST /api/ai/telegram/import`
**Body:** `{"group_username": "@group_name", "limit": 100}`

**Response:** `{"success": true, "imported": 25, "skipped": 75}`

### `POST /api/ai/telegram/evaluate`
**Body:** `{"days_back": 7}`

**Response:**
```json
{
  "success": true,
  "evaluated": 20,
  "wins": 12,
  "losses": 8,
  "win_rate": 60.0
}
```

## Premium Predictions APIs (جديد)

### `GET /api/ai/premium/predictions`
توقعات أعمق للمدفوعين.

**Query params:**
- `market` — السوق (افتراضي EGX)
- `limit` — عدد النتائج (افتراضي 10، حد أقصى 20)
- `tier` — فلترة (1/2/3/all)

**Response:**
```json
{
  "success": true,
  "premium": true,
  "count": 5,
  "predictions": [
    {
      "ticker": "COMI",
      "name": "البنك التجاري الدولي",
      "tier": {
        "number": 1,
        "name": "Strong Buy",
        "name_ar": "شراء قوي",
        "description": "🟢 عوامل متفقة بقوة — فرصة ممتازة"
      },
      "confluence_score": 82.5,
      "maestro_score": 85,
      "ai_confidence": 75,
      "risk_reward": 2.5,
      "premium_features": {
        "ai_narrative": "تحليل AI متقدم...",
        "risk_assessment": "...",
        "multi_factor": true
      }
    }
  ],
  "tier_distribution": {"1": 2, "2": 3, "3": 0, "4": 0}
}
```

### Confidence Tiers
| Tier | Score | المعنى |
|------|-------|--------|
| 1 | ≥75 | 🟢 Strong Buy — فرصة ممتازة |
| 2 | 60-74 | 🟡 Buy — فرصة جيدة |
| 3 | 45-59 | 🟠 Accumulate — تجميع تدريجي |
| 4 | <45 | ⚪ Watch — انتظر تأكيد |

