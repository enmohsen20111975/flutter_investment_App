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
    _initGoogleSignIn();
  }

  void _initGoogleSignIn() {
    final config = GoogleAuthConfig.webClientId;
    debugPrint('[Auth] Initializing Google Sign-In with client ID: ${config.isNotEmpty ? "configured" : "NOT SET"}');
    
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
    setState(() { _isLoading = true; _error = null; _success = null; });

    try {
      debugPrint('[Auth] Starting Google Sign-In...');
      
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[Auth] User cancelled Google Sign-In');
        setState(() { _isLoading = false; _error = 'تم إلغاء عملية تسجيل الدخول'; });
        return;
      }

      debugPrint('[Auth] Google user: ${googleUser.email}');
      
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      
      debugPrint('[Auth] ID Token: ${idToken != null ? "received (${idToken.length} chars)" : "NULL"}');
      debugPrint('[Auth] Access Token: ${accessToken != null ? "received" : "NULL"}');
      
      if (idToken == null) {
        debugPrint('[Auth] No ID token received from Google');
        setState(() { 
          _isLoading = false; 
          _error = 'لم يتم الحصول على رمز التوثيق من Google. تأكد من إعداد OAuth بشكل صحيح.'; 
        });
        return;
      }

      debugPrint('[Auth] Sending ID token to backend...');
      final result = await api.googleLogin(idToken);
      
      debugPrint('[Auth] Backend response: success=${result.success}, token=${result.token != null ? "received" : "null"}');
      
      if (result.success && result.token != null) {
        debugPrint('[Auth] Login successful!');
        // Token and user are already saved in api.googleLogin()
        
        final needsPhone = result.user?.phone == null;
        if (needsPhone) {
          setState(() { _isLoading = false; });
          if (mounted) {
            final phone = await _showPhoneDialog(result.user?.name ?? result.user?.email ?? '');
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          }
        } else {
          setState(() { _success = result.messageAr ?? result.message; _isLoading = false; });
          if (mounted) Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        debugPrint('[Auth] Login failed: ${result.message}');
        setState(() { 
          _error = result.messageAr ?? result.message ?? 'فشل تسجيل الدخول'; 
          _isLoading = false; 
        });
      }
    } on GoogleSignInAccountNotFoundException catch (e) {
      debugPrint('[Auth] Account not found: $e');
      setState(() {
        _error = 'لم يتم العثور على حساب Google';
        _isLoading = false;
      });
    } on GoogleSignInCanceledException catch (e) {
      debugPrint('[Auth] Sign-in cancelled: $e');
      setState(() {
        _error = 'تم إلغاء عملية تسجيل الدخول';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[Auth] Unexpected error: $e');
      setState(() {
        final errorStr = e.toString();
        if (errorStr.contains('NOT_FOUND') || errorStr.contains('sign_in_canceled')) {
          _error = 'تم إلغاء عملية تسجيل الدخول';
        } else if (errorStr.contains('network') || errorStr.contains('SocketException')) {
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
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_success != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_success!, style: const TextStyle(color: AppColors.success, fontSize: 13))),
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
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                          : Image.asset(
                              'assets/image/google_logo.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (ctx, error, trace) => const Icon(Icons.login, color: AppColors.white, size: 20),
                            ),
                      label: Text(
                        _isLoading ? 'جاري تسجيل الدخول...' : 'الدخول بواسطة Google',
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.google,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                    child: const Text('تخطي وتصفح كزائر', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
