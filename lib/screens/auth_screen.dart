import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/colors.dart';
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
    _initGoogleSignIn();
  }

  void _initGoogleSignIn() {
    const config = GoogleAuthConfig.webClientId;
    debugPrint(
        '[Auth] Initializing Google Sign-In with client ID: ${config.isNotEmpty ? "configured" : "NOT SET"}');

    if (config.isNotEmpty) {
      _googleSignIn = GoogleSignIn(
        scopes: <String>['email', 'profile'],
        serverClientId: config,
      );
    } else {
      _googleSignIn = GoogleSignIn(scopes: <String>['email', 'profile']);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      debugPrint('[Auth] Starting Google Sign-In...');

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[Auth] User cancelled Google Sign-In');
        setState(() {
          _isLoading = false;
          _error = 'تم إلغاء عملية تسجيل الدخول';
        });
        return;
      }

      debugPrint('[Auth] Google user: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      debugPrint(
          '[Auth] ID Token: ${idToken != null ? "received (${idToken.length} chars)" : "NULL"}');
      debugPrint(
          '[Auth] Access Token: ${accessToken != null ? "received" : "NULL"}');

      if (idToken == null) {
        debugPrint('[Auth] No ID token received from Google');
        setState(() {
          _isLoading = false;
          _error =
              'لم يتم الحصول على رمز التوثيق من Google. تأكد من إعداد OAuth بشكل صحيح.';
        });
        return;
      }

      debugPrint('[Auth] Sending ID token to backend...');
      final result = await api.googleLogin(idToken);

      debugPrint(
          '[Auth] Backend response: success=${result.success}, token=${result.token != null ? "received" : "null"}');

      if (result.success && result.token != null) {
        debugPrint('[Auth] Login successful!');
        if (mounted) {
          final user = result.user;
          final isNewUser = result.isNewUser == true ||
              user?.phone == null ||
              user!.phone!.isEmpty;
          if (isNewUser) {
            _showPhoneInputDialog(context);
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        debugPrint('[Auth] Login failed: ${result.message}');
        setState(() {
          _error = result.messageAr ?? result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Auth] Unexpected error: $e');
      setState(() {
        final errorStr = e.toString();
        if (errorStr.contains('NOT_FOUND') ||
            errorStr.contains('sign_in_canceled')) {
          _error = 'تم إلغاء عملية تسجيل الدخول';
        } else if (errorStr.contains('network') ||
            errorStr.contains('SocketException')) {
          _error = 'خطأ في الاتصال. تحقق من اتصال الإنترنت.';
        } else if (errorStr.contains('timeout')) {
          _error = 'انتهت مهلة الاتصال. حاول مرة أخرى.';
        } else {
          _error = 'فشل تسجيل الدخول بواسطة Google: $errorStr';
        }
        _isLoading = false;
      });
    }
  }

  void _showPhoneInputDialog(BuildContext context) {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('أهلاً بك في مساعد الاستثمار',
                style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لإكمال عملية التسجيل وتأمين حسابك، يرجى إدخال رقم هاتفك المحمول:',
                  style:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف المحمول',
                    hintText: 'مثال: 01012345678',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(this.context).pushReplacementNamed('/home');
                },
                child: const Text('تخطي الآن'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final phone = phoneCtrl.text.trim();
                  if (phone.isEmpty) return;
                  Navigator.pop(context);

                  setState(() {
                    _isLoading = true;
                  });
                  try {
                    await api.updateProfile(phone: phone);
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                            content: Text('تم حفظ رقم الهاتف بنجاح!'),
                            backgroundColor: AppColors.success),
                      );
                      Navigator.of(this.context).pushReplacementNamed('/home');
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                            content: Text('حدث خطأ أثناء حفظ الهاتف: $e'),
                            backgroundColor: AppColors.danger),
                      );
                      Navigator.of(this.context).pushReplacementNamed('/home');
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                child: const Text('حفظ ومتابعة'),
              ),
            ],
          ),
        );
      },
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
                      gradient: LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.login,
                        color: AppColors.white, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text('مساعد الاستثمار',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  const SizedBox(height: 8),
                  const Text('سجل الدخول باستخدام حساب Google الخاص بك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppColors.danger, fontSize: 13))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_success != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_success!,
                                  style: const TextStyle(
                                      color: AppColors.success, fontSize: 13))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleLogin,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: AppColors.white, strokeWidth: 2))
                          : Image.asset(
                              'assets/image/google_logo.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (ctx, error, trace) => const Icon(
                                  Icons.login,
                                  color: AppColors.white,
                                  size: 20),
                            ),
                      label: Text(
                        _isLoading
                            ? 'جاري تسجيل الدخول...'
                            : 'الدخول بواسطة Google',
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.google,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/home'),
                    child: const Text('تخطي وتصفح كزائر',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
