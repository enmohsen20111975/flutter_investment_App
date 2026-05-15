# مساعد الاستثمار App — Requirements & Implementation Plan

> Mobile companion app for the مساعد الاستثمار web platform (https://invist.m2y.net)
> Flutter • Dart • Material 3 • RTL Arabic UI

---

## 📋 Feature Requirements

### 1. Stock Monitoring
| # | Requirement | Status | Screen | API Endpoint |
|---|------------|--------|--------|-------------|
| 1.1 | View all stocks (winners/losers) | ✅ Done | `DashboardScreen` | `GET /api/market/overview` |
| 1.2 | Search stocks by name/ticker | ✅ Done | `StocksScreen` | `GET /api/stocks?query=` |
| 1.3 | View stock detail page | ✅ Done | `StockHistoryScreen` | `GET /api/stocks/:ticker` |
| 1.4 | View stock price history (chart) | ✅ Done | `StockHistoryScreen` | `GET /api/stocks/:ticker/history` |
| 1.5 | View market indices | ✅ Done | `DashboardScreen` | `GET /api/market/indices` |
| 1.6 | Market status (open/closed) | ✅ Done | `DashboardScreen` | `GET /api/market/status` |

### 2. Analysis & Recommendations
| # | Requirement | Status | Screen | API Endpoint |
|---|------------|--------|--------|-------------|
| 2.1 | Expert recommendations | ✅ Done | `RecommendationsScreen` | `GET /api/expert-recommendations` |
| 2.2 | Filter recommendations by status | ✅ Done | `RecommendationsScreen` | `GET /api/expert-recommendations?status=` |
| 2.3 | Expert stats/leaderboard | ✅ Done | `RecommendationsScreen` | `GET /api/expert-recommendations/experts` |
| 2.4 | AI-powered stock analysis | ✅ Done | `AIAnalysisScreen` | `POST /api/ai-analysis` |
| 2.5 | AI recommendations list | ✅ Done | `AIAnalysisScreen` | `GET /api/ai/recommendations` |
| 2.6 | AI predictions | ✅ Done | `AIAnalysisScreen` | `GET /api/predictions` |
| 2.7 | Batch analysis for all stocks | ✅ Done | `AIAnalysisScreen` | `GET /api/stocks/batch-analysis` |
| 2.8 | Professional analysis per stock | ✅ Done | `StockHistoryScreen` | `GET /api/stocks/:ticker/professional-analysis` |
| 2.9 | Stock-specific recommendation | ✅ Done | `StockHistoryScreen` | `GET /api/stocks/:ticker/recommendation` |

### 3. Notifications
| # | Requirement | Status | Screen | Notes |
|---|------------|--------|--------|-------|
| 3.1 | New analysis notifications | ❌ Missing | _Not created_ | Needs Firebase Cloud Messaging or local notifications |
| 3.2 | Portfolio alerts (price targets) | ❌ Missing | _Not created_ | Watchlist has alert fields but no push notification |
| 3.3 | Market open/close notifications | ❌ Missing | _Not created_ | Needs notification service |

### 4. Portfolio Management
| # | Requirement | Status | Screen | API Endpoint |
|---|------------|--------|--------|-------------|
| 4.1 | View portfolio summary | ✅ Done | `PortfolioScreen` | `GET /api/portfolio` |
| 4.2 | Add stock to portfolio | ✅ Done | `PortfolioScreen` (FAB) | `POST /api/portfolio` |
| 4.3 | Remove stock from portfolio | ✅ Done | `PortfolioScreen` | `DELETE /api/portfolio?id=` |
| 4.4 | Portfolio performance tracking | ✅ Done | `PortfolioScreen` | `GET /api/portfolio` |

### 5. Watchlist Management
| # | Requirement | Status | Screen | API Endpoint |
|---|------------|--------|--------|-------------|
| 5.1 | View watchlist | ✅ Done | `WatchlistScreen` | `GET /api/watchlist` |
| 5.2 | Add stock to watchlist | ✅ Done | `WatchlistScreen` (FAB) | `POST /api/watchlist` |
| 5.3 | Remove stock from watchlist | ✅ Done | `WatchlistScreen` | `DELETE /api/watchlist/:id` |
| 5.4 | Price alerts (above/below) | ✅ Done | `WatchlistScreen` (dialog) | Alert fields in add dialog |

### 6. Zakat Calculator
| # | Requirement | Status | Screen | API Endpoint |
|---|------------|--------|--------|-------------|
| 6.1 | Calculate zakat on assets | ✅ Done | `ZakatScreen` | `POST /api/zakat/calculate` |
| 6.2 | Input: cash, gold, stocks, receivables, debts | ✅ Done | `ZakatScreen` | All fields supported |

### 7. Crypto
| # | Requirement | Status | Screen | API Endpoint |
|---|------------|--------|--------|-------------|
| 7.1 | View crypto market list | ✅ Done | `CryptoScreen` | `GET /api/crypto` |
| 7.2 | Crypto detail page | ⚠️ Partial | — | `GET /api/crypto/:id` (API exists, no dedicated screen) |
| 7.3 | Crypto OHLC chart | ⚠️ Partial | — | `GET /api/crypto/ohlc` (API exists, no dedicated screen) |
| 7.4 | Crypto portfolio | ❌ Missing | — | Shares `PortfolioScreen` (no crypto-specific view) |
| 7.5 | Crypto watchlist | ❌ Missing | — | Shares `WatchlistScreen` (no crypto-specific view) |
| 7.6 | Crypto analysis/recommendations | ❌ Missing | — | No crypto-specific analysis |

### 8. Gold & Silver (Metals)
| # | Requirement | Status | Screen | API Endpoint |
|---|------------|--------|--------|-------------|
| 8.1 | View gold prices (ounce, gram, karat) | ✅ Done | `MetalsScreen` | `GET /api/market/gold` |
| 8.2 | Gold price history | ⚠️ Partial | — | `GET /api/market/gold/history` (API exists, not used in screen) |
| 8.3 | Silver prices | ❌ Missing | — | No dedicated silver data |
| 8.4 | Metals portfolio | ❌ Missing | — | Shares `PortfolioScreen` (no metals-specific view) |
| 8.5 | Metals watchlist | ❌ Missing | — | Shares `WatchlistScreen` (no metals-specific view) |
| 8.6 | Metals analysis | ❌ Missing | — | No metals-specific analysis |

### 9. Currency
| # | Requirement | Status | Screen | API Endpoint |
|---|------------|--------|--------|-------------|
| 9.1 | View currency rates | ✅ Done | `CurrencyScreen` | `GET /api/market/currency` |
| 9.2 | Currency converter | ✅ Done | `CurrencyScreen` | `GET /api/currency/convert` |

### 10. Authentication & Account
| # | Requirement | Status | Screen | API Endpoint |
|---|------------|--------|--------|-------------|
| 10.1 | Login (email/password) | ✅ Done | `AuthScreen` | `POST /api/auth/login` |
| 10.2 | Register | ✅ Done | `AuthScreen` | `POST /api/auth/register` |
| 10.3 | Google login | ✅ Done | `AuthScreen` | `POST /api/auth/google` |
| 10.4 | Subscription management | ✅ Done | `SubscriptionScreen` | `GET /api/subscription/plans` |
| 10.5 | Settings (risk, language, notifications) | ✅ Done | `SettingsScreen` | Local `SharedPreferences` |

---

## 🗺️ Navigation Map

### Bottom Tab Bar (5 tabs)
```
┌──────────┬──────────┬──────────┬──────────┬──────────┐
│ 🏠 الرئيسية  │ 📈 الأسهم   │   ✨ AI   │ ₿ الكريبتو │ 👛 المحفظة  │
│ index: 0  │ index: 1  │ index: 2  │ index: 3  │ index: 4  │
└──────────┴──────────┴──────────┴──────────┴──────────┘
     │            │           │           │           │
 DashboardScreen  StocksScreen  AIAnalysisScreen  CryptoScreen  PortfolioScreen
```

### Side Drawer
```
┌─────────────────────────────┐
│  🌐 مساعد الاستثمار          │
│     منصة الاستثمار الذكية    │
├─────────────────────────────┤
│  الوصول السريع               │
│  ├── 👁 قائمة المراقبة        │  → WatchlistScreen
│  └── 🕐 تاريخ الأسهم         │  → StockHistoryScreen
├─────────────────────────────┤
│  الأسواق                     │
│  ├── 📈 الأسهم               │  → Tab 1 (StocksScreen)
│  ├── ₿ الكريبتو              │  → Tab 3 (CryptoScreen)
│  ├── 💰 الذهب والفضة          │  → MetalsScreen
│  └── 💱 العملات               │  → CurrencyScreen
├─────────────────────────────┤
│  التحليل والأدوات             │
│  ├── 💡 التوصيات              │  → RecommendationsScreen
│  ├── ✨ تحليل AI              │  → Tab 2 (AIAnalysisScreen)
│  └── 🧮 حاسبة الزكاة          │  → ZakatScreen
├─────────────────────────────┤
│  الحساب                      │
│  ├── 👛 المحفظة               │  → Tab 4 (PortfolioScreen)
│  ├── 🏷 الاشتراكات            │  → SubscriptionScreen
│  ├── ⚙️ الإعدادات             │  → SettingsScreen
│  └── 🔑 تسجيل الدخول         │  → AuthScreen
└─────────────────────────────┘
```

### Floating Action Buttons
| Screen | FAB Action |
|--------|-----------|
| `PortfolioScreen` | ➕ Add stock to portfolio (dialog) |
| `WatchlistScreen` | ➕ Add stock to watchlist (dialog) |

---

## 📁 File Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # MaterialApp + MainNavigator (tabs + drawer)
├── api/
│   └── client.dart                    # Dio HTTP client (singleton `api`)
├── models/
│   └── types.dart                     # All data models (Stock, Crypto, Portfolio, etc.)
├── theme/
│   ├── colors.dart                    # AppColors, AppSpacing, AppRadius
│   └── typography.dart               # AppTypography, AppTheme
├── widgets/
│   └── state_view.dart               # StateView, DataRowWidget, HeaderCard, etc.
├── charts/
│   └── tradingview_chart.dart         # TradingView WebView widget
└── screens/
    ├── dashboard_screen.dart          # 🏠 Home — market overview, winners/losers
    ├── stocks_screen.dart             # 📈 Stocks list + search
    ├── stock_history_screen.dart      # 📊 Stock detail + price history chart
    ├── ai_analysis_screen.dart        # ✨ AI analysis, recommendations, predictions
    ├── crypto_screen.dart             # ₿ Crypto market list
    ├── metals_screen.dart             # 💰 Gold & metals prices
    ├── currency_screen.dart           # 💱 Currency rates + converter
    ├── portfolio_screen.dart          # 👛 Portfolio CRUD + summary
    ├── watchlist_screen.dart          # 👁 Watchlist CRUD + price alerts
    ├── recommendations_screen.dart    # 💡 Expert recommendations + stats
    ├── zakat_screen.dart              # 🧮 Zakat calculator
    ├── subscription_screen.dart       # 🏷 Subscription plans + upgrade
    ├── settings_screen.dart           # ⚙️ App settings + account
    └── auth_screen.dart               # 🔑 Login / Register
```

---

## 🚧 Implementation Priority

### Phase 1 — Critical Fixes ✅ (Completed)
- [x] Fix `No MaterialLocalizations found` error
- [x] Fix `Skipped 18146 frames` (main thread blocking)
- [x] Fix BottomNavigationBar tab mapping bug
- [x] Remove redundant `Directionality` wrappers
- [x] Reorganize drawer navigation

### Phase 2 — Feature Parity (Crypto & Metals)
- [ ] **Crypto Detail Screen** — dedicated page with chart (`getCryptoOHLC`), price history, market data
- [ ] **Gold/Silver History** — add price history chart to `MetalsScreen` (`getGoldHistory`)
- [ ] **Silver Data** — add silver prices to `MetalsScreen`
- [ ] **Unified Portfolio** — show stocks + crypto + metals in `PortfolioScreen` with category tabs
- [ ] **Unified Watchlist** — show stocks + crypto + metals in `WatchlistScreen` with category tabs

### Phase 3 — Notifications
- [ ] Add `flutter_local_notifications` package
- [ ] Create notification service for analysis alerts
- [ ] Create notification service for portfolio price alerts
- [ ] Add notification settings to `SettingsScreen`
- [ ] Add notification bell icon to `DashboardScreen` header

### Phase 4 — Enhanced Features
- [ ] **Crypto Analysis** — crypto-specific AI analysis and recommendations
- [ ] **Metals Analysis** — gold/silver-specific analysis
- [ ] **Backtesting** — UI for `runBacktest` / `getBacktestingResults` APIs
- [ ] **Finance Tracking** — UI for `getFinanceAssets`, `getFinanceObligations`, `getFinanceReports` APIs
- [ ] **Push Notifications** — Firebase Cloud Messaging integration

---

## 🔧 Technical Architecture

```
┌─────────────────────────────────────────────────┐
│                    main.dart                     │
│            WidgetsFlutterBinding.ensureInit()    │
│                  runApp(GLMInvestmentApp)        │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│              GLMInvestmentApp (StatelessWidget)  │
│  MaterialApp                                    │
│  ├── locale: ar_EG (RTL)                        │
│  ├── localizationsDelegates: Global*            │
│  ├── theme: AppTheme.lightTheme (Material 3)    │
│  └── home: MainNavigator                        │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────┐
│            MainNavigator (StatefulWidget)        │
│  ├── Directionality(RTL)                        │
│  ├── Scaffold                                   │
│  │   ├── drawer: _buildDrawer()                 │
│  │   ├── body: IndexedStack(_screens)           │
│  │   └── bottomNavigationBar                    │
│  └── 5 tabs: Dashboard, Stocks, AI, Crypto,     │
│              Portfolio                           │
└─────────────────────────────────────────────────┘
```

### State Management
- Each screen is a `StatefulWidget` with local state
- API calls via singleton `api` (`ApiClient` instance)
- `SharedPreferences` for local settings
- No global state store (could add Riverpod later)

### API Communication
- Base URL: `https://invist.m2y.net`
- HTTP client: Dio with interceptors
- Auth: Bearer token from `SharedPreferences`
- All endpoints return JSON, parsed into typed models

---

## 📝 Notes
- All UI is in **Arabic (RTL)** with `Locale('ar', 'EG')`
- The app uses **Material 3** design with emerald green primary color
- The `IndexedStack` preserves all tab screen states across switches
- Each screen handles its own loading/error/empty states via `StateView`
- The drawer provides quick access to all features not in the bottom tabs
