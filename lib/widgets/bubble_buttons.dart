// ============================================================================
// Bubble-style Floating Action Buttons and Scrolling Action Buttons
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';

class BubbleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isActive;

  const BubbleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    final fg = foregroundColor ?? AppColors.white;

    return Material(
      color: isActive ? bg : bg.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? bg.withValues(alpha: 0.9) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: bg.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isActive ? fg : bg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? fg : bg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BubbleFloatingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final bool extended;

  const BubbleFloatingButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!extended) {
      return FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(icon, color: AppColors.white),
      );
    }

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? AppColors.primary,
      icon: Icon(icon, color: AppColors.white),
      label: Text(label, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
    );
  }
}

class BubbleActionMenu extends StatelessWidget {
  final List<BubbleMenuItem> items;
  final double spacing;
  final Axis direction;

  const BubbleActionMenu({
    super.key,
    required this.items,
    this.spacing = 8,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final children = items.map((item) => BubbleButton(
      icon: item.icon,
      label: item.label,
      onPressed: item.onPressed,
      backgroundColor: item.backgroundColor,
      isActive: item.isActive,
    )).toList();

    if (direction == Axis.horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: children.map((c) => Padding(
            padding: EdgeInsets.only(left: spacing),
            child: c,
          )).toList(),
        ),
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: children,
    );
  }
}

class BubbleMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final bool isActive;

  BubbleMenuItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.isActive = false,
  });
}

class FloatingActionBubble extends StatefulWidget {
  final List<FloatingBubbleItem> items;
  final IconData mainIcon;
  final Color? mainColor;

  const FloatingActionBubble({
    super.key,
    required this.items,
    this.mainIcon = Icons.add,
    this.mainColor,
  });

  @override
  State<FloatingActionBubble> createState() => _FloatingActionBubbleState();
}

class FloatingBubbleItem {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  FloatingBubbleItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });
}

class _FloatingActionBubbleState extends State<FloatingActionBubble> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_isOpen)
          GestureDetector(
            onTap: _toggle,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) => Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(opacity: _scaleAnimation.value, child: child),
              ),
              child: Container(
                color: Colors.black54,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
          ),
        ..._buildItemButtons(),
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: widget.mainColor ?? AppColors.primary,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(widget.mainIcon, color: AppColors.white),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildItemButtons() {
    final buttons = <Widget>[];
    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final animation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0, 0.5 + (i * 0.1)),
        ),
      );

      buttons.add(
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Transform.scale(
            scale: animation.value,
            alignment: Alignment.bottomRight,
            child: Opacity(opacity: animation.value, child: child),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: (i + 1) * 60.0),
            child: FloatingActionButton.extended(
              onPressed: () {
                _toggle();
                item.onPressed();
              },
              backgroundColor: item.color ?? AppColors.surfaceDark,
              icon: Icon(item.icon, color: AppColors.primary),
              label: Text(item.label, style: const TextStyle(color: AppColors.text)),
            ),
          ),
        ),
      );
    }
    return buttons.reversed.toList();
  }
}