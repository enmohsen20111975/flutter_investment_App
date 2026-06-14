# 📚 EGX Investment Platform - Complete API Handbook

> **Version:** 15.0 | **Last Updated:** January 2026
> 
> **Base URLs:**
> - Production: `https://invist.m2y.net`
> - Development: `http://localhost:3000`
> - Python Backend: `http://localhost:8010`

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Authentication APIs](#authentication-apis)
3. [Stock Market APIs](#stock-market-apis)
4. [Analysis APIs](#analysis-apis)
5. [Predictions APIs](#predictions-apis)
6. [Portfolio APIs](#portfolio-apis)
7. [Watchlist APIs](#watchlist-apis)
8. [Crypto APIs](#crypto-apis)
9. [Multi-Market APIs](#multi-market-apis)
10. [Learning & Backtesting APIs](#learning--backtesting-apis)
11. [Admin APIs](#admin-apis)
12. [Mobile APIs](#mobile-apis)
13. [Payment & Subscription APIs](#payment--subscription-apis)
14. [Error Handling](#error-handling)
15. [Rate Limits & Timeouts](#rate-limits--timeouts)

---

## 🏗️ Architecture Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         FRONTEND (Next.js 16)                           │
│                            Port 3000                                    │
│                                                                         │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                 │
│   │  Web App    │   │ Mobile Web  │   │  Admin UI   │                 │
│   └──────┬──────┘   └──────┬──────┘   └──────┬──────┘                 │
│          │                 │                 │                          │
│          └─────────────────┼─────────────────┘                          │
│                            │                                            │
│                   /api/* (REST Endpoints)                               │
│                            │                                            │
│          ┌─────────────────┼─────────────────┐                          │
│          │                 │                 │                          │
│          ▼                 ▼                 ▼                          │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                 │
│   │   Proxy     │   │   Local     │   │   Direct    │                 │
│   │   Routes    │   │   Routes    │   │   Routes    │                 │
│   └──────┬──────┘   └──────┬──────┘   └──────┬──────┘                 │
│          │                 │                 │                          │
└──────────┼─────────────────┼─────────────────┼──────────────────────────┘
           │                 │                 │
           ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       PYTHON BACKEND (THE BRAIN)                        │
│                            Port 8010                                    │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                      Flask Application                          │  │
│   │                                                                 │  │
│   │   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐  │  │
│   │   │Analysis │ │Predict- │ │Portfolio│ │ Crypto  │ │Learning │  │  │
│   │   │ Engine  │ │ions API │ │ Manager │ │ Engine  │ │ Engine  │  │  │
│   │   └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘  │  │
│   │        │           │           │           │           │        │  │
│   │        └───────────┴───────────┴───────────┴───────────┘        │  │
│   │                              │                                   │  │
│   │                              ▼                                   │  │
│   │   ┌─────────────────────────────────────────────────────────┐   │  │
│   │   │              Core Scoring Engine                        │   │  │
│   │   │   • Technical Analysis  • Fundamental Analysis          │   │  │
│   │   │   • Pattern Recognition • Risk Management               │   │  │
│   │   │   • Fibonacci Levels    • Timing Analysis               │   │  │
│   │   └─────────────────────────────────────────────────────────┘   │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                      DATABASES (SQLite)                         │  │
│   │                                                                 │  │
│   │   stocks.db  │  predictions.db  │  price_history.db            │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Core Principles

| Principle | Description |
|-----------|-------------|
| **Python = THE BRAIN** | All calculations, logic, and analysis happen in Python Backend |
| **Node.js = DISPLAY ONLY** | Frontend is for presentation, no business logic |
| **No Mock Data** | Production only, all data is real |
| **API Documentation Required** | Every change must be documented |

### Request Flow

```
User Request → Next.js (/api/*) → Python Backend (:8010) → Database
                   │
                   └── Some endpoints query local DB directly
```

---

## 🔐 Authentication APIs

### Base Path: `/api/auth`

### POST /api/auth/register

Register a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "username": "username",
  "password": "securePassword123",
  "name": "User Name"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Registration successful",
  "message_ar": "تم التسجيل بنجاح",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "username",
    "name": "User Name",
    "subscription_tier": "free"
  }
}
```

### POST /api/auth/login

Authenticate user and get token.

**Request Body:**
```json
{
  "username_or_email": "user@example.com",
  "password": "securePassword123"
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
    "subscription_tier": "free",
    "is_admin": false
  },
  "token": "egx_uuid_token...",
  "token_type": "Bearer",
  "expires_in": 2592000
}
```

### GET /api/auth/me

Get current authenticated user info.

**Headers:**
```
Authorization: Bearer {token}
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
    "is_admin": false,
    "email_verified": true
  }
}
```

### POST /api/auth/logout

Logout current user.

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

### POST /api/auth/google

Google OAuth login.

**Request Body:**
```json
{
  "id_token": "google_id_token"
}
```

---

## 📈 Stock Market APIs

### Base Path: `/api/stocks`

### GET /api/stocks

Get list of all stocks with optional filters.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `sector` | string | null | Filter by sector |
| `index` | string | null | Filter by index (EGX30, EGX70) |
| `query` | string | null | Search by name/ticker |
| `limit` | int | 100 | Number of results |
| `offset` | int | 0 | Pagination offset |
| `market` | string | EGX | Market code |

**Response:**
```json
{
  "success": true,
  "stocks": [
    {
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "name_ar": "البنك التجاري الدولي",
      "sector": "Banks",
      "market": "EGX",
      "current_price": 136.59,
      "change_percent": 1.55,
      "volume": 1500000,
      "high_price": 138.00,
      "low_price": 135.00,
      "previous_close": 134.50
    }
  ],
  "total": 330,
  "limit": 100,
  "offset": 0
}
```

### GET /api/stocks/{ticker}

Get details for a specific stock.

**Response:**
```json
{
  "success": true,
  "stock": {
    "ticker": "COMI",
    "name": "Commercial International Bank",
    "name_ar": "البنك التجاري الدولي",
    "sector": "Banks",
    "market": "EGX",
    "current_price": 136.59,
    "change": 2.09,
    "change_percent": 1.55,
    "volume": 1500000,
    "high_price": 138.00,
    "low_price": 135.00,
    "previous_close": 134.50,
    "year_high": 165.00,
    "year_low": 95.00,
    "market_cap": 62500000000,
    "pe_ratio": 5.2,
    "dividend_yield": 3.5,
    "is_active": true,
    "last_updated": "2026-01-15T14:30:00Z"
  }
}
```

### GET /api/stocks/{ticker}/history

Get price history for a stock.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `period` | string | 1M | Period (1D, 1W, 1M, 3M, 6M, 1Y, ALL) |
| `interval` | string | daily | Interval (daily, weekly, monthly) |

**Response:**
```json
{
  "success": true,
  "ticker": "COMI",
  "period": "1M",
  "data": [
    {
      "date": "2026-01-15",
      "open": 135.00,
      "high": 138.00,
      "low": 134.50,
      "close": 136.59,
      "volume": 1500000
    }
  ],
  "count": 30
}
```

### GET /api/stocks/search

Search stocks by name or ticker.

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | Yes | Search query |
| `limit` | int | No | Max results (default: 20) |

**Response:**
```json
{
  "success": true,
  "query": "commercial",
  "results": [
    {
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "name_ar": "البنك التجاري الدولي",
      "sector": "Banks",
      "current_price": 136.59
    }
  ],
  "count": 1
}
```

### GET /api/stocks/recommendations

Get stock recommendations.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `persona` | string | balanced | conservative/balanced/gambler |
| `limit` | int | 10 | Number of results |

### GET /api/stocks/fundamentals

Get fundamental data for stocks.

---

## 📊 Analysis APIs

### Base Path: `/api/analysis`, `/api/advanced-analysis`, `/api/v2/analysis`

### GET /api/advanced-analysis

Get advanced analysis for a stock (Proxy to Python).

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ticker` | string | Yes | Stock ticker |
| `action` | string | No | analyze/golden/status |

**Response:**
```json
{
  "success": true,
  "ticker": "COMI",
  "analysis": {
    "signal": "BUY",
    "signal_ar": "شراء",
    "score": 78,
    "confidence": 82,
    "reasons": [
      "Strong bullish momentum",
      "Above key moving averages",
      "Good volume support"
    ],
    "technical": {
      "rsi": 55.2,
      "macd": "bullish",
      "trend": "uptrend",
      "support": 130.00,
      "resistance": 145.00
    },
    "fundamental": {
      "pe_ratio": 5.2,
      "pb_ratio": 1.1,
      "dividend_yield": 3.5,
      "roe": 18.5
    },
    "risk": {
      "level": "medium",
      "stop_loss": 128.00,
      "position_size": 5
    },
    "targets": {
      "target_1": 150.00,
      "target_2": 165.00,
      "stop_loss": 128.00,
      "risk_reward": 2.5
    }
  }
}
```

### POST /api/advanced-analysis

Run custom analysis with your data.

**Request Body:**
```json
{
  "action": "comprehensive",
  "ticker": "COMI",
  "price_history": [
    {"date": "2026-01-01", "open": 130, "high": 135, "low": 129, "close": 134, "volume": 1000000}
  ],
  "timeframe": "daily",
  "persona": "balanced"
}
```

**Available Actions:**
| Action | Description |
|--------|-------------|
| `analyze` | Full stock analysis |
| `candlesticks` | Candlestick pattern analysis |
| `patterns` | Price pattern recognition |
| `comprehensive` | Complete technical + fundamental |
| `confluence` | Multi-timeframe confluence |
| `quick-signal` | Quick trading signal |
| `golden` | Golden stocks scanner |

### GET /api/v2/analysis/{ticker}

V2 Enhanced analysis endpoint.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `persona` | string | trader | Persona type |
| `market` | string | EGX | Market code |

### GET /api/v2/scanner

Market scanner for opportunities.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `market` | string | EGX | Market to scan |
| `persona` | string | trader | Persona filter |
| `min_score` | int | 65 | Minimum score |
| `limit` | int | 20 | Max results |

**Response:**
```json
{
  "success": true,
  "market": "EGX",
  "timestamp": "2026-01-15T14:30:00Z",
  "results": [
    {
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "score": 82,
      "signal": "BUY",
      "price": 136.59,
      "target": 150.00,
      "stop_loss": 128.00,
      "risk_reward": 2.1
    }
  ],
  "total_analyzed": 120,
  "passed_filter": 15
}
```

### GET /api/v2/morning-recommendations

Get morning recommendations for the day.

### POST /api/v2/unified/analyze

Unified analysis endpoint (supports multi-market).

**Request Body:**
```json
{
  "ticker": "COMI",
  "market": "EGX",
  "persona": "trader",
  "support": 130.0,
  "resistance": 145.0
}
```

### POST /api/v2/unified/scan

Scan market for opportunities.

**Request Body:**
```json
{
  "market": "EGX",
  "persona": "trader",
  "top_n": 20,
  "min_score": 65
}
```

### GET /api/v2/unified/markets

List available markets with their configurations.

### GET /api/v2/unified/personas

List available personas with their settings.

### GET /api/v2/unified/config

Get unified configuration for market + persona.

**Query Parameters:**
| Parameter | Type | Default |
|-----------|------|---------|
| `market` | string | EGX |
| `persona` | string | trader |

---

## 🔮 Predictions APIs

### Base Path: `/api/predictions`, `/api/ai-predictions`

### GET /api/predictions

Get all AI predictions.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `status` | string | all | all/pending/verified |
| `signal` | string | all | all/BUY/SELL/HOLD |
| `limit` | int | 50 | Max results |

**Response:**
```json
{
  "success": true,
  "predictions": [
    {
      "id": "pred_123",
      "symbol": "COMI",
      "market": "EGX",
      "signal": "BUY",
      "confidence": 85,
      "entry_price": 136.59,
      "target_price": 150.00,
      "stop_loss": 128.00,
      "risk_reward": 1.7,
      "reasoning": "Strong technical setup with bullish momentum",
      "created_at": "2026-01-15T10:00:00Z",
      "verify_date": "2026-01-22T10:00:00Z",
      "verified": false,
      "result": null,
      "final_price": null,
      "profit_loss_pct": null
    }
  ],
  "stats": {
    "total_predictions": 50,
    "verified_predictions": 35,
    "successful": 25,
    "failed": 10,
    "success_rate": 71.4
  }
}
```

### POST /api/predictions/generate

Generate new AI predictions.

**Request Body:**
```json
{
  "tickers": ["COMI", "ETAL", "HRHO"],
  "market": "EGX",
  "persona": "balanced"
}
```

### POST /api/predictions/generate-all

Generate predictions for all stocks.

**Query Parameters:**
| Parameter | Type | Default |
|-----------|------|---------|
| `market` | string | EGX |
| `limit` | int | 50 |

### POST /api/predictions/verify

Verify pending predictions.

### GET /api/predictions/performance

Get prediction performance statistics.

**Response:**
```json
{
  "success": true,
  "performance": {
    "total_predictions": 100,
    "verified": 75,
    "successful": 52,
    "failed": 23,
    "success_rate": 69.3,
    "avg_profit_pct": 4.2,
    "avg_loss_pct": -2.1,
    "by_signal": {
      "BUY": {
        "count": 60,
        "success_rate": 72.5
      },
      "SELL": {
        "count": 40,
        "success_rate": 65.0
      }
    }
  }
}
```

### GET /api/ai-predictions/info

Get available analysis information.

### POST /api/ai-predictions/generate

Generate AI predictions with full control.

**Request Body:**
```json
{
  "market": "EGX",
  "limit": 20,
  "min_score": 70,
  "persona": "trader"
}
```

### POST /api/ai-predictions/evaluate

Evaluate prediction accuracy.

### GET /api/ai-predictions/stats

Get AI prediction statistics.

---

## 💼 Portfolio APIs

### Base Path: `/api/portfolio`, `/api/finance/assets`

### GET /api/portfolio

Get user portfolio.

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "positions": [
    {
      "id": "pos_123",
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "sector": "Banks",
      "shares": 500,
      "avg_cost": 120.00,
      "current_price": 136.59,
      "market_value": 68295.00,
      "cost_basis": 60000.00,
      "unrealized_pnl": 8295.00,
      "unrealized_pnl_percent": 13.83,
      "entry_date": "2026-01-01T00:00:00Z",
      "notes": "Long term hold"
    }
  ],
  "summary": {
    "total_positions": 5,
    "total_cost_basis": 100000.00,
    "total_market_value": 115000.00,
    "total_unrealized_pnl": 15000.00,
    "total_unrealized_pnl_percent": 15.00,
    "winning_positions": 4,
    "losing_positions": 1
  }
}
```

### POST /api/portfolio

Add position to portfolio.

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "stock_symbol": "COMI",
  "shares": 100,
  "avg_cost": 136.00,
  "entry_date": "2026-01-15",
  "notes": "Optional notes"
}
```

### DELETE /api/portfolio

Remove position from portfolio.

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
| Parameter | Type | Required |
|-----------|------|----------|
| `id` | string | Yes |

### POST /api/portfolio/analyze

Analyze portfolio risk and performance.

### GET /api/finance/assets

Get all finance assets.

### POST /api/finance/assets

Add new finance asset.

### GET /api/finance/calculate-values

Calculate portfolio values with live prices.

---

## 👀 Watchlist APIs

### Base Path: `/api/watchlist`

### GET /api/watchlist

Get user watchlist.

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "watchlist": [
    {
      "id": "wl_123",
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "current_price": 136.59,
      "change_percent": 1.55,
      "alert_price_above": 145.00,
      "alert_price_below": 130.00,
      "notes": "Watching for breakout",
      "added_at": "2026-01-15T10:00:00Z"
    }
  ],
  "total": 5
}
```

### POST /api/watchlist

Add stock to watchlist.

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "ticker": "COMI",
  "alert_price_above": 145.00,
  "alert_price_below": 130.00,
  "notes": "Watching for breakout"
}
```

### DELETE /api/watchlist/{id}

Remove stock from watchlist.

### GET /api/mobile/watchlist-enhanced

Get enhanced watchlist with analysis and alerts.

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "watchlist": [
    {
      "id": "wl_123",
      "ticker": "COMI",
      "name": "Commercial International Bank",
      "name_ar": "البنك التجاري الدولي",
      "sector": "Banks",
      "current_price": 136.59,
      "previous_close": 134.50,
      "change_percent": 1.55,
      "volume": 1500000,
      "alert_price_above": 145.00,
      "alert_price_below": 130.00,
      "notes": "Watching for breakout",
      "purchase_price": 120.00,
      "quantity": 100,
      "pnl": 1659.00,
      "pnl_percent": 13.83,
      "has_alert": false,
      "recommendation": {
        "signal": "BUY",
        "score": 78
      }
    }
  ],
  "summary": {
    "total": 5,
    "gainers": 3,
    "losers": 2,
    "alerts": 1
  }
}
```

---

## ₿ Crypto APIs

### Base Path: `/api/crypto`

### GET /api/crypto

Get list of cryptocurrencies.

**Response:**
```json
{
  "success": true,
  "coins": [
    {
      "id": "bitcoin",
      "symbol": "BTC",
      "name": "Bitcoin",
      "name_ar": "بيتكوين",
      "current_price": 67500.00,
      "price_change_24h": 2.5,
      "price_change_percent_24h": 3.85,
      "market_cap": 1320000000000,
      "total_volume": 28500000000,
      "high_24h": 68500.00,
      "low_24h": 65000.00,
      "circulating_supply": 19500000,
      "image": "https://..."
    }
  ],
  "timestamp": "2026-01-15T14:30:00Z"
}
```

### GET /api/crypto/{id}

Get details for specific cryptocurrency.

### GET /api/crypto/status

Get crypto system status.

### GET /api/crypto/stats

Get crypto market statistics.

### POST /api/crypto/analyze

Analyze a cryptocurrency.

**Request Body:**
```json
{
  "symbol": "BTC",
  "timeframe": "daily"
}
```

### GET /api/crypto/recommendations

Get crypto recommendations.

**Query Parameters:**
| Parameter | Type | Default |
|-----------|------|---------|
| `limit` | int | 10 |
| `min_score` | int | 60 |

### POST /api/crypto/start

Start crypto data sync.

### POST /api/crypto/stop

Stop crypto data sync.

### GET /api/crypto/ohlc

Get OHLC data for crypto.

**Query Parameters:**
| Parameter | Type | Required |
|-----------|------|----------|
| `symbol` | string | Yes |
| `days` | int | No (default: 30) |

### GET /api/mobile/crypto

Mobile-optimized crypto list.

---

## 🌍 Multi-Market APIs

### Base Path: `/api/multi-market`

### Supported Markets

| Code | Market | Currency |
|------|--------|----------|
| EGX | Egyptian Exchange | EGP |
| TADAWUL | Saudi Stock Exchange | SAR |
| KSE | Kuwait Stock Exchange | KWD |
| QSE | Qatar Stock Exchange | QAR |
| DFM | Dubai Financial Market | AED |
| ADX | Abu Dhabi Securities Exchange | AED |
| BSE | Bahrain Stock Exchange | BHD |

### GET /api/multi-market/sync

Sync data from all markets.

### GET /api/multi-market/status

Get multi-market sync status.

### POST /api/v2/unified/scan

Scan specific market.

**Request Body:**
```json
{
  "market": "TADAWUL",
  "persona": "trader",
  "top_n": 20
}
```

### GET /api/maestro/stock/{ticker}

Get Maestro analysis for any stock.

**Query Parameters:**
| Parameter | Type | Default |
|-----------|------|---------|
| `market` | string | EGX |
| `persona` | string | balanced |

---

## 📚 Learning & Backtesting APIs

### Base Path: `/api/learning`, `/api/backtesting`, `/api/unified-learning`

### GET /api/unified-learning/status

Get learning system status.

### POST /api/unified-learning/iterative

Run iterative learning.

### POST /api/unified-learning/intelligent

Run intelligent Bayesian learning.

### GET /api/unified-learning/indicators

Get indicator trust scores.

### GET /api/unified-learning/patterns

Get discovered patterns.

### POST /api/unified-learning/mine-lessons

Mine lessons from historical data.

### GET /api/learning/content

Get learning content.

### GET /api/learning/progress

Track learning progress.

### GET /api/backtesting

Run and analyze backtests.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `action` | string | summary/quick-backtest/full-backtest/walk-forward |
| `persona` | string | Persona type |
| `year` | int | Start year |
| `month` | int | Start month |
| `weeks` | int | Number of weeks |

**Available Actions:**
| Action | Description |
|--------|-------------|
| `summary` | System status |
| `quick-backtest` | Quick backtest |
| `full-backtest` | Full historical backtest |
| `walk-forward` | Walk-Forward backtest |
| `test-personas` | Test all personas |
| `verify` | Verify predictions |
| `auto-adjust` | Auto-adjust parameters |

### POST /api/backtesting/unified

Unified backtesting endpoint.

### GET /api/kimi/backtest/run

Run Kimi backtest.

### GET /api/walk-forward/run

Run walk-forward backtest.

---

## 🔧 Admin APIs

### Base Path: `/api/admin`

> **Note:** All admin endpoints require authentication with admin privileges.

### GET /api/admin/stats

Get system statistics.

**Response:**
```json
{
  "success": true,
  "stats": {
    "users": {
      "total": 1500,
      "active": 850,
      "new_today": 12
    },
    "predictions": {
      "total": 5000,
      "verified": 3500,
      "success_rate": 72.5
    },
    "stocks": {
      "total": 500,
      "active": 480
    },
    "system": {
      "uptime_days": 45,
      "db_size_mb": 250,
      "last_sync": "2026-01-15T14:00:00Z"
    }
  }
}
```

### GET /api/admin/monitor

System monitoring dashboard data.

### GET /api/admin/analytics

Analytics overview.

### GET /api/admin/db-health

Database health check.

### POST /api/admin/sync-vps

Sync data from VPS.

### GET /api/admin/users

List all users.

**Query Parameters:**
| Parameter | Type | Default |
|-----------|------|---------|
| `limit` | int | 50 |
| `offset` | int | 0 |
| `search` | string | null |

### GET /api/admin/users/{id}

Get user details.

### PUT /api/admin/users/{id}

Update user.

### DELETE /api/admin/users/{id}

Delete user.

### POST /api/admin/import-stocks

Import stocks from file.

### POST /api/admin/import-data

Import market data.

### GET /api/admin/export-data

Export system data.

### POST /api/admin/clean-predictions

Clean old predictions.

### GET /api/admin/recommendation-settings

Get/set recommendation settings.

### POST /api/admin/ai-predictions/generate

Admin: Generate predictions with full control.

### POST /api/admin/historical-backfill/run

Run historical data backfill.

### GET /api/admin/historical-backfill/status

Get backfill status.

---

## 📱 Mobile APIs

### Base Path: `/api/mobile`

> All mobile endpoints are optimized for mobile apps with smaller payloads and efficient responses.

### GET /api/mobile/auth/me

Get current user (mobile optimized).

### GET /api/mobile/summary

Quick market summary.

**Response:**
```json
{
  "success": true,
  "source": "python_backend",
  "timestamp": "2026-01-15T14:30:00Z",
  "market": {
    "indices": {
      "egx30": { "value": 28500, "change": 1.2 },
      "egx70": { "value": 4200, "change": -0.5 }
    },
    "top_stocks": [...],
    "gainers": [...],
    "losers": [...]
  },
  "portfolio_summary": {
    "total_value": 115000,
    "pnl": 15000,
    "pnl_percent": 15.0
  }
}
```

### GET /api/mobile/market/overview

Market overview with top movers.

### GET /api/mobile/recommendations

Stock recommendations by persona.

**Query Parameters:**
| Parameter | Type | Default |
|-----------|------|---------|
| `persona` | string | balanced |
| `limit` | int | 10 |

### GET /api/mobile/predictions

AI predictions list.

### GET /api/mobile/portfolio

User portfolio.

### POST /api/mobile/portfolio

Add position.

### DELETE /api/mobile/portfolio

Remove position.

### GET /api/mobile/watchlist-enhanced

Enhanced watchlist with alerts.

### GET /api/mobile/crypto

Crypto prices.

### GET /api/mobile/stocks/{ticker}

Stock detail.

### GET /api/mobile/stocks/{ticker}/recommendation

Stock recommendation.

### GET /api/mobile/stocks/{ticker}/professional-analysis

Professional analysis.

### GET /api/mobile/market/recommendations/ai-insights

AI market sentiment.

### GET /api/mobile/news

Market news.

### GET /api/mobile/dashboard

Dashboard data for mobile.

### GET /api/mobile/alerts/check

Check for price alerts.

### GET /api/mobile/notifications

Get notifications.

### GET /api/mobile/risk

Risk management data.

### GET /api/mobile/seasonality

Seasonality data.

### GET /api/mobile/maestro

Maestro analysis for mobile.

### GET /api/mobile/gold

Gold prices.

### GET /api/mobile/subscription

Subscription status.

---

## 💳 Payment & Subscription APIs

### Base Path: `/api/subscription`, `/api/paymob`, `/api/instapay`

### GET /api/subscription/plans

List available subscription plans.

**Response:**
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
      "features": {
        "daily_predictions": 5,
        "portfolio_positions": 10,
        "watchlist_items": 20,
        "advanced_analysis": false
      }
    },
    {
      "id": "pro",
      "name": "Pro",
      "name_ar": "احترافي",
      "price": 199,
      "currency": "EGP",
      "features": {
        "daily_predictions": 50,
        "portfolio_positions": 100,
        "watchlist_items": 50,
        "advanced_analysis": true
      }
    }
  ]
}
```

### GET /api/subscription/current

Get current subscription status.

### POST /api/subscription/activate

Activate subscription.

### POST /api/subscription/deactivate

Deactivate subscription.

### POST /api/subscription/start-trial

Start free trial.

### POST /api/subscription/upgrade

Upgrade subscription.

### GET /api/subscription/check-access

Check access to feature.

**Query Parameters:**
| Parameter | Type | Required |
|-----------|------|----------|
| `feature` | string | Yes |

### POST /api/paymob/create-payment

Create Paymob payment.

**Request Body:**
```json
{
  "amount": 199,
  "currency": "EGP",
  "plan_id": "pro"
}
```

### POST /api/paymob/callback

Paymob payment callback.

### POST /api/instapay/verify

Verify Instapay payment.

### POST /api/google-play/verify-receipt

Verify Google Play purchase.

---

## ❌ Error Handling

### Standard Error Response

```json
{
  "success": false,
  "error": "Error message in English",
  "error_ar": "رسالة الخطأ بالعربية",
  "detail": "Technical details for debugging",
  "code": "ERROR_CODE"
}
```

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource already exists |
| 422 | Unprocessable Entity | Validation error |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Service temporarily unavailable |

### Error Codes

| Code | Description |
|------|-------------|
| `AUTH_REQUIRED` | Authentication token required |
| `INVALID_TOKEN` | Token is invalid or expired |
| `INSUFFICIENT_PERMISSIONS` | User lacks required permissions |
| `RESOURCE_NOT_FOUND` | Requested resource not found |
| `VALIDATION_ERROR` | Input validation failed |
| `RATE_LIMIT_EXCEEDED` | Too many requests |
| `MARKET_CLOSED` | Market is currently closed |
| `SERVICE_UNAVAILABLE` | Service temporarily unavailable |

---

## ⏱️ Rate Limits & Timeouts

### Rate Limits

| Endpoint Category | Rate Limit |
|-------------------|------------|
| Authentication | 10 req/min |
| Market Data | 60 req/min |
| Analysis | 30 req/min |
| Predictions | 20 req/min |
| Admin | 100 req/min |

### Timeouts

| Endpoint Type | Timeout |
|---------------|---------|
| Market Data | 10 seconds |
| Authentication | 5 seconds |
| Analysis | 60 seconds |
| Backtesting | 180 seconds |
| Learning | 180 seconds |
| AI Generation | 120 seconds |

---

## 🔄 Data Sources

| Data Type | Primary Source | Fallback |
|-----------|---------------|----------|
| Stock Prices | Python Backend | Local SQLite |
| Market Overview | Python Backend | Local SQLite |
| Predictions | Python Backend | Local SQLite |
| Crypto | Python Backend | External API |
| Portfolio | PostgreSQL (Prisma) | - |
| Watchlist | SQLite + PostgreSQL | - |
| News | Python Backend | Cached |

---

## 🚀 Quick Reference

### Personas

| Persona | Min Score | Risk Level | Position Size |
|---------|-----------|------------|---------------|
| `conservative` | 75+ | Low | 3% |
| `balanced` | 65+ | Medium | 5% |
| `gambler` | 50+ | High | 10% |
| `trader` | 60+ | Medium-High | 7% |
| `investor` | 70+ | Low-Medium | 4% |

### Markets

| Code | Name | Currency | Trading Hours (UTC) |
|------|------|----------|---------------------|
| EGX | Egyptian Exchange | EGP | 07:00 - 11:30 |
| TADAWUL | Saudi Exchange | SAR | 07:00 - 15:00 |
| KSE | Kuwait Exchange | KWD | 06:00 - 10:00 |
| QSE | Qatar Exchange | QAR | 07:00 - 13:00 |

### Signal Types

| Signal | Meaning | Score Range |
|--------|---------|-------------|
| `STRONG_BUY` | Strong buy signal | 85+ |
| `BUY` | Buy signal | 70-84 |
| `HOLD` | Hold position | 50-69 |
| `AVOID` | Avoid/Reduce | 30-49 |
| `SELL` | Sell signal | Below 30 |

---

## 📝 Changelog

### v15.0 (January 2026)
- Added complete Mobile API documentation
- Added Multi-Market support documentation
- Added Payment & Subscription APIs
- Enhanced error handling documentation
- Added rate limits and timeouts

### v14.0 (June 2025)
- Major architecture change: Python = THE BRAIN
- Node.js for display only
- Converted APIs to proxies for Python Backend
- Removed duplicate logic from Node.js

### v13.0 (June 2025)
- Complete documentation update
- Removed all mock data
- Documented actual APIs

---

*Last Updated: January 2026*
*Version: 15.0*
