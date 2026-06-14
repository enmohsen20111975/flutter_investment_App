# Fix Summary — v2.0.2+2

## Phase 1: Core Fixes

### 1. Crypto Data Parsing Fix
**Location**: `lib/screens/crypto_detail_screen.dart:195`
- Safe `parseInt()` instead of unsafe cast

### 2. Stock Name Display
- **WatchlistScreen**: `item.nameAr ?? item.name ?? item.ticker`
- **PortfolioScreen**: `pos.stockName ?? pos.stockSymbol`

### 3. TradingView Chart Enhancement
**Files**: `lib/widgets/tradingview_chart.dart` (new), `assets/charts/tradingview.html` (updated)
- `ChartType` enum: candle, line, area
- `ChartInterval` enum: 1D, 1W, 1M, 3M, 6M, 1Y, ALL
- `TradingViewChart` + `TradingViewChartWithControls` widgets
- Theme support (dark/light)

### 4. Local Historical Data
**Location**: `lib/api/local_database.dart`
- `stock_history` table with v2 migration
- Batch insert, query by date range, sync check, cleanup methods

---

## Phase 2: Subscription System

### SubscriptionService (`lib/services/subscription_service.dart`)
- `SubscriptionStatus` model with tier detection (free/plus/premium)
- `FeatureAccessResult` for check-access API
- Local cache with SharedPreferences + 5-min TTL
- Feature gating: `hasAccess()`, `canAddToWatchlist()`, `canAddToPortfolio()`

### Feature Gates
- **stock_history_screen**: Recommendation + Analysis tabs locked behind subscription
- **ai_analysis_screen**: AI analysis checks access before running
- **watchlist_screen**: 3-item limit for Free tier
- **portfolio_screen**: 3-item limit for Free tier

### Upgrade Modal (`lib/widgets/upgrade_modal.dart`)
- Bottom sheet with Plus/Premium tier cards
- Navigation to subscription screen

---

## Phase 3: Full API Integration

### 15 Missing Endpoints Added to `client.dart`
| Endpoint | Method | Usage |
|----------|--------|-------|
| `/api/stocks/[ticker]/news` | `getStockNews()` | stock_history_screen (news tab) |
| `/api/stocks/movement-classification` | `getStockMovementClassification()` | stocks_screen (gainers/losers) |
| `/api/stocks/fundamentals` | `getStockFundamentals()` | stock_history_screen (data tab) |
| `/api/portfolio/analyze` | `analyzePortfolio()` | portfolio_screen (analysis section) |
| `/api/watchlist-enhanced` | `getWatchlistEnhanced()` | watchlist_screen (fallback chain) |
| `/api/market/live-data` | `getMarketLiveData()` | dashboard_screen (live section) |
| `/api/market/investing` | `getMarketInvesting()` | dashboard_screen (investing section) |
| `/api/market/recommendations/ai-insights` | `getMarketAiInsights()` | recommendations_screen |
| `/api/v2/live-analysis` | `getLiveAnalysis()` | ai_analysis_screen |
| `/api/subscription/upgrade` | `upgradeSubscription()` | subscription_screen |
| `/api/finance/assets/[id]` | `deleteFinanceAsset()` | (finance management) |
| `/api/currency/list` | `getCurrencyList()` | currency_screen (fallback) |
| `/api/reports/morning` | `getMorningReports()` | recommendations_screen |
| `/api/auth/register` | ❌ Not needed (Google-only) | — |
| `/api/auth/login` | ❌ Not needed (Google-only) | — |

### Screen Updates
- **auth_screen**: Google-only + phone number dialog after first login
- **stocks_screen**: Gainers/Losers/Most Active toggle filter
- **stock_history_screen**: 4 tabs (Data, Recommendation, Analysis, News) + fundamentals
- **portfolio_screen**: Portfolio analysis section with diversification/risk metrics
- **watchlist_screen**: Uses enhanced endpoint with fallback to basic
- **dashboard_screen**: Live market data + Investing.com data sections
- **ai_analysis_screen**: Live analysis data loaded in parallel
- **recommendations_screen**: AI market insights + morning reports sections
- **subscription_screen**: Uses upgrade endpoint for plan changes
- **currency_screen**: Falls back to currency list endpoint

### User Model
- Added `phone` field to `User` model (`lib/models/user.dart`)

## Files Changed
- `pubspec.yaml` — version bump to 2.0.2+2
- `lib/api/client.dart` — 15 new API methods
- `lib/api/local_database.dart` — stock_history table + migration
- `lib/models/user.dart` — phone field
- `lib/services/subscription_service.dart` — new
- `lib/widgets/upgrade_modal.dart` — new
- `lib/widgets/tradingview_chart.dart` — new
- `assets/charts/tradingview.html` — rewritten
- `lib/screens/auth_screen.dart` — Google-only + phone dialog
- `lib/screens/stocks_screen.dart` — movement classification
- `lib/screens/stock_history_screen.dart` — news tab + fundamentals + feature gates
- `lib/screens/portfolio_screen.dart` — analysis section + feature gate
- `lib/screens/watchlist_screen.dart` — enhanced endpoint + feature gate
- `lib/screens/dashboard_screen.dart` — live data + investing sections
- `lib/screens/ai_analysis_screen.dart` — live analysis + feature gate
- `lib/screens/recommendations_screen.dart` — AI insights + morning reports
- `lib/screens/subscription_screen.dart` — upgrade flow
- `lib/screens/currency_screen.dart` — currency list fallback
- `APIlist.md` — endpoint usage table (58 used, 15 pending)
- `AI-bridge-request.md` — checklist updated
- `AGENTS.md` — this file

## Build Status
- `flutter analyze`: 0 errors, 155 warnings/info only
