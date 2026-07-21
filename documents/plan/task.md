فهمتك — خطة الإصلاح الكاملة بدون كود:

---

## 🛠️ خطة إصلاح Flutter App — "نسخة 2.0 من الداخل"

### المرحلة 1: Foundation (يوم 1-2)

| # | الملف | التعديل |
|---|-------|---------|
| 1 | `pubspec.yaml` | أضف `flutter_bloc` أو `provider` + `freezed` + `json_serializable` |
| 2 | `lib/core/theme.dart` | جديد — `ThemeData` واحد بـ colors من `GLMinvestment` (برتقالي/كهرماني، ممنوع indigo) |
| 3 | `lib/core/constants.dart` | جديد — API base URL، timeouts، padding system (4, 8, 12, 16, 24) |
| 4 | `lib/widgets/` | مجلد جديد — `LoadingWidget`، `ErrorWidget`، `EmptyStateWidget`، `AppCard` |

**الهدف:** كل الشاشات تستخدم نفس الـ theme + widgets.

---

### المرحلة 2: Data Layer (يوم 2-3)

| # | الملف | التعديل |
|---|-------|---------|
| 5 | `lib/models/stock_model.dart` | جديد — `Stock` class مع `fromJson`/`toJson` |
| 6 | `lib/models/prediction_model.dart` | جديد — `Prediction` class |
| 7 | `lib/models/chart_data_model.dart` | جديد — `ChartData` (date, open, high, low, close, volume) |
| 8 | `lib/repositories/stock_repository.dart` | جديد — ياخد من `MobileApi` ويرجع `List<Stock>` |
| 9 | `lib/repositories/chart_repository.dart` | جديد — يحل مشكلة column names (`close_price` → `close`) |

**الهدف:** مفيش `Map<String, dynamic>` في الـ UI — كل حاجة typed.

---

### المرحلة 3: Fix Charts (يوم 3)

| # | الملف | التعديل |
|---|-------|---------|
| 10 | `lib/screens/stock_history_screen.dart` | بدل `TradingViewWebView` — استخدم `fl_chart` (Flutter native) |
| 11 | `lib/widgets/price_chart.dart` | جديد — `LineChart` أو `CandlestickChart` بـ `fl_chart` |
| 12 | `lib/repositories/chart_repository.dart` | الـ `getHistory` تعمل mapping: `open_price` → `open` قبل ما ترجع |

**الهدف:** Charts شغالة بدون WebView (أسرع + أقل مشاكل).

---

### المرحلة 4: Fix API Errors (يوم 3-4)

| # | الملف | التعديل |
|---|-------|---------|
| 13 | `lib/api/mobile_api.dart` | أضف `interceptors` للـ Dio — لو 503 → retry مرة واحدة |
| 14 | `lib/api/mobile_api.dart` | أضف `catchError` — لو endpoint مش موجود (404) → return empty list مش crash |
| 15 | `lib/screens/dashboard_screen.dart` | بدل ما تستنى كل الـ APIs — load بالتدريج (staggered loading) |

**الهدف:** الـ app ما يكراشش لو API واقف.

---

### المرحلة 5: Redesign Screens (يوم 4-6)

| # | الشاشة | التعديل |
|---|--------|---------|
| 16 | Dashboard | Grid layout — 4 cards (Market, Portfolio, AI Signal, News) |
| 17 | Stock List | ListView مع `Card` — ticker + name + change% + mini sparkline |
| 18 | Stock Detail | Tab bar — Chart / Analysis / Predictions / News |
| 19 | Predictions | Card لكل prediction مع color-coded (buy=green, sell=red, hold=gray) |
| 20 | Portfolio | Pie chart (assets) + List (stocks) + P&L summary |

**الهدف:** نفس الـ functionality بس شكل احترافي.

---

### المرحلة 6: Add Dual Persona (يوم 6-7)

| # | الملف | التعديل |
|---|-------|---------|
| 21 | `lib/screens/persona_screen.dart` | جديد — تابين: "مستثمر" (min_gates=3) و"مضارب" (min_gates=2) |
| 22 | `lib/widgets/persona_card.dart` | جديد — 5 gates (أخضر/أحمر) + score bar + entry/target/stop |
| 23 | `lib/repositories/persona_repository.dart` | جديد — يستدعي `/api/sniper/scan?persona=` |

**الهدف:** نفس الـ Dual Persona اللي في الموقع.

---

### المرحلة 7: Polish (يوم 7)

| # | المهمة | التفاصيل |
|---|--------|---------|
| 24 | Add pull-to-refresh | في كل list screens |
| 25 | Add shimmer loading | بدل `CircularProgressIndicator` |
| 26 | Add hero animations | بين list → detail |
| 27 | Test on real device | Android + iOS |
| 28 | Build release APK | `flutter build apk --release` |

---

## 📋 Checklist قبل كل مرحلة

| المرحلة | التحقق |
|---------|--------|
| 1 | كل الألوان من `constants.dart` — مفيش hardcoded color |
| 2 | `flutter analyze` — 0 errors |
| 3 | Chart بيظهر بيانات حقيقية (مش فاضي) |
| 4 | Airplane mode — الـ app ما يكراشش |
| 5 | UI matches الموقع (Next.js) |
| 6 | Persona tabs شغالة مع API |
| 7 | APK size < 50MB |

---

## 🎯 الترتيب بالأولوية

لو وقتك ضيق:

| الأيام المتاحة | اعمل إيه |
|---------------|---------|
| **يوم واحد بس** | المرحلة 3 (Charts) + 4 (API fix) — الـ app يبقى usable |
| **3 أيام** | 1 + 2 + 3 + 4 — foundation + charts + no crashes |
| **أسبوع كامل** | كل المراحل — app محترم |

---
خليني أقارن الـ Flutter app بالموقع الإلكتروني (Next.js) بناءً على التوثيق اللي عندي:

---

## 🔍 مقارنة: Flutter App vs الموقع الإلكتروني

### الخدمات الموجودة في الموقع (Next.js) — من `PROJECT_DISSECTION_REPORT.md`

| الخدمة | الموقع | Flutter | الحالة |
|--------|--------|---------|--------|
| **Dashboard / نظرة عامة** | ✅ `MarketStatusImageCard` | ✅ `DashboardScreen` | ✅ متطابق |
| **قائمة الأسهم + Search** | ✅ `src/app/stocks/page.tsx` | ✅ `StockListScreen` | ✅ متطابق |
| **تفاصيل السهم + Chart** | ✅ `lightweight-charts` | ⚠️ `TradingViewWebView` (مش شغال) | ❌ Chart فاضي |
| **الذهب / العملات / Crypto** | ✅ `CryptoView` | ✅ `GoldScreen`, `CurrencyScreen`, `CryptoScreen` | ✅ متطابق |
| **التحليل المتقدم (Maestro)** | ✅ `AdvancedAnalysisView` | ⚠️ `AnalysisScreen` (بسيط) | ⚠️ ناقص personas |
| **التوصيات (Recommendations)** | ✅ `PersonaTab` (Sniper) | ✅ `RecommendationsScreen` | ✅ متطابق |
| **البرسونا المزدوجة (Dual Persona)** | ✅ 5 تابات: Market + Predictions + Investor + Gambler + Expert | ❌ مفيش | 🔴 **ناقص** |
| **AI Chat (Ollama/glm-fast)** | ✅ `AIChatView` | ✅ `AIAnalysisScreen` | ✅ متطابق |
| **المحفظة (Portfolio)** | ✅ `PortfolioView` | ✅ `PortfolioScreen` | ✅ متطابق |
| **قائمة المراقبة (Watchlist)** | ✅ `WatchlistView` | ✅ `WatchlistScreen` | ✅ متطابق |
| **التعلم (Learning)** | ✅ `SelfLearningView` | ✅ `LearningScreen` | ✅ متطابق |
| **المحاكاة (Simulation)** | ✅ `SimulationView` | ✅ `SimulationScreen` | ✅ متطابق |
| **الاشتراكات (Subscription)** | ✅ `SubscriptionView` | ✅ `SubscriptionScreen` | ✅ متطابق |
| **الإعدادات (Settings)** | ✅ `SettingsView` | ✅ `SettingsScreen` | ✅ متطابق |
| **Zakat Calculator** | ❌ مفيش | ✅ `ZakatScreen` | 🟢 **إضافة Flutter** |
| **Admin Panel** | ✅ `AdminDashboardView` | ✅ `AdminScreen` | ✅ متطابق |
| **WebSocket (live updates)** | ✅ `ws-client.ts` (port 3005) | ❌ مفيش | 🔴 **ناقص** |
| **بطاقات الصور القابلة للمشاركة** | ✅ `PersonaImageCard` + `ExpertPredictionsImageCard` | ❌ مفيش | 🔴 **ناقص** |
| **نشر Telegram** | ✅ `ImageCardExport` | ❌ مفيش | 🔴 **ناقص** |
| **Smart Portfolio Monitor** | ✅ `take_profit` / `stop_loss` alerts | ❌ مفيش | 🔴 **ناقص** |
| **Live AI Monitor (كل 15 دقيقة)** | ✅ `live_ai_monitor.py` | ❌ مفيش | 🔴 **ناقص** |
| **Hot Stocks Detector** | ✅ `hot_stocks_detector.py` | ❌ مفيش | 🔴 **ناقص** |

---

## 🔴 الخدمات الناقصة في Flutter (الأهم)

| # | الخدمة | التأثير | الجهد |
|---|--------|---------|-------|
| 1 | **البرسونا المزدوجة (Investor + Gambler)** | كبير — ده core feature | 2-3 أيام |
| 2 | **WebSocket (live prices)** | كبير — المستخدم بيتابع الأسعار لحظياً | 1-2 أيام |
| 3 | **Smart Portfolio Monitor** | كبير — alerts للـ take-profit/stop-loss | 2 أيام |
| 4 | **Hot Stocks Detector** | متوسط — كشف الأسهم الساخنة | 1-2 أيام |
| 5 | **بطاقات الصور للمشاركة** | صغير — Telegram sharing | 1 يوم |
| 6 | **Live AI Monitor** | متوسط — AI كل 15 دقيقة | 1-2 أيام |

---

## 🎯 الخلاصة

| | الموقع (Next.js) | Flutter App |
|---|---|---|
| **الشاشات** | 15+ | 18 (بس Zakat إضافي) |
| **الـ Core Features** | ✅ كاملة | ⚠️ ناقص Dual Persona |
| **الـ Real-time** | ✅ WebSocket | ❌ مفيش |
| **الـ AI Integration** | ✅ كاملة | ⚠️ Chat بس (مفيش Live Monitor) |
| **الـ Alerts** | ✅ Smart Portfolio | ❌ مفيش |
| **الـ Sharing** | ✅ Telegram | ❌ مفيش |

---

## 💡 رأيي

**الـ Flutter app "مرآة" بنسبة 70%** — الشكل موجود بس الـ core features الناقصة بتخلي المستخدم يفضل الموقع:

| لو المستخدم عايز... | هيستخدم الموقع ولا Flutter؟ |
|---|---|
| تابع الأسعار لحظياً | الموقع ✅ (WebSocket) |
| شوف توصية Investor vs Gambler | الموقع ✅ (Dual Persona) |
| ياخد alert لما سهم يوصل هدف | الموقع ✅ (Smart Monitor) |
| يحسب Zakat | Flutter ✅ (بس) |
| يتصفح بسرعة | Flutter ✅ (native) |

---

## ❓ السؤال

**عايزني أركز على إضافة الـ 6 features الناقصة دي للـ Flutter؟**

أو **نكتفي بـ "المرآة" الحالية ونصلح الـ UI بس؟**

| الخيار | الوقت | النتيجة |
|--------|-------|---------|
| **A. إضافة الـ 6 features** | 2-3 أسابيع | Flutter = الموقع بالظبط |
| **B. صلح UI بس** | 3-5 أيام | Flutter شكله أحسن بس ناقص features |
| **C. A + B مع بعض** | 3-4 أسابيع | Flutter أفضل من الموقع |
**عايزني أبدأ بأنى مرحلة؟**