import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../config/google_auth_config.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  String? _error;
  String? _success;

  late final GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    final config = GoogleAuthConfig.webClientId;
    if (config.isNotEmpty) {
      _googleSignIn = GoogleSignIn(scopes: <String>['email'], serverClientId: config);
    } else {
      _googleSignIn = GoogleSignIn(scopes: <String>['email', 'profile']);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() { _isLoading = true; _error = null; _success = null; });

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() { _isLoading = false; _error = 'تم إلغاء عملية تسجيل الدخول'; });
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('لم يتم الحصول على رمز التوثيق من Google.');
      }

      final result = await api.googleLogin(idToken);
      if (result.success && result.token != null) {
        await api.saveToken(result.token!);
        if (result.user != null) await api.saveUser(result.user!);

        final needsPhone = result.user?.phone == null;
        if (needsPhone) {
          setState(() { _isLoading = false; });
          if (mounted) {
            final phone = await _showPhoneDialog(result.user?.name ?? result.user?.email ?? '');
            if (phone != null && mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            } else if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          }
        } else {
          setState(() { _success = result.messageAr ?? result.message; _isLoading = false; });
          if (mounted) Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        setState(() { _error = result.messageAr ?? result.message ?? 'فشل تسجيل الدخول'; _isLoading = false; });
      }
    } catch (e) {
      setState(() {
        if (e.toString().contains('NOT_FOUND') || e.toString().contains('sign_in_canceled')) {
          _error = 'تم إلغاء عملية تسجيل الدخول';
        } else if (e.toString().contains('network') || e.toString().contains('SocketException')) {
          _error = 'خطأ في الاتصال. تحقق من اتصال الإنترنت.';
        } else {
          _error = 'فشل تسجيل الدخول بواسطة Google. حاول مرة أخرى.';
        }
        _isLoading = false;
      });
    }
  }

  Future<String?> _showPhoneDialog(String userName) async {
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              const Icon(Icons.phone_android, color: AppColors.primary, size: 40),
              const SizedBox(height: 12),
              Text('مرحباً $userName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('أدخل رقم هاتفك لإكمال التسجيل', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '01XXXXXXXXX',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('+20', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                      const SizedBox(width: 4),
                      Container(width: 1, height: 24, color: AppColors.border),
                    ],
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 60),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary, width: 2)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى إدخال رقم الهاتف';
                final clean = v.replaceAll(RegExp(r'[\s\-]'), '');
                if (clean.length < 11) return 'رقم الهاتف غير صحيح';
                return null;
              },
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx, phoneCtrl.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('متابعة', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('تخطي', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.login, color: AppColors.white, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text('مساعد الاستثمار', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 8),
                  const Text('سجل الدخول باستخدام حساب Google الخاص بك', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(12)),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_success != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)),
                      child: Text(_success!, style: const TextStyle(color: AppColors.success, fontSize: 13)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleLogin,
                      icon: _isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                          : const Icon(Icons.login, color: AppColors.white, size: 20),
                      label: Text(
                        _isLoading ? 'جاري تسجيل الدخول بواسطة Google...' : 'الدخول بواسطة Google',
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.google,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
