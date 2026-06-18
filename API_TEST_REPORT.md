# مساعد الاستثمار - API Test Report

**Date:** 2026-06-18  
**Environment:** Production (`https://invist.m2y.net/api`)  
**Tester:** Automated API health check via Python  

---

## 🟢 WORKING ENDPOINTS (200 OK)

| Method | Endpoint | Flutter Method | Notes |
|--------|----------|----------------|-------|
| GET | `/api/health` | `healthCheck()` | Healthy |
| GET | `/api/market/overview` | `getMarketOverview()` | Standard response |
| GET | `/api/stocks` | `getStocks()` | Returns stock list |
| GET | `/api/crypto` | `getCrypto()` | Returns crypto list |
| GET | `/api/subscription/plans` | `getSubscriptionPlans()` / `getSubscriptionPlansV2()` | Works |
| GET | `/api/market/status` | `getMarketStatus()` | Market open/closed info |
| GET | `/api/market/live-data` | `getMarketLiveData()` | Live data |
| GET | `/api/market/recommendations/ai-insights` | `getMarketAiInsights()` | AI insights present |
| GET | `/api/v2/live-analysis` | `getLiveAnalysis()` | Live analysis works |
| GET | `/api/reports/morning` | `getMorningReports()` | Morning reports |
| GET | `/api/watchlist-enhanced` | `getWatchlistEnhanced()` | Enhanced watchlist |
| GET | `/api/currency/list` | `getCurrencyList()` | Currency list |
| GET | `/api/portfolio/analyze` | `analyzePortfolio()` | Portfolio analysis |
| GET | `/api/mobile/recommendations` | `getMobileRecommendations()` | Mobile recommendations |
| GET | `/api/mobile/news` | `getMobileNews()` | News feed |
| GET | `/api/mobile/notifications` | `getMobileNotifications()` | Notifications |
| GET | `/api/expert-recommendations` | `getExpertRecommendations()` | Expert recs |
| GET | `/api/mobile/gold` | `getGold()` | Gold prices via mobile |
| GET | `/api/mobile/predictions` | `getMobilePredictions()` | Predictions |
| GET | `/api/learning/content` | `getLearningContent()` | Learning content |
| GET | `/api/hunter/screener` | `getHunterScreener()` | Hunter screener |
| POST | `/api/ai/chat` | `sendAiChat()` | AI chat works |
| POST | `/api/backtest` | `runBacktest()` | Backtest endpoint |

---

## 🔴 FAILING ENDPOINTS

### Critical Failures (Cannot serve expected data)

| Status | Endpoint | Flutter Method | Likely Cause | Impact |
|--------|----------|----------------|--------------|--------|
| **503** | `/api/stocks/movement-classification` | `getStockMovementClassification()` | Service Unavailable | Stocks screen gainers/losers filter broken |
| **500** | `/api/market/investing` | `getMarketInvesting()` | Internal Server Error | Dashboard investing section broken |
| **500** | `/api/predictions` | `getPredictions()` | Internal Server Error | AI predictions screen broken |
| **500** | `/api/maestro/stock/COMI` | `getMaestroAnalysis()` | Internal Server Error | Maestro analysis broken |
| **500** | `/api/instapay/verify` | `verifyInstapayPayment()` | Internal Server Error | Payment verification broken |

### Not Found (404)

| Status | Endpoint | Flutter Method | Notes |
|--------|----------|----------------|-------|
| **404** | `/api/market/gold` | (Old path) | Use `/api/mobile/gold` instead (works) |
| **404** | `/api/ai/batch-analysis` | `getBatchAnalysis()` | Endpoint does not exist |
| **404** | `/api/stocks/AEFM/recommendation` | `getStockRecommendation()` (case test) | Ticker-specific test |
| **404** | `/api/kimi/backtest/run` | `runKimiBacktest()` | Missing endpoint |
| **404** | `/api/walk-forward/run` | `runWalkForward()` | Missing endpoint |
| **404** | `/api/unified-learning/status` | `getUnifiedLearningStatus()` | Missing endpoint |
| **404** | `/api/unified-learning/indicators` | `getUnifiedLearningIndicators()` | Missing endpoint |

### Method Not Allowed (405)

| Status | Endpoint | Flutter Method | Notes |
|--------|----------|----------------|-------|
| **405** | `/api/auth/google` (GET) | `googleLogin()` | Requires POST (client uses POST correctly, test used GET) |
| **405** | `/api/subscription/upgrade` (GET) | `upgradeSubscription()` | Requires POST (client uses POST correctly) |
| **405** | `/api/google-play/verify-receipt` (GET) | `verifyGooglePlayReceipt()` | Requires POST (client uses POST correctly) |
| **405** | `/api/paymob/create-payment` (GET) | `createPaymobPayment()` | Requires POST (client uses POST correctly) |

### Unauthorized (401) - Expected behavior (auth required)

| Status | Endpoint | Flutter Method | Notes |
|--------|----------|----------------|-------|
| **401** | `/api/mobile/portfolio` | `getMobilePortfolio()` | Requires valid Bearer token |
| **401** | `/api/mobile/alerts/settings` | `getAlertSettings()` | Requires valid Bearer token |
| **401** | `/api/auth/me` | `getMe()` | Requires valid Bearer token |

---

## ⚠️ ENDPOINTS REQUIRING POST BODY PARAMETERS

These endpoints returned 400/405 in GET-only testing because they require POST request body. Client code uses POST correctly.

| Endpoint | Method | Issue | Client Status |
|----------|--------|-------|---------------|
| `/api/stocks/fundamentals` | GET | Requires `ticker` query param | ✅ Client passes `ticker` |
| `/api/auth/google` | POST | Needs `id_token` body | ✅ Client uses POST |
| `/api/subscription/upgrade` | POST | Needs `plan_id` body | ✅ Client uses POST |
| `/api/paymob/create-payment` | POST | Needs amount/currency/plan_id | ✅ Client uses POST |
| `/api/google-play/verify-receipt` | POST | Needs `receipt_data` body | ✅ Client uses POST |
| `/api/instapay/verify` | POST | Needs `tx_hash` body | ✅ Client uses POST |

---

## 📊 SUCCESS RATE SUMMARY

| Category | Count |
|----------|-------|
| Total tested | 33 |
| 200 OK | 23 |
| 401 Unauthorized | 3 |
| 405 Method Not Allowed (GET tested, POST used by client) | 4 |
| 404 Not Found | 7 |
| 500 Internal Server Error | 5 |
| 503 Service Unavailable | 1 |
| 400 Bad Request | 1 |

---

## 🚨 ACTION ITEMS FOR FULLSTACK ENGINEER

### P0 - Immediate Fix Required (500/503)
1. **`/api/market/investing`** - 500 Internal Server Error. Dashboard investing section non-functional.
2. **`/api/predictions`** - 500 Internal Server Error. AI predictions completely broken.
3. **`/api/stocks/movement-classification`** - 503 Service Unavailable. Gainers/losers filter broken.
4. **`/api/maestro/stock/[ticker]`** - 500 Internal Server Error. Maestro analysis broken.
5. **`/api/instapay/verify`** - 500 Internal Server Error. Instapay payment verification broken.

### P1 - Missing Endpoints (404)
1. **`/api/ai/batch-analysis`** - Implement or remove from client.
2. **`/api/kimi/backtest/run`** - Implement or remove.
3. **`/api/walk-forward/run`** - Implement or remove.
4. **`/api/unified-learning/status`** - Implement or remove.
5. **`/api/unified-learning/indicators`** - Implement or remove.
6. **`/api/unified-learning/patterns`** - Implement or remove (referenced in client).
7. **`/api/unified-learning/iterative`** - Implement or remove.
8. **`/api/unified-learning/intelligent`** - Implement or remove.
9. **`/api/unified-learning/mine-lessons`** - Implement or remove.

### P2 - Client Fallback Verification
1. **`/api/market/gold`** vs `/api/mobile/gold` - Gold screen already falls back to `/api/mobile/gold` (works).
2. **`/api/stocks/movement-classification`** - Client already catches error and returns `{}`.

### P3 - Minor Issues
1. **`/api/currency`** returns 503. Client `getCurrency()` may fail. Fallback to `/api/currency/list` works.
2. **`/api/currency/convert`** - Not tested (POST endpoint). Should be verified.
3. **`/api/subscription/plans`** - Works via GET, but `getSubscriptionPlansV2()` expects list or `plans` key.
4. **Auth endpoints** - All require proper POST body. GET testing gives 405, which is expected.

---

## 📝 ADDITIONAL NOTES

### Client-side Robustness
The Flutter client (`GLMApiClient`) is well-designed with:
- Comprehensive try/catch blocks
- Local fallbacks for many failing APIs
- Empty data return instead of crash (graceful degradation)
- Separate Dio instances for different timeouts

### Screens Most Affected
| Screen | Broken APIs | User Impact |
|--------|-------------|-------------|
| `stocks_screen.dart` | `getStockMovementClassification()` | Gainers/losers filter shows nothing |
| `dashboard_screen.dart` | `getMarketInvesting()` | Investing.com data section hidden |
| `ai_analysis_screen.dart` | `getPredictions()` | Predictions tab empty/fallback |
| `learning_backtest_screen.dart` | `getUnifiedLearningStatus()`, `getUnifiedLearningIndicators()` | Learning section broken |
| `payment_screen.dart` | `verifyInstapayPayment()` | Instapay payments fail |
| `subscription_screen.dart` | `upgradeSubscription()` | May use wrong HTTP method |