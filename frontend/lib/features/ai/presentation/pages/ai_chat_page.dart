import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/ai_chat_local_ds.dart';
import '../../../../core/utils/toast_helper.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _Message {
  final String text;
  final bool isUser;
  bool isFullyTyped;
  bool isNew;
  _Message(this.text, this.isUser, {this.isFullyTyped = false, this.isNew = true});
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await getIt<AiChatLocalDataSource>().getChatHistory();
    setState(() {
      _messages.clear();
      _messages.add(_Message("Halo! Aku konsultan keuangan pribadi kamu. Ada yang bisa dibantu soal budget atau ngekos hari ini?", false, isFullyTyped: true, isNew: false));
      for (var chat in history) {
        _messages.add(_Message(chat.prompt, true, isFullyTyped: true, isNew: false));
        _messages.add(_Message(chat.response, false, isFullyTyped: true, isNew: false));
      }
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text, true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await Dio().post(
        'https://b69e46f5d5620c.lhr.life/api/v1/ai/chat',
        data: {'message': text},
      );

      if (response.statusCode == 200) {
        final reply = response.data['data']['reply'] as String;
        setState(() {
          _messages.add(_Message(reply, false));
        });
        await getIt<AiChatLocalDataSource>().insertChat(
          AiChatModel(prompt: text, response: reply, timestamp: DateTime.now())
        );
        _scrollToBottom();
      }
    } on DioException catch (e) {
      final serverMsg = e.response?.data['message'] ?? e.message;
      setState(() {
        _messages.add(_Message("Aduh, error dari server: $serverMsg", false));
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(_Message("Aduh, maaf aku lagi error nih: $e", false));
      });
      _scrollToBottom();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bud-AI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              await getIt<AiChatLocalDataSource>().clearHistory();
              _loadHistory();
              ToastHelper.showSuccess(context, 'Histori obrolan dihapus');
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _TypingIndicator();
                }
                final msg = _messages[index];
                return _buildChatBubble(msg, theme);
              },
            ),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildChatBubble(_Message msg, ThemeData theme) {
    final bgColor = msg.isUser 
        ? theme.colorScheme.primary.withOpacity(0.2) 
        : Colors.transparent;
        
    final textColor = Colors.white;

    Widget bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: msg.isUser 
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          : const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24).copyWith(
          bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(24),
        ),
      ),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          (!msg.isUser) 
            ? (!msg.isFullyTyped
            ? _TypewriterMarkdownText(
                text: msg.text,
                textColor: textColor,
                onFinished: () {
                  setState(() {
                    msg.isFullyTyped = true;
                  });
                },
              )
            : MarkdownBody(
                data: msg.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: textColor, height: 1.4, fontSize: 14),
                  strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
                  listBullet: TextStyle(color: textColor),
                  tableBody: TextStyle(color: textColor),
                  tableHead: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  code: const TextStyle(
                    backgroundColor: Color(0xFF1E1F20),
                    color: Colors.white,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFF1E1F20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ))
        : Text(
            msg.text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w400,
              height: 1.5,
              fontSize: 15,
            ),
          ),
        ],
      )
    );

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: _SlideInBubble(
        isNew: msg.isNew,
        onFinished: () {
          msg.isNew = false;
        },
        child: bubble,
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12 + 90),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan di sini...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: theme.colorScheme.primary),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * 0.2;
                final value = (_controller.value - delay) % 1.0;
                final offset = (value >= 0.0 && value <= 0.4) 
                    ? -4.0 * (0.2 - (value - 0.2).abs()) / 0.2 
                    : 0.0;
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _TypewriterMarkdownText extends StatefulWidget {
  final String text;
  final Color? textColor;
  final VoidCallback? onFinished;

  const _TypewriterMarkdownText({required this.text, this.textColor, this.onFinished});

  @override
  State<_TypewriterMarkdownText> createState() => _TypewriterMarkdownTextState();
}

class _TypewriterMarkdownTextState extends State<_TypewriterMarkdownText> {
  String _displayedText = "";
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _animateText();
  }

  void _animateText() async {
    while (_currentIndex < widget.text.length) {
      if (!mounted) return;
      
      setState(() {
        _currentIndex++;
        _displayedText = widget.text.substring(0, _currentIndex);
      });
      
      // Speed of typing
      await Future.delayed(const Duration(milliseconds: 10));
    }
    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return MarkdownBody(
      data: _displayedText,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: widget.textColor, height: 1.4, fontSize: 14),
        strong: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold),
        em: TextStyle(color: widget.textColor, fontStyle: FontStyle.italic),
        listBullet: TextStyle(color: widget.textColor),
        tableBody: TextStyle(color: widget.textColor),
        tableHead: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold),
        code: const TextStyle(
          backgroundColor: Color(0xFF1E1F20),
          color: Colors.white,
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF1E1F20),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _SlideInBubble extends StatefulWidget {
  final Widget child;
  final bool isNew;
  final VoidCallback onFinished;

  const _SlideInBubble({required this.child, required this.isNew, required this.onFinished});

  @override
  State<_SlideInBubble> createState() => _SlideInBubbleState();
}

class _SlideInBubbleState extends State<_SlideInBubble> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _offsetAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart));
        
    if (widget.isNew) {
      _animController.forward().then((_) {
        widget.onFinished();
      });
    } else {
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isNew && _animController.value == 1.0) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _animController,
      child: SlideTransition(
        position: _offsetAnim,
        child: widget.child,
      ),
    );
  }
}
