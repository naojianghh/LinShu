import 'package:flutter/material.dart';
import 'package:lingshu_app/utils/log_util.dart';

import '../services/qwen_service.dart';

class TextChatScreen extends StatefulWidget {
  const TextChatScreen({super.key});

  @override
  State<TextChatScreen> createState() => _TextChatScreenState();
}

class _TextChatScreenState extends State<TextChatScreen> {
  final QwenService _qwenService = QwenService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'content': '你好，我是灵枢·AI文本问诊助手。你可以告诉我近期症状、作息、饮食和情绪状态。'},
  ];

  final List<String> _quickPrompts = const [
    '最近总是失眠，入睡困难怎么办？',
    '经期腹痛明显，有什么日常调理建议？',
    '最近焦虑、心烦，怎么缓解？',
    '久坐后腰背酸胀，如何改善？',
    '最近便秘、口干，饮食要怎么调？',
    '我经常熬夜，如何把伤害降到最低？',
  ];

  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = (quickText ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isSending = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final stream = await _qwenService.chatWithTcmAssistantStream(
        messages: _messages,
      );

      String fullResponse = '';
      await for (final chunk in stream) {
        if (!mounted) return;
        fullResponse += chunk;
        setState(() {
          _isSending = false;
          // 最后一条消息实时更新
          if (_messages.last['role'] == 'assistant') {
            _messages.last['content'] = fullResponse;
          } else {
            _messages.add({'role': 'assistant', 'content': fullResponse});
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      Log.d('error: $e');
      if (!mounted) return;
      final msg = e.toString();
      final timeoutLike =
          msg.contains('timeout') ||
              msg.contains('连接超时') ||
              msg.contains('接收超时');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': timeoutLike
              ? '网络较慢，响应超时。建议稍后重试或切换到更稳定的网络（如Wi-Fi）。'
              : '抱歉，当前问诊服务暂时不可用，请稍后再试。',
        });
        _isSending = false;
      });
    }

    // try {
    //   final response = await _qwenService.chatWithTcmAssistant(
    //     messages: _messages,
    //   );
    //   Log.d('response: $response');
    //   if (!mounted) return;
    //   setState(() {
    //     _messages.add({'role': 'assistant', 'content': response});
    //     _isSending = false;
    //   });
    // } catch (e) {
    //   Log.d('error: $e');
    //   if (!mounted) return;
    //   final msg = e.toString();
    //   final timeoutLike =
    //       msg.contains('timeout') ||
    //       msg.contains('连接超时') ||
    //       msg.contains('接收超时');
    //   setState(() {
    //     _messages.add({
    //       'role': 'assistant',
    //       'content': timeoutLike
    //           ? '网络较慢，响应超时。建议稍后重试或切换到更稳定的网络（如Wi-Fi）。'
    //           : '抱歉，当前问诊服务暂时不可用，请稍后再试。',
    //     });
    //     _isSending = false;
    //   });
    // }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFCF7),
        elevation: 0,
        title: const Text(
          '文本问诊',
          style: TextStyle(
            color: Color(0xFF2D4A3E),
            fontFamily: 'STKaiti',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2D4A3E)),
      ),
      body: Column(
        children: [
          _buildQuickPromptBar(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF3C9566) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: isUser
                          ? null
                          : Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                    ),
                    child: Text(
                      msg['content'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        fontFamily: 'STKaiti',
                        color: isUser ? Colors.white : const Color(0xFF2D4A3E),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI 正在思考中...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B5D4F),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: '输入你的症状、作息或饮食问题...',
                        hintStyle: const TextStyle(fontFamily: 'STKaiti'),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3C9566),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '发送',
                        style: TextStyle(fontFamily: 'STKaiti'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPromptBar() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final text = _quickPrompts[index];
          return ActionChip(
            onPressed: _isSending ? null : () => _sendMessage(text),
            label: Text(
              text,
              style: const TextStyle(fontSize: 12, fontFamily: 'STKaiti'),
            ),
            backgroundColor: const Color(0xFFEFF6FF),
            side: const BorderSide(color: Color(0xFFBEDBFF), width: 0.6),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _quickPrompts.length,
      ),
    );
  }
}
