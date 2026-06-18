// ============================================================================
// مساعد الاستثمار Flutter - AI Chat Screen
// Chat with AI investment assistant via /api/ai/chat
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.content, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _suggestions = [
    'ما أفضل سهم للمضاربة؟',
    'تحليل السوق المصري',
    'توصيات ذهبية',
    'مقارنة بين COMI و EKHO',
    'تحليل فني لـ EGX30',
  ];

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text.trim()));
      _isLoading = true;
    });
    _messageCtrl.clear();
    _scrollToBottom();

    try {
      final response = await api.sendAiChat(text.trim(), context: {
        'screen': 'ai_chat',
        'timestamp': DateTime.now().toIso8601String(),
      });

      final reply = response['reply']?.toString() ??
          response['response']?.toString() ??
          response['message']?.toString() ??
          'عذراً، لم أتمكن من معالجة طلبك. حاول مرة أخرى.';

      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: reply));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
            role: 'assistant',
            content:
                'عذراً، حدث خطأ في الاتصال. تحقق من اتصالك وحاول مرة أخرى.'));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPurplePink,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('المساعد الذكي',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ]),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(child: _buildMessages()),
            if (_messages.isEmpty) _buildSuggestions(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPurplePink,
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('مرحباً! أنا مساعدك الاستثماري الذكي',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text)),
            const SizedBox(height: 8),
            const Text('اسألني عن الأسهم، التحليلات، التوصيات وأكثر',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              SizedBox(width: 48),
              Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary)),
                      SizedBox(width: 8),
                      Text('AI يكتب...',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ]),
                  )),
            ]),
          );
        }

        final msg = _messages[index];
        final isUser = msg.role == 'user';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPurplePink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12).copyWith(
                      bottomRight:
                          isUser ? Radius.zero : const Radius.circular(12),
                      bottomLeft:
                          isUser ? const Radius.circular(12) : Radius.zero,
                    ),
                    border:
                        !isUser ? Border.all(color: AppColors.border) : null,
                  ),
                  child: Text(msg.content,
                      style: TextStyle(
                          fontSize: 13,
                          color: isUser ? AppColors.text : AppColors.text)),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryMuted,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: const Icon(Icons.person,
                      color: AppColors.primary, size: 18),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('أسئلة مقترحة:',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions
              .map((s) => ActionChip(
                    label: Text(s,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.primary)),
                    backgroundColor: AppColors.primaryMuted,
                    side:
                        const BorderSide(color: AppColors.primary, width: 0.5),
                    onPressed: () => _sendMessage(s),
                  ))
              .toList(),
        ),
      ]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _messageCtrl,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'اكتب سؤالك هنا...',
              hintTextDirection: TextDirection.rtl,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: _sendMessage,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradientPurplePink,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.white),
            onPressed: () => _sendMessage(_messageCtrl.text),
          ),
        ),
      ]),
    );
  }
}
