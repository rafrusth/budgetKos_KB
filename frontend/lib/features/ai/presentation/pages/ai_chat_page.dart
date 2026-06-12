import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/ai_chat_local_ds.dart';
import '../../../../core/utils/toast_helper.dart';

import '../../../../core/network/api_client.dart';

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
  List<AiChatModel> _chatHistory = [];
  bool _isLoading = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadHistory();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult.contains(ConnectivityResult.none);
    });
  }

  Future<void> _loadHistory() async {
    final history = await getIt<AiChatLocalDataSource>().getChatHistory();
    setState(() {
      _chatHistory = history;
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
      final response = await ApiClient.instance.post(
        '/ai/chat',
        data: {'message': text},
      );

      if (response.statusCode == 200) {
        final reply = response.data['data']['reply'] as String;
        final newChat = AiChatModel(prompt: text, response: reply, timestamp: DateTime.now());
        await getIt<AiChatLocalDataSource>().insertChat(newChat);
        setState(() {
          _messages.add(_Message(reply, false));
          _chatHistory.add(newChat);
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
        title: const Text('Bud-AI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(theme),
      body: _isOffline 
        ? _buildOfflineUI(theme)
        : Column(
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
              _buildQuickPrompts(theme),
              _buildInputArea(theme),
            ],
          ),
    );
  }

  Widget _buildOfflineUI(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Anda sedang Offline",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Fitur AI membutuhkan koneksi internet untuk membalas pesan Anda. Silakan periksa koneksi internet Anda.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _checkConnectivity();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Coba Lagi"),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickPrompts(ThemeData theme) {
    if (_messages.length > 2) return const SizedBox(); // Only show when empty or just welcomed

    final prompts = [
      "Tolong evaluasi keuanganku bulan ini",
      "Beri saya saran penghematan",
      "Bantu buat rencana keuangan bulan depan"
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: prompts.length,
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              label: Text(prompt, style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
              onPressed: () {
                _controller.text = prompt;
                _sendMessage();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
            width: double.infinity,
            color: theme.colorScheme.primary.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.history, size: 40, color: Colors.blue),
                const SizedBox(height: 12),
                Text("Riwayat Obrolan", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: _chatHistory.isEmpty 
              ? const Center(child: Text("Belum ada riwayat", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _chatHistory.length,
                  itemBuilder: (context, index) {
                    final chat = _chatHistory[index];
                    return ListTile(
                      leading: const Icon(Icons.chat_bubble_outline, size: 20),
                      title: Text(
                        chat.prompt, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close drawer
                        // We could scroll to index, but a simple close is fine for now
                      },
                    );
                  },
                ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text("Hapus Semua Riwayat", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await getIt<AiChatLocalDataSource>().clearHistory();
              _loadHistory();
              if (mounted) {
                Navigator.pop(context);
                ToastHelper.showSuccess(context, 'Histori obrolan dihapus');
              }
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildChatBubble(_Message msg, ThemeData theme) {
    final bgColor = msg.isUser 
        ? theme.colorScheme.primary.withOpacity(0.2) 
        : Colors.transparent;
        
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final extraPadding = bottomInset > 0 ? 0.0 : 100.0; // 100px to avoid navbar
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12 + extraPadding
      ),
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
                style: TextStyle(color: theme.colorScheme.onSurface),
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
