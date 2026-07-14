// ============================================================================
// مساعد الاستثمار Flutter - Force Update Screen
// Blocking screen shown when the installed app version is too old
// ============================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../services/version_service.dart';

class ForceUpdateScreen extends StatelessWidget {
  final VersionCheckResult result;

  const ForceUpdateScreen({super.key, required this.result});

  Future<void> _openStore(BuildContext context) async {
    final url = Uri.parse(result.storeUrl ??
        'https://play.google.com/store/apps/details?id=com.egx.investment');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try forcing external launch
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[ForceUpdate] Failed to open store: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = result.messageAr ??
        result.message ??
        'يرجى تحديث التطبيق إلى أحدث إصدار للمتابعة.';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      color: AppColors.white,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'تحديث مطلوب',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.6,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Version info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _versionRow('الإصدار الحالي', result.currentVersion),
                        const Divider(height: 24),
                        _versionRow(
                            'الإصدار المطلوب', result.minRequiredVersion),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Update button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _openStore(context),
                      icon: const Icon(Icons.download_rounded,
                          color: AppColors.white, size: 22),
                      label: const Text(
                        'تحديث الآن',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Retry button (in case user updated and reopens without
                  // killing the app)
                  TextButton.icon(
                    onPressed: () {
                      // Restart-friendly: just relaunch via popping to root
                      // The real re-check happens on next full launch.
                      Navigator.of(context).maybePop();
                    },
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.textMuted, size: 18),
                    label: const Text(
                      'أحدثت بالفعل - إعادة التحقق',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _versionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}
