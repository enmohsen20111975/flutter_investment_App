// ============================================================================
// مساعد الاستثمار - Official Links & Marketing Share System
// الروابط الرسمية ونظام المشاركة الترويجي
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';

class OfficialLinks {
  static const String website = 'https://invist.m2y.net';
  static const String android =
      'https://play.google.com/store/apps/details?id=com.egx.investment';
  static const String facebook =
      'https://www.facebook.com/profile.php?id=61590600300048';
  static const String telegram = 'https://t.me/Arabian_investment_guide';
  static const String whatsapp =
      'https://chat.whatsapp.com/L9hjEpJloAZAUvwMzB10Tc';

  static const String communityPrompt =
      'انضم الآن إلى مجتمع المتداولين بلا مشاعر، ودع الأرقام تقود محفظتك! 📈';

  static const String officialLinksBlock = '''
━━━━━

$communityPrompt

🔗 روابطنا الرسمية:
🌐 الموقع: $website
📱 أندرويد: $android
📘 فيسبوك: $facebook
✈️ تليجرام: $telegram
💬 واتساب: $whatsapp''';

  /// اسم مستعار للتوافق مع شاشات المشاركة السابقة
  static const String linksBlock = officialLinksBlock;

  /// إنشاء نص التقرير والمشاركة الاحترافي
  static String buildStockShareText({
    required String ticker,
    required String name,
    required double price,
    double? changePercent,
    String? recommendation,
    num? confidence,
    double? buyPrice,
    double? sellPrice,
    double? targetPrice,
    double? stopLoss,
    double? fairValue,
    double? expectedReturn,
    double? pe,
    double? pb,
    double? roe,
    double? dividendYield,
    String? sector,
  }) {
    final buffer = StringBuffer();
    final isUp = (changePercent ?? 0) >= 0;
    final changeSign = isUp ? '▲ +' : '▼ ';
    final changeText = changePercent != null
        ? ' ($changeSign${changePercent.abs().toStringAsFixed(2)}%)'
        : '';

    buffer.writeln('📈 تحليل سهم: $ticker - $name');
    buffer.writeln('💰 السعر الحالي: ${price.toStringAsFixed(2)} ج.م$changeText');

    if (sector != null && sector.isNotEmpty) {
      buffer.writeln('🏢 القطاع: $sector');
    }

    if (recommendation != null && recommendation.isNotEmpty) {
      buffer.writeln('🎯 إشارة التحليل: $recommendation');
    }

    if (confidence != null && confidence > 0) {
      buffer.writeln('📊 مستوى الثقة: ${confidence.toStringAsFixed(0)}%');
    }

    final hasTradingPrices = buyPrice != null ||
        sellPrice != null ||
        targetPrice != null ||
        stopLoss != null ||
        fairValue != null ||
        expectedReturn != null;

    if (hasTradingPrices) {
      buffer.writeln('\n〰️〰️ أهم أسعار ومستويات التداول 〰️〰️');
      if (buyPrice != null && buyPrice > 0) {
        buffer.writeln('✅ سعر الشراء الجيد: ${buyPrice.toStringAsFixed(2)} ج.م');
      }
      if (sellPrice != null && sellPrice > 0) {
        buffer.writeln('📤 سعر البيع المقترح: ${sellPrice.toStringAsFixed(2)} ج.م');
      } else if (targetPrice != null && targetPrice > 0) {
        buffer.writeln('🎯 السعر المستهدف: ${targetPrice.toStringAsFixed(2)} ج.م');
      }
      if (stopLoss != null && stopLoss > 0) {
        buffer.writeln('🛑 وقف الخسارة: ${stopLoss.toStringAsFixed(2)} ج.م');
      }
      if (fairValue != null && fairValue > 0) {
        buffer.writeln('📐 القيمة العادلة: ${fairValue.toStringAsFixed(2)} ج.م');
      }
      if (expectedReturn != null) {
        final retSign = expectedReturn >= 0 ? '+' : '';
        buffer.writeln('📈 العائد المتوقع: $retSign${expectedReturn.toStringAsFixed(1)}%');
      }
    }

    final hasMetrics = pe != null || pb != null || roe != null || dividendYield != null;
    if (hasMetrics) {
      buffer.writeln('\n📊 المؤشرات المالية الأساسية:');
      final parts = <String>[];
      if (pe != null && pe > 0) parts.add('مضاعف الربحية P/E: ${pe.toStringAsFixed(1)}');
      if (pb != null && pb > 0) parts.add('مضاعف القيمة الدفترية P/B: ${pb.toStringAsFixed(1)}');
      if (roe != null && roe > 0) parts.add('العائد على الملكية ROE: ${roe.toStringAsFixed(1)}%');
      if (dividendYield != null && dividendYield > 0) parts.add('عائد التوزيعات: ${dividendYield.toStringAsFixed(1)}%');
      buffer.writeln(parts.join(' | '));
    }

    buffer.write(officialLinksBlock);
    return buffer.toString();
  }

  /// إظهار نافذة منبثقة للمشاركة الاحترافية مع خيارات التطبيقات المباشرة
  static void showShareModal(
    BuildContext context, {
    required String ticker,
    required String name,
    required double price,
    double? changePercent,
    String? recommendation,
    num? confidence,
    double? buyPrice,
    double? sellPrice,
    double? targetPrice,
    double? stopLoss,
    double? fairValue,
    double? expectedReturn,
    double? pe,
    double? pb,
    double? roe,
    double? dividendYield,
    String? sector,
  }) {
    final text = buildStockShareText(
      ticker: ticker,
      name: name,
      price: price,
      changePercent: changePercent,
      recommendation: recommendation,
      confidence: confidence,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      targetPrice: targetPrice,
      stopLoss: stopLoss,
      fairValue: fairValue,
      expectedReturn: expectedReturn,
      pe: pe,
      pb: pb,
      roe: roe,
      dividendYield: dividendYield,
      sector: sector,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.quantumSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.share, color: AppColors.primaryLight, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'مشاركة تحليل $ticker ($name)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'انشر التحليل مع روابط المنصة والمجتمع لزيادة التفاعل والدعاية',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // زر مشاركة النظام الشامل (ShareSheet)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'مشاركة التقرير عبر التطبيقات (Share)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Share.share(text, subject: 'تحليل سهم $ticker');
                  },
                ),
                const SizedBox(height: 12),

                // أزرار سريعة للتطبيقات المباشرة
                Row(
                  children: [
                    // واتساب
                    Expanded(
                      child: _buildQuickShareButton(
                        label: 'واتساب',
                        color: const Color(0xFF25D366),
                        icon: Icons.chat,
                        onTap: () async {
                          Navigator.pop(ctx);
                          final uri = Uri.parse(
                              'https://wa.me/?text=${Uri.encodeComponent(text)}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            Share.share(text);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // تليجرام
                    Expanded(
                      child: _buildQuickShareButton(
                        label: 'تليجرام',
                        color: const Color(0xFF0088CC),
                        icon: Icons.send,
                        onTap: () async {
                          Navigator.pop(ctx);
                          final uri = Uri.parse(
                              'https://t.me/share/url?url=${Uri.encodeComponent(website)}&text=${Uri.encodeComponent(text)}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            Share.share(text);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // نسخ النص
                    Expanded(
                      child: _buildQuickShareButton(
                        label: 'نسخ النص',
                        color: AppColors.card,
                        textColor: AppColors.text,
                        borderColor: AppColors.cardBorder,
                        icon: Icons.copy_rounded,
                        onTap: () {
                          Navigator.pop(ctx);
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ تقرير السهم وروابط المنصة بنجاح!'),
                              backgroundColor: AppColors.success,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildQuickShareButton({
    required String label,
    required Color color,
    Color? textColor,
    Color? borderColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: textColor ?? Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}