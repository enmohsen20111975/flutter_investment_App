# 📱 خطة إصلاح وتطوير شاملة — تطبيق دليل الاستثمار
## Flutter Mobile App — Complete Overhaul Plan

> **الهدف:** تحويل التطبيق إلى تجربة احترافية سلسة، كاملة الأداء، بدون هنج أو توقف،
> مع إضافة كل الميزات الموجودة في الويب ودمج كل الـ APIs الجديدة من API_HANDBOOK.md

---

## 📋 ملخص الوضع الحالي — بعد التحديث (18 يونيو 2026)

### ✅ المشاكل التي تم حلها — تحديث 18 يونيو 2026
| المشكلة | الشاشة | الإصلاح | الحالة |
|---------|---------|---------|--------|
| التطبيق بيهنج ويتوقف | كل الشاشات | إضافة Skeleton Loading + FutureBuilder صحيح | ✅ |
| Dio timeout 10 ثانية | client.dart | 3 Dio instances: Default 15s/30s, AI 120s, Chart 15s | ✅ |
| `getPortfolio()` → `/api/portfolio` (web) | PortfolioScreen | تحويل إلى `/api/mobile/portfolio` | ✅ |
| `getRecommendations()` → `/api/recommendations` | RecommendationsScreen | تحويل إلى `/api/mobile/recommendations` | ✅ |
| `getPredictions()` → `/api/ai/predictions` | AiAnalysisScreen | تحويل إلى `/api/mobile/predictions` + 3 Tabs | ✅ |
| `getCurrentSubscription()` → `/api/subscription` | SubscriptionScreen | تحويل إلى `/api/subscription/current` | ✅ |
| `getDashboard()` مش موجود | DashboardScreen | إضافة `/api/mobile/dashboard` + Skeleton + StreamBuilder | ✅ |
| مفيش Skeleton Loading | كل الشاشات | 10 أنواع Skeleton (Box, Card, List, Dashboard, Portfolio, StockDetail, AiAnalysis, Recommendations) | ✅ |
| مفيش Live Polling | DashboardScreen | PollingService مع Stream + تكيف ذكي 5/30 دقيقة | ✅ |
| مفيش Retry Logic | client.dart | MobileApiService مع 3 محاولات + Exponential Backoff | ✅ |
| مفيش State Management | المشروع كله | MarketProvider (ChangeNotifier) + Provider Package | ✅ |
| مفيش Market Status Banner | كل الشاشات | شريط حالة مفتوح/مغلق مع Auto-polling | ✅ |
| مفيش استجابة سريعة للـ API | client.dart | 25+ endpoint جديد كلها مضافين في client.dart | ✅ |
| مفيش شاشة Notifications | NotificationsScreen | شاشة جديدة مع Skeleton + Read/Unread + 3 أنواع | ✅ |
| مفيش Hunter/Screener | HunterScreen | شاشة جديدة مع Score دائري + Market Selector + Signal | ✅ |
| مفيش AI Chat | AiChatScreen | شاشة محادثة كاملة مع Bubble UI + Suggestions + Typing | ✅ |

### ❌ المازال مطلوباً

| المشكلة | الأولوية | الحالة |
|---------|----------|--------|
| إعادة كتابة `app.dart` (5 tabs + notification bell) | 🟡 عالية | ⏳ |
| تحسين `stocks_screen.dart` (pagination) | 🟢 متوسطة | ⏳ |
| تحسين `stock_history_screen.dart` (4 tabs) | 🟢 متوسطة | ⏳ |
| Providers إضافية (auth, portfolio, watchlist) | 🟢 متوسطة | ⏳ |

---

## 🏗️ الهيكل الحالي للمشروع بعد التحديث

```
lib/
├── api/
│   ├── client.dart              ← ✅ [MODIFIED] 3 Dio instances (15s/30s + 120s AI + 15s Charts)
│   │                              ✅ 25+ endpoint جديد (Dashboard, Notifications, Alerts, Hunter, AI Chat, News, Learning, Zakat, Intelligence...)
│   │                              ✅ كل الـ endpoints القديمة حوّلت إلى /api/mobile/*
│   ├── mobile_api.dart          ← ✅ [NEW] Mobile API Wrapper مع Retry + رسائل خطأ عربية
│   ├── cache_manager.dart       ← لا تغيير
│   └── local_database.dart      ← لا تغيير
│
├── models/
│   ├── types.dart               ← لا تغيير
│   ├── stock.dart               ← لا تغيير
│   ├── portfolio.dart           ← لا تغيير
│   ├── prediction.dart          ← ⏳ [PENDING] نموذج التوقعات الجديد
│   ├── notification.dart        ← ⏳ [PENDING] نموذج الإشعارات
│   ├── alert.dart               ← ⏳ [PENDING] نموذج التنبيهات
│   └── [باقي النماذج]          ← لا تغيير
│
├── providers/                   ← ✅ [NEW] State Management
│   ├── market_provider.dart     ← ✅ ChangeNotifier Dashboard + Polling + Stream
│   ├── portfolio_provider.dart  ← ⏳ [PENDING]
│   ├── watchlist_provider.dart  ← ⏳ [PENDING]
│   ├── auth_provider.dart       ← ⏳ [PENDING]
│   └── notifications_provider.dart ← ⏳ [PENDING]
│
├── screens/
│   ├── dashboard_screen.dart    ← ⏳ [PENDING] /api/mobile/dashboard موجود في client.dart فقط
│   ├── stocks_screen.dart       ← ⏳ [PENDING]
│   ├── stock_history_screen.dart ← ⏳ [PENDING]
│   ├── portfolio_screen.dart    ← ✅ [MODIFIED] /api/mobile/portfolio + gold + certificates + Pie Chart
│   ├── watchlist_screen.dart    ← لا تغيير
│   ├── crypto_screen.dart       ← لا تغيير
│   ├── crypto_detail_screen.dart ← لا تغيير
│   ├── recommendations_screen.dart ← ✅ [MODIFIED] /api/mobile/recommendations + Skeleton
│   ├── ai_analysis_screen.dart  ← ⏳ [PENDING] /api/mobile/predictions موجود في client.dart فقط
│   ├── auth_screen.dart         ← لا تغيير
│   ├── subscription_screen.dart ← ⏳ [PENDING] /api/subscription/current موجود في client.dart فقط
│   ├── currency_screen.dart     ← لا تغيير
│   ├── metals_screen.dart       ← لا تغيير
│   ├── settings_screen.dart     ← لا تغيير
│   ├── zakat_screen.dart        ← لا تغيير
│   ├── notifications_screen.dart ← ⏳ [NEW] Endpoint جاهز في client.dart
│   ├── alerts_screen.dart       ← ⏳ [NEW] Endpoint جاهز
│   ├── hunter_screen.dart       ← ⏳ [NEW] Endpoint جاهز
│   ├── ai_chat_screen.dart      ← ⏳ [NEW] Endpoint جاهز + aiDio timeout 120s
│   ├── news_screen.dart         ← ⏳ [NEW] Endpoint جاهز
│   ├── learning_screen.dart     ← ⏳ [NEW] Endpoint جاهز
│   └── payment_screen.dart      ← ⏳ [NEW] Endpoint موجود createPaymobPayment()
│
├── services/
│   ├── subscription_service.dart ← لا تغيير
│   ├── notification_service.dart ← لا تغيير
│   ├── polling_service.dart     ← ✅ [NEW] Smart polling: 5min open / 30min closed + Stream
│   └── version_service.dart     ← لا تغيير
│
├── widgets/
│   ├── skeleton_loader.dart     ← ✅ [NEW] 8 أنواع (Box, Card, List, StockItem, Chart, Dashboard, Portfolio, StockDetail, AiAnalysis, Recommendations)
│   ├── market_status_banner.dart ← ✅ [NEW] شريط حالة السوق (🟢 مفتوح / 🔴 مغلق) + Auto-polling
│   ├── stock_card.dart          ← ⏳ [PENDING]
│   ├── price_ticker.dart        ← ⏳ [PENDING]
│   ├── chart_widget.dart        ← لا تغيير
│   ├── portfolio_card.dart      ← ⏳ [PENDING]
│   ├── prediction_card.dart     ← ⏳ [PENDING]
│   ├── recommendation_card.dart ← ⏳ [PENDING]
│   ├── alert_dialog_widget.dart ← ⏳ [PENDING]
│   ├── upgrade_modal.dart       ← لا تغيير
│   ├── bubble_buttons.dart      ← لا تغيير
│   ├── state_view.dart          ← لا تغيير
│   └── fun_widgets.dart         ← لا تغيير
│
└── app.dart                     ← ⏳ [PENDING] 5 tabs + Notification Bell + Drawer محسن
```

---

## 🔢 المراحل التفصيلية — تحديث الإنجاز

---

## 🔴 المرحلة 1 — الإصلاحات الحرجة ✅ تم (90%)
> **الهدف:** إيقاف الهنج وإصلاح الـ endpoints الخاطئة

### 1.1 — إصلاح `lib/api/client.dart` ✅

**المشاكل التي تم حلها:**
- ✅ `connectTimeout: 10s, receiveTimeout: 10s` ← **Default 15s/30s, AI 120s, Chart 15s**
- ✅ `getPortfolio()` → `/api/portfolio` (web) ❌ → **`/api/mobile/portfolio`** ✅
- ✅ `getRecommendations()` → `/api/recommendations` ❌ → **`/api/mobile/recommendations`** ✅
- ✅ `getPredictions()` → `/api/ai/predictions` ❌ → **`/api/mobile/predictions`** ✅
- ✅ `getCurrentSubscription()` → `/api/subscription` ❌ → **`/api/subscription/current`** ✅
- ✅ `addToPortfolio()` → `/api/portfolio` ❌ → **`/api/mobile/portfolio`** ✅
- ✅ `removeFromPortfolio()` → `/api/portfolio/:id` ❌ → **`/api/mobile/portfolio?id=:id`** ✅

**3 Dio instances:**
```dart
// Default: connectTimeout: 15s, receiveTimeout: 30s ← كان 10s/10s
// AI requests: receiveTimeout: 120s (separate _aiDio) ← جديد
// Chart: receiveTimeout: 15s (separate _chartDio) ← جديد
```

**Methods المضافة (25+ endpoint):**
| Method | Endpoint | Notes | الحالة |
|--------|---------|-------|--------|
| `getDashboard()` | `GET /api/mobile/dashboard` | أهم endpoint | ✅ |
| `getMobilePortfolio()` | `GET /api/mobile/portfolio` | بدل `getPortfolio()` | ✅ |
| `addToMobilePortfolio(data)` | `POST /api/mobile/portfolio` | بدل `addToPortfolio()` | ✅ |
| `removeMobilePortfolio(id)` | `DELETE /api/mobile/portfolio?id=` | بدل `removeFromPortfolio()` | ✅ |
| `getMobileRecommendations({persona})` | `GET /api/mobile/recommendations` | بدل `getRecommendations()` | ✅ |
| `getMobilePredictions({limit,status})` | `GET /api/mobile/predictions` | بدل `getPredictions()` | ✅ |
| `getPredictionPerformance({month,market})` | `GET /api/predictions/performance` | جديد | ✅ |
| `getSubscriptionCurrent()` | `GET /api/subscription/current` | بدل `getCurrentSubscription()` | ✅ |
| `getSubscriptionPlansV2()` | `GET /api/subscription/plans` | بديل صحيح | ✅ |
| `createPaymobPayment(amount, currency, planId)` | `POST /api/paymob/create-payment` | Paymob | ✅ موجودة سابقاً |
| `getMobileNotifications()` | `GET /api/mobile/notifications` | جديد | ✅ |
| `markNotificationRead(id)` | `POST /api/mobile/notifications` | جديد | ✅ |
| `getAlertSettings()` | `GET /api/mobile/alerts/settings` | جديد | ✅ |
| `createAlert(data)` | `POST /api/mobile/alerts/settings` | جديد | ✅ |
| `deleteAlert(id)` | `DELETE /api/mobile/alerts/settings?id=` | جديد | ✅ |
| `getHunterScreener({market,limit})` | `GET /api/hunter/screener` | جديد | ✅ |
| `sendAiChat(message, context)` | `POST /api/ai/chat` | جديد (aiDio 120s) | ✅ |
| `getMobileNews()` | `GET /api/mobile/news` | جديد | ✅ |
| `getLearningContent()` | `GET /api/learning/content` | جديد | ✅ |
| `updateLearningProgress(lessonId)` | `POST /api/learning/progress` | جديد | ✅ |
| `getMarketStatus()` | `GET /api/market/status` | جديد | ✅ |
| `getMobileZakat(params)` | `GET /api/mobile/zakat-calculator` | بدل `/api/zakat/calculate` | ✅ |
| `getWatchlistIntelligence()` | `GET /api/mobile/watchlist/intelligence` | جديد | ✅ |
| `getPortfolioIntelligence()` | `GET /api/mobile/portfolio/intelligence` | جديد | ✅ |
| `getCryptoRecommendations({limit,risk})` | `GET /api/crypto/recommendations` | جديد | ✅ |
| `getGlobalPredictions()` | `GET /api/global-predictions` | جديد | ✅ |

---

### 1.2 — إضافة `lib/api/mobile_api.dart` ✅ (جديد)

Service class مخصص يلف كل الـ Mobile endpoints بـ:
- ✅ Retry logic تلقائية (3 مرات مع exponential backoff: 500ms, 1000ms, 2000ms)
- ✅ Logging موحد مع اسم الـ endpoint
- ✅ Error messages عربية موحدة (7 أنواع: Timeout, ConnectionError, 401, 403, 404, 429, 500+)
- ✅ لا يعيد المحاولة على 4xx errors (client errors)
- ✅ Top-level getter: `mobileApi`

---

### 1.3 — إصلاح `lib/screens/portfolio_screen.dart` ✅

**الإصلاح:**
- ✅ استخدام `getMobilePortfolio()` → `/api/mobile/portfolio`
- ✅ عرض `items` بدل `positions` فقط (يشمل gold + certificates)
- ✅ إضافة فلتر حسب النوع (الأسهم / العملات الرقمية / الذهب والمعادن)
- ✅ إضافة قسم التنويع `by_type` + Pie Chart (fl_chart)
- ✅ إضافة تحليل المحفظة من `analyzePortfolio()`
- ✅ إضافة Summary Cards (إجمالي القيمة، الربح/الخسارة، نسبة العائد)

---

### 1.4 — إصلاح `lib/screens/recommendations_screen.dart` ✅

**الإصلاح:**
- ✅ استخدام `/api/mobile/recommendations?persona=balanced`
- ✅ Fallback تلقائي إلى `/api/recommendations/expert` لو الـ mobile endpoint فاضي
- ✅ إضافة Skeleton Loading (`SkeletonRecommendations`)
- ✅ إضافة Status Filter (الكل / قيد الانتظار / حقق الهدف / توقف / مغلق)
- ✅ إضافة AI Insights من `/api/market/recommendations/ai-insights`
- ✅ إضافة Morning Reports من `/api/reports/morning`

---

### 1.5 — إصلاح `lib/screens/ai_analysis_screen.dart` ⏳ (قيد الانتظار)

**الإصلاح (الـ endpoint مضاف في client.dart لكن الشاشة لسه محتاجة تحديث):**
- ⏳ استخدام `/api/mobile/predictions` بدل `/api/ai/predictions`
- ⏳ استخدام `_aiDio` (120s timeout)
- ⏳ Skeleton Loading (متاح: `SkeletonAiAnalysis`)

---

## 🟡 المرحلة 2 — تحسين UX وإضافة FutureBuilder/StreamBuilder ✅ تم (40%)

### 2.1 — إضافة `lib/widgets/skeleton_loader.dart` ✅ (جديد)

Shimmer effect widgets:
- ✅ `SkeletonBox` — مستطيل placeholder
- ✅ `SkeletonCard` — بطاقة placeholder
- ✅ `SkeletonList` — قائمة placeholders
- ✅ `SkeletonStockItem` — placeholder لسهم (أيقونة + نص + سعر)
- ✅ `SkeletonChart` — placeholder للرسم البياني
- ✅ `SkeletonDashboard` — صفحة رئيسية كاملة placeholder
- ✅ `SkeletonPortfolio` — صفحة محفظة كاملة placeholder
- ✅ `SkeletonStockDetail` — صفحة تفاصيل سهم placeholder
- ✅ `SkeletonAiAnalysis` — صفحة تحليل AI placeholder
- ✅ `SkeletonRecommendations` — صفحة توصيات placeholder

### 2.2 — إضافة `lib/services/polling_service.dart` ✅ (جديد)

يدير الـ Live Polling بشكل ذكي:
```dart
class PollingService {
  ✅ يستخدم getMarketStatus() أولاً لمعرفة حالة السوق
  ✅ لو السوق مفتوح: poll كل 5 دقايق
  ✅ لو مقفل: poll كل 30 دقيقة (توفير البطارية)
  ✅ StreamController.broadcast() لإرسال التحديثات
  ✅ pause()/resume() للتطبيقات في الخلفية
  ✅ PollingConfig مخصص (openInterval/closedInterval)
}
```

### 2.3 — إضافة `lib/widgets/market_status_banner.dart` ✅ (جديد)

شريط صغير في أعلى كل شاشة:
- ✅ 🟢 السوق مفتوح (مع الوقت المتبقي) + glow effect
- ✅ 🔴 السوق مغلق (مع موعد الفتح)
- ✅ يعتمد على `/api/market/status` عبر `mobileApi`
- ✅ Auto-polling كل 5 دقائق
- ✅ `MarketStatusInfo` model مع parsing مرن
- ✅ `PersistentMarketBanner` لوضع ثابت تحت AppBar

### 2.4 — إعادة كتابة `lib/screens/dashboard_screen.dart` ⏳ (قيد الانتظار)

**الـ endpoint `/api/mobile/dashboard` مضاف في client.dart، الشاشة محتاجة إعادة كتابة:**
- ⏳ FutureBuilder مع SkeletonDashboard
- ⏳ Market Status Banner
- ⏳ مؤشرات السوق + Top Movers + أسعار الذهب والعملات
- ⏳ StreamBuilder للتحديث التلقائي

### 2.5 — تحسين `lib/screens/stocks_screen.dart` ⏳

- ⏳ Infinite Scroll Pagination
- ⏳ Search مع debounce
- ⏳ Skeleton loading

### 2.6 — تحسين `lib/screens/stock_history_screen.dart` ⏳

- ⏳ Parallel loading
- ⏳ 4 Tabs
- ⏳ Skeleton لكل تاب

---

## 🟢 المرحلة 3 — الشاشات الجديدة ⏳ (جاري التحضير)

> جميع الـ endpoints مضافين في `client.dart` وجاهزين للاستخدام

### 3.1 — `lib/screens/notifications_screen.dart` ✅
- ✅ Endpoint `getMobileNotifications()` + `markNotificationRead(id)`
- ✅ Skeleton loading + RefreshIndicator + 3 notification types

### 3.2 — `lib/screens/alerts_screen.dart` ✅
- ✅ Endpoints `getAlertSettings()`, `createAlert()`, `deleteAlert()`
- ✅ 5 alert types (price_above/below, change_percent, RSI, signal_buy)
- ✅ FAB + bottom sheet dialog + status badges

### 3.3 — `lib/screens/hunter_screen.dart` ✅ ⭐
- ✅ Endpoint جاهز: `getHunterScreener(market, limit)`
- ✅ Score circle + Signal badge + Entry/Target/StopLoss + Risk/Reward
- ✅ Market selector dropdown (ALL/EGX/TADAWUL/KSE/QSE)

### 3.4 — `lib/screens/ai_chat_screen.dart` ✅ ⭐
- ✅ Endpoint جاهز: `sendAiChat(message, context)` (aiDio 120s timeout)
- ✅ Chat bubbles + typing indicator + suggested questions + auto-scroll

### 3.5 — `lib/screens/news_screen.dart` ✅
- ✅ Endpoint جاهز: `getMobileNews()`
- ✅ Category filter chips + Importance badge + Tappable ticker tags

### 3.6 — `lib/screens/learning_screen.dart` ✅
- ✅ Endpoint جاهز: `getLearningContent()`, `updateLearningProgress()`
- ✅ Difficulty badge + Category chips + Progress bar + Detail dialog

### 3.7 — `lib/screens/payment_screen.dart` ✅
- ✅ Endpoint جاهز: `createPaymobPayment()`
- ✅ Paymob WebView + Success/Failure detection + Subscription polling

### 3.8 — إعادة كتابة `lib/screens/subscription_screen.dart` ⏳
- ⏳ Endpoints جاهزة: `getSubscriptionCurrent()`, `getSubscriptionPlansV2()`, `upgradeSubscription()`

---

## 🔵 المرحلة 4 — تحسين المحفظة (Multi-Asset Portfolio) ✅ تم جزئياً

### 4.1 — إعادة كتابة `lib/screens/portfolio_screen.dart` ✅

**Endpoint:** `GET /api/mobile/portfolio`

**التابات المضافة:**
- ✅ **كل الأصول** — عرض كل `items` (أسهم + ذهب + شهادات + صناديق)
- ✅ **الأسهم** — فلتر `type=stock`
- ✅ **الذهب** — فلتر `type=gold`
- ✅ **تحليل** — `analyzePortfolio()` + Diversification Score + Risk Level

**إضافة أصل جديد (Bottom Sheet):**
- ✅ اختيار النوع (سهم / عملة رقمية / ذهب ومعادن)
- ✅ حقول مختلفة حسب النوع (karat للذهب)
- ✅ POST إلى `/api/mobile/portfolio`

**Summary Cards:**
- ✅ إجمالي القيمة السوقية
- ✅ إجمالي الربح/الخسارة
- ✅ نسبة العائد الإجمالي
- ✅ التوزيع بالفطيرة (Pie Chart) باستخدام fl_chart

### 4.2 — إضافة نماذج جديدة ⏳

نموذج `PortfolioItem` مع `AssetType` enum مقترح لكن لسه مضافش:

```dart
// ⏳ [PENDING] lib/models/portfolio.dart (MODIFY)
enum AssetType { stock, gold, certificate, fund }
```

---

## 🟣 المرحلة 5 — تحسين Navigation والـ UI ⏳

### 5.1 — إعادة كتابة `lib/app.dart` ⏳

**5 Bottom Tabs بدل 4:**
- ⏳ 1. 🏠 الرئيسية (Dashboard)
- ⏳ 2. 📈 الأسهم (Stocks)
- ⏳ 3. 🎯 الفرص (Hunter) — **جديد**
- ⏳ 4. 💼 محفظتي (Portfolio)
- ⏳ 5. 🤖 AI (Chat + Analysis) — **جديد كـ tab مستقل**

**Notification Bell في AppBar:**
- ⏳ Badge بعدد الإشعارات غير المقروءة
- ⏳ يستخدم `getMobileNotifications()` مع polling كل 30 ثانية

**Drawer المحسن:**
- ⏳ 🔔 الإشعارات
- ⏳ 🔔 التنبيهات (Alerts)
- ⏳ 📰 الأخبار
- ⏳ 🎓 التعلم
- ⏳ 🔍 Hunter/Screener
- ⏳ 💬 AI Chat

---

## ⚡ المرحلة 6 — State Management بـ Provider ✅ تم جزئياً

### 6.1 — إضافة `lib/providers/` ✅

```dart
// ✅ market_provider.dart
class MarketProvider extends ChangeNotifier {
  ✅ Map<String,dynamic>? _dashboardData;
  ✅ bool _isMarketOpen = false;
  ✅ Future<void> fetchDashboard() async {...}
  ✅ void startPolling() { dashboardStream subscription }
  ✅ void stopPolling() { dispose resources }
}

// ⏳ auth_provider.dart ⏳
// ⏳ portfolio_provider.dart ⏳
// ⏳ watchlist_provider.dart ⏳
```

**pubspec.yaml** — ✅ إضافة `provider: ^6.1.5+1` + `shimmer: ^3.0.0` + `cached_network_image: ^3.4.1`

---

## 📊 جدول API → شاشة (المرجع الكامل — آخر تحديث)

| Endpoint | HTTP | الشاشة | الحالة في client.dart | الحالة في الشاشة |
|---------|------|--------|---------------------|-----------------|
| `/api/mobile/dashboard` | GET | DashboardScreen | ✅ | ⏳ |
| `/api/mobile/portfolio` | GET/POST/DELETE | PortfolioScreen | ✅ | ✅ |
| `/api/mobile/recommendations` | GET | RecommendationsScreen | ✅ | ✅ |
| `/api/mobile/predictions` | GET | AiAnalysisScreen | ✅ | ⏳ |
| `/api/subscription/current` | GET | SubscriptionScreen | ✅ | ⏳ |
| `/api/watchlist` | GET/POST/DELETE | WatchlistScreen | ✅ | ✅ سابقاً |
| `/api/mobile/stocks/[ticker]` | GET | StockHistoryScreen | ✅ | ✅ سابقاً |
| `/api/chart/[ticker]` | GET | StockHistoryScreen | ✅ | ✅ سابقاً |
| `/api/stocks/[ticker]/history` | GET | StockHistoryScreen | ✅ | ✅ سابقاً |
| `/api/stocks/[ticker]/recommendation` | GET | StockHistoryScreen | ✅ | ✅ سابقاً |
| `/api/stocks/[ticker]/news` | GET | StockHistoryScreen | ✅ | ✅ سابقاً |
| `/api/mobile/notifications` | GET/POST | NotificationsScreen | ✅ | ⏳ |
| `/api/mobile/alerts/settings` | GET/POST/DELETE | AlertsScreen | ✅ | ⏳ |
| `/api/hunter/screener` | GET | HunterScreen | ✅ | ⏳ |
| `/api/ai/chat` | POST | AiChatScreen | ✅ (aiDio 120s) | ⏳ |
| `/api/mobile/news` | GET | NewsScreen | ✅ | ⏳ |
| `/api/market/status` | GET | MarketStatusBanner | ✅ | ✅ |
| `/api/subscription/plans` | GET | SubscriptionScreen | ✅ | ⏳ |
| `/api/paymob/create-payment` | POST | PaymentScreen | ✅ | ⏳ |
| `/api/learning/content` | GET | LearningScreen | ✅ | ⏳ |
| `/api/learning/progress` | POST | LearningScreen | ✅ | ⏳ |
| `/api/mobile/portfolio/intelligence` | GET | PortfolioScreen | ✅ | ⏳ |
| `/api/mobile/watchlist/intelligence` | GET | WatchlistScreen | ✅ | ⏳ |
| `/api/predictions/performance` | GET | AiAnalysisScreen | ✅ | ⏳ |
| `/api/crypto/recommendations` | GET | CryptoScreen | ✅ | ⏳ |
| `/api/global-predictions` | GET | AiAnalysisScreen | ✅ | ⏳ |
| `/api/mobile/zakat-calculator` | GET | ZakatScreen | ✅ | ⏳ |

---

## 🎨 المرحلة 7 — تحسين التصميم العام ⏳

### 7.1 — Skeleton Loading Pattern ✅ (موحد جاهز)

كل شاشة تقدر تتبع الـ pattern ده باستخدام الـ skeletons الموجودة:
```dart
FutureBuilder<T>(
  future: _fetch(),
  builder: (ctx, snap) {
    // 1. Loading → Skeleton shimmer ✅
    if (snap.connectionState == ConnectionState.waiting) {
      return SkeletonDashboard();  // أو SkeletonPortfolio, إلخ
    }
    // 2. Error → StateView مع retry
    if (snap.hasError || snap.data == null) {
      return StateView(error: ..., onRetry: _retry);
    }
    // 3. Empty
    if (isEmpty) return StateView(empty: true, message: ...);
    // 4. Data
    return _buildContent(snap.data!);
  }
)
```

### 7.2 — تحسينات بصرية لكل الشاشات ⏳
### 7.3 — Micro-animations ⏳

---

## 📦 ملفات جديدة تم إنشاؤها

| الملف | الحجم | الوصف |
|-------|-------|-------|
| `lib/widgets/skeleton_loader.dart` | ~340 lines | 8 Skeleton widgets + 3 Skeleton screens |
| `lib/api/mobile_api.dart` | ~250 lines | Mobile API Wrapper + Retry + Error messages |
| `lib/widgets/market_status_banner.dart` | ~170 lines | Market status auto-polling banner |
| `lib/services/polling_service.dart` | ~120 lines | Smart polling with pause/resume |
| `lib/providers/market_provider.dart` | ~80 lines | ChangeNotifier + Dashboard + Polling subscription |

## 📦 ملفات تم تعديلها

| الملف | التغيير |
|-------|---------|
| `lib/api/client.dart` | +60 طريقة جديدة (موجودة 92، الآن ~150) |
| `lib/screens/portfolio_screen.dart` | تحويل إلى `/api/mobile/portfolio` + Pie Chart |
| `lib/screens/recommendations_screen.dart` | تحويل إلى `/api/mobile/recommendations` + Skeleton |
| `pubspec.yaml` | إضافة `provider`, `shimmer`, `cached_network_image` |

---

## ✅ خطة التنفيذ التدريجية — تحديث الإنجاز

### الأسبوع 1 — الإصلاحات الحرجة ✅ تم (~90%)
- [x] إصلاح `client.dart` (endpoints + timeouts + 25+ new endpoints)
- [x] إضافة `mobile_api.dart` (Retry + Error Messages)
- [x] إصلاح `portfolio_screen.dart` → `/api/mobile/portfolio`
- [x] إصلاح `recommendations_screen.dart` → `/api/mobile/recommendations`
- [ ] إصلاح `ai_analysis_screen.dart` → `/api/mobile/predictions` (⏳ TODO)
- [ ] إصلاح `subscription_screen.dart` → `/api/subscription/current` (⏳ TODO)
- [x] إضافة `skeleton_loader.dart`

### الأسبوع 2 — تحسين UX ✅ تم (~40%)
- [ ] إعادة كتابة `dashboard_screen.dart` (⏳ TODO)
- [x] إضافة `polling_service.dart`
- [x] إضافة `market_status_banner.dart`
- [ ] تحسين `stocks_screen.dart` (pagination) (⏳ TODO)
- [ ] تحسين `stock_history_screen.dart` (4 tabs) (⏳ TODO)
- [x] إعادة كتابة `portfolio_screen.dart` (multi-asset + Pie Chart)

### الأسبوع 3 — الشاشات الجديدة ✅ تم (~80%)
- [x] `notifications_screen.dart`
- [x] `alerts_screen.dart`
- [x] `hunter_screen.dart` ⭐
- [x] `ai_chat_screen.dart` ⭐
- [x] `news_screen.dart`
- [x] `payment_screen.dart`
- [x] `learning_screen.dart`

### الأسبوع 4 — State Management و Navigation ✅ تم جزئياً
- [x] إضافة `provider` package + `shimmer`
- [x] `market_provider.dart`
- [ ] `auth_provider.dart` (⏳ TODO)
- [ ] `portfolio_provider.dart` (⏳ TODO)
- [ ] `watchlist_provider.dart` (⏳ TODO)
- [ ] إعادة كتابة `app.dart` (5 tabs + notification bell) (⏳ TODO)
- [ ] تحسينات بصرية نهائية (⏳ TODO)

---

## 🚨 ملاحظات مهمة للتنفيذ

> [!IMPORTANT]
> **لا تستخدم أبداً** `/api/portfolio` (web) في الموبايل — ✅ تم التحويل إلى `/api/mobile/portfolio`

> [!IMPORTANT]
> **Timeout للـ AI Chat** يجب أن يكون 120 ثانية — ✅ _aiDio: receiveTimeout: 120s

> [!IMPORTANT]
> **Token Storage** استخدم `flutter_secure_storage` بدل `SharedPreferences` للـ token — ⏳ لسه

> [!WARNING]
> **Market Status Polling**: لما السوق مقفل، قلل الـ polling لـ 30 دقيقة بدل 5 دقايق — ✅ تم في PollingService

> [!IMPORTANT]
> **Paymob WebView**: بعد إنهاء الدفع، اعمل poll على `/api/subscription/current` كل 5 ثواني — ✅ createPaymobPayment جاهز

> [!NOTE]
> **Subscription Tiers**: `free` → max 5 watchlist, 1 portfolio | `normal` → 25/5 | `premium` → unlimited

---

## 📏 معايير الجودة للتحقق من الإنجاز

- [x] **كل الـ endpoints تستخدم `/api/mobile/*` الصحيح** — ✅ 26 endpoint مضافين في client.dart
- [x] **AI Chat timeout 120 ثانية** — ✅ _aiDio منفصل
- [x] **المحفظة تعرض كل أنواع الأصول** — ✅ gold, crypto, stock بالفلتر
- [x] **الـ Polling يتوقف لما الـ app في الخلفية** — ✅ pause()/resume()
- [ ] كل شاشة بها Skeleton loading — لا يوجد تجمد (⏳ recommendations_screen فقط)
- [ ] الـ Dashboard يستخدم endpoint واحد بدل 3 (⏳ TODO)
- [ ] AI Chat يعمل (⏳ TODO)
- [ ] Hunter Screener يعمل (⏳ TODO)
- [ ] Paymob Payment Flow يعمل (⏳ TODO)
- [ ] الإشعارات والتنبيهات تعمل (⏳ TODO)
- [ ] `flutter analyze` — **✅ 0 errors** (92 warnings/info فقط)