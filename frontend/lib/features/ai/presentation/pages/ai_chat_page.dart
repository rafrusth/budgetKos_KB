import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
    // Welcome message
    _messages.add(_Message("Halo! Aku konsultan keuangan pribadi kamu. Ada yang bisa dibantu soal budget atau ngekos hari ini?", false, isFullyTyped: true, isNew: false));
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
        'http://10.105.98.210:8080/api/v1/ai/chat',
        data: {'message': text},
      );

      if (response.statusCode == 200) {
        final reply = response.data['data']['reply'] as String;
        setState(() {
          _messages.add(_Message(reply, false));
        });
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
        title: Text('Konsultan AI', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      backgroundColor: theme.colorScheme.background,
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
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // AI uses card color, User uses Primary color
    final bgColor = msg.isUser 
        ? theme.colorScheme.primary 
        : theme.cardColor;
        
    final textColor = msg.isUser 
        ? theme.colorScheme.onPrimary 
        : theme.textTheme.bodyMedium?.color;

    Widget bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
          bottomLeft: !msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
      child: (!msg.isUser) 
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
                  code: TextStyle(
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ))
        : Text(
            msg.text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              height: 1.4,
              fontSize: 14,
            ),
          ),
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
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12 + 90),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Tanya saran keuangan...',
                  hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
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
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: const Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
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
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.6),
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
        code: TextStyle(
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
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
