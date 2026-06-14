# Z.AI Bridge - API Specifications for Flutter Mobile App

## 🔄 Revision History
| Date | Version | Changed By |
|------|---------|-----------|
| 2026-05-14 | v1 — Initial bridge request for all mobile endpoints | Kilo Team |
| 2026-05-15 | v2 — Added full Subscription System spec + lazy reset (no cron) | Kilo + Z.AI |

---

---

## 📱 Endpoints Summary

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/stocks/[ticker]` | GET | Stock details (use `?flat=1` for mobile) |
| `/api/stocks/[ticker]/history` | GET | Price history chart data |
| `/api/stocks/[ticker]/recommendation` | GET | Stock recommendation |
| `/api/stocks/[ticker]/professional-analysis` | GET | Expert analysis |
| `/api/mobile/expert-recommendations` | GET | Expert recommendations list |
| `/api/mobile/zakat-calculator` | POST | Zakat calculator |
| `/api/mobile/analysis/[ticker]` | GET | Detailed stock analysis |
| `/api/auth/google` | POST | Google login |
| `/api/auth/me` | GET | Current user info |

---

## 1. Stock Details

### GET `/api/stocks/[ticker]?flat=1`

**Use `flat=1` for mobile app - returns flat structure**

```json
{
  "ticker": "GBCO",
  "name": "GB Corp",
  "name_ar": "جي بي كورب",
  "current_price": 29.30,
  "previous_close": 28.50,
  "open_price": 28.75,
  "high_price": 29.50,
  "low_price": 28.60,
  "volume": 1250000,
  "sector": "Financials",
  "market_cap": 15000000000,
  "price_change": 2.81,
  "egx30_member": false,
  "egx70_member": true,
  "egx100_member": true,
  "is_halal": null,
  "investment_type": "stock",
  "source": "local"
}
```

**Query params:**
- `flat=1` - Return flat structure (required for mobile)
- `history=30` - Include last 30 days of price history
- `live=1` - Fetch live price from external APIs

---

## 2. Stock Recommendation

### GET `/api/stocks/[ticker]/recommendation`

```json
{
  "success": true,
  "ticker": "GBCO",
  "action": "BUY",
  "recommendation": "BUY",
  "confidence": 72.5,
  "target_price": 32.00,
  "stop_loss": 27.50,
  "current_price": 29.30,
  "risk_level": "medium",
  "reasons": [
    "Strong earnings growth",
    "Positive technical momentum",
    "Good support zone at 28.70"
  ]
}
```

**Important:**
- `confidence` is `null` or omitted if not available (NOT 0)
- `action` and `recommendation` are the same field (both included for compatibility)
- Valid actions: `BUY`, `SELL`, `HOLD`

---

## 3. Professional Analysis

### GET `/api/stocks/[ticker]/professional-analysis`

```json
{
  "success": true,
  "ticker": "GBCO",
  "technical_analysis": "The stock is in a bullish trend with strong momentum above key moving averages.",
  "fundamental_analysis": "Earnings are above expectations and the balance sheet looks healthy.",
  "overall_rating": "BUY",
  "rating": "BUY",
  "technical_score": 78,
  "fundamental_score": 74,
  "key_points": [
    "RSI is stable around 60",
    "Volume increased on the last three sessions",
    "Strong support at 28.70",
    "No major resistance until 32"
  ],
  "points": [
    "RSI is stable around 60",
    "Volume increased on the last three sessions"
  ],
  "recommendation": {
    "action": "BUY",
    "confidence": 70,
    "target_price": 32.00,
    "stop_loss": 27.50
  }
}
```

**Note:** Both `key_points` and `points` are included for compatibility.

---

## 4. Expert Recommendations (Mobile)

### GET `/api/mobile/expert-recommendations`

**Returns expert recommendations in the exact format needed:**

```json
{
  "success": true,
  "recommendations": [
    {
      "id": "abc123",
      "ticker": "GBCO",
      "name_ar": "جي بي كورب",
      "last_price": 29.30,
      "action": "BUY",
      "status": "PENDING",
      "expert_name": "محلل مالي",
      "session_date": "14-5-2026",
      "session_type": "صباحية",
      "buy_range": "من 29.20 إلى 29 جنيه",
      "buy_condition": "أو الاستقرار والثبات أعلى 29.35",
      "support": 28.70,
      "targets": ["30.30", "31 جنيه"],
      "investment_target": 31.90,
      "expected_profit": "من 6% إلى 9%",
      "stop_loss": "كسر 28.10",
      "technical_analysis": "السهم في ترند صاعد...",
      "notes": "توصية قوية"
    },
    {
      "id": "def456",
      "ticker": "ATQA",
      "name_ar": "عتاقة",
      "last_price": 10.12,
      "action": "BUY",
      "buy_range": "حوالي 10.05 جنيه",
      "buy_condition": "أو الاستقرار أعلى 10.15",
      "targets": ["10.40", "10.60 جنيه"],
      "investment_target": 10.96,
      "expected_profit": "من 6% إلى 9%",
      "stop_loss": "كسر 9.90 إغلاق"
    }
  ],
  "groupedByDate": {
    "14-5-2026": [...],
    "13-5-2026": [...]
  },
  "session_dates": [
    { "date": "14-5-2026", "type": "صباحية", "count": 5 },
    { "date": "13-5-2026", "type": "مسائية", "count": 3 }
  ],
  "total": 8
}
```

**Query params:**
- `status=PENDING` or `status=PENDING,ACTIVE` - Filter by status
- `session_date=14-5-2026` - Filter by session date
- `limit=50` - Limit results

---

## 5. Zakat Calculator

### POST `/api/mobile/zakat-calculator`

**Request:**
```json
{
  "stocks": [
    { "ticker": "COMI", "shares": 100, "current_price": 25.50, "is_for_trade": true }
  ],
  "gold_grams": 50,
  "gold_karat": 21,
  "cash": 10000,
  "other_assets": 5000,
  "debts": 2000,
  "calculation_method": "gold",
  "agricultural_income": 50000,
  "irrigation_type": "rain"
}
```

**Response:**
```json
{
  "success": true,
  "nisab": {
    "value": 340000,
    "method": "ذهب (85 جرام)",
    "grams": 85,
    "price_per_gram": 4000,
    "met": true
  },
  "assets": {
    "stocks": {
      "value": 2550,
      "count": 1,
      "details": [
        {
          "ticker": "COMI",
          "shares": 100,
          "current_price": 25.50,
          "market_value": 2550,
          "zakat": 63.75,
          "type": "تجارة"
        }
      ]
    },
    "gold": {
      "grams": 50,
      "karat": 21,
      "price_per_gram": 4000,
      "value": 200000
    },
    "cash": 10000,
    "other": 5000,
    "total": 217550,
    "net": 215550
  },
  "debts": 2000,
  "zakat": {
    "rate": 0.025,
    "rate_percent": "2.5%",
    "stocks_zakat": 63.75,
    "gold_zakat": 5000,
    "cash_zakat": 250,
    "other_zakat": 125,
    "agricultural_tenth": 5000,
    "total": 10438.75,
    "due": true
  },
  "agricultural": {
    "income": 50000,
    "irrigation_type": "مطر/سيح",
    "rate": "10%",
    "tenth_due": 5000
  },
  "summary": {
    "nisab_met": true,
    "total_assets": 217550,
    "net_assets": 215550,
    "zakat_due": 10438.75,
    "message": "يجب عليك إخراج زكاة قدرها 10438.75 جنيه مصري"
  }
}
```

### GET `/api/mobile/zakat-calculator`

**Returns current nisab values:**

```json
{
  "success": true,
  "nisab": {
    "gold": {
      "grams": 85,
      "price_per_gram": 4000,
      "total_value": 340000,
      "description": "85 جرام ذهب"
    },
    "silver": {
      "grams": 595,
      "price_per_gram": 50,
      "total_value": 29750,
      "description": "595 جرام فضة"
    },
    "recommended": "silver",
    "recommendation_reason": "الأقل أفضل للفقير"
  },
  "zakat_rate": {
    "percent": "2.5%",
    "fraction": "1/40"
  },
  "tenth_rates": {
    "rain_irrigation": "10%",
    "artificial_irrigation": "5%"
  }
}
```

---

## 6. Detailed Stock Analysis

### GET `/api/mobile/analysis/[ticker]`

```json
{
  "success": true,
  "ticker": "GBCO",
  "name_ar": "جي بي كورب",
  "name_en": "GB Corp",
  "sector": "Financials",
  "current_price": 29.30,
  "previous_close": 28.50,
  "price_change": 2.81,
  "volume": 1250000,
  "market_cap": 15000000000,
  "egx30_member": false,
  "egx70_member": true,
  "egx100_member": true,
  "is_halal": null,
  "data_available": true,
  
  "technical_indicators": {
    "rsi": 58.5,
    "macd": 0.45,
    "macd_signal": "bullish",
    "ma_20": 28.80,
    "ma_50": 27.50,
    "ma_200": 25.00,
    "bb_upper": 31.00,
    "bb_lower": 26.00,
    "atr": 1.20,
    "volume_trend": "increasing"
  },
  
  "price_levels": {
    "support": 28.70,
    "resistance": 31.00,
    "pivot": 29.30,
    "entry_zone": "28.70 - 29.20",
    "target_1": 30.30,
    "target_2": 31.00,
    "stop_loss": 28.10
  },
  
  "recommendation": {
    "action": "BUY",
    "action_ar": "شراء",
    "confidence": 72,
    "horizon": "قصير المدى",
    "reasons": ["Strong momentum", "Good support level"]
  },
  
  "risk_assessment": {
    "level": "medium",
    "level_ar": "متوسط",
    "score": 45,
    "factors": ["Market volatility", "Sector risk"]
  },
  
  "key_points": [
    "السهم يتحرك فوق المتوسط المتحرك 50 يوم",
    "حجم التداول في ارتفاع",
    "مستوى دعم قوي عند 28.70"
  ],
  
  "predictions": {
    "short_term": "صعودي",
    "medium_term": "محايد",
    "long_term": "صعودي",
    "probability_up": 65,
    "probability_down": 25,
    "probability_neutral": 10
  },
  
  "signals": {
    "trend": "bullish",
    "trend_ar": "صعودي",
    "strength": "strong",
    "momentum": "positive",
    "volume_signal": "bullish",
    "overall_signal": "buy"
  },
  
  "scores": {
    "total": 72,
    "technical": 78,
    "fundamental": 65,
    "momentum": 75,
    "risk": 45
  },
  
  "analysis_date": "2026-05-14T10:30:00Z",
  "data_points": 250
}
```

---

## 7. Google Authentication

### POST `/api/auth/google`

**Request:**
```json
{
  "id_token": "google_id_token_from_sdk"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Google login successful",
  "message_ar": "تم تسجيل الدخول عبر جوجل بنجاح",
  "user": {
    "id": "user-uuid",
    "email": "user@gmail.com",
    "username": "username",
    "name": "User Name",
    "image": "https://...",
    "subscription_tier": "free",
    "is_admin": false
  },
  "token": "egx_user_uuid_token_timestamp",
  "token_type": "Bearer",
  "expires_in": 2592000,
  "is_new_user": false
}
```

**Flutter Usage:**
```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String?> signInWithGoogle() async {
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
  final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
  final String? idToken = googleAuth?.idToken;
  
  if (idToken == null) return null;
  
  final response = await http.post(
    Uri.parse('https://invist.m2y.net/api/auth/google'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'id_token': idToken}),
  );
  
  final data = jsonDecode(response.body);
  if (data['success']) {
    return data['token']; // Bearer token
  }
  return null;
}
```

---

## 8. Current User Info

### GET `/api/auth/me`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "user-uuid",
    "email": "user@gmail.com",
    "username": "username",
    "name": "User Name",
    "image": "https://...",
    "subscription_tier": "free",
    "is_admin": false
  }
}
```

---

## 📝 Important Notes

### Error Format
All errors return:
```json
{
  "success": false,
  "error": "Error message",
  "message_ar": "رسالة الخطأ بالعربية"
}
```

### Authentication
- All endpoints that require authentication use Bearer token
- Include header: `Authorization: Bearer {token}`
- Token obtained from `/api/auth/google`

### Base URL
```
Production: https://invist.m2y.net
Local: http://localhost:3000
```

---

## 🤖 Z.AI Reply

> Replace this section with the Z.AI response.
> 
> The Z.AI agent should include:
> - which endpoint(s) are missing or incorrect
> - the exact JSON contract it will implement
> - any new field names required by the mobile app
> - whether the response will come from the Node.js API or the Python backend
> 
> Example:
> ```json
> {
>   "endpoint": "/api/stocks/[ticker]/recommendation",
>   "status": "required",
>   "fields": ["action", "confidence", "target_price", "stop_loss", "reasons", "risk_level"]
> }
> ```

---

## 🔐 Subscription System — Mobile App API Specification

**Status:** 🚧 Awaiting Z.AI Implementation  
**Priority:** Critical (blocking mobile app release)  
**Platforms affected:** Flutter Mobile + Website (shared backend)

---

### 📌 Context & Problem

The Flutter app (`lib/screens/subscription_screen.dart`) already has a subscription screen connected to these endpoints:

```
GET  /api/subscription/plans
GET  /api/subscription/current
POST /api/subscription/activate
POST /api/subscription/start-trial
POST /api/subscription/upgrade
POST /api/subscribe/[plan]
POST /api/paymob/create-payment
```

**Current issues:**
1. The `/api/subscription/plans` response format in `APIlist.md` only has 3 fields (`id, name, price`) — missing critical fields like `duration_days`, `features`, `max_watchlist`, `max_portfolio`, etc. that the mobile `SubscriptionPlan` model expects.
2. No endpoint to **check feature access** before consuming a paid feature.
3. No endpoint to **verify Google Play Billing receipts** (mobile path).
4. Website pays via **PayMob**, mobile pays via **Google Play** — both must write to the same subscription record.
5. No daily quota/limit tracking endpoint (for "daily free uses" logic).
6. **No cron job needed** — daily resets happen lazily inside endpoint calls (no external scheduler).

---

### 🎯 Requirements

#### 1. Unified Subscription Source

Both Website and Mobile App must read/write from **the same database table/collection** for subscriptions. The user must have exactly **one active subscription** regardless of which platform they paid from.

---

#### 2. Subscription Plans

**Three tiers only:**

| Tier | ID | Price (EGP) | Period | Core Limits |
|------|-----|-------------|--------|-------------|
| Free | `free` | 0 | Lifetime | 3 portfolio items, 3 watchlist items, 2 AI analyses/day |
| Plus | `plus` | 49 | 7 days | Unlimited portfolio, unlimited watchlist, unlimited recommendations + AI analysis |
| Premium | `premium` | 99 | 7 days | Everything in Plus + Predictions + Priority support |

**Plans must be seedable via `POST /api/admin/subscription/seed` with these exact values.**

---

#### 3. API Endpoints Required

##### 3.1 `GET /api/subscription/plans` — List Plans

**Request:** None (no auth required for public listing)

**Response (UPDATE THIS — current is incomplete):**
```json
{
  "success": true,
  "plans": [
    {
      "id": "free",
      "name": "Free",
      "name_ar": "مجاني",
      "price": 0,
      "currency": "EGP",
      "duration_days": 0,
      "trial_days": null,
      "features": [
        "عرض جميع الأسهم",
        "أسعار العملات الرقمية",
        "أسعار الذهب والعملات",
        "حاسبة الزكاة",
        "3 أسهم في المحفظة",
        "3 أسهم في المتابعة",
        "2 تحليل ذكي في اليوم"
      ],
      "is_popular": false,
      "max_watchlist": 3,
      "max_portfolio": 3,
      "max_alerts": 3,
      "max_daily_ai_analysis": 2,
      "max_daily_recommendations": 0,
      "ai_analysis": false,
      "recommendations": true,
      "predictions": false,
      "priority_support": false,
      "reports_export": false
    },
    {
      "id": "plus",
      "name": "Plus",
      "name_ar": "بلس",
      "price": 49,
      "currency": "EGP",
      "duration_days": 7,
      "trial_days": 7,
      "features": [
        "كل مزايا المجاني",
        "محفظة غير محدودة",
        "قائمة متابعة غير محدودة",
        "توصيات احترافية غير محدودة",
        "تحليل ذكي غير محدود"
      ],
      "is_popular": true,
      "max_watchlist": null,
      "max_portfolio": null,
      "max_alerts": null,
      "max_daily_ai_analysis": null,
      "max_daily_recommendations": null,
      "ai_analysis": true,
      "recommendations": true,
      "predictions": false,
      "priority_support": false,
      "reports_export": false
    },
    {
      "id": "premium",
      "name": "Premium",
      "name_ar": "بريميوم",
      "price": 99,
      "currency": "EGP",
      "duration_days": 7,
      "trial_days": null,
      "features": [
        "كل مزايا بلس",
        "تنبؤات الأسعار",
        "دعم أولوية",
        "تصدير التقارير PDF"
      ],
      "is_popular": false,
      "max_watchlist": null,
      "max_portfolio": null,
      "max_alerts": null,
      "max_daily_ai_analysis": null,
      "max_daily_recommendations": null,
      "ai_analysis": true,
      "recommendations": true,
      "predictions": true,
      "priority_support": true,
      "reports_export": true
    }
  ]
}
```

**New fields added (Flutter needs these):**
| Field | Type | Description |
|-------|------|-------------|
| `duration_days` | int | Plan duration in days (0 = lifetime) |
| `trial_days` | int? | Free trial days (null = no trial) |
| `max_watchlist` | int? | Max watchlist items (null = unlimited) |
| `max_portfolio` | int? | Max portfolio items (null = unlimited) |
| `max_alerts` | int? | Max price alerts (null = unlimited) |
| `max_daily_ai_analysis` | int? | Daily AI analysis limit (null = unlimited) |
| `max_daily_recommendations` | int? | Daily recommendations limit (null = unlimited) |
| `ai_analysis` | bool | Feature flag: AI analysis access |
| `recommendations` | bool | Feature flag: Expert recommendations access |
| `predictions` | bool | Feature flag: Price predictions access |
| `priority_support` | bool | Feature flag: Priority support |
| `reports_export` | bool | Feature flag: Export PDF reports |

---

##### 3.2 `GET /api/subscription/current` — Current Subscription

**Request:** Auth required

**Response (extend current):**
```json
{
  "success": true,
  "subscription": {
    "id": "sub-uuid",
    "tier": "free",
    "plan_id": "free",
    "status": "active",
    "started_at": "2026-05-01T00:00:00Z",
    "expires_at": null,
    "trial_ends_at": null,
    "is_trial": false,
    "payment_provider": null,
    "payment_id": null,
    "created_at": "2026-05-01T00:00:00Z",
    "updated_at": "2026-05-15T00:00:00Z"
  },
 
  "usage_today": {
    "ai_analysis_count": 1,
    "recommendations_count": 0,
    "resets_at": "2026-05-16T00:00:00+02:00"
  },
  "limits": {
    "max_ai_analysis_per_day": 2,
    "max_recommendations_per_day": 0,
    "max_portfolio_items": 3,
    "max_watchlist_items": 3
  }
}
```

---

##### 3.3 `POST /api/subscription/check-access` — Feature Access Check

**Request:** Auth required

```json
{
  "feature": "ai_analysis"
}
```

Valid `feature` values:
| Feature key | Description |
|-------------|-------------|
| `ai_analysis` | AI stock analysis |
| `recommendations` | Expert recommendations |
| `predictions` | Price predictions |
| `reports_export` | PDF exports |
| `portfolio_unlimited` | Beyond 3 item limit |
| `watchlist_unlimited` | Beyond 3 item limit |

**Response:**
```json
{
  "success": true,
  "feature": "ai_analysis",
  "has_access": true,
  "reason": null,
  "tier": "plus",
  "remaining_today": 1,
  "limit_per_day": 2,
  "resets_at": "2026-05-16T00:00:00+02:00"
}
```

**If access is denied:**
```json
{
  "success": true,
  "feature": "ai_analysis",
  "has_access": false,
  "reason": "لقد استخدمت الحد اليومي للتحليل الذكي. قم بالترقية لـ بلس للحصول على استخدام غير محدود.",
  "reason_en": "You've used your daily AI analysis limit. Upgrade to Plus for unlimited access.",
  "tier": "free",
  "remaining_today": 0,
  "limit_per_day": 2,
  "resets_at": "2026-05-16T00:00:00+02:00",
  "upgrade_to": "plus"
}
```

---

##### 3.4 `POST /api/google-play/verify-receipt` — Google Play Purchase Verification

**Request:** Auth required

```json
{
  "product_id": "com.investmentplus.weekly",
  "purchase_token": "google_play_purchase_token_here",
  "order_id": "GPA.1234-5678-9012-34567"
}
```

**Response on success:**
```json
{
  "success": true,
  "subscription": {
    // Same as GET /api/subscription/current response
    "id": "sub-uuid",
    "tier": "plus",
    "plan_id": "plus",
    "status": "active",
    "started_at": "2026-05-15T00:00:00Z",
    "expires_at": "2026-05-22T00:00:00Z",
    "trial_ends_at": null,
    "is_trial": false,
    "payment_provider": "google_play",
    "payment_id": "GPA.1234-5678-9012-34567"
  }
}
```

This endpoint MUST:
1. Verify the receipt with Google Play Developer API
2. Create or update the user's subscription record
3. Set `payment_provider = 'google_play'` and `payment_id = order_id`
4. Set `expires_at` based on product `duration_days`
5. Handle trial verification (if product has trial)

**Google Play Product IDs mapping:**
| Product ID (Google Play) | Plan Tier | Duration |
|--------------------------|-----------|----------|
| `com.investmentplus.weekly` | `plus` | 7 days |
| `com.investmentplus.premium_weekly` | `premium` | 7 days |

---

##### 3.5 `POST /api/paymob/confirm-payment` — PayMob Webhook/Callback Confirmation

**Request:** Auth not required (called from PayMob webhook or website redirect)

```json
{
  "paymob_order_id": "order_12345",
  "paymob_transaction_id": "txn_67890",
  "user_id": "user-uuid",
  "plan_id": "plus",
  "amount": 49,
  "currency": "EGP",
  "payment_status": "CAPTURED"
}
```

**Response:**
```json
{
  "success": true,
  "subscription": {
    // Same subscription object as above
    "id": "sub-uuid",
    "tier": "plus",
    "status": "active",
    "expires_at": "2026-05-22T00:00:00Z",
    "payment_provider": "paymob",
    "payment_id": "txn_67890"
  }
}
```

---

##### 3.6 `POST /api/subscription/start-trial` — Start Free Trial

**Request:** Auth required

```json
{
  "plan_id": "plus"
}
```

**Response:**
```json
{
  "success": true,
  "subscription": {
    "id": "sub-uuid",
    "tier": "plus",
    "status": "trialing",
    "started_at": "2026-05-15T00:00:00Z",
    "trial_ends_at": "2026-05-22T00:00:00Z",
    "expires_at": "2026-05-22T00:00:00Z",
    "is_trial": true
  }
}
```

**Rules:**
- Only allow trial if user hasn't used one before (`trial_used = false`)
- Max 1 trial per user ever
- Trial auto-converts to paid after trial_ends_at (prompt user)

---

##### 3.7 `POST /api/subscription/upgrade` — Upgrade Plan

**Request:** Auth required

```json
{
  "plan_id": "premium"
}
```

**Response:** Same as payment confirmation (prorates remaining time if needed — optional)

---

#### 4. Daily Usage Tracking (Quota System)

The backend must track **daily feature usage** per user per calendar day (UTC or Egypt timezone `Africa/Cairo`).

**Table/Collection: `subscription_usage`**

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID / ObjectId | Primary key |
| `user_id` | UUID | Foreign key to user |
| `date` | date | Calendar date (UTC midnight) |
| `ai_analysis_count` | int | Default 0 |
| `recommendations_count` | int | Default 0 |
| `created_at` | datetime | Row created time |
| `updated_at` | datetime | Last update time |

**Logic:**
- On `POST /api/subscription/check-access`, increment the relevant counter atomically if access is granted
- On `GET /api/subscription/current`, return today's usage counts
- Auto-reset: new row per user per day (or increment at midnight)
- For **unlimited** tiers (Plus/Premium), don't increment — just return `has_access: true`

---

#### 5. Database Schema (PostgreSQL)

```sql
-- Plans (seedable)
CREATE TABLE subscription_plans (
  id TEXT PRIMARY KEY,          -- 'free', 'plus', 'premium'
  name TEXT NOT NULL,
  name_ar TEXT NOT NULL,
  price INTEGER NOT NULL,       -- in smallest currency unit (piasters) or use NUMERIC
  duration_days INTEGER NOT NULL,
  trial_days INTEGER,
  features JSONB NOT NULL DEFAULT '[]',
  is_popular BOOLEAN DEFAULT false,
  max_watchlist INTEGER,
  max_portfolio INTEGER,
  max_alerts INTEGER,
  max_daily_ai_analysis INTEGER,
  max_daily_recommendations INTEGER,
  ai_analysis BOOLEAN DEFAULT false,
  recommendations BOOLEAN DEFAULT false,
  predictions BOOLEAN DEFAULT false,
  priority_support BOOLEAN DEFAULT false,
  reports_export BOOLEAN DEFAULT false,
  google_play_product_id TEXT,
  paymob_integration_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User subscriptions (one active per user)
CREATE TABLE user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_id TEXT NOT NULL REFERENCES subscription_plans(id),
  status TEXT NOT NULL DEFAULT 'active', -- 'active', 'canceled', 'expired', 'trialing'
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  trial_ends_at TIMESTAMPTZ,
  trial_used BOOLEAN DEFAULT false,
  is_trial BOOLEAN DEFAULT false,
  payment_provider TEXT, -- 'google_play', 'paymob', 'admin', 'manual'
  payment_id TEXT,
  canceled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Daily usage tracking
CREATE TABLE subscription_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  ai_analysis_count INTEGER DEFAULT 0,
  recommendations_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- Indexes
CREATE INDEX idx_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON user_subscriptions(status);
CREATE INDEX idx_subscription_usage_user_date ON subscription_usage(user_id, date);
```

---

#### 6. Daily Reset — No Cron Job (Lazy In-Request Reset)

> **🚫 No cron job, no external scheduler, no Vercel/PM2 task required.**

Instead, the app uses **lazy same-request reset** — a zero-dependency, infinitely-repeatable lazy-indexed storage pattern. The reset check runs inside a **single database write call** and can be repeated as many times as needed without cost.

The reset is triggered when the **server detects that the calendar day has changed** since the last reset, which happens onevery `POST /api/subscription/check-access` or `GET /api/subscription/current` call — **no separate background job is ever needed**.

---

##### 6.1 Add `last_reset_date` Column

Add this to the `subscription_usage` table schema:

```sql
ALTER TABLE subscription_usage
  ADD COLUMN IF NOT EXISTS last_reset_date DATE NOT NULL DEFAULT CURRENT_DATE;
```

This column records the **date when the last counter reset actually happened** (not just any date the row was created), so the server can compare it against today's date.

---

##### 6.2 Reset Logic — Run on Endpoint Call (No Job Needed)

On `POST /api/subscription/check-access`: 

```javascript
// Inside the same DB write call (single atomic transaction)
function ensureDailyReset(userId) {
  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD in Africa/Cairo

  const result = await db.query(`
    INSERT INTO subscription_usage (user_id, date, ai_analysis_count, recommendations_count, last_reset_date)
    VALUES ($1, $2, 0, 0, $2)
    ON CONFLICT (user_id, date)
    DO UPDATE SET
      last_reset_date = EXCLUDED.last_reset_date
    WHERE subscription_usage.last_reset_date < EXCLUDED.last_reset_date
    RETURNING ai_analysis_count, recommendations_count
  `, [userId, today]);

  return result.rows[0];
}
```

Or equivalently, in a single-row approach without upsert:

```sql
-- Step 1: Check if reset is needed
SELECT last_reset_date FROM subscription_usage
WHERE user_id = $1 ORDER BY date DESC LIMIT 1;

-- Step 2: If last_reset_date < today → reset
UPDATE subscription_usage
SET ai_analysis_count = 0,
    recommendations_count = 0,
    last_reset_date = CURRENT_DATE
WHERE user_id = $1 AND last_reset_date < CURRENT_DATE;
```

**Key properties:**
- ✅ **No cron job** → reset lives entirely in endpoint logic
- ✅ **Idempotent** → running it 1000 times for the same user on the same day is free/fast (no-op after first run)
- ✅ **Infinite-repeatable** → no state gets corrupted by repeated calls
- ✅ **Zero cost** → no background task, no scheduler, no monitoring needed
- ✅ **Always-correct** → counter is valid the instant a new day begins

---

##### 6.3 Zero-Dependency Version (If You Don't Want a DB Write)

If you prefer to avoid even a DB write on every request, store the **current Egypt date** in `SharedPreferences` (client-side) and compare server-side against `UTC+2`.

```javascript
// Server: compute Egypt date without knowing the user's TZ
function getEgyptDate() {
  const now = new Date();
  // Egypt is UTC+2 (or UTC+3 in summer), server already runs in UTC
  const egyptOffset = 2; // or 3 during EEST
  const egyptTime = new Date(now.getTime() + egyptOffset * 60 * 60 * 1000);
  return egyptTime.toISOString().split('T')[0]; // e.g. "2026-05-16"
}
```

Then compare `getEgyptDate()` against the user's `last_reset_date` in the DB using pure SQL:

```sql
UPDATE subscription_usage
SET ai_analysis_count = 0,
    recommendations_count = 0,
    last_reset_date = CURRENT_DATE
WHERE user_id = $1
  AND last_reset_date < (CURRENT_DATE + INTERVAL '2 hours');
```

No cron. No job. No scheduler. **Just one `UPDATE` statement, run inside `check-access`.**

---

##### 6.4 No-Nightly-Batch Alternative (Single Transaction Summary)

The storage is **infinitely repeatable** — if the server restarts or the endpoint is called twice in the same day, the second call is a no-op. This is the core property: there are **no batch jobs**, only a single-row lazy-update pattern.

```sql
-- This is the only query ever run. Run it as many times as you want.
INSERT INTO subscription_usage (user_id, date, ai_analysis_count, recommendations_count, last_reset_date)
VALUES ($1, CURRENT_DATE, 0, 0, CURRENT_DATE)
ON CONFLICT (user_id, date) DO NOTHING;
```

After this one basic set-up, the `check-access` endpoint can safely assume:
- `usage_row` **already exists** for today
- `last_reset_date <= today` by definition
- **No reset ever needed** — counters are already correct from the moment a new day begins


---

#### 7. Updated Endpoints Summary

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| GET | `/api/subscription/plans` | ❌ No | List all plans with full details |
| GET | `/api/subscription/current` | ✅ Yes | Current user's full subscription status + usage today (runs lazy reset) |
| POST | `/api/subscription/check-access` | ✅ Yes | Check if user can use a feature right now + lazy reset |
| POST | `/api/subscription/start-trial` | ✅ Yes | Start 7-day free trial (Plus) |
| POST | `/api/subscription/activate` | ✅ Yes | Manually activate a plan (admin) |
| POST | `/api/subscription/upgrade` | ✅ Yes | Upgrade/downgrade mid-cycle |
| POST | `/api/subscribe/[plan]` | ✅ Yes | Subscribe via PayMob (website path — keep for backward compat) |
| POST | `/api/google-play/verify-receipt` | ✅ Yes | Verify Google Play purchase and create subscription |
| POST | `/api/paymob/confirm-payment` | ❌ Webhook | Confirm PayMob payment and create subscription |
| POST | `/api/admin/subscription/set-plan` | ✅ Admin | Manually set a user's plan |
| POST | `/api/admin/subscription/seed` | ✅ Admin | Seed subscription plans intoDB |
| PUT | `PUT /api/subscription/usage` | ✅ Yes | Manually force-reset today's counters (optional, for admin use) |

---

#### 8. Flutter Mobile App Integration Notes

**What the Flutter team (`lib/api/client.dart`) needs added:**

```dart
// lib/services/subscription_service.dart  (new file)

class SubscriptionService {
  // Singleton
  static final SubscriptionService instance = SubscriptionService._();
  SubscriptionService._() { _init(); }
  
  SubscriptionStatus? _currentStatus;
  DateTime? _lastFetch;
  static const _ttl = Duration(minutes: 5); // cache TTL
  
  void _init() {
    // Load cached status from SharedPreferences on init
    // Auto-refresh if >5 min old
  }
  
  Future<SubscriptionStatus> getStatus({bool forceRefresh = false});
  
  Future<FeatureAccessResult> checkAccess(String feature);
  
  bool hasAccess(String feature) => _currentStatus?.hasFeature(feature) ?? false;
  int remainingToday(String feature) => _currentStatus?.remainingToday(feature) ?? 0;
  bool isPlus() => _currentStatus?.tier == 'plus';
  bool isPremium() => _currentStatus?.tier == 'premium';
  bool isFree() => _currentStatus?.tier == 'free';
}

// Model: SubscriptionStatus
class SubscriptionStatus {
  final String tier; // free, plus, premium
  final bool isTrial;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime? trialEndsAt;
  final String? paymentProvider;
  final Map<String, int> usageToday; // ai_analysis: 1, recommendations: 0
  final Map<String, int> limitsToday; // ai_analysis: 2, recommendations: 0 (null = unlimited)
}
```

**Feature gate usage in screens (Flutter side):**
```dart
// Before showing AI analysis button in stock_history_screen.dart:
final access = await SubscriptionService.instance.checkAccess('ai_analysis');
if (!access.hasAccess) {
  // Show "Upgrade to Plus" modal
  return _showUpgradeModal(context, access.reason);
}

// Before showing expert recommendations:
final access = await SubscriptionService.instance.checkAccess('recommendations');
if (!access.hasAccess) {
  return _showUpgradeModal(context, access.reason);
}
```

---

### ✅ Status Tracker: What's Done vs. Pending

#### ✅ DONE (Flutter Side)
| Item | Status | File |
|------|--------|------|
| Subscription screen UI | ✅ Complete | `lib/screens/subscription_screen.dart` |
| SubscriptionPlan model | ✅ Complete | `lib/models/user.dart:88-143` |
| Subscription API methods | ✅ Complete | `lib/api/client.dart:501-533` |
| Routes configured | ✅ Complete | `lib/main.dart:113-121` |
| SubscriptionService | ✅ Complete | `lib/services/subscription_service.dart` |
| Upgrade modal / paywall UI | ✅ Complete | `lib/widgets/upgrade_modal.dart` |
| Feature gate in stock_history_screen.dart | ✅ Complete | Recommendation + Analysis tabs locked |
| Feature gate in ai_analysis_screen.dart | ✅ Complete | AI analysis locked behind subscription |
| Feature gate in watchlist_screen.dart | ✅ Complete | 3-item limit enforced for Free |
| Feature gate in portfolio_screen.dart | ✅ Complete | 3-item limit enforced for Free |

#### ❌ PENDING (Backend — Z.AI)
| Item | Priority | Notes |
|------|----------|-------|
| Update `/api/subscription/plans` response format | 🔴 High | Missing 10+ fields that Flutter model expects |
| Add `POST /api/subscription/check-access` endpoint | 🔴 High | Critical for gating paid features |
| Add `POST /api/google-play/verify-receipt` endpoint | 🔴 High | Required for mobile in-app purchases |
| Add/Update `POST /api/paymob/confirm-payment` endpoint | 🔴 High | Required for website purchases |
| Create/update `subscription_usage` table (add `last_reset_date`) | 🔴 High | Daily quota tracking — lazy in-request reset, NO cron job |
| Create/update `user_subscriptions` table | 🔴 High | Must add new fields |
| Seed Free/Plus/Premium plans with correct values | 🔴 High | `duration_days`, `trial_days`, `max_*` fields |
| Payment provider sync (Google Play ↔ PayMob → same DB) | 🔴 High | Both must write to same subscription record |

> **ℹ️ NO Cron Job Needed:** Daily counters reset via lazy evaluation inside `check-access` and `subscription/current` endpoint calls — never uses external cron/task scheduler.

#### ❌ PENDING (Flutter Side)
| Item | Priority | Notes |
|------|----------|-------|
| `lib/services/subscription_service.dart` | 🔴 High | Central subscription logic + feature gating |
| Feature gate in `stock_history_screen.dart` | 🔴 High | Lock recommendations/AI behind subscription |
| Feature gate in `ai_analysis_screen.dart` | 🔴 High | Lock AI behind subscription |
| Feature gate in `watchlist_screen.dart` | 🟡 Medium | Enforce 3-item limit for Free |
| Feature gate in `portfolio_screen.dart` | 🟡 Medium | Enforce 3-item limit for Free |
| Google Play Billing integration | 🟡 Medium | `in_app_purchase` package + product IDs |
| Google Play Billing integration | 🟡 Medium | `in_app_purchase` package + product IDs |

---

### 🔗 Cross-Platform Requirement (Website + Mobile)

Both platforms **MUST** share the same subscription records. The rule is:

```
User logs in on Mobile  →  PAYS on Mobile → Google Play → /api/google-play/verify-receipt → Server updates DB
User logs in on Website →  PAYS on Website → PayMob → /api/paymob/confirm-payment → Server updates SAME DB
User logs in anywhere   →  GET /api/subscription/current  →  Reads from SAME DB
```

No matter where the user paid, `GET /api/subscription/current` must return the **same** tier and expiry date. A user upgrading on the **website** must immediately see the upgrade on the **mobile app** — and vice versa.

---

*This section started: May 15, 2026*  
*Awaiting Z.AI response on feasibility, missing fields, and timeline.*

---

## 📱 Quick Integration Checklist

### ✅ Mobile App Integration (Z.AI / Backend)
- [x] Stock details: `/api/stocks/[ticker]?flat=1`
- [x] Stock history: `/api/stocks/[ticker]/history`
- [x] Recommendation: `/api/stocks/[ticker]/recommendation`
- [x] Professional analysis: `/api/stocks/[ticker]/professional-analysis`
- [x] Expert recommendations: `/api/mobile/expert-recommendations`
- [x] Zakat calculator: `/api/mobile/zakat-calculator`
- [x] Detailed analysis: `/api/mobile/analysis/[ticker]`
- [x] Google auth: `/api/auth/google`
- [x] User info: `/api/auth/me`
### 🚧 Subscription System (Flutter Side ✅ Complete | Backend — Pending Z.AI)
- [x] Subscription screen UI built (`lib/screens/subscription_screen.dart`)
- [x] `SubscriptionPlan` model defined (`lib/models/user.dart:88-143`)
- [x] Subscription API methods in client.dart (`lib/api/client.dart:501-533`)
- [x] `lib/services/subscription_service.dart` — central logic + cache + feature gating
- [x] Feature gates in `stock_history_screen.dart` (recommendations, expert analysis)
- [x] Feature gate in `ai_analysis_screen.dart` (AI behind subscription)
- [x] Portfolio/watchlist limits enforced for Free tier (3 items each)
- [x] Upgrade modal / paywall UI (`lib/widgets/upgrade_modal.dart`)
- [ ] **Z.AI:** Update `/api/subscription/plans` — full fields (`duration_days`, `max_*`, feature flags)
- [ ] **Z.AI:** `POST /api/subscription/check-access` — feature gating + lazy daily reset
- [ ] **Z.AI:** `POST /api/google-play/verify-receipt` — Google Play billing → same DB
- [ ] **Z.AI:** `POST /api/paymob/confirm-payment` — PayMob callback → same DB
- [ ] **Z.AI:** Add `last_reset_date` to `subscription_usage` table (lazy reset, no cron)
- [ ] **Z.AI:** Update `user_subscriptions` table (`payment_provider`, `payment_id`, trial fields)
- [ ] **Z.AI:** Seed Free/Plus/Premium plans with correct durations and limits
- [ ] **Kilo:** `in_app_purchase` package + Google Play Billing products
- [x] ~~Cron job~~ ~~REMOVED — replaced with lazy in-request reset (zero external dependencies)~~
---

## 🔧 Environment Variables Needed

For Google Auth to work, ensure these are set in `.env`:
```
GOOGLE_CLIENT_ID=your_google_client_id
NEXT_PUBLIC_GOOGLE_CLIENT_ID=your_google_client_id
```

---

## 📋 Z.AI Quick Action Items (Subscription System)

### When you implement, do these in order:

1. **`GET /api/subscription/plans`** — Update response format to include all new fields (`duration_days`, `max_*`, feature flags)
2. **`POST /api/subscription/check-access`** — Feature gating + lazy daily reset (RULE #1: run the lazy-reset at the start of every call)
3. **`subscription_usage` table** — Add `last_reset_date DATE NOT NULL DEFAULT CURRENT_DATE`
4. **`user_subscriptions` table** — Add `payment_provider TEXT`, `payment_id TEXT`, `trial_used BOOLEAN DEFAULT false`
5. **`POST /api/google-play/verify-receipt`** — Verify Google Play receipt and write to `user_subscriptions`
6. **`POST /api/paymob/confirm-payment`** — Confirmation endpoint for PayMob webhooks (write to same `user_subscriptions` table)
7. **Seed plans** — Insert Free/Plus/Premium with correct `duration_days` and `max_*` values

> ⚠️ **NO cron job required.** Daily counters reset via lazy evaluation inside `check-access` and `GET /api/subscription/current` endpoints only.

---

*Last updated: May 15, 2026 — Z.AI Backend Team + Kilo Mobile Team*

