// ============================================================================
// مساعد الاستثمار Flutter - Fun Widgets Library
// TikTok/Game-like UI components with animations and effects
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../theme/colors.dart';

class FunUtils {
  static Color getChangeColor(double? change) {
    if (change == null) return AppColors.textMuted;
    if (change > 0) return AppColors.success;
    if (change < 0) return AppColors.danger;
    return AppColors.textMuted;
  }

  static String getChangeEmoji(double? change) {
    if (change == null) return '➡️';
    if (change > 0) return '🚀';
    if (change < 0) return '📉';
    return '➡️';
  }

  static IconData getChangeIcon(double? change) {
    if (change == null) return Icons.remove;
    if (change > 0) return Icons.rocket_launch;
    if (change < 0) return Icons.trending_down;
    return Icons.remove;
  }

  static Widget buildConfetti() {
    final controller = ConfettiController(duration: const Duration(seconds: 3));
    return ConfettiWidget(
      confettiController: controller,
      blastDirectionality: BlastDirectionality.explosive,
      particleDrag: 0.05,
      emissionFrequency: 0.05,
      minBlastForce: 20,
      maxBlastForce: 60,
      gravity: 0.3,
      shouldLoop: false,
      colors: const [
        AppColors.primaryGlow,
        AppColors.secondary,
        AppColors.accent,
        AppColors.neonCyan,
        AppColors.neonLime,
        AppColors.neonYellow,
      ],
    );
  }
}

class FunCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool hasGlow;
  final Gradient? gradient;

  const FunCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.hasGlow = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.gradientCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primaryMuted,
          highlightColor: AppColors.primaryMuted,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      card = card.animate().fadeIn(duration: 400.ms, curve: Curves.easeOut);
    }

    return card;
  }
}

class FunButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isOutlined;
  final bool hasGlow;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const FunButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isOutlined = false,
    this.hasGlow = true,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final txtColor = textColor ?? AppColors.white;

    Widget button = Container(
      width: width,
      decoration: BoxDecoration(
        color: isOutlined ? null : (backgroundColor ?? AppColors.primary),
        gradient: isOutlined ? null : null,
        borderRadius: BorderRadius.circular(16),
        border: isOutlined ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: hasGlow && !isOutlined
            ? [
                BoxShadow(
                  color: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: isOutlined ? Colors.transparent : Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primaryMuted,
          highlightColor: AppColors.primaryMuted,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: txtColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: txtColor,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return button;
  }
}

class FunSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onSeeAll;
  final Color? iconColor;

  const FunSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.onSeeAll,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryMuted,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'عرض الكل',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontFamily: 'Cairo',
              ),
            ),
          ),
      ],
    );
  }
}

class FunBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const FunBadge({
    super.key,
    required this.text,
    this.color = AppColors.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class FunLoadingIndicator extends StatelessWidget {
  final String? message;

  const FunLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGlow),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
            duration: 1500.ms,
            color: AppColors.primaryLight.withValues(alpha: 0.3),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FunEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryText;

  const FunEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox,
    this.onRetry,
    this.retryText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, size: 48, color: AppColors.textMuted),
          ).animate().scale(
            duration: 600.ms,
            curve: Curves.elasticOut,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FunButton(
              text: retryText ?? 'حاول مرة أخرى',
              icon: Icons.refresh,
              onPressed: onRetry,
              backgroundColor: AppColors.primary,
              hasGlow: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class FunErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const FunErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.gradientDanger,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.danger.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.error_outline, size: 48, color: AppColors.white),
          ).animate().shake(duration: 800.ms, hz: 3),
          const SizedBox(height: 20),
          Text(
            'Oops! حدث خطأ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.danger,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            FunButton(
              text: 'إعادة المحاولة',
              icon: Icons.refresh,
              onPressed: onRetry,
              backgroundColor: AppColors.danger,
              hasGlow: true,
            ),
          ],
        ],
      ),
    );
  }
}

class PulseDot extends StatefulWidget {
  final Color? color;
  final double size;

  const PulseDot({super.key, this.color = AppColors.success, this.size = 12});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color ?? AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (widget.color ?? AppColors.success).withValues(alpha: 0.6),
                  blurRadius: (_animation.value * 8).clamp(4.0, 20.0),
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShimmerLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 16,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    ).animate().shimmer(
      duration: 1500.ms,
      color: AppColors.surfaceHover.withValues(alpha: 0.5),
    );
  }
}

class TickerTape extends StatelessWidget {
  final List<Map<String, dynamic>> tickers;
  final Color? upColor;
  final Color? downColor;

  const TickerTape({
    super.key,
    required this.tickers,
    this.upColor,
    this.downColor,
  });

  @override
  Widget build(BuildContext context) {
    final items = tickers.map((t) {
      final change = (t['change'] as num?)?.toDouble() ?? 0;
      final isUp = change >= 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: isUp
              ? AppColors.success.withValues(alpha: 0.15)
              : AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUp
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.danger.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t['name'] ?? '',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${t['price'] ?? '0'}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUp
                    ? (upColor ?? AppColors.success)
                    : (downColor ?? AppColors.danger),
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isUp ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12,
              color: isUp
                  ? (upColor ?? AppColors.success)
                  : (downColor ?? AppColors.danger),
            ),
          ],
        ),
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: items),
    );
  }
}

class FunBottomNavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  FunBottomNavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

class FunBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FunBottomNavItem> items;

  const FunBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1025), Color(0xFF281A3A)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedItemColor: AppColors.primaryGlow,
          unselectedItemColor: AppColors.textMuted,
          items: items.map((item) {
            final isActive = items.indexOf(item) == currentIndex;
            return BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isActive ? item.activeIcon : item.inactiveIcon,
                  size: 24,
                ),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class FunFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? backgroundColor;

  const FunFloatingActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor ?? AppColors.primary,
            (backgroundColor ?? AppColors.primary).withValues(alpha: 0.8),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.6),
            blurRadius: 25,
            spreadRadius: 3,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: Icon(icon, size: 28, color: AppColors.white),
      ),
    );
  }
}

class GlowText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final double glowRadius;
  final TextAlign? textAlign;

  const GlowText({
    super.key,
    required this.text,
    this.fontSize = 24,
    this.fontWeight = FontWeight.w800,
    this.color = AppColors.primary,
    this.glowRadius = 12,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          color,
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
          fontFamily: 'Cairo',
          shadows: [
            Shadow(
              color: color.withValues(alpha: 0.8),
              blurRadius: glowRadius,
            ),
            Shadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: glowRadius * 0.5,
            ),
          ],
        ),
        textAlign: textAlign,
      ),
    );
  }
}

class ParticleBackground extends StatelessWidget {
  final Widget child;
  final int particleCount;

  const ParticleBackground({
    super.key,
    required this.child,
    this.particleCount = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.gradientDark,
          ),
        ),
        if (particleCount > 0)
          ...List.generate(particleCount, (i) {
            final x = (i * 137.508) % 1.0;
            final y = (i * 89.5) % 1.0;
            final size = 2.0 + (i % 3);
            final colors = [
              AppColors.primary.withValues(alpha: 0.3),
              AppColors.secondary.withValues(alpha: 0.3),
              AppColors.neonCyan.withValues(alpha: 0.2),
              AppColors.accent.withValues(alpha: 0.2),
            ];
            final color = colors[i % colors.length];
            return Positioned(
              left: x * MediaQuery.of(context).size.width,
              top: y * MediaQuery.of(context).size.height,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              ).fadeIn(duration: (1000 + i * 100).ms).fadeOut(
                duration: (1000 + i * 100).ms,
              ),
            );
          }),
        child,
      ],
    );
  }
}

class WaveDivider extends StatelessWidget {
  final Color color;
  final double height;

  const WaveDivider({
    super.key,
    this.color = AppColors.primary,
    this.height = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _WavePainter(color: color),
        size: Size(MediaQuery.of(context).size.width, height),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;

  _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    
    for (double x = 0; x <= size.width; x += 5) {
      final y = size.height * 0.5 + 
                 sin(x * 0.02) * 5 + 
                 sin(x * 0.05 + 1) * 3;
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

double sin(double x) => (x % (2 * 3.14159265359)) < 3.14159265359
    ? 4 * ((x % (2 * 3.14159265359)) / 3.14159265359) * (1 - (x % (2 * 3.14159265359)) / 3.14159265359)
    : -4 * ((x % (2 * 3.14159265359)) / 3.14159265359 - 2) * (1 - (x % (2 * 3.14159265359)) / 3.14159265359 + 2);

class HeroAnimated extends StatelessWidget {
  final Widget child;
  final String tag;

  const HeroAnimated({
    super.key,
    required this.child,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}

class FunAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onMenuTap;
  final bool transparent;
  final double elevation;

  const FunAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onMenuTap,
    this.transparent = false,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: preferredSize.height,
      decoration: BoxDecoration(
        gradient: transparent
            ? null
            : const LinearGradient(
                colors: [AppColors.surface, AppColors.surfaceMuted],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: transparent ? Colors.transparent : null,
        elevation: elevation,
        centerTitle: true,
        leading: onMenuTap != null
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: onMenuTap,
                  icon: const Icon(Icons.menu, color: AppColors.text),
                ),
              )
            : null,
        title: GlowText(
          text: title,
          fontSize: 20,
          color: AppColors.text,
          glowRadius: 8,
        ),
        actions: actions,
      ),
    );
  }
}

class FunSkeletonCard extends StatelessWidget {
  final double height;

  const FunSkeletonCard({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppColors.gradientCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ShimmerLoader(width: 44, height: 44, borderRadius: BorderRadius.circular(12)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerLoader(height: 16, width: 120),
                  const SizedBox(height: 8),
                  ShimmerLoader(height: 12, width: 80),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerLoader(height: 16, width: 60),
                const SizedBox(height: 8),
                ShimmerLoader(height: 12, width: 40),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
