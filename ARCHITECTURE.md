# توثيق شامل — تطبيق مساعد الاستثمار

## 📋 نظرة عامة على المشروع

```
التطبيق: مساعد الاستثمار (Investment Assistant)
النوع: Flutter App — Android / iOS / Web
الإصدار: 2.0.1+1
اللغة: عربية فقط (RTL)
المنصة الخلفية: Next.js / Node.js على https://invist.m2y.net
قاعدة بيانات إضافية: Python FastAPI على VPS (72.61.137.86:8010)
```

---

## 🗂️ هيكل المشروع

```
investment/
├── lib/
│   ├── main.dart                    # نقطة الدخول — MaterialApp + Routes + Riverpod
│   ├── app.dart                     # MainNavigator (BottomTabs + SideDrawer + CommandBar)
│   │
│   ├── api/
│   │   ├── client.dart              # عميل Dio HTTP واحد لجميع الـ APIs (Singleton)
│   │   └── local_database.dart      # SQLite محلي للقراءة فقط (Asset DB)
│   │
│   ├── models/                      # نماذج البيانات (Types + JSON Helpers)
│   │   ├── types.dart               # Barrel re-export
│   │   ├── json_helpers.dart        # parseInt / parseDouble / parseBool
│   │   ├── stock.dart               # Stock + StockHistory
│   │   ├── market.dart              # MarketOverview + MarketIndex
│   │   ├── crypto.dart              # CryptoAsset
│   │   ├── gold.dart                # GoldPrice + GoldHistory
│   │   ├── currency.dart            # Currency + ConversionResult
│   │   ├── portfolio.dart           # PortfolioPosition + PortfolioSummary
│   │   ├── watchlist.dart           # WatchlistItem
│   │   ├── user.dart                # User + SubscriptionPlan + AuthResponse
│   │   ├── recommendation.dart      # Recommendation + AIRecommendation + ExpertRecommendation
│   │   └── zakat.dart               # ZakatCalculation
│   │
│   ├── screens/                     # 16 شاشة
│   │   ├── dashboard_screen.dart    # الصفحة الرئيسية (سهم + مؤشرات + اكثر ارتفاعاً/انخفاضاً)
│   │   ├── stocks_screen.dart       # قائمة الأسهم مع بحث
│   │   ├── stock_history_screen.dart # تفاصيل السهم + تاريخ + توصيات + تحليل خبير (~1030 سطر)
│   │   ├── ai_analysis_screen.dart  # تحليل ذكي + تحليل دفاعي + تنبؤات
│   │   ├── crypto_screen.dart       # قائمة العملات الرقمية
│   │   ├── crypto_detail_screen.dart# تفاصيل العملة + OHLC + مؤشرات
│   │   ├── metals_screen.dart       # أسعار الذهب والفضة + تاريخ
│   │   ├── currency_screen.dart     # أسعار العملات + محول عملات
│   │   ├── portfolio_screen.dart    # محفظة المستخدم
│   │   ├── watchlist_screen.dart    # قائمة المتابعة
│   │   ├── recommendations_screen.dart # توصيات الخبراء
│   │   ├── zakat_screen.dart        # حاسبة الزكاة
│   │   ├── subscription_screen.dart # خطط الاشتراك ✅ موجودة ومتصلة
│   │   ├── settings_screen.dart     # الإعدادات + الوضع الليلي
│   │   ├── auth_screen.dart         # تسجيل الدخول (Google Sign-In فقط)
│   │   └── webview_screen.dart      # فتح الموقع في WebView
│   │
│   ├── services/
│   │   └── notification_service.dart # إشعارات محلية (يومية + توصيات)
│   │
│   ├── theme/
│   │   ├── colors.dart              # AppColors + AppSpacing + AppRadius
│   │   └── typography.dart          # AppTypography + AppTheme (فاتح + داكن)
│   │
│   └── widgets/
│       ├── state_view.dart          # StateView (loading/error/empty)
│       └── tradingview_chart.dart   # Widget TradingView LightweightCharts
│
├── assets/
│   ├── charts/tradingview.html      # ملف HTML/JS للرسم البياني
│   ├── db/
│   │   ├── custom.db                # SQLite (أسهم + مؤشرات + ذهب)
│   │   ├── egx_investment.db        # قاعدة بيانات Python VPS
│   │   └── gold_prices.db
│   └── image/                       # الأيقونات والصور
│
└── pubspec.yaml                     # التبعيات
```

---

## 🌐 البنية التحتية للخادم (المنصة)

```
[Flutter App]
    │
    │ Dio HTTP → https://invist.m2y.net/api/*
    ▼
[Next.js / Node.js Backend]
    │
    ├──► Python FastAPI (VPS: 72.61.137.86:8010)
    │     • محرك الأسهم الرئيسي (EGX)
    │     • بيانات OHLC تاريخية
    │     • تحليل فني
    │
    ├──► Twelve Data / EODHD / Marketstack / Alpha Vantage
    │     • مصادر بديلة لبيانات الأسهم (سلسلة فشل)
    │
    ├──► CoinGecko
    │     • أسعار العملات الرقمية
    │
    ├──► FCSAPI
    │     • أسعار الذهب والعملات
    │
    ├──► قاعدة البيانات
    │     • مستخدمين + اشتراكات
    │     • محافظ + قوائم متابعة
    │     • توصيات + تحليلات
    │
    └──► PayMob
          • معالجة مدفوعات الاشتراكات
```

---

## 🔑 المصادقة الحالية

| العنصر | التفاصيل |
|--------|---------|
| الطريقة | Google Sign-In فقط (لا يوجد باسوورد/إيميل) |
| نقطة النهاية | `POST /api/auth/google` |
| التخزين المحلي | SharedPreferences (`auth_token` + `user_data`) |
| مدة التوكن | 30 يوم (`expires_in: 2592000`) |
| فحص الجلسة | `GET /api/auth/me` عند فتح التطبيق |

**تدفق المصادقة:**
```
1. المستخدم يضغط "تسجيل دخول بـ Google"
2. google_sign_in → ID Token
3. POST /api/auth/google ← id_token
4. الخادم يرد: { user, token, is_new_user }
5. حفظ التوكن في SharedPreferences
6. التوجيه للصفحة الرئيسية
```

---

## 💾 كيف يتم حفظ البيانات حالياً

### 1. بيانات المستخدم (User Data)
- **الطريقة**: SharedPreferences (محلي)
- **المحتويات**: `id, email, username, name, subscription_tier, is_admin`
- **المفتاح**: `user_data` (سلسلة JSON)

### 2. توكن المصادقة
- **الطريقة**: SharedPreferences
- **المفتاح**: `auth_token`
- **يُحقن تلقائياً**: في كل طلب Dio من خلال Interceptor

### 3. المحفظة (Portfolio)
- **الطريقة**: **خادم فقط** — لا يوجد نسخة محلية
- **نقاط النهاية**: `GET/POST/DELETE /api/portfolio`
- **النموذج**: `PortfolioResponse` → `List<PortfolioPosition>` + `PortfolioSummary`

### 4. قائمة المتابعة (Watchlist)
- **الطريقة**: **خادم فقط** — لا يوجد نسخة محلية
- **نقاط النهاية**: `GET/POST/DELETE /api/watchlist`
- **النموذج**: `WatchlistResponse` → `List<WatchlistItem>`

### 5. قاعدة البيانات المحلية (Local SQLite)
- **الطريقة**: قراءة فقط (Read-Only Fallback)
- **الملف**: `assets/db/custom.db` → ينسخ في أول تشغيل
- **الجداول**: `stocks`, `market_indices`, `gold_prices`
- **الاستخدام**: بديل عند فشل طلب API (للأسهم والسوق فقط)
- **غير مستخدمة للكتابة**: لا يتم حفظ أي بيانات جديدة فيها من التطبيق

### 6. الإعدادات
| المفتاح | النوع | الوصف |
|---------|-------|-------|
| `dark_mode` | bool | الوضع الليلي |
| `notifications_enabled` | bool | تفعيل الإشعارات |
| `risk_tolerance` | string | تحمل المخاطر |
| `language` | string | لغة التطبيق |

---

## 📱 إدارة الحالة (State Management)

```
نموذج الحالة الحالي:
─────────────────────────────
كل شاشة StatefulWidget تدير حالتها بنفسها
لا يوجد حل مشترك للبيانات بين الشاشات
─────────────────────────────

Riverpod: مستخدم فقط للوضع الليلي (darkModeProvider)
─────────────────────────────
مثال من main.dart:
final darkModeProvider = StateProvider<bool>((ref) => false);
─────────────────────────────

النتيجة:
  - لا يوجد تدفق بيانات موحد
  - كل شاشة تعمل بشكل مستقل
  - لا يوجد مستمع عام لتغييرات البيانات
```

---

## 💰 نظام الاشتراكات الحالي

### ما is موجود الآن

**في الخادم (Backend):**
| نقطة النهاية | الوصف |
|-------------|-------|
| `GET /api/subscription/plans` | قائمة الباقات المتاحة |
| `GET /api/subscription/current` | الباقة النشطة حالياً للمستخدم |
| `POST /api/subscription/activate` | تفعيل باقة |
| `POST /api/subscription/start-trial` | بدء تجربة مجانية |
| `POST /api/subscription/upgrade` | ترقية الباقة |
| `POST /api/paymob/create-payment` | إنشاء عملية دفع PayMob |
| `POST /api/admin/subscription/set-plan` | تعيين باقة لمستخدم (ادمن) |

**في التطبيق:**
- شاشة `subscription_screen.dart` موجودة ومتصلة بـ API
- نموذج `SubscriptionPlan` في `models/user.dart` (سطور 88–143)
- أساليب API في `client.dart` (سطور 501–533)

### ما هو ناقص

```
❌ دعم الفواتير داخل التطبيق (in_app_purchase)
❌ ربط Google Play Billing Library
❌ التحقق من حالة الاشتراك المحلي (بدون اتصال)
❌ تقييد الوصول للميزات المدفوعة على حسب الباقة
❌ تجربة مجانية محدودة بوقت
❌ واجهة ترقية منظمة (Banner/Modal)">
```

---

## 🔒 ما تحتاجه قبل نظام الاشتراكات

### الخيار الأول: Firebase / Supabase (موصى به للسرعة)
```
✅ مصادقة جاهزة (Google + Email + Phone)
✅ قاعدة بيانات للمستخدمين والاشتراكات
✅ التحقق من حالة الاشتراك بدون اتصال (Cache)
✅ إشعارات عبر الإنترنت
✅ تحليلات
✅ استضافة مجانية للمشاريع الصغيرة
السلبي: تعتمد على خدمات خارجية
```

### الخيار الثاني: نظام خاص بك (Next.js + SQL)
```
✅ تحكم كامل
✅ لا توجد رسوم اشتراك للخدمات
السلبي: تحتاج لوقت أكبر وصيانة مستمرة
```

---

## 📊 حالات الاستخدام لنظام الاشتراكات

### المستخدم الحر (Free)
```
الوصول:
  ✅ عرض قائمة الأسهم
  ✅ عرض تفاصيل السهم الأساسية
  ✅ تحويل عملات
  ✅ أسعار الذهب
  ✅ الزكاة
  ❌ التوصيات الاحترافية
  ❌ التحليل الذكي
  ❌ إضافة للمحفظة (قمود على 3 أسهم)
  ❌ إضافة لقائمة المتابعة (قمود على 3 أسهم)
  ❌ تحليل دفاعي (AI Batch)
  ❌ تنبؤات
```

### المستخدم بلس (Plus — ~99 جنيه/شهر)
```
الوصول:
  ✅ كل ما في Free
  ✅ توصيات احترافية غير محدودة
  ✅ محفظة غير محدودة
  ✅ قائمة متابعة غير محدودة
  ✅ تحليل ذكي أساسي
  ❌ تحليل دفاعي
  ❌ تنبؤات
```

### المستخدم بريميوم (Premium — ~199 جنيه/شهر)
```
الوصول:
  ✅ كل ما في Plus
  ✅ تحليل دفاعي (AI Batch Analysis)
  ✅ تنبؤات الأسعار
  ✅ دعم أولوية
  ✅ تحميل تقارير PDF
```

---

## 🔧 المتطلبات الفنية

| العنصر | الحالة الحالية | المطلوب |
|--------|---------------|---------|
| مصادقة المستخدمين | Google فقط | Google + Email/Password (اختياري) |
| قاعدة بيانات المستخدمين | Server-side فقط | قاعدة بيانات اشتراكات منفصلة أو مدمجة |
| نظام دفع | PayMob (عبر API) | Google Play Billing + in_app_purchase |
| تقييد الميزات | لا يوجد | Check subscription tier قبل كل ميزة مدفوعة |
| تجربة مجانية | لا يوجد | فترة تجربة 7/14 يوم مع بدء تلقائي للعد |
| إشعارات التجديد | لا يوجد | إشعار قبل انتهاء الاشتراك بـ 3 أيام |
| تحقق محلي بدون اتصال | لا | حفظ حالة الاشتراك محلياً مع تحديث دوري |

---

## 📁 ملفات تحتاج تعديل عند التنفيذ

```
📄 lib/models/user.dart
   → SubscriptionPlan model موجود مسبقاً
   → يحتاج: حقل isActive, startDate, endDate, trialUsed

📄 lib/api/client.dart
   → أساليب الاشتراك موجودة مسبقاً (سطور 501–533)
   → يحتاج: دالة checkFeatureAccess() للتحقق من الصلاحيات

📄 lib/screens/subscription_screen.dart
   → موجودة ومتصلة بالخادم
   → يحتاج: عرض حالات الاشتراك + زر ترقية

📄 lib/main.dart / lib/app.dart
   → يحتاج: فحص صلاحية الاشتراك عند فتح التطبيق
   → يحتاج: عرض Banner/Modal Expired إذا انتهى الاشتراك

📄 lib/screens/stock_history_screen.dart
   → يحتاج: قفل التوصيات الاحترافية إذا كان المستخدم Free

📄 lib/screens/ai_analysis_screen.dart
   → يحتاج: قفل التحليل الذكي if Free

📄 pubspec.yaml
   → يحتاج إضافة: in_app_purchase
```

---

## 🧱 خطة العمل المقترحة

### المرحلة 1: تجهيز البنية التحتية (1–2 يوم)
```
☐ 1-1: إعداد Firebase أو Supabase
☐ 1-2: إنشاء مجموعات/جداول المستخدمين والاشتراكات
☐ 1-3: إعداد Google Play Console للاشتراكات (المنتجات)
☐ 1-4: إضافة in_app_purchase package في pubspec.yaml
```

### المرحلة 2: منطق الاشتراك (2–3 أيام)
```
☐ 2-1: دالة checkSubscriptionStatus() في client.dart
☐ 2-2: دالة hasFeatureAccess(feature) في models/user.dart أو client.dart
☐ 2-3: Middleware/Interceptor للتحقق من الاشتراك قبل الطلبات المدفوعة
☐ 2-4: حفظ حالة الاشتراك محلياً (SharedPreferences + TTL)
```

### المرحلة 3: واجهة المستخدم (2–3 أيام)
```
☐ 3-1: تعديل subscription_screen.dart لعرض الباقات بشكل جذاب
☐ 3-2: إضافة Banner ترقية في الشاشات الرئيسية
☐ 3-3: إضافة Modal عند الوصول لحد الاستخدام المجاني
☐ 3-4: شاشة إدارة الاشتراك (عرض حالة، إلغاء، تجديد)
```

### المرحلة 4: تقييد الميزات (3–4 أيام)
```
☐ 4-1: Portfolio max items check (3 items for Free)
☐ 4-2: Watchlist max items check (3 items for Free)
☐ 4-3: Recommendations feature flag
☐ 4-4: AI Analysis feature flag
☐ 4-5: Predictions feature flag
☐ 4-6: Exports/Reports feature flag
```

### المرحلة 5: اختبار ونشر (1–2 يوم)
```
☐ 5-1: اختبار على Test Track (Google Play)
☐ 5-2: اختبار تجربة مجانية
☐ 5-3: اختبار الإلغاء والتجديد
☐ 5-4: اختبار بدون اتصال
☐ 5-5: الإصدار النهائي للإنتاج
```

---

## ⚠️ ملاحظات هامة

1. **الخادم الحالي يحتاج تعديلات**: حالياً الخادم على `invist.m2y.net` لا يعالج有力地 دفع Google Play — تحتاج لربط PayMob مع Google Play Billing أو استخدام حل وسيط.

2. **الموقع الإلكتروني مستقل**: التطبيق يفتح الموقع في WebView منفصل (`webview_screen.dart`) — الاشتراكات في الموقع والطبع يجب أن تكون متزامنة مع قاعدة بيانات واحدة مشتركة.

3. **المستخدمون الحاليون**: إذا كان هناك مستخدمون حالياً يستخدمون التطبيق بدون اشتراك، يجب إضافة مسار ترقية ناعم (grace period) — لا تقفل الميزات فوراً بعد التحديث.

4. **تجربة مجانية**: الخادم يحتاج نقطة نهاية `/api/subscription/start-trial` (موجودة في APIlist.md) — فقط تحتاج لربطها بـ Google Play.

5. **الشروط والأحكام**: يجب إضافة صفحة شروط استخدام وخصوصية في التطبيق قبل تفعيل الدفع.

---

*آخر تحديث: 2026-05-15*
*الإصدار: 2.0.1+1*
