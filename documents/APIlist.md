# مساعد الاستثمار Platform - Complete API Documentation

## Base URLs
```
Production:     https://invist.m2y.net/api
Local:          http://localhost:3000/api
Python Backend: http://72.61.137.86:8010 (VPS)
```

---

## Table of Contents

### Internal APIs (Next.js/Node.js)
1. [Authentication API](#1-authentication-api)
2. [Stocks API](#2-stocks-api)
3. [Expert Recommendations API](#3-expert-recommendations-api)
4. [Portfolio API](#4-portfolio-api)
5. [Watchlist API](#5-watchlist-api)
6. [Market Data API](#6-market-data-api)
7. [Predictions API](#7-predictions-api)
8. [AI Analysis API](#8-ai-analysis-api)
9. [Admin API](#9-admin-api)
10. [Subscription API](#10-subscription-api)
11. [Finance API](#11-finance-api)
12. [Crypto API](#12-crypto-api)
13. [Gold & Currency API](#13-gold--currency-api)
14. [Backtesting API](#14-backtesting-api)
15. [Learning & Self-Learning API](#15-learning--self-learning-api)
16. [Sync & Data Update API](#16-sync--data-update-api)
17. [Reports API](#17-reports-api)
18. [Payment API](#18-payment-api)
19. [Health & System API](#19-health--system-api)
20. [Cron Jobs API](#20-cron-jobs-api)

### Python Backend APIs (VPS - Port 8010)
21. [Python Engine API](#21-python-engine-api)
22. [Data Engine API (Local)](#22-data-engine-api-local)

### External APIs
23. [External Data Sources & API Keys](#23-external-data-sources--api-keys)

---

# INTERNAL APIs (Next.js/Node.js)

---

## 1. Authentication API

**Source:** `src/app/api/auth/`  
**Type:** Internal (Node.js)  
**Auth Required:** Varies by endpoint

### POST /api/auth/register
Register a new user (Web & Mobile).

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "username": "username",
  "risk_tolerance": "medium"
}
```

**Response:**
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
  "api_key": "egx_user_id_timestamp"
}
```

---

### POST /api/auth/login
Login with email/username and password - Returns Bearer token for mobile.

**Request Body:**
```json
{
  "username_or_email": "user@example.com",
  "password": "password123"
}
```

**Response:**
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
    "image": "https://...",
    "subscription_tier": "free",
    "is_admin": false
  },
  "token": "egx_uuid_token_timestamp",
  "token_type": "Bearer",
  "expires_in": 2592000
}
```

---

### POST /api/auth/google
Login/Register with Google ID Token - For mobile apps using Google Sign-In SDK.

**Request Body:**
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
  "user": {
    "id": "uuid",
    "email": "user@gmail.com",
    "name": "User Name"
  },
  "token": "egx_uuid_token_timestamp",
  "is_new_user": false
}
```

---

### GET /api/auth/me
Get current user info using Bearer token.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "username",
    "name": "User Name",
    "subscription_tier": "free",
    "is_admin": false
  }
}
```

---

### POST /api/auth/logout
Logout and invalidate token.

### GET /api/auth/config
Get authentication configuration.

### Web Authentication (NextAuth.js)
- `GET /api/auth/signin` - Sign in page
- `GET /api/auth/signout` - Sign out
- `GET /api/auth/callback/google` - Google OAuth callback
- `GET /api/auth/session` - Get current session

---

## 2. Stocks API

**Source:** `src/app/api/stocks/`  
**Type:** Internal (Node.js)  
**Auth Required:** No

### GET /api/stocks
Get all stocks list.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `query` | string | - | Search query |
| `sector` | string | - | Filter by sector |
| `limit` | number | 500 | Number of results |

**Response:**
```json
{
  "stocks": [
    {
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "name_ar": "البنك التجاري الدولي",
      "sector": "Banks",
      "current_price": 25.50,
      "previous_close": 25.00,
      "change": 0.50,
      "change_percent": 2.0,
      "volume": 1000000,
      "market_cap": 50000000000,
      "pe_ratio": 5.2,
      "egx30_member": true
    }
  ],
  "total": 452
}
```

---

### GET /api/stocks/[ticker]
Get single stock details.

**Response:**
```json
{
  "ticker": "COMI",
  "name": "Commercial International Bank",
  "name_ar": "البنك التجاري الدولي",
  "current_price": 25.50,
  "previous_close": 25.00,
  "high_price": 26.00,
  "low_price": 24.50,
  "open_price": 25.20,
  "volume": 1000000,
  "sector": "Banks",
  "egx30_member": true
}
```

---

### GET /api/stocks/[ticker]/history
Get stock price history (OHLCV data for charts).

**Query Parameters:**
| Parameter | Type | Default | Max | Description |
|-----------|------|---------|-----|-------------|
| `days` | number | 90 | 365 | Number of days |
| `period` | string | - | - | Time period (1d, 1w, 1m, 3m, 1y) |

**Response:**
```json
{
  "success": true,
  "ticker": "COMI",
  "days": 30,
  "data": [
    {
      "date": "2024-01-15",
      "open": 25.00,
      "high": 25.50,
      "low": 24.80,
      "close": 25.30,
      "volume": 1000000,
      "rsi": 55.5
    }
  ],
  "summary": {
    "highest": 28.00,
    "lowest": 22.50,
    "avg_price": 25.50,
    "change_percent": 5.42
  }
}
```

---

### GET /api/stocks/[ticker]/recommendation
Get AI recommendation for a stock.

### GET /api/stocks/[ticker]/professional-analysis
Get professional analysis for a stock.

### GET /api/stocks/[ticker]/news
Get news for a specific stock.

### GET /api/stocks/search
Search stocks.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | Yes | Search query |

### GET /api/stocks/batch-analysis
Analyze multiple stocks at once.

### GET /api/stocks/movement-classification
Get stocks classified by movement (gainers, losers, etc.).

### GET /api/stocks/data-coverage
Get data coverage statistics.

### GET /api/stocks/fundamentals
Get fundamental data for stocks.

---

## 3. Expert Recommendations API

**Source:** `src/app/api/expert-recommendations/`  
**Type:** Internal (Node.js)  
**Auth Required:** Yes (for POST/PUT/DELETE)

### GET /api/expert-recommendations
Get all expert recommendations.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `status` | string | - | PENDING, HIT_TARGET, STOPPED, CLOSED |
| `expert_name` | string | - | Filter by expert name |
| `ticker` | string | - | Filter by stock symbol |
| `limit` | number | 100 | Number of results |

**Response:**
```json
{
  "success": true,
  "recommendations": [
    {
      "id": "uuid",
      "stock_symbol": "COMI",
      "expert_name": "خبير 1",
      "action": "BUY",
      "entry_price": 25.50,
      "target_price": 28.00,
      "stop_loss": 24.00,
      "recommendation_date": "2024-01-15",
      "status": "PENDING",
      "hit_target": false,
      "hit_stop_loss": false,
      "profit_loss_percent": null
    }
  ],
  "expertStats": [
    {
      "expert_name": "خبير 1",
      "total_recommendations": 10,
      "successful_recommendations": 7,
      "success_rate": 70.0,
      "avg_return": 5.5
    }
  ]
}
```

---

### POST /api/expert-recommendations
Create a new expert recommendation.

**Request Body:**
```json
{
  "stock_symbol": "COMI",
  "expert_name": "خبير 1",
  "action": "BUY",
  "entry_price": 25.50,
  "target_price": 28.00,
  "stop_loss": 24.00,
  "recommendation_date": "2024-01-15",
  "notes": "ملاحظات إضافية"
}
```

**Required Fields:** `stock_symbol`, `expert_name`, `action`, `entry_price`

---

### PUT /api/expert-recommendations
Update an existing recommendation.

### DELETE /api/expert-recommendations?id={uuid}
Delete a recommendation.

### POST /api/expert-recommendations/import
Import multiple recommendations.

### GET /api/expert-recommendations/experts
Get list of all experts with their statistics.

---

## 4. Portfolio API

**Source:** `src/app/api/portfolio/`  
**Type:** Internal (Node.js)  
**Auth Required:** Yes

### GET /api/portfolio
Get user's portfolio positions.

**Response:**
```json
{
  "success": true,
  "positions": [
    {
      "id": "uuid",
      "stock_symbol": "COMI",
      "stock_name": "البنك التجاري الدولي",
      "shares": 100,
      "avg_cost": 24.00,
      "current_price": 25.50,
      "market_value": 2550.00,
      "cost_basis": 2400.00,
      "unrealized_pnl": 150.00,
      "unrealized_pnl_percent": 6.25
    }
  ],
  "summary": {
    "total_positions": 5,
    "total_cost_basis": 10000.00,
    "total_market_value": 11000.00,
    "total_unrealized_pnl": 1000.00,
    "total_unrealized_pnl_percent": 10.0
  }
}
```

---

### POST /api/portfolio
Add a position to portfolio.

**Request Body:**
```json
{
  "stock_symbol": "COMI",
  "shares": 100,
  "avg_cost": 24.00,
  "entry_date": "2024-01-15",
  "notes": "ملاحظات"
}
```

**Required Fields:** `stock_symbol`, `shares`, `avg_cost`

---

### DELETE /api/portfolio?id={uuid}
Remove a position from portfolio.

### GET /api/portfolio/analyze
Analyze portfolio performance.

### GET /api/portfolio/assets
Get portfolio assets breakdown.

### POST /api/portfolio/priority-sync
Sync priority stocks from portfolio.

---

## 5. Watchlist API

**Source:** `src/app/api/watchlist/`  
**Type:** Internal (Node.js)  
**Auth Required:** Yes

### GET /api/watchlist
Get user's watchlist.

**Response:**
```json
{
  "success": true,
  "items": [
    {
      "id": 1,
      "stock_id": 123,
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "name_ar": "البنك التجاري الدولي",
      "current_price": 25.50,
      "previous_close": 25.00,
      "price_change": 2.0,
      "sector": "Banks",
      "alert_price_above": 28.00,
      "alert_price_below": 23.00,
      "notes": "مراقبة للشراء"
    }
  ],
  "total": 10
}
```

---

### POST /api/watchlist
Add stock to watchlist.

**Request Body:**
```json
{
  "ticker": "COMI",
  "alert_price_above": 28.00,
  "alert_price_below": 23.00,
  "notes": "مراقبة للشراء"
}
```

---

### DELETE /api/watchlist/{id}
Remove stock from watchlist.

### GET /api/watchlist-enhanced
Get enhanced watchlist with more details.

---

## 6. Market Data API

**Source:** `src/app/api/market/`  
**Type:** Internal (Node.js)  
**Auth Required:** No

### GET /api/market/overview
Get market overview data.

### GET /api/market/indices
Get market indices (EGX30, EGX70, EGX100).

### GET /api/market/live-data
Get live market data.

### GET /api/market/status
Get market status (open/closed).

**Response:**
```json
{
  "success": true,
  "is_open": true,
  "market": "EGX",
  "next_open": "2024-01-16T09:30:00+02:00",
  "next_close": "2024-01-16T15:00:00+02:00",
  "trading_day": true
}
```

---

### POST /api/market/sync
Sync market data from external sources.

### GET /api/market/connections
Get market data connections status.

### GET /api/market/test-sources
Test all market data sources.

### GET /api/market/investing
Get investing.com data.

### POST /api/market/refresh-data
Refresh market data.

### POST /api/market/bulk-update
Bulk update market data.

### GET /api/market/recommendations/ai-insights
Get AI insights for market recommendations.

---

## 7. Predictions API

**Source:** `src/app/api/predictions/`  
**Type:** Internal (Node.js)  
**Auth Required:** Yes (for POST/PUT/DELETE)

### GET /api/predictions
Get AI predictions.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `status` | string | - | ACTIVE, EXPIRED, HIT_TARGET, MISSED |
| `ticker` | string | - | Filter by stock symbol |
| `limit` | number | 50 | Number of results |
| `offset` | number | 0 | Pagination offset |

**Response:**
```json
{
  "success": true,
  "predictions": [
    {
      "id": "uuid",
      "ticker": "COMI",
      "prediction_type": "BUY",
      "confidence": 75,
      "entry_price": 25.00,
      "target_price": 28.00,
      "stop_loss": 23.00,
      "technical_score": 70,
      "fundamental_score": 80,
      "status": "ACTIVE",
      "prediction_date": "2024-01-15"
    }
  ],
  "stats": {
    "active": 25
  }
}
```

---

### POST /api/predictions
Create a new prediction.

### PUT /api/predictions
Update a prediction.

### DELETE /api/predictions?id={uuid}
Delete a prediction.

### POST /api/predictions/verify
Verify and update prediction statuses.

---

## 8. AI Analysis API

**Source:** `src/app/api/`, `src/app/api/v2/`  
**Type:** Internal (Node.js)  
**Auth Required:** No

### POST /api/ai-analysis
Get AI analysis for a stock.

**Request Body:**
```json
{
  "ticker": "COMI",
  "analysis_type": "technical"
}
```

---

### GET /api/ai-proxy
Proxy to AI services.

### POST /api/v2/recommend
Get AI recommendation.

**Request Body:**
```json
{
  "ticker": "COMI",
  "risk_tolerance": "medium"
}
```

---

### GET /api/v2/stock/[symbol]/analysis
Get comprehensive stock analysis.

### GET /api/v2/live-analysis
Get live analysis for all stocks.

---

## 9. Admin API

**Source:** `src/app/api/admin/`  
**Type:** Internal (Node.js)  
**Auth Required:** Yes (Admin only)

### GET /api/admin/stats
Get platform statistics.

**Response:**
```json
{
  "success": true,
  "stats": {
    "total_users": 150,
    "active_users": 45,
    "total_stocks": 452,
    "total_predictions": 120
  }
}
```

---

### GET /api/admin/users
Get all registered users.

### GET /api/admin/recommendations
Get all recommendations for admin review.

### POST /api/admin/sync-vps
Sync data from VPS server.

### GET /api/admin/export-data
Export platform data.

### POST /api/admin/import-data
Import platform data.

### GET /api/admin/monitor
Get system monitoring data.

### GET /api/admin/analytics
Get analytics data.

### POST /api/admin/scrape-stocks
Scrape stock data.

### GET /api/admin/data-sources
Get configured data sources.

### POST /api/admin/sync-stocks-db
Sync stocks database.

### POST /api/admin/gold
Update gold prices.

### POST /api/admin/import-stocks
Import stocks from file.

### POST /api/admin/sync-fundamentals
Sync fundamental data.

### POST /api/admin/import-snapshot
Import data snapshot.

### POST /api/admin/currency
Update currency rates.

### POST /api/admin/auth
Admin authentication.

### GET /api/admin/export-vps
Export data for VPS.

### POST /api/admin/subscription/set-plan
Set user subscription plan.

### POST /api/admin/subscription/seed
Seed subscription plans.

---

## 10. Subscription API

**Source:** `src/app/api/subscription/`  
**Type:** Internal (Node.js)  
**Auth Required:** Yes

### GET /api/subscription/plans
Get available subscription plans.

**Response:**
```json
{
  "plans": [
    { "id": "free", "name": "Free", "name_ar": "مجاني", "price": 0, "features": ["basic"] },
    { "id": "plus", "name": "Plus", "name_ar": "بلس", "price": 99, "features": ["basic", "alerts"] },
    { "id": "premium", "name": "Premium", "name_ar": "بريميوم", "price": 199, "features": ["basic", "alerts", "ai"] }
  ]
}
```

---

### GET /api/subscription/current
Get current user's subscription status.

### POST /api/subscription/activate
Activate a subscription.

### POST /api/subscription/start-trial
Start a free trial.

### POST /api/subscription/upgrade
Upgrade subscription.

### POST /api/subscribe/[plan]
Subscribe to a plan.

---

## 11. Finance API

**Source:** `src/app/api/finance/`  
**Type:** Internal (Node.js)  
**Auth Required:** Yes

### GET /api/finance/assets
Get user's financial assets.

### POST /api/finance/assets
Add a financial asset.

### DELETE /api/finance/assets/[id]
Delete a financial asset.

### GET /api/finance/obligations
Get user's financial obligations.

### POST /api/finance/obligations
Add a financial obligation.

### GET /api/finance/obligations/payments
Get obligation payments.

### GET /api/finance/reports
Get financial reports.

### GET /api/finance/transactions
Get transaction history.

### POST /api/finance/calculate-values
Calculate financial values.

### GET /api/finance/schema
Get finance data schema.

---

## 12. Crypto API

**Source:** `src/app/api/crypto/`  
**Type:** Internal (Node.js)  
**Auth Required:** No

### GET /api/crypto
Get cryptocurrency prices.

**Response:**
```json
{
  "success": true,
  "coins": [
    {
      "id": "bitcoin",
      "symbol": "BTC",
      "name": "Bitcoin",
      "current_price": 42000,
      "price_change_24h": 800,
      "price_change_percent_24h": 1.9,
      "market_cap": 820000000000,
      "total_volume": 25000000000
    }
  ]
}
```

---

### GET /api/crypto/[id]
Get specific cryptocurrency details.

### GET /api/crypto/ohlc
Get OHLC data for charts.

**Query Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `coin_id` | string | Yes | - | Coin ID (bitcoin, ethereum) |
| `days` | number | No | 30 | Number of days |
| `interval` | string | No | daily | Interval (daily, hourly) |

**Response:**
```json
{
  "success": true,
  "data": {
    "coin_id": "bitcoin",
    "ohlcv": [
      { "timestamp": 1705363200000, "open": 42000, "high": 43500, "low": 41500, "close": 42800 }
    ],
    "indicators": {
      "rsi": 55.5,
      "sma": { "sma20": 42500, "sma50": 41000 },
      "macd": { "macd": 500, "signal": 450, "histogram": 50 }
    }
  }
}
```

---

### POST /api/crypto/sync
Sync cryptocurrency data.

---

## 13. Gold & Currency API

**Source:** `src/app/api/market/`, `src/app/api/currency/`  
**Type:** Internal (Node.js)  
**Auth Required:** No

### GET /api/market/gold
Get gold and silver prices.

**Response:**
```json
{
  "success": true,
  "source": "database",
  "prices": {
    "karats": [
      { "key": "24", "name_ar": "عيار 24", "price_per_gram": 4250, "change": 50 },
      { "key": "22", "name_ar": "عيار 22", "price_per_gram": 3895, "change": 43 },
      { "key": "21", "name_ar": "عيار 21", "price_per_gram": 3718, "change": 40 },
      { "key": "18", "name_ar": "عيار 18", "price_per_gram": 3187, "change": 37 }
    ],
    "ounce": { "price": 132200, "change": 1500 },
    "silver": { "price_per_gram": 45, "change": 0.5 }
  }
}
```

---

### GET /api/market/gold/history
Get gold price history for charts.

**Query Parameters:**
| Parameter | Type | Default | Max | Description |
|-----------|------|---------|-----|-------------|
| `karat` | string | 24 | - | Gold karat (24, 22, 21, 18) |
| `days` | number | 30 | 365 | Number of days |

---

### POST /api/market/gold/sync
Sync gold prices from sources.

### GET /api/market/currency
Get currency exchange rates.

**Response:**
```json
{
  "success": true,
  "central_bank_rate": 50.5,
  "currencies": [
    { "code": "USD", "name_ar": "دولار أمريكي", "buy_rate": 50.5, "sell_rate": 50.7, "is_major": true },
    { "code": "EUR", "name_ar": "يورو", "buy_rate": 54.8, "sell_rate": 55.0, "is_major": true },
    { "code": "GBP", "name_ar": "جنيه إسترليني", "buy_rate": 63.5, "sell_rate": 63.8, "is_major": true },
    { "code": "SAR", "name_ar": "ريال سعودي", "buy_rate": 13.5, "sell_rate": 13.6, "is_major": false }
  ]
}
```

---

### GET /api/currency/list
Get list of all currencies.

### POST /api/currency/convert
Convert currency.

---

## 14. Backtesting API

**Source:** `src/app/api/backtest/`, `src/app/api/backtesting/`  
**Type:** Internal (Node.js)  
**Auth Required:** No

### POST /api/backtest
Run a backtest on a trading strategy.

**Request Body:**
```json
{
  "strategy": "ma_crossover",
  "ticker": "COMI",
  "start_date": "2023-01-01",
  "end_date": "2024-01-01"
}
```

---

### GET /api/backtesting
Get backtesting results.

---

## 15. Learning & Self-Learning API

**Source:** `src/app/api/learning/`, `src/app/api/self-learning/`  
**Type:** Internal (Node.js)  
**Auth Required:** No

### GET /api/learning/progress
Get learning progress.

### POST /api/iterative-learning
Run iterative learning.

### GET /api/self-learning
Get self-learning status.

### GET /api/learning-params
Get learning parameters.

### POST /api/learning-params/save
Save learning parameters.

### GET /api/learning-params/active
Get active learning parameters.

### POST /api/learning-params/init
Initialize learning parameters.

### GET /api/unified-scoring
Get unified scoring data.

---

## 16. Sync & Data Update API

**Source:** `src/app/api/sync/`, `src/app/api/mubasher/`  
**Type:** Internal (Node.js)  
**Auth Required:** Yes (Admin)

### POST /api/sync/from-website
Sync stocks and historical data from live website.

### POST /api/sync/stocks
Sync stock list only.

### POST /api/sync/history
Sync historical data for specific stocks.

### POST /api/mubasher/sync
Sync all stocks from local Mubasher Trade databases.

### GET /api/mubasher/sync/status
Check Mubasher connection status.

### POST /api/sync-names
Sync stock names.

### POST /api/sync-historical
Sync historical data.

### POST /api/market/scheduled-sync
Run scheduled sync.

### POST /api/market/incremental-sync
Run incremental sync.

### POST /api/market/sync-live
Sync live market data.

---

## 17. Reports API

**Source:** `src/app/api/reports/`  
**Type:** Internal (Node.js)  
**Auth Required:** No

### POST /api/reports/morning
Push a morning report from Python backend.

**Request Body:**
```json
{
  "report_date": "2025-01-15",
  "report_text": "## تقرير صباحي...",
  "report_type": "daily"
}
```

---

### GET /api/reports/morning
Get stored morning reports.

### DELETE /api/reports/morning
Clear old morning reports.

---

## 18. Payment API

**Source:** `src/app/api/paymob/`, `src/app/api/subscription/`  
**Type:** Internal (Node.js)  
**Auth Required:** Yes

### POST /api/paymob/create-payment
Create a payment request.

**Request Body:**
```json
{
  "amount": 199,
  "currency": "EGP",
  "plan": "premium"
}
```

---

### GET /api/paymob/callback
Payment callback endpoint.

---

## 19. Health & System API

**Source:** `src/app/api/health/`, `src/app/api/system/`  
**Type:** Internal (Node.js)  
**Auth Required:** No

### GET /api/health
Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

---

### GET /api/init-db
Initialize database.

### GET /api/system/db-health
Check database health.

### GET /api/keepalive
Keep-alive endpoint for preventing sleep.

### GET /api/cache
Get cache status.

---

## 20. Cron Jobs API

**Source:** `src/app/api/cron/`  
**Type:** Internal (Node.js)  
**Auth Required:** No

### GET /api/cron/scheduled
Run scheduled tasks.

### GET /api/cron/verify-predictions
Verify and update prediction statuses.

### GET /api/cron/auto-sync
Auto-sync data from external sources.

### GET /api/cron/update-cache
Update cache.

---

# PYTHON BACKEND APIs (VPS - Port 8010)

---

## 21. Python Engine API

**Source:** VPS `/root/egxpy_service/egx_api_service.py`  
**Type:** Python (FastAPI)  
**Base URL:** `http://72.61.137.86:8010`  
**Auth Required:** Yes (X-API-Key header)  
**API Key:** `mubasher-sync-2024-secret`

### Authentication
```
Header: X-API-Key: mubasher-sync-2024-secret
Query: ?api_key=mubasher-sync-2024-secret
```

---

### GET /
API info.

### GET /health
Health check with stock count.

**Response:**
```json
{
  "status": "healthy",
  "stock_count": 60,
  "database": "egx_investment.db",
  "last_update": "2024-01-15T10:30:00Z"
}
```

---

### GET /api/stocks
Get all stocks with live prices.

**Response:**
```json
{
  "success": true,
  "count": 60,
  "data": [
    {
      "symbol": "COMI",
      "name": "البنك التجاري الدولي",
      "current_price": 44.90,
      "change": 0.50,
      "change_percent": 1.12,
      "volume": 1000000,
      "high": 45.20,
      "low": 44.50
    }
  ]
}
```

---

### GET /api/stocks/[symbol]
Get single stock info.

---

### GET /api/stocks/[symbol]/history
Get price history.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `days` | number | 90 | Number of days |

---

### GET /api/stocks/[symbol]/local-history
Get local history for backtesting.

### GET /api/analyze/[symbol]
Full technical analysis.

**Response:**
```json
{
  "symbol": "COMI",
  "analysis": {
    "trend": "bullish",
    "rsi": 55.5,
    "macd": { "macd": 0.5, "signal": 0.3, "histogram": 0.2 },
    "sma": { "sma20": 44.5, "sma50": 43.2, "sma200": 40.1 },
    "support": [43.5, 42.0],
    "resistance": [46.0, 48.0]
  }
}
```

---

### GET /api/recommendations
Get recommendations.

### GET /api/market/overview
Market overview.

### GET /api/market/top-gainers
Top gaining stocks.

### GET /api/market/top-losers
Top losing stocks.

### GET /api/learning/progress
Self-learning progress.

### POST /api/learning/start
Start self-learning.

### POST /api/learning/stop
Stop self-learning.

### GET /api/stats
Database statistics.

---

## 22. Data Engine API (Local)

**Source:** `data-engine/main.py`  
**Type:** Python CLI  
**Runs On:** Local PC

### CLI Commands

```bash
# System status
python main.py status

# Fetch all stocks
python main.py fetch

# Fetch specific stocks
python main.py fetch COMI EMFD HRHO

# Analyze a stock
python main.py analyze COMI

# Get recommendations
python main.py recommendations

# Sync with website
python main.py sync

# Run as background service
python main.py daemon
```

---

# EXTERNAL APIs

---

## 23. External Data Sources & API Keys

### API Keys Configuration

| Provider | API Key | Free Limit | Priority | Status | Use Case |
|----------|---------|------------|----------|--------|----------|
| **VPS** | `http://72.61.137.86:8010` | Unlimited | 1 | ✅ Active | EGX Stocks |
| **Twelve Data** | `821e4b4a88874941af581ad4d3141d93` | 800/day | 2 | ✅ Active | Stocks Backup |
| **EODHD** | `6990ef9ee966c5.41761316` | 20/day | 3 | ✅ Active | Stocks Backup |
| **Marketstack** | `49e316b2786f93cb87c674bdcf6a595d` | 100/month | 4 | ✅ Active | Stocks Backup |
| **Alpha Vantage** | `UOTWJFFUX1SLZ63W` | 25/day | 5 | ✅ Active | Stocks Backup |
| **FCSAPI** | `n6RbYitzjnw0xx32h0IlgP` | 100/month | 1 | ✅ Active | Gold/Currency |
| **CoinGecko** | Free (no key) | 10-50/min | 1 | ✅ Active | Crypto |
| **Yahoo Finance** | - | - | N/A | ❌ Disabled | - |

---

### Data Source Priority Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Stock Data Flow                          │
├─────────────────────────────────────────────────────────────┤
│  1. VPS (unlimited) → Primary for EGX stocks               │
│  2. Twelve Data (800/day) → Secondary fallback             │
│  3. EODHD (20/day) → Tertiary fallback                     │
│  4. Marketstack (100/month) → Fourth fallback              │
│  5. Alpha Vantage (25/day) → Last resort                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                 Gold & Currency Flow                        │
├─────────────────────────────────────────────────────────────┤
│  1. FCSAPI → Primary for gold (XAU/USD) & forex            │
│  2. Default values → Fallback if API fails                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    Crypto Flow                              │
├─────────────────────────────────────────────────────────────┤
│  1. CoinGecko → Primary for all crypto prices              │
│  2. CoinGecko OHLC → For chart data                        │
└─────────────────────────────────────────────────────────────┘
```

---

### VPS API (Primary - EGX Stocks)

**Source:** `src/lib/vps-client.ts`  
**Base URL:** `http://72.61.137.86:8010`  
**Auth Required:** Yes  
**API Key:** `mubasher-sync-2024-secret`

```
GET /api/stocks/all          - Get all EGX stocks
GET /api/stock/{ticker}      - Get single stock quote
GET /api/gold                - Get gold prices
GET /api/currency            - Get currency rates
GET /api/health              - Health check

Authentication: X-API-Key header or ?api_key= parameter
```

**Data Format:**
```json
{
  "success": true,
  "data": {
    "symbol": "COMI",
    "name": "البنك التجاري الدولي",
    "current_price": 44.90,
    "change": 0.50,
    "change_percent": 1.12,
    "volume": 1000000
  }
}
```

---

### Twelve Data API

**Source:** `src/lib/multi-source-adapter.ts`  
**Base URL:** `https://api.twelvedata.com`  
**Auth Required:** Yes (apikey parameter)  
**API Key:** `821e4b4a88874941af581ad4d3141d93`  
**Rate Limit:** 800 requests/day

```
GET /quote?symbol={TICKER}.EGX&apikey={KEY}  - Stock quote
GET /time_series                            - Historical data
```

**Symbol Format:** `COMI.EGX` (append `.EGX` for Egyptian stocks)

**Data Format:**
```json
{
  "symbol": "COMI.EGX",
  "name": "Commercial International Bank",
  "close": "44.90",
  "change": "0.50",
  "percent_change": "1.12",
  "volume": "1000000"
}
```

---

### EODHD API

**Source:** `src/lib/multi-source-adapter.ts`  
**Base URL:** `https://eodhistoricaldata.com/api`  
**Auth Required:** Yes (api_token parameter)  
**API Key:** `6990ef9ee966c5.41761316`  
**Rate Limit:** 20 requests/day

```
GET /real-time/{TICKER}.EGX?api_token={KEY}&fmt=json  - Real-time quote
GET /eod/{TICKER}.EGX?api_token={KEY}                 - End-of-day data
```

**Symbol Format:** `COMI.EGX` (append `.EGX` for Egyptian stocks)

**Data Format:**
```json
{
  "code": "COMI.EGX",
  "close": "44.90",
  "high": "45.20",
  "low": "44.50",
  "open": "44.80",
  "volume": "1000000",
  "previousClose": "44.40"
}
```

---

### Alpha Vantage API

**Source:** `src/lib/multi-source-adapter.ts`  
**Base URL:** `https://www.alphavantage.co`  
**Auth Required:** Yes (apikey parameter)  
**API Key:** `UOTWJFFUX1SLZ63W`  
**Rate Limit:** 25 requests/day

```
GET /query?function=GLOBAL_QUOTE&symbol={TICKER}.CAIRO&apikey={KEY}
```

**Symbol Format:** `COMI.CAIRO` (append `.CAIRO` for EGX stocks)

**Data Format:**
```json
{
  "Global Quote": {
    "01. symbol": "COMI.CAIRO",
    "05. price": "44.90",
    "06. volume": "1000000",
    "09. change": "0.50",
    "10. change percent": "1.12%"
  }
}
```

---

### FCSAPI (Gold & Currency)

**Source:** `src/lib/multi-source-adapter.ts`  
**Base URL:** `https://fcsapi.com/api-v3`  
**Auth Required:** Yes (access_key parameter)  
**API Key:** `n6RbYitzjnw0xx32h0IlgP`  
**Rate Limit:** 100 requests/month

```
GET /forex/latest?symbol=XAU/USD&access_key={KEY}     - Gold price
GET /forex/latest?symbol=USD/EGP&access_key={KEY}     - Currency rate
```

**Data Format:**
```json
{
  "status": true,
  "response": [
    {
      "s": "XAU/USD",
      "c": 2050.50,
      "h": 2055.00,
      "l": 2045.00,
      "o": 2048.00,
      "ch": 5.50
    }
  ]
}
```

---

### Marketstack API

**Source:** `src/lib/multi-source-adapter.ts`  
**Base URL:** `http://api.marketstack.com/v1`  
**Auth Required:** Yes (access_key parameter)  
**API Key:** `49e316b2786f93cb87c674bdcf6a595d`  
**Rate Limit:** 100 requests/month

```
GET /eod/latest?access_key={KEY}&symbols={TICKER}.XEGX
```

**Symbol Format:** `COMI.XEGX` (append `.XEGX` for EGX stocks)

**Data Format:**
```json
{
  "data": [
    {
      "symbol": "COMI.XEGX",
      "open": 44.80,
      "high": 45.20,
      "low": 44.50,
      "close": 44.90,
      "volume": 1000000,
      "date": "2024-01-15T00:00:00+0000"
    }
  ]
}
```

---

### CoinGecko API (Free - No Key Required)

**Source:** `src/app/api/crypto/`  
**Base URL:** `https://api.coingecko.com/api/v3`  
**Auth Required:** No  
**Rate Limit:** 10-50 requests/minute

```
GET /coins/markets?vs_currency=usd&order=market_cap_desc - Top coins
GET /coins/{id}/ohlc?vs_currency=usd&days=30             - OHLC data
GET /coins/{id}/market_chart?vs_currency=usd&days=30      - Price history
```

**Data Format:**
```json
[
  {
    "id": "bitcoin",
    "symbol": "btc",
    "name": "Bitcoin",
    "current_price": 42000,
    "price_change_24h": 800,
    "price_change_percentage_24h": 1.9,
    "market_cap": 820000000000,
    "total_volume": 25000000000
  }
]
```

---

### Environment Variables

```env
# Primary Data Sources
EGX_VPS_API_URL=http://72.61.137.86:8010

# Stock Data APIs
TWELVE_DATA_API_KEY=821e4b4a88874941af581ad4d3141d93
EODHD_API_KEY=6990ef9ee966c5.41761316
ALPHA_VANTAGE_API_KEY=UOTWJFFUX1SLZ63W
MARKETSTACK_API_KEY=49e316b2786f93cb87c674bdcf6a595d

# Gold & Currency API
FCSAPI_API_KEY=n6RbYitzjnw0xx32h0IlgP

# Authentication
VPS_API_KEY=mubasher-sync-2024-secret

# Payment (PayMob)
PAYMOB_API_KEY=your_paymob_api_key
```

---

### Implementation Details

**File Locations:**
| File | Purpose |
|------|---------|
| `src/lib/multi-source-adapter.ts` | Main multi-source data adapter |
| `src/lib/vps-client.ts` | VPS API client |
| `src/lib/data-adapter.ts` | Data transformation layer |
| `src/lib/external-data-fetcher.ts` | External API fetchers |

**Features:**
- ✅ Automatic failover between sources
- ✅ Rate limiting and quota management
- ✅ In-memory caching (2-5 minutes TTL)
- ✅ Source health tracking
- ✅ Smart distribution across sources

**Rate Limit Handling:**
- Daily requests tracked in memory
- Sources disabled after 5 consecutive failures
- Automatic retry with next source in priority

---

# ERROR HANDLING

## Standard Error Response

All APIs follow a standard error format:

```json
{
  "success": false,
  "error": "Error message in English",
  "error_ar": "رسالة الخطأ بالعربية"
}
```

## HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request (missing/invalid parameters) |
| 401 | Unauthorized (authentication required) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 409 | Conflict (e.g., duplicate entry) |
| 500 | Internal Server Error |

---

# AUTHENTICATION HEADERS

For authenticated requests:

```
Authorization: Bearer <token>
```

Or use session cookies with NextAuth.js.

---

# RATE LIMITS

| Endpoint Type | Rate Limit |
|---------------|------------|
| Default | 100 requests/minute |
| Admin | 1000 requests/minute |
| Health/Keepalive | Unlimited |

---

# LIVE SERVER

| Service | URL |
|---------|-----|
| Production | https://invist.m2y.net |
| API Base | https://invist.m2y.net/api |
| Admin Panel | https://invist.m2y.net/admin |
| Python API | http://72.61.137.86:8010 |

---

# NOTES

1. All prices are in EGP (Egyptian Pounds) unless specified otherwise.
2. Stock tickers are case-insensitive.
3. Dates should be in ISO 8601 format.
4. All endpoints return JSON responses.
5. Arabic text is returned in UTF-8 encoding.

---

---

# Flutter App Endpoint Integration Status

## ✅ Integrated Endpoints (58 unique)

| # | Method | Endpoint | Flutter Method | Screen/Service |
|---|--------|----------|----------------|----------------|
| 1 | POST | `/api/auth/google` | `googleLogin()` | auth_screen |
| 2 | GET | `/api/auth/me` | `getMe()` | auth_screen |
| 3 | POST | `/api/auth/logout` | `logout()` | settings_screen |
| 4 | GET | `/api/market/overview` | `getMarketOverview()` | dashboard_screen |
| 5 | GET | `/api/market/status` | `getMarketStatus()` | dashboard_screen |
| 6 | GET | `/api/market/indices` | `getMarketIndices()` | dashboard_screen |
| 7 | GET | `/api/market/gold` | `getGold()` | metals_screen |
| 8 | GET | `/api/market/gold/history` | `getGoldHistory()` | metals_screen |
| 9 | GET | `/api/market/currency` | `getCurrency()` | currency_screen |
| 10 | GET | `/api/stocks` | `getStocks()` | stocks_screen |
| 11 | GET | `/api/stocks/$ticker` | `getStockDetail()` | stock_history_screen |
| 12 | GET | `/api/stocks/$ticker/history` | `getStockHistory()` | stock_history_screen |
| 13 | GET | `/api/stocks/$ticker/recommendation` | `getStockRecommendation()` | stock_history_screen |
| 14 | GET | `/api/stocks/$ticker/professional-analysis` | `getStockProfessionalAnalysis()` | stock_history_screen |
| 15 | GET | `/api/stocks/search` | `searchStocks()` | stocks_screen |
| 16 | GET | `/api/stocks/batch-analysis` | `getBatchAnalysis()` | ai_analysis_screen |
| 17 | GET | `/api/crypto` | `getCrypto()` | crypto_screen |
| 18 | GET | `/api/crypto/$id` | `getCryptoDetail()` | crypto_detail_screen |
| 19 | GET | `/api/crypto/ohlc` | `getCryptoOHLC()` | crypto_detail_screen |
| 20 | GET | `/api/expert-recommendations` | `getExpertRecommendations()` | recommendations_screen |
| 21 | GET | `/api/expert-recommendations/experts` | `getExpertStats()` | recommendations_screen |
| 22 | POST | `/api/expert-recommendations` | `createExpertRecommendation()` | recommendations_screen |
| 23 | PUT | `/api/expert-recommendations` | `updateExpertRecommendation()` | recommendations_screen |
| 24 | DELETE | `/api/expert-recommendations` | `deleteExpertRecommendation()` | recommendations_screen |
| 25 | GET | `/api/predictions` | `getPredictions()` | ai_analysis_screen |
| 26 | POST | `/api/ai-analysis` | `analyzeStock()` | ai_analysis_screen |
| 27 | POST | `/api/v2/recommend` | `getAIRecommend()` | ai_analysis_screen |
| 28 | GET | `/api/v2/stock/$symbol/analysis` | `getStockAnalysis()` | stock_history_screen |
| 29 | GET | `/api/portfolio` | `getPortfolio()` | portfolio_screen |
| 30 | POST | `/api/portfolio` | `addToPortfolio()` | portfolio_screen |
| 31 | DELETE | `/api/portfolio` | `removeFromPortfolio()` | portfolio_screen |
| 32 | GET | `/api/watchlist` | `getWatchlist()` | watchlist_screen |
| 33 | POST | `/api/watchlist` | `addToWatchlist()` | watchlist_screen |
| 34 | DELETE | `/api/watchlist/$id` | `removeFromWatchlist()` | watchlist_screen |
| 35 | GET | `/api/currency/convert` | `convertCurrency()` | currency_screen |
| 36 | GET | `/api/subscription/plans` | `getSubscriptionPlans()` | subscription_screen |
| 37 | GET | `/api/subscription/current` | `getCurrentSubscription()` | subscription_service |
| 38 | POST | `/api/subscription/activate` | `activateSubscription()` | subscription_screen |
| 39 | POST | `/api/subscription/start-trial` | `startTrial()` | subscription_screen |
| 40 | POST | `/api/subscribe/$plan` | `subscribeToPlan()` | subscription_screen |
| 41 | POST | `/api/subscription/check-access` | `checkFeatureAccess()` | subscription_service |
| 42 | POST | `/api/google-play/verify-receipt` | `verifyGooglePlayReceipt()` | subscription_service |
| 43 | POST | `/api/paymob/create-payment` | `createPayment()` | subscription_screen |
| 44 | GET | `/api/finance/assets` | `getFinanceAssets()` | zakat_screen |
| 45 | POST | `/api/finance/assets` | `addFinanceAsset()` | zakat_screen |
| 46 | GET | `/api/finance/obligations` | `getFinanceObligations()` | zakat_screen |
| 47 | GET | `/api/finance/reports` | `getFinanceReports()` | zakat_screen |
| 48 | POST | `/api/backtest` | `runBacktest()` | (future) |
| 49 | GET | `/api/backtesting` | `getBacktestingResults()` | (future) |
| 50 | POST | `/api/zakat/calculate` | `calculateZakat()` | zakat_screen |
| 51 | GET | `/api/health` | `healthCheck()` | ai_analysis_screen |
| 52 | GET | `/api/version` | `fetchRemoteVersion()` | version_service |
| 53 | GET | `/api/mobile/stocks/$ticker/recommendation` | fallback | stock_history_screen |
| 54 | GET | `/api/mobile/stocks/$ticker/professional-analysis` | fallback | stock_history_screen |
| 55 | GET | `/api/mobile/analysis/$ticker` | fallback | ai_analysis_screen |
| 56 | GET | `/api/mobile/expert-recommendations` | fallback | recommendations_screen |
| 57 | GET | `/api/mobile/expert-recommendations/experts` | fallback | recommendations_screen |
| 58 | POST | `/api/mobile/zakat-calculator` | fallback | zakat_screen |

---

## ❌ Missing Endpoints — Pending Integration

| # | Method | Endpoint | Section | Plan | Target Screen |
|---|--------|----------|---------|------|---------------|
| 1 | POST | `/api/auth/register` | Auth | ❌ Not needed (Google-only) | — |
| 2 | POST | `/api/auth/login` | Auth | ❌ Not needed (Google-only) | — |
| 3 | GET | `/api/stocks/[ticker]/news` | Stocks | Stock news feed tab | stock_history_screen (new tab) |
| 4 | GET | `/api/stocks/movement-classification` | Stocks | Gainers/Losers/Active | stocks_screen (new filter) |
| 5 | GET | `/api/stocks/fundamentals` | Stocks | Fundamental data cards | stock_history_screen (data tab) |
| 6 | GET | `/api/portfolio/analyze` | Portfolio | Portfolio analysis section | portfolio_screen |
| 7 | GET | `/api/watchlist-enhanced` | Watchlist | Enhanced watchlist details | watchlist_screen |
| 8 | GET | `/api/market/live-data` | Market | Real-time market data | dashboard_screen |
| 9 | GET | `/api/market/investing` | Market | Investing.com data | dashboard_screen |
| 10 | GET | `/api/market/recommendations/ai-insights` | Market | AI market insights | recommendations_screen |
| 11 | GET | `/api/v2/live-analysis` | AI | Live analysis for all stocks | ai_analysis_screen |
| 12 | POST | `/api/subscription/upgrade` | Subscription | Plan upgrade flow | subscription_screen |
| 13 | DELETE | `/api/finance/assets/[id]` | Finance | Delete financial asset | zakat_screen |
| 14 | GET | `/api/currency/list` | Currency | Full currency list | currency_screen |
| 15 | GET | `/api/reports/morning` | Reports | Morning market reports | recommendations_screen |

---

## 🔒 Admin/Backend Only (Not Needed in Mobile)

Sync, Cron, Learning, Data Engine, System, Admin endpoints — server-side only.

---

*Last Updated: May 2026 (v2.0.2+2)*
