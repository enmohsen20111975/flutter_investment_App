# 📱 خطة إصلاح وتطوير شاملة — تطبيق دليل الاستثمار
## Flutter Mobile App — Complete Overhaul Plan

> **الهدف:** تحويل التطبيق إلى تجربة احترافية سلسة، كاملة الأداء، بدون هنج أو توقف،
> مع إضافة كل الميزات الموجودة في الويب ودمج كل الـ APIs الجديدة من API_HANDBOOK.md

---

## 📋 ملخص الوضع الحالي

### المشاكل الموجودة الآن
| المشكلة | الشاشة | السبب |
|---------|---------|-------|
| التطبيق بيهنج ويتوقف | كل الشاشات | البيانات بتتحمل sync بدون FutureBuilder صحيح |
| `getPortfolio()` بيستخدم `/api/portfolio` (web only) | PortfolioScreen | لازم يستخدم `/api/mobile/portfolio` |
| `getRecommendations()` بيستخدم `/api/recommendations` خاطئ | RecommendationsScreen | لازم `/api/mobile/recommendations` |
| `getPredictions()` بيستخدم `/api/ai/predictions` خاطئ | AiAnalysisScreen | لازم `/api/mobile/predictions` |
| `getCurrentSubscription()` بيستخدم `/api/subscription` ناقص | SubscriptionScreen | لازم `/api/subscription/current` |
| `getDashboard()` مش موجود | DashboardScreen | لازم يضيف `/api/mobile/dashboard` |
| الـ Dio timeout 10 ثانية بس | client.dart | AI requests بتاخد 60 ثانية |
| مفيش Skeleton Loading | كل الشاشات | الشاشة بتظهر فاضية أثناء التحميل |
| مفيش Live Polling | DashboardScreen | الأسعار مش بتتحدث |
| مفيش شاشة Notifications | app.dart | مفيش endpoint استخدام |
| مفيش شاشة Alerts | المشروع كله | `/api/mobile/alerts/settings` مش محتسبه |
| مفيش AI Chat | المشروع كله | `/api/ai/chat` مش موجود |
| مفيش Hunter/Screener | المشروع كله | `/api/hunter/screener` مش محتسبه |
| مفيش Payment Flow | المشروع كله | Paymob integration ناقصة |
| مفيش Learning Screen جديدة | المشروع كله | `/api/learning/content` مش محتسبه |
| مفيش Market Status Banner | كل الشاشات | `/api/market/status` مش مستخدمه |

---

## 🏗️ الهيكل المقترح للمشروع الجديد

```
lib/
├── api/
│   ├── client.dart              ← [MODIFY] إصلاح كل الـ endpoints + timeout أطول
│   ├── mobile_api.dart          ← [NEW] Mobile-specific API wrapper
│   ├── cache_manager.dart       ← [MODIFY] تحسين TTL و invalidation
│   └── local_database.dart      ← لا تغيير
│
├── models/
│   ├── types.dart               ← [MODIFY] re-export كل النماذج
│   ├── stock.dart               ← [MODIFY] إضافة حقول ناقصة
│   ├── portfolio.dart           ← [MODIFY] دعم gold + certificates
│   ├── prediction.dart          ← [NEW] نموذج التوقعات الجديد
│   ├── notification.dart        ← [NEW] نموذج الإشعارات
│   ├── alert.dart               ← [NEW] نموذج التنبيهات
│   └── [باقي النماذج]          ← لا تغيير
│
├── providers/                   ← [NEW] State Management
│   ├── market_provider.dart     ← ChangeNotifier للسوق
│   ├── portfolio_provider.dart  ← ChangeNotifier للمحفظة
│   ├── watchlist_provider.dart  ← ChangeNotifier لقائمة المراقبة
│   ├── auth_provider.dart       ← ChangeNotifier للمصادقة
│   └── notifications_provider.dart ← ChangeNotifier للإشعارات
│
├── screens/
│   ├── dashboard_screen.dart    ← [REWRITE] /api/mobile/dashboard
│   ├── stocks_screen.dart       ← [IMPROVE] Pagination + better UX
│   ├── stock_history_screen.dart ← [IMPROVE] FutureBuilder محسن
│   ├── portfolio_screen.dart    ← [REWRITE] /api/mobile/portfolio (+ gold + certs)
│   ├── watchlist_screen.dart    ← [IMPROVE] Real-time updates
│   ├── crypto_screen.dart       ← [REWRITE] /api/mobile/crypto محسن
│   ├── crypto_detail_screen.dart ← [IMPROVE] بيانات أكثر
│   ├── recommendations_screen.dart ← [REWRITE] /api/mobile/recommendations
│   ├── ai_analysis_screen.dart  ← [REWRITE] /api/mobile/predictions + AI chat
│   ├── auth_screen.dart         ← [IMPROVE] تحسين UX
│   ├── subscription_screen.dart ← [REWRITE] /api/subscription/current + Paymob
│   ├── currency_screen.dart     ← [IMPROVE] /api/mobile/currency
│   ├── metals_screen.dart       ← [IMPROVE] /api/mobile/gold
│   ├── settings_screen.dart     ← [IMPROVE] تحسين UX
│   ├── zakat_screen.dart        ← [IMPROVE] /api/mobile/zakat-calculator
│   ├── notifications_screen.dart ← [NEW] /api/mobile/notifications
│   ├── alerts_screen.dart       ← [NEW] /api/mobile/alerts/settings
│   ├── hunter_screen.dart       ← [NEW] /api/hunter/screener
│   ├── ai_chat_screen.dart      ← [NEW] /api/ai/chat
│   ├── news_screen.dart         ← [NEW] /api/mobile/news
│   ├── learning_screen.dart     ← [NEW] /api/learning/content (تحل محل LearningBacktestScreen)
│   └── payment_screen.dart      ← [NEW] Paymob WebView integration
│
├── services/
│   ├── subscription_service.dart ← [MODIFY] استخدام /api/subscription/current
│   ├── notification_service.dart ← [MODIFY] FCM + local polling
│   ├── polling_service.dart     ← [NEW] Live prices + market status polling
│   └── version_service.dart     ← لا تغيير
│
├── widgets/
│   ├── skeleton_loader.dart     ← [NEW] Shimmer loading placeholders
│   ├── market_status_banner.dart ← [NEW] شريط حالة السوق
│   ├── stock_card.dart          ← [NEW] بطاقة سهم موحدة
│   ├── price_ticker.dart        ← [NEW] عرض السعر مع animation
│   ├── chart_widget.dart        ← [MODIFY] تحسين TradingView chart
│   ├── portfolio_card.dart      ← [NEW] بطاقة أصول المحفظة
│   ├── prediction_card.dart     ← [NEW] بطاقة توقع
│   ├── recommendation_card.dart ← [NEW] بطاقة توصية
│   ├── alert_dialog_widget.dart ← [NEW] نافذة إنشاء تنبيه
│   ├── upgrade_modal.dart       ← [MODIFY] تحسين تصميم
│   ├── bubble_buttons.dart      ← لا تغيير
│   ├── state_view.dart          ← [MODIFY] إضافة Skeleton states
│   └── fun_widgets.dart         ← [MODIFY] تحسينات
│
└── app.dart                     ← [REWRITE] Navigation محسن + 5 tabs
```

---

## 🔢 المراحل التفصيلية

---

## 🔴 المرحلة 1 — الإصلاحات الحرجة (Priority: CRITICAL)
> **الهدف:** إيقاف الهنج وإصلاح الـ endpoints الخاطئة

### 1.1 — إصلاح `lib/api/client.dart`

**المشاكل الحالية:**
- `connectTimeout: 10s, receiveTimeout: 10s` — بيسبب timeout للـ AI requests
- `getPortfolio()` → `/api/portfolio` (web) ❌ → يجب `/api/mobile/portfolio` ✅
- `getRecommendations()` → `/api/recommendations` ❌ → يجب `/api/mobile/recommendations` ✅
- `getPredictions()` → `/api/ai/predictions` ❌ → يجب `/api/mobile/predictions` ✅
- `getCurrentSubscription()` → `/api/subscription` ❌ → يجب `/api/subscription/current` ✅
- `addToPortfolio()` → `/api/portfolio` ❌ → يجب `/api/mobile/portfolio` ✅
- `removeFromPortfolio()` → `/api/portfolio/:id` ❌ → يجب `/api/mobile/portfolio?id=:id` ✅

**الإصلاحات:**
```dart
// Timeouts by type:
// Default: connectTimeout: 15s, receiveTimeout: 30s
// AI requests: receiveTimeout: 120s (separate Dio instance)
// Chart: receiveTimeout: 15s
```

**Methods جديدة تضاف:**
| Method | Endpoint | Notes |
|--------|---------|-------|
| `getDashboard()` | `GET /api/mobile/dashboard` | أهم endpoint |
| `getMobilePortfolio()` | `GET /api/mobile/portfolio` | بدل `getPortfolio()` |
| `addToMobilePortfolio(data)` | `POST /api/mobile/portfolio` | بدل `addToPortfolio()` |
| `removeMobilePortfolio(id)` | `DELETE /api/mobile/portfolio?id=` | بدل `removeFromPortfolio()` |
| `getMobileRecommendations({persona})` | `GET /api/mobile/recommendations` | بدل `getRecommendations()` |
| `getMobilePredictions({limit,status})` | `GET /api/mobile/predictions` | بدل `getPredictions()` |
| `getPredictionPerformance({month,market})` | `GET /api/predictions/performance` | جديد |
| `getSubscriptionCurrent()` | `GET /api/subscription/current` | بدل `getCurrentSubscription()` |
| `getSubscriptionPlansV2()` | `GET /api/subscription/plans` | بديل صحيح |
| `createPayment(planId, period)` | `POST /api/paymob/create-payment` | جديد |
| `getMobileNotifications()` | `GET /api/mobile/notifications` | جديد |
| `markNotificationRead(id)` | `POST /api/mobile/notifications` | جديد |
| `getAlertSettings()` | `GET /api/mobile/alerts/settings` | جديد |
| `createAlert(data)` | `POST /api/mobile/alerts/settings` | جديد |
| `deleteAlert(id)` | `DELETE /api/mobile/alerts/settings?id=` | جديد |
| `getHunterScreener({market,limit})` | `GET /api/hunter/screener` | جديد |
| `sendAiChat(message, context)` | `POST /api/ai/chat` | جديد |
| `getMobileNews()` | `GET /api/mobile/news` | جديد |
| `getLearningContent()` | `GET /api/learning/content` | جديد |
| `updateLearningProgress(lessonId)` | `POST /api/learning/progress` | جديد |
| `getMarketStatus()` | `GET /api/market/status` | جديد |
| `getMobileZakat(params)` | `GET /api/mobile/zakat-calculator` | بدل `/api/zakat/calculate` |
| `getWatchlistIntelligence()` | `GET /api/mobile/watchlist/intelligence` | جديد |
| `getPortfolioIntelligence()` | `GET /api/mobile/portfolio/intelligence` | جديد |
| `getCryptoRecommendations({limit,risk})` | `GET /api/crypto/recommendations` | جديد |
| `getGlobalPredictions()` | `GET /api/global-predictions` | جديد |

---

### 1.2 — إضافة `lib/api/mobile_api.dart` (جديد)

Service class مخصص يلف كل الـ Mobile endpoints بـ:
- Retry logic تلقائية (3 مرات مع exponential backoff)
- Logging موحد
- Error messages عربية موحدة
- Cache integration

---

### 1.3 — إصلاح `lib/screens/portfolio_screen.dart`

**الحالة الحالية:** بيستخدم `getPortfolio()` الذي يستدعي `/api/portfolio` (web-only session-based)

**الإصلاح:**
- استخدام `getMobilePortfolio()` → `/api/mobile/portfolio`
- عرض `items` بدل `positions` فقط (يشمل gold + certificates)
- FutureBuilder صح مع Skeleton loading
- إضافة قسم التنويع `by_type`

---

### 1.4 — إصلاح `lib/screens/recommendations_screen.dart`

**الإصلاح:**
- استخدام `/api/mobile/recommendations?persona=balanced`
- إضافة Persona selector (محافظ/متوازن/مغامر)
- FutureBuilder مع error handling

---

### 1.5 — إصلاح `lib/screens/ai_analysis_screen.dart`

**الإصلاح:**
- استخدام `/api/mobile/predictions` بدل `/api/ai/predictions`
- Timeout 120 ثانية للـ AI requests
- Loading indicator مناسب

---

## 🟡 المرحلة 2 — تحسين UX وإضافة FutureBuilder/StreamBuilder
> **الهدف:** القضاء على الهنج وإضافة Skeleton Loading لكل الشاشات

### 2.1 — إضافة `lib/widgets/skeleton_loader.dart` (جديد)

Shimmer effect widgets:
- `SkeletonBox` — مستطيل placeholder
- `SkeletonCard` — بطاقة placeholder
- `SkeletonList` — قائمة placeholders
- `SkeletonStockItem` — placeholder لسهم
- `SkeletonChart` — placeholder للرسم البياني

### 2.2 — إضافة `lib/services/polling_service.dart` (جديد)

يدير الـ Live Polling بشكل ذكي:
```dart
class PollingService {
  // يتحقق من حالة السوق أولاً
  // لو السوق مفتوح: poll كل 5 دقايق
  // لو مقفل: poll كل 30 دقيقة
  // StreamController.broadcast() لإرسال التحديثات
  Stream<Map<String,dynamic>> get dashboardStream;
  void startPolling();
  void stopPolling();
}
```

### 2.3 — إضافة `lib/widgets/market_status_banner.dart` (جديد)

شريط صغير في أعلى كل شاشة:
- 🟢 السوق مفتوح (مع الوقت المتبقي)
- 🔴 السوق مغلق (مع موعد الفتح)
- يعتمد على `/api/market/status`

### 2.4 — إعادة كتابة `lib/screens/dashboard_screen.dart`

**استخدام `/api/mobile/dashboard` بدل 3 calls منفصلة:**
```dart
// الكود الجديد:
FutureBuilder<Map<String,dynamic>>(
  future: api.getDashboard(),
  builder: (ctx, snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return SkeletonDashboard();  // Shimmer
    }
    // عرض البيانات
  }
)
```

**الأقسام الجديدة في Dashboard:**
1. Market Status Banner (مفتوح/مغلق)
2. مؤشرات السوق (EGX 30/70/100)
3. ملخص السوق (ارتفاعات/انخفاضات)
4. Top Movers (Gainers/Losers/Most Active) — بـ TabBar
5. أسعار الذهب (من gold_prices)
6. أسعار العملات (من currency_rates)
7. StreamBuilder للتحديث التلقائي

### 2.5 — تحسين `lib/screens/stocks_screen.dart`

- Infinite Scroll Pagination (page=1, limit=50, ثم التالي)
- Search مع debounce 300ms
- Skeleton loading أثناء البحث
- Stock Card موحدة جميلة
- مؤشرات RSI / توصية على كل بطاقة

### 2.6 — تحسين `lib/screens/stock_history_screen.dart`

- Parallel loading: detail + history + recommendation
- 4 Tabs: البيانات / التوصية / التحليل / الأخبار
- Chart Controls (1D/1W/1M/3M)
- Skeleton لكل تاب

---

## 🟢 المرحلة 3 — الشاشات الجديدة
> **الهدف:** إضافة الميزات الموجودة في الويب لكن ناقصة في الموبايل

### 3.1 — `lib/screens/notifications_screen.dart` (جديد)

**Endpoint:** `GET /api/mobile/notifications`
- قائمة الإشعارات مع `unread_count` badge
- Mark as read بالضغط
- أنواع: price_alert / signal / system
- Pull to refresh

### 3.2 — `lib/screens/alerts_screen.dart` (جديد)

**Endpoints:** `GET/POST/DELETE /api/mobile/alerts/settings`
- قائمة التنبيهات الحالية
- إنشاء تنبيه جديد (bottom sheet):
  - نوع: price_above / price_below / change_percent_up / rsi_overbought / signal_buy ...
  - اختيار السهم
  - القيمة المستهدفة
- حذف تنبيه
- عرض التنبيهات المحققة (recent_alerts)

### 3.3 — `lib/screens/hunter_screen.dart` (جديد) ⭐

**Endpoint:** `GET /api/hunter/screener?market=EGX&limit=10`

الـ "Hunter" هي أقوى ميزة — بيحدد أفضل الفرص تلقائياً:
- قائمة بأفضل 10 فرص
- Score + Signals لكل سهم
- Target Price + Stop Loss
- Risk/Reward Ratio
- تصفية بالسوق (EGX/TADAWUL/KSE/QSE/ALL)
- لوحة جميلة بألوان حسب الدرجة (90+ ذهبي، 80+ أخضر، إلخ)

### 3.4 — `lib/screens/ai_chat_screen.dart` (جديد) ⭐

**Endpoint:** `POST /api/ai/chat`

شاشة محادثة كاملة مع AI:
- Chat bubble UI
- Loading indicator خاص بـ AI (مع قياس DeepSeek V3 vs R1)
- Context-aware (بيبعت معلومات الشاشة الحالية)
- Memory support (محادثات متعددة)
- اقتراحات أسئلة شائعة
- Typing indicator
- عرض reasoning (لو R1)

### 3.5 — `lib/screens/news_screen.dart` (جديد)

**Endpoint:** `GET /api/mobile/news`
- تصنيف: كل الأخبار / بورصة / كريبتو / مؤشرات
- بطاقة خبر جميلة مع تاريخ ومصدر
- Importance badge (مهم/متوسط/عادي)
- Pull to refresh
- Ticker linking (اضغط على اسم سهم → شاشة السهم)

### 3.6 — `lib/screens/learning_screen.dart` (جديد - يحل محل LearningBacktestScreen)

**Endpoint:** `GET /api/learning/content` + `POST /api/learning/progress`
- فئات: أساسيات / تحليل فني / تحليل أساسي / إدارة محفظة / كريبتو
- Progress bar لكل فئة
- شاشة درس مع محتوى نصي جميل
- Completion tracking
- مستوى الصعوبة badge

### 3.7 — `lib/screens/payment_screen.dart` (جديد)

**Endpoint:** `POST /api/paymob/create-payment` → WebView
- مراحل الدفع:
  1. عرض الخطة المختارة
  2. POST → الحصول على `payment_url`
  3. WebView للـ Paymob
  4. Polling على `/api/subscription/current` كل 5 ثواني
  5. Success/Failure screen
- دعم Monthly/Yearly billing
- عرض السعر بالجنيه المصري

### 3.8 — إعادة كتابة `lib/screens/subscription_screen.dart`

- `/api/subscription/plans` — عرض الخطط
- `/api/subscription/current` — الاشتراك الحالي
- `/api/subscription/start-trial` — بدء تجربة
- زر الترقية → `payment_screen.dart`
- مقارنة بين الخطط (جدول)

---

## 🔵 المرحلة 4 — تحسين المحفظة (Multi-Asset Portfolio)
> **الهدف:** دعم الذهب والشهادات والصناديق بجانب الأسهم

### 4.1 — إعادة كتابة `lib/screens/portfolio_screen.dart`

**Endpoint:** `GET /api/mobile/portfolio`

**التابات:**
1. **كل الأصول** — عرض كل `items` (أسهم + ذهب + شهادات + صناديق)
2. **الأسهم** — فلتر `type=stock`
3. **الذهب** — فلتر `type=gold`
4. **الشهادات** — فلتر `type=certificate`
5. **تحليل** — `/api/mobile/portfolio/intelligence`

**إضافة أصل جديد (Bottom Sheet):**
- اختيار النوع (سهم / ذهب / شهادة / صندوق)
- حقول مختلفة حسب النوع
- POST إلى `/api/mobile/portfolio`

**Summary Cards:**
- إجمالي القيمة السوقية
- إجمالي الربح/الخسارة
- نسبة العائد الإجمالي
- التوزيع بالفطيرة (Pie Chart)

### 4.2 — إضافة نماذج جديدة

```dart
// lib/models/portfolio.dart (MODIFY)
enum AssetType { stock, gold, certificate, fund }

class PortfolioItem {
  final AssetType type;
  // مشترك لكل الأنواع:
  final double marketValue;
  final double costBasis;
  final double unrealizedPnl;
  // للأسهم:
  final String? ticker;
  final int? quantity;
  // للذهب:
  final double? weightGrams;
  final int? karat;
  // للشهادات:
  final String? bankName;
  final double? interestRate;
  final DateTime? maturityDate;
}
```

---

## 🟣 المرحلة 5 — تحسين Navigation والـ UI

### 5.1 — إعادة كتابة `lib/app.dart`

**5 Bottom Tabs بدل 4:**
1. 🏠 الرئيسية (Dashboard)
2. 📈 الأسهم (Stocks)
3. 🎯 الفرص (Hunter) — **جديد**
4. 💼 محفظتي (Portfolio)
5. 🤖 AI (Chat + Analysis) — **جديد كـ tab مستقل**

**Notification Bell في AppBar:**
- Badge بعدد الإشعارات غير المقروءة
- يفتح `notifications_screen.dart`
- يستخدم `getMobileNotifications()` مع polling كل 30 ثانية

**Persistent Market Status:**
- شريط ثابت تحت الـ AppBar يعرض حالة السوق

**Drawer المحسن (يضيف):**
- 🔔 الإشعارات
- 🔔 التنبيهات (Alerts)
- 📰 الأخبار
- 🎓 التعلم
- 🔍 Hunter/Screener
- 💬 AI Chat

### 5.2 — تحسين تصميم Navigation

```
Bottom Nav: Dashboard | Stocks | Hunter | Portfolio | AI-Hub
Drawer:     News | Alerts | Notifications | Learning | Crypto | Currency | Metals | Zakat | Subscription | Settings
```

---

## ⚡ المرحلة 6 — State Management بـ Provider
> **الهدف:** مشاركة البيانات بين الشاشات بدون re-fetch

### 6.1 — إضافة `lib/providers/`

```dart
// market_provider.dart
class MarketProvider extends ChangeNotifier {
  Map<String,dynamic>? _dashboardData;
  bool _isMarketOpen = false;
  Timer? _pollingTimer;
  
  Future<void> fetchDashboard() async {...}
  void startPolling() {...}
  void stopPolling() {...}
}

// auth_provider.dart
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoggedIn = false;
  String? _subscriptionTier;
  // login/logout/checkAuth
}

// portfolio_provider.dart
class PortfolioProvider extends ChangeNotifier {
  List<dynamic> _items = [];
  Map<String,dynamic>? _summary;
  // add/remove/refresh
}

// watchlist_provider.dart
class WatchlistProvider extends ChangeNotifier {
  List<dynamic> _items = [];
  // add/remove/refresh
}
```

**pubspec.yaml** — إضافة `provider: ^6.x`

---

## 📊 جدول API → شاشة (المرجع الكامل)

| Endpoint | HTTP | الشاشة | الأولوية |
|---------|------|--------|---------|
| `/api/mobile/dashboard` | GET | DashboardScreen | 🔴 حرج |
| `/api/mobile/portfolio` | GET/POST/DELETE | PortfolioScreen | 🔴 حرج |
| `/api/mobile/recommendations` | GET | RecommendationsScreen | 🔴 حرج |
| `/api/mobile/predictions` | GET | AiAnalysisScreen | 🔴 حرج |
| `/api/subscription/current` | GET | SubscriptionScreen | 🔴 حرج |
| `/api/watchlist` | GET/POST/DELETE | WatchlistScreen | 🔴 حرج |
| `/api/mobile/stocks/[ticker]` | GET | StockHistoryScreen | 🟡 مهم |
| `/api/chart/[ticker]` | GET | StockHistoryScreen | 🟡 مهم |
| `/api/stocks/[ticker]/history` | GET | StockHistoryScreen | 🟡 مهم |
| `/api/stocks/[ticker]/recommendation` | GET | StockHistoryScreen | 🟡 مهم |
| `/api/stocks/[ticker]/news` | GET | StockHistoryScreen | 🟡 مهم |
| `/api/mobile/notifications` | GET/POST | NotificationsScreen | 🟡 مهم |
| `/api/mobile/alerts/settings` | GET/POST/DELETE | AlertsScreen | 🟡 مهم |
| `/api/hunter/screener` | GET | HunterScreen | 🟡 مهم |
| `/api/ai/chat` | POST | AiChatScreen | 🟡 مهم |
| `/api/mobile/news` | GET | NewsScreen | 🟡 مهم |
| `/api/market/status` | GET | MarketStatusBanner | 🟡 مهم |
| `/api/subscription/plans` | GET | SubscriptionScreen | 🟡 مهم |
| `/api/paymob/create-payment` | POST | PaymentScreen | 🟡 مهم |
| `/api/learning/content` | GET | LearningScreen | 🟢 إضافة |
| `/api/learning/progress` | POST | LearningScreen | 🟢 إضافة |
| `/api/mobile/portfolio/intelligence` | GET | PortfolioScreen | 🟢 إضافة |
| `/api/mobile/watchlist/intelligence` | GET | WatchlistScreen | 🟢 إضافة |
| `/api/predictions/performance` | GET | AiAnalysisScreen | 🟢 إضافة |
| `/api/crypto/recommendations` | GET | CryptoScreen | 🟢 إضافة |
| `/api/global-predictions` | GET | AiAnalysisScreen | 🟢 إضافة |
| `/api/mobile/zakat-calculator` | GET | ZakatScreen | 🟢 إضافة |
| `/api/advanced-analysis?action=golden` | GET | HunterScreen | 🟢 إضافة |
| `/api/finance/smart-confluence` | GET | HunterScreen | 🟢 إضافة |

---

## 🎨 المرحلة 7 — تحسين التصميم العام

### 7.1 — Skeleton Loading Pattern (موحد)

كل شاشة لازم تتبع الـ pattern ده:
```dart
FutureBuilder<T>(
  future: _fetch(),
  builder: (ctx, snap) {
    // 1. Loading → Skeleton shimmer
    if (snap.connectionState == ConnectionState.waiting) {
      return SkeletonLoader.forScreen();
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

### 7.2 — تحسينات بصرية لكل الشاشات

- **Stock Card:** سعر كبير + badge ملون للتغيير + RSI indicator
- **Prediction Card:** Signal badge (STRONG_BUY = ذهبي) + confidence bar + entry/target/stop
- **Portfolio Asset Card:** animation للربح/الخسارة + progress bar للأداء
- **Alert Card:** نوع التنبيه + icon مناسب + حالة Active/Triggered
- **News Card:** Importance badge + source logo + تاريخ منسق

### 7.3 — Micro-animations

- Price change → brief color flash (أخضر/أحمر)
- Adding to portfolio/watchlist → Checkmark animation
- Pull to refresh → Custom lottie animation (اختياري)
- Tab switching → Smooth slide transition

---

## 📦 تعديلات `pubspec.yaml`

```yaml
dependencies:
  # موجودة بالفعل:
  dio: ^5.x
  shared_preferences: ^2.x
  google_sign_in: ^6.x
  # 
  # إضافة جديدة:
  provider: ^6.1.0           # State management
  shimmer: ^3.0.0            # Skeleton loading
  webview_flutter: ^4.x      # Paymob payment
  cached_network_image: ^3.x # صور مخزنة
  fl_chart: ^0.68.0          # Pie chart للمحفظة
  flutter_local_notifications: ^17.x  # تنبيهات محلية
  connectivity_plus: ^6.x    # فحص الإنترنت
  intl: ^0.19.0              # تنسيق التواريخ
```

---

## ✅ خطة التنفيذ التدريجية

### الأسبوع 1 — الإصلاحات الحرجة
- [ ] إصلاح `client.dart` (endpoints + timeouts)
- [ ] إضافة `mobile_api.dart`
- [ ] إصلاح `portfolio_screen.dart` → `/api/mobile/portfolio`
- [ ] إصلاح `recommendations_screen.dart` → `/api/mobile/recommendations`
- [ ] إصلاح `ai_analysis_screen.dart` → `/api/mobile/predictions`
- [ ] إصلاح `subscription_screen.dart` → `/api/subscription/current`
- [ ] إضافة `skeleton_loader.dart`

### الأسبوع 2 — تحسين UX
- [ ] إعادة كتابة `dashboard_screen.dart`
- [ ] إضافة `polling_service.dart`
- [ ] إضافة `market_status_banner.dart`
- [ ] تحسين `stocks_screen.dart` (pagination)
- [ ] تحسين `stock_history_screen.dart` (4 tabs)
- [ ] إعادة كتابة `portfolio_screen.dart` (multi-asset)

### الأسبوع 3 — الشاشات الجديدة
- [ ] `notifications_screen.dart`
- [ ] `alerts_screen.dart`
- [ ] `hunter_screen.dart` ⭐
- [ ] `ai_chat_screen.dart` ⭐
- [ ] `news_screen.dart`
- [ ] `payment_screen.dart`
- [ ] `learning_screen.dart`

### الأسبوع 4 — State Management و Navigation
- [ ] إضافة `provider` package
- [ ] `market_provider.dart`
- [ ] `auth_provider.dart`
- [ ] `portfolio_provider.dart`
- [ ] `watchlist_provider.dart`
- [ ] إعادة كتابة `app.dart` (5 tabs + notification bell)
- [ ] تحسينات بصرية نهائية

---

## 🚨 ملاحظات مهمة للتنفيذ

> [!IMPORTANT]
> **لا تستخدم أبداً** `/api/portfolio` (web) في الموبايل — استخدم دائماً `/api/mobile/portfolio`

> [!IMPORTANT]
> **Timeout للـ AI Chat** يجب أن يكون 120 ثانية — DeepSeek R1 بيأخد وقت طويل

> [!IMPORTANT]
> **Token Storage** استخدم `flutter_secure_storage` بدل `SharedPreferences` للـ token

> [!WARNING]
> **Market Status Polling**: لما السوق مقفل، قلل الـ polling لـ 30 دقيقة بدل 5 دقايق لتوفير البطارية

> [!IMPORTANT]
> **Paymob WebView**: بعد إنهاء الدفع، اعمل poll على `/api/subscription/current` كل 5 ثواني لمدة 5 دقايق

> [!NOTE]
> **Subscription Tiers**: `free` → max 5 watchlist, 1 portfolio | `normal` → 25/5 | `premium` → unlimited

---

## 📏 معايير الجودة للتحقق من الإنجاز

- [ ] كل شاشة بها Skeleton loading — لا يوجد تجمد
- [ ] كل الـ endpoints تستخدم `/api/mobile/*` الصحيح
- [ ] الـ Dashboard يستخدم endpoint واحد بدل 3
- [ ] المحفظة تعرض كل أنواع الأصول
- [ ] AI Chat يعمل مع timeout 120 ثانية
- [ ] Hunter Screener يعمل ويعرض فرص حقيقية
- [ ] Paymob Payment Flow يعمل كاملاً
- [ ] الإشعارات والتنبيهات تعمل
- [ ] الـ Polling يتوقف لما الـ app في الخلفية
- [ ] `flutter analyze` — 0 errors
