
📱 توثيق Google Sign-In للموبايل (Flutter)
Endpoint
text

POST https://invist.m2y.net/api/auth/google
الخطوات في Flutter:
1️⃣ تثبيت الحزم المطلوبة
yaml

# pubspec.yaml
dependencies:
  google_sign_in: ^6.2.1
  http: ^1.1.0
2️⃣ إعداد Google Sign-In
dart

import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  // استخدم Web Client ID من Google Console
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);
3️⃣ دالة تسجيل الدخول
dart

import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> signInWithGoogle() async {
  try {
    // 1. تسجيل الدخول عبر Google
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) return null; // المستخدم ألغى

    // 2. الحصول على id_token
    final GoogleSignInAuthentication auth = await account.authentication;
    final String? idToken = auth.idToken;
    
    if (idToken == null) {
      print('Error: id_token is null');
      return null;
    }

    // 3. إرسال id_token للـ Backend
    final response = await http.post(
      Uri.parse('https://invist.m2y.net/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': data['success'],
        'token': data['token'],           // احفظ هذا التوكن
        'user': data['user'],             // بيانات المستخدم
        'is_new_user': data['is_new_user'],
      };
    } else {
      print('Error: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Exception: $e');
    return null;
  }
}
📤 Request
json

{
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6..."
}
📥 Response (نجاح)
json

{
  "success": true,
  "message": "Google login successful",
  "message_ar": "تم تسجيل الدخول عبر جوجل بنجاح",
  "user": {
    "id": "uuid",
    "email": "user@gmail.com",
    "username": "username",
    "name": "الاسم الكامل",
    "image": "https://...",
    "subscription_tier": "free",
    "is_admin": false
  },
  "token": "egx_uuid_token_timestamp",
  "token_type": "Bearer",
  "expires_in": 2592000,
  "is_new_user": false
}
❌ Response (خطأ)
json

{
  "success": false,
  "error": "فشل التحقق من Google token",
  "error_en": "Invalid Google token"
}
🔐 استخدام التوكن في الطلبات اللاحقة
dart

// حفظ التوكن محلياً
final token = data['token'];
// استخدمه في كل طلب
final response = await http.get(
  Uri.parse('https://invist.m2y.net/api/stocks'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
);
📝 ملاحظات مهمة:
Web Client ID: استخدم نفس Client ID الموجود في الموقع
SHA-1: إذا واجهت مشكلة في Android، أضف SHA-1 للتطبيق في Google Console
مدة صلاحية التوكن: 30 يوم
is_new_user: true إذا كان مستخدم جديد، false إذا موجود مسبقاً
