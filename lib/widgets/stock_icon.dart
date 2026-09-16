// ============================================================================
// مساعد Investment Flutter - Stock Icon Widget
// ============================================================================

import 'package:flutter/material.dart';
import '../models/stock.dart';

/// رموزsectors المstileة كfallback عند عدم وجود أيقونة صورة
String getSectorIcon(String? sector) {
  final s = (sector ?? '').toLowerCase();
  if (s.contains('financial') || s.contains('bank') || s.contains('بنك')) return '🏦';
  if (s.contains('real estate') || s.contains('عقار') || s.contains('property')) return '🏢';
  if (s.contains('basic materials') || s.contains('mining') || s.contains('تعدين')) return '⛏️';
  if (s.contains('consumer') || s.contains('food') || s.contains('retail') || s.contains('استهلاك')) return '🛒';
  if (s.contains('healthcare') || s.contains('pharma') || s.contains(' Pharma') || s.contains('صحة')) return '💊';
  if (s.contains('technology') || s.contains('telecom') || s.contains(' Divide') || s.contains('تقني')) return '💻';
  if (s.contains('energy') || s.contains('oil') || s.contains('طاقة')) return '⛽';
  if (s.contains('industrials') || s.contains('manufacturing') || s.contains('صناعي')) return '🏭';
  if (s.contains('construction') || s.contains('building') || s.contains('بناء')) return '🏗️';
  if (s.contains('crypto') || s.contains('digital')) return '₿';
  if (s.contains('utilities')) return '💡';
  if (s.contains('communication') || s.contains('media') || s.contains('إعلام')) return '📡';
  if (s.contains('automotive') || s.contains('auto')) return '🚗';
  if (s.contains('travel') || s.contains('tourism') || s.contains('سياحة')) return '✈️';
  if (s.contains('agriculture') || s.contains('farming') || s.contains('زراعة')) return '🌾';
  return '📈';
}

class StockIcon extends StatefulWidget {
  final Stock? stock;
  final String? ticker;
  final String? name;
  final String? nameAr;
  final String? sector;
  final String? iconUrl;
  final double? size;
  final double iconSize;
  final bool showFallback;

  const StockIcon({
    super.key,
    this.stock,
    this.ticker,
    this.name,
    this.nameAr,
    this.sector,
    this.iconUrl,
    this.size = 44,
    this.iconSize = 24,
    this.showFallback = true,
  });

  @override
  State<StockIcon> createState() => _StockIconState();
}

class _StockIconState extends State<StockIcon> {
  bool _imageError = false;

  String? get _iconUrl => widget.iconUrl ?? widget.stock?.iconUrl;

  String? get _ticker => widget.stock?.ticker ?? widget.ticker;
  String? get _name => widget.stock?.name ?? widget.name;
  String? get _nameAr => widget.stock?.nameAr ?? widget.nameAr;
  String? get _sector => widget.stock?.sector ?? widget.sector;

  @override
  Widget build(BuildContext context) {
    final url = _iconUrl;
    final fallbackEmoji = getSectorIcon(_sector);
    final displayName = _nameAr ?? _name ?? _ticker ?? '';

    if (url != null && !_imageError) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Image.network(
          url,
          width: widget.iconSize,
          height: widget.iconSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            if (mounted) setState(() => _imageError = true);
            return _buildFallback(fallbackEmoji);
          },
        ),
      );
    }

    return _buildFallback(fallbackEmoji);
  }

  Widget _buildFallback(String emoji) {
    if (!widget.showFallback) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          (_ticker ?? '').isNotEmpty ? _ticker![0] : '?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
            fontSize: widget.size! * 0.4,
          ),
        ),
      );
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: widget.size! * 0.45)),
    );
  }
}

/// نسخة صغيرة لـ table rows
class StockIconMini extends StatefulWidget {
  final Stock? stock;
  final String? ticker;
  final String? sector;
  final double size;

  const StockIconMini({
    super.key,
    this.stock,
    this.ticker,
    this.sector,
    this.size = 32,
  });

  @override
  State<StockIconMini> createState() => _StockIconMiniState();
}

class _StockIconMiniState extends State<StockIconMini> {
  bool _imageError = false;

  String? get _iconUrl => widget.stock?.iconUrl;
  String? get _ticker => widget.stock?.ticker ?? widget.ticker;
  String? get _sector => widget.stock?.sector ?? widget.sector;

  @override
  Widget build(BuildContext context) {
    final url = _iconUrl;
    final fallbackEmoji = getSectorIcon(_sector);

    if (url != null && !_imageError) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Image.network(
          url,
          width: widget.size * 0.6,
          height: widget.size * 0.6,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            if (mounted) setState(() => _imageError = true);
            return _buildFallback(fallbackEmoji);
          },
        ),
      );
    }

    return _buildFallback(fallbackEmoji);
  }

  Widget _buildFallback(String emoji) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: widget.size * 0.5)),
    );
  }
}