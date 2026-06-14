# 📋 قائمة التحقق والتحقق النهائي لتطبيق مساعد الاستثمار

هذه قائمة المهام التفصيلية لتأكيد دمج كافة الميزات والـ APIs والتأكد من استقرار تطبيق الهاتف وحل الأخطاء. يمكنك استخدامها كدليل خطوة بخطوة للتحقق من الميزات.

---

## 🛠️ أولاً: التحقق من الأكواد وبناء التطبيق
- `[x]` إزالة التكرار الخاص بدوال الذهب والمعادن في عميل الـ API الموحد [client.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/api/client.dart).
- `[x]` إجراء فحص برمجى تلقائي للتطبيق عبر مفسر الأكواد لـ Flutter لضمان عدم وجود أخطاء تمنع البناء.
  - *النتيجة*: تم التحقق والتأكد من خلو المشروع تماماً من أي خطأ بناء (0 errors).

---

## 🧭 ثانياً: التحقق من شريط التطبيق والتنقل (Navigation & AppBar)
- `[ ]` التحقق من منتقي الأسواق (Market Selector) في الشريط العلوي (AppBar) لـ [app.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/app.dart):
  - `[ ]` تشغيل التطبيق والتحقق من ظهور زر التبديل بين الأسواق في الـ AppBar.
  - `[ ]` التأكد من أن التبديل يقوم بحفظ تفضيل السوق نشطاً في الـ `SharedPreferences` تحت الاسم `active_market`.
- `[ ]` التحقق من القائمة الجانبية (Drawer):
  - `[ ]` فتح القائمة والتحقق من إدراج قسم "الذهب والمعادن" ونقله إلى شاشة [metals_screen.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/screens/metals_screen.dart).
  - `[ ]` التحقق من وجود خيار "التعلم واختبار الاستراتيجيات" ونقله إلى شاشة [learning_backtest_screen.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/screens/learning_backtest_screen.dart).

---

## 📊 ثالثاً: التحقق من الشاشات الأساسية ومطابقة الموقع
- `[ ]` شاشة لوحة التحكم ([dashboard_screen.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/screens/dashboard_screen.dart)):
  - `[ ]` التأكد من أن لوحة التحكم تعيد قراءة السوق المختار من التفضيلات تلقائياً عند التبديل وتحدث قيم الأسعار والمؤشرات.
- `[ ]` شاشة الذهب والمعادن ([metals_screen.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/screens/metals_screen.dart)):
  - `[ ]` التحقق من جلب أسعار عيارات الذهب والفضة والتحميل التلقائي للمخطط البياني التاريخي.
  - `[ ]` اختبار حاسبة أسعار الذهب عبر إدخال أوزان مختلفة وتأكيد دقة الاحتساب بناءً على السعر الحالي للجرام.
- `[ ]` شاشة اختبار الاستراتيجيات والتعلم ([learning_backtest_screen.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/screens/learning_backtest_screen.dart)):
  - `[ ]` اختبار تشغيل الـ Backtest الافتراضي والتأكد من إظهار مؤشر الانتظار الدائري ثم رسم بطاقات النتائج الإجمالية والصفقات الفردية.
  - `[ ]` استعراض تبويب "التعلم الذاتي للـ AI" والتحقق من ظهور مستويات الثقة للمؤشرات الفنية المأخوذة من الـ API بنجاح.
- `[ ]` شاشة المحفظة المتقدمة ([portfolio_screen.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/screens/portfolio_screen.dart)):
  - `[ ]` إضافة أصول مختلفة (أسهم، عملات رقمية، ذهب) والتأكد من إدراجها وحفظها محلياً أو بالخادم.
  - `[ ]` التحقق من ظهور المخطط الدائري (Pie Chart) لتوزيع الأصول بمظهر نيون متميز بناءً على تحليل المحفظة.
- `[ ]` شاشة قائمة المراقبة والتنبيهات ([watchlist_screen.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/screens/watchlist_screen.dart)):
  - `[ ]` التحقق من فرز القائمة بشكل تلقائي حسب نوع الأصول.
  - `[ ]` تفعيل منبهات السعر (Price Alerts) والتأكد من ظهورها وتخزينها بالشكل السليم.

---

## 💳 رابعاً: التحقق من بوابات الدفع والتسجيل الأول
- `[ ]` شاشة الاشتراكات والترقيات ([subscription_screen.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/screens/subscription_screen.dart)):
  - `[ ]` اختيار الترقية إلى باقة متميزة وتجربة فتح اللوح السفلي للدفع (Payment Bottom Sheet).
  - `[ ]` تجربة اختيار خيار الدفع بـ PayMob والتحقق من فتح الـ WebView بالرابط المخصص.
  - `[ ]` تجربة الدفع بـ InstaPay وكتابة رقم وهمي، ثم الضغط على تأكيد والتحقق من استجابة النظام بنجاح للتأكيد اليدوي.
- `[ ]` التحقق من عملية التسجيل لأول مرة ([auth_screen.dart](file:///d:/My%20WebStie%20Applications/Flutter/investment/lib/screens/auth_screen.dart)):
  - `[ ]` اختبار تسجيل الدخول عبر Google للتحقق من ظهور نافذة تطلب رقم الهاتف في حال كان غير مسجل مسبقاً بالخادم، وقبول التحديث وتخزينه.
