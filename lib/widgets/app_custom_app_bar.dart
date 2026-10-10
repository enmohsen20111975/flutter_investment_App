// ============================================================================
// مساعد الاستثمار Flutter - Reusable App Custom AppBar
// ===============================================================================
//
// NAV-FIX (2026-10-10): حل مشكلة احتجاز المستخدم في الشاشات
//
// القاعدة الذهبية: كل شاشة تفحص تلقائياً:
//   - لو شاشة فرعية (Navigator.canPop == true) → يظهر زر الرجوع
//   - لو شاشة رئيسية (لا يمكن الرجوع) → يظهر زر القائمة الجانبية (Drawer)
//
// الاستخدام:
//   appBar: AppCustomAppBar(title: 'اسم الشاشة')
//
// مع actions إضافية:
//   appBar: AppCustomAppBar(
//     title: 'التقارير',
//     actions: [IconButton(...)],
//   )
// ===============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AppCustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final bool centerTitle;

  const AppCustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.backgroundColor,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.surface,
      elevation: 0,
      centerTitle: centerTitle,
      // القاعدة الذهبية: لو canPop → زر رجوع، غير كده → زر Drawer
      leading: leading ??
          (canPop
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.text,
                    size: 20,
                  ),
                  tooltip: 'رجوع',
                  onPressed: () => Navigator.maybePop(context),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.text,
                    size: 24,
                  ),
                  tooltip: 'القائمة الرئيسية',
                  onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
                )),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: AppColors.text,
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
