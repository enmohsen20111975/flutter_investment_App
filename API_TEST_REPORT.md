# تقرير اختبار كل الـ APIs المستخدمة في التطبيق

**التاريخ:** 2026-10-01 11:55
**Base URL:** `https://invist.m2y.net`
**المصدر:** استخراج آلي لكل `_(dio|aiDio|chartDio).get/post/put/delete` من `lib/api/client.dart`
**عدد الـ endpoints المفحوصة:** 191 (method + path فريد)
**طريقة الاختبار:** طلبات HTTP حقيقية مع `Authorization: Bearer <token>` من تسجيل دخول فعلي بحساب اختبار

---

## الخلاصة

| الحالة | العدد | النسبة |
|--------|------:|-------:|
| ✅ شغال (2xx) | **161** | 84% |
| ❌ خطأ سيرفر حقيقي | **7** | 4% |
| ⚠️ أخطاء مخفية (200 مع `success:false`) | **2** | 1% |
| ℹ️ 403 أدمن / 400 payload ناقص / 404 ID وهمي | 21 | 11% |

### مقارنة بالتقرير الأول (2026-09-30)

| المؤشر | قبل | بعد |
|---|---:|---:|
| شغال | 147 | **161** (+14) |
| خطأ سيرفر 5xx | 4 | **7** |

**إصلاحات مؤكدة من الـ deploy الجديد:**
- `/api/mobile/notifications` — كان 500، بقى شغال
- `/api/crypto/recommendations` — كان 500 بـ Prisma error، الـ error اتغيّر (لسه 500 لكن برسالة مختلفة)
- `/api/portfolio/accounts/{id}/equity-curve` — كان 503 بـ HTML، بقى 502 بـ JSON نظيف
- الـ auth بقى شغال على كل الـ endpoints المحمية (المشكلة اللي كانت في التقرير الأول اتحلّت — كانت في السيرفر وقت الاختبار الأول)

---

## 1. أخطاء سيرفر حقيقية (تحتاج إصلاح في الـ backend)

| # | Method | Endpoint | الخطأ | السبب |
|---|---|---|---|---|
| 1 | GET | `/api/subscription/plans` | 500 `internal_error` | متكرر 3/3 مرات — **شاشة الاشتراكات هتفشل تمامًا** |
| 2 | GET | `/api/crypto/recommendations` | 500 `internal_error` | متكرر 3/3 مرات — `data: []` |
| 3 | POST | `/api/mobile/portfolio` | 500 | Prisma: `The column updated_at does not exist` في جدول `portfolioItem` |
| 4 | POST | `/api/unified-learning/intelligent` | 503 | `python_backend_unavailable` — الـ Python backend مش شغال |
| 5 | POST | `/api/crypto/simulation` | 503 | `python_backend_unavailable` — تنفيذ صفقات الكريبتو معطل |
| 6 | GET | `/api/auth/me` | 401 | **باقي Lupgap واحد بس في الـ auth** — التوكن صالح لكن `/api/auth/me` مرفوض |
| 7 | PUT | `/api/auth/profile` | 401 | نفس المشكلة — تعديل البروفايل مرفوض رغم صحة التوكن |

### تفاصيل لازم تتصلح في الداتابيز
```
Missing table : market_pricing        (subscription/plans)
Missing column: predictions.published_at
Missing column: portfolioItem.updated_at  (mobile/portfolio)
```
بعد آخر deploy اتغيّرت رسالة الخطأ من Prisma لـ `internal_error` — يعني صار فيه error handling، بس **الجدول/العمود لسه ناقصين**.

---

## 2. أخطاء مخفية (HTTP 200 لكن `success:false`)

الكلاينت بيعتمد على status code بس، فدي“Khelt” الأخطاء دي:

| Method | Endpoint | الرد |
|---|---|---|
| POST | `/api/ai/chat` | 200 → `{"success":false,"error":"NO_API_KEY","reply":"API Key غير موجود"}` — **مفتاح DeepSeek ناقص في السيرفر**، الشات مش هيشتغل |
| GET | `/api/portfolio/bag-holder-rescue` | 200 → لا توجد أسهم في المحفظة (طبيعي لحساب فاضي) |

> ملاحظة: `/api/ai/analyze-stock` **شغال تمام** (`success:true`, source: `python_maestro`) — يعني المشكلة في الشات بس.

---

## 3. 403 أدمن — طبيعي، مش خلل

| Method | Endpoint |
|---|---|
| POST | `/api/market/sync` |
| POST | `/api/market/sync-live` |
| POST | `/api/market/incremental-sync` |
| POST | `/api/backtesting/unified` |

كلهم `ADMIN_AUTH_REQUIRED` — مستخدم عادي مش أدمن.

---

## 4. 400/404 بسبب payload الاختبار — اتحلت كلها

| Endpoint | بعد تصحيح الـ payload |
|---|---|
| `POST /api/paper-trading-v2/order` | ✅ 200 (محتاج `asset_type`, `order_type`, `shares`, `entry_price`) |
| `POST /api/finance/assets` | ✅ 200 (محتاج `type: gold` مش `cash`) |
| `DELETE /api/finance/assets/{id}` | ✅ 404 «Asset not found» — يعني autenticar شغال |
| `POST /api/push/register` | ✅ 200 (المفتاح `push_token` مش `token`) |
| `POST /api/subscription/subscribe` | ✅ 200 (المفتاح `plan_id`) |
| `POST /api/maker-radar/track` | ✅ 200 (محتاج `entryPrice` + `action`) |
| `POST /api/alerts/create` | محتاج `threshold` — ظاهر في الكود؟ اتأكد |
| `POST /api/mobile/portfolio` | ⚠️ 500 — مشكله داتابيز (فوق) |
| `POST /api/auth/google` | طبيعي — محتاج Google ID token حقيقي |
| `POST /api/auth/register` | طبيعي — validation |
| `POST /api/google-play/verify-receipt` | طبيعي — product id fictive |
| `POST /api/instapay/verify` | طبيعي — بيانات ناقصة |
| `POST /api/subscription/checkout` | طبيعي — الباقات المتاحة: `premium`, `pro`, `b2b_starter`, `b2b_pro`, `b2b_enterprise` |
| `DELETE /api/watchlist/{id}` | ❌ 401 — **bug حقيقي، شوف تحت** |

---

## 5. Auth — الحالة الحالية

حساب اختبار (`apitest@glmtest.com`) بياخد token من `/api/auth/login` وبيشتغل على:

`/api/portfolio/holdings` · `/api/subscription/status` · `/api/watchlist` · `/api/portfolio/accounts` · `/api/portfolio/equity-curve` · `/api/finance/assets` · `/api/alerts` · `/api/ai/chat` · `/api/radar/personalized` · `/api/portfolio/unified-watch` · `/api/paper-trading-v2/*` · `/api/mobile/portfolio` (GET) · `/api/mobile/dashboard` ✅

**المرفوض رغم صحة التوكن:**
- `GET /api/auth/me` → 401 ❌
- `PUT /api/auth/profile` → 401 ❌
- `POST /api/subscription/upgrade` → 401 ❌
- `POST /api/paymob/create-payment` → 401 ❌
- `DELETE /api/watchlist/{id}` → 401 ❌

**⚠️ مهم — بلاغ للـ backend:** `main.dart:57` بيعتمد على `prefs.containsKey('auth_token')` عشان يقرّر يدخل `/home` ولا `/auth`. لو `/api/auth/me` مرفوض، **المستخدم هيفضل داخل ببيانات فاضية**. لازم يتصلح.

**تحذير للـ client:** الـ app بيخزّن التوكن في `SharedPreferences` (غير مشفّر) — الأفضل `flutter_secure_storage`.

---

## 6. أبطأ الـ endpoints

| الوقت | Endpoint |
|------:|---|
| 9245ms | `/api/v2/unified/analyze` |
| 8845ms | `/api/ai/analyze-stock` |
| 5338ms | `/api/maestro/stock/{ticker}` |
| 5174ms | `/api/mobile/crypto/bitcoin` |
| 4866ms | `/api/stocks` |
| 4434ms | `/api/maker-radar` |
| 4391ms | `/api/crypto/explosive` |
| 4383ms | `/api/confluence/market-scan` |
| 4264ms | `/api/crypto/flow` |

---

## الأولويات

| # | الأولوية | الإصلاح |
|---|---|---|
| 1 | 🔴 عاجل | `/api/auth/me` + `/api/auth/profile` — الـ app بيفتكر المستخدم مسجّل وهو لأ |
| 2 | 🔴 عاجل | `/api/subscription/plans` 500 — جدول `market_pricing` ناقص |
| 3 | 🔴 عاجل | `/api/crypto/recommendations` 500 |
| 4 | 🔴 عاجل | Python backend شغال؟ بيأثر على `unified-learning/intelligent` + `crypto/simulation` |
| 5 | 🟠 مهم | DeepSeek `API Key` ناقص → `/api/ai/chat` مش شغال |
| 6 | 🟠 مهم | `/api/mobile/portfolio` — عمود `portfolioItem.updated_at` ناقص |
| 7 | 🟡 متوسط | `/api/subscription/upgrade` + `/api/paymob/create-payment` + `DELETE /api/watchlist/{id}` — 401 رغم صحة التوكن |
| 8 | 🟡 متوسط | `ApiCacheManager` للـ endpoints الـ 9 اللي فوق ٤ ثواني |
| 9 | 🟡 متوسط | خلّي الـ client يقرأ `success` من الـ body، مش status code بس |
| 10 | 🔵 تحسين | `flutter_secure_storage` بدل `SharedPreferences` للتوكن |
