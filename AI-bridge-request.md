# Z.AI Bridge - API Specifications for Flutter Mobile App

## 🔄 Last Updated: May 14, 2026

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


### Rate Limits
- Default: 100 requests per minute per user
- Use caching for stock data (refresh every 5-15 minutes)

---

## 📱 Quick Integration Checklist

- [ ] Stock details: `/api/stocks/[ticker]?flat=1`
- [ ] Stock history: `/api/stocks/[ticker]/history`
- [ ] Recommendation: `/api/stocks/[ticker]/recommendation`
- [ ] Professional analysis: `/api/stocks/[ticker]/professional-analysis`
- [ ] Expert recommendations: `/api/mobile/expert-recommendations`
- [ ] Zakat calculator: `/api/mobile/zakat-calculator`
- [ ] Detailed analysis: `/api/mobile/analysis/[ticker]`
- [ ] Google auth: `/api/auth/google`
- [ ] User info: `/api/auth/me`

---

## 🔧 Environment Variables Needed

For Google Auth to work, ensure these are set in `.env`:
```
GOOGLE_CLIENT_ID=your_google_client_id
NEXT_PUBLIC_GOOGLE_CLIENT_ID=your_google_client_id
```

---

*Last updated: May 14, 2026 - Z.AI Backend Team*
