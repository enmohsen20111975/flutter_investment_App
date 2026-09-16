// ============================================================================
// مساعد Investment Flutter - نظام Participate الموحّد
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'official_links.dart';

/// بناء النص الكامل للمشاركة (مع روابط المنصة الرسمية)
String buildShareText(String title, {String? body, String? url}) {
  final parts = <String>[];
  if (title.isNotEmpty) parts.add('📊 $title');
  if (body != null && body.isNotEmpty) {
    parts.add('');
    parts.add(body);
  }
  parts.add('');
  parts.add(OfficialLinks.linksBlock);
  return parts.join('\n');
}

/// بناء روابط Participate لكل منصة
Map<String, String> buildShareUrls(String title, {String? body, String? url}) {
  final text = buildShareText(title, body: body, url: url);
  final shareUrl = url ?? OfficialLinks.website;
  return {
    'facebook': 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}',
    'twitter': 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(title)}&url=${Uri.encodeComponent(shareUrl)}',
    'whatsapp': 'https://wa.me/?text=${Uri.encodeComponent(text)}',
    'telegram': 'https://t.me/share/url?url=${Uri.encodeComponent(shareUrl)}&text=${Uri.encodeComponent(text)}',
    'linkedin': 'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(shareUrl)}',
    'copy': text,
  };
}

/// فتح نافذة Participate للمنصة المحددة
void openShareWindow(String platform, Map<String, String> urls) {
  final url = urls[platform];
  if (url == null) return;
  if (platform == 'copy') {
    Clipboard.setData(ClipboardData(text: url));
  }
}

/// عرض menu Participate
void showShareSheet(BuildContext context, String title, {String? body, String? url}) {
  final urls = buildShareUrls(title, body: body, url: url);
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('مشاركة على منصات مختلفة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildSharePlatform('واتساب', const Color(0xFF25D366), Icons.chat, () => openShareWindow('whatsapp', urls)),
              _buildSharePlatform('فيسبوك', const Color(0xFF1877F2), Icons.facebook, () => openShareWindow('facebook', urls)),
              _buildSharePlatform('تليجرام', const Color(0xFF0088CC), Icons.send, () => openShareWindow('telegram', urls)),
              _buildSharePlatform('Twitter', Colors.black, Icons.alternate_email, () => openShareWindow('twitter', urls)),
              _buildSharePlatform('LinkedIn', const Color(0xFF0A66C2), Icons.link, () => openShareWindow('linkedin', urls)),
              _buildSharePlatform('نسخ', Colors.grey, Icons.content_copy, () => openShareWindow('copy', urls)),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildSharePlatform(String label, Color color, IconData icon, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}