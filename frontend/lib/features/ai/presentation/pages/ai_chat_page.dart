import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import 'dart:io' as import_io;
import 'package:window_manager/window_manager.dart';
import '../../../../core/widgets/custom_title_bar.dart';
import '../../../../core/utils/popup_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/ai_chat_local_ds.dart';
import '../../../../core/utils/toast_helper.dart';

import '../../../../core/network/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../transaction/presentation/bloc/transaction_bloc.dart';
import '../../../transaction/presentation/bloc/transaction_event.dart';
import '../../../transactions/data/datasources/transaction_local_ds.dart';
import 'package:budget_kos/shared/models/transaction_model.dart';
import '../../../categories/data/datasources/category_local_ds.dart';
import 'package:budget_kos/shared/models/category_model.dart';
import '../../../../core/sync/sync_engine.dart';

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

  String _formatMoney(double amount) {
    if (amount >= 1000) {
      String formatted = amount.toStringAsFixed(0);
      return formatted.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    }
    return amount.toStringAsFixed(0);
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  /// Jumlah exchange (prompt+response) terakhir yang dikirim ke Gemini.
  /// Menghemat token: hanya 5 percakapan terakhir, bukan seluruh riwayat.
  static const int _kPreviousMessages = 5;

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
      final transactions = await getIt<TransactionLocalDataSource>().getTransactions();
      double totalIncome = 0;
      double totalExpense = 0;
      List<Map<String, dynamic>> recentTxs = [];
      
      for (var i = 0; i < transactions.length; i++) {
         final tx = transactions[i];
         if (tx.type.toLowerCase() == 'income' || tx.type.toLowerCase() == 'pemasukan') {
             totalIncome += tx.amount;
         } else {
             totalExpense += tx.amount;
         }
         if (i < 10) { // Kirim 10 transaksi terakhir saja untuk mempercepat respons AI
             recentTxs.add({
                 'date': tx.date.toIso8601String(),
                 'title': tx.title,
                 'amount': tx.amount,
                 'type': tx.type,
                 'category': tx.category?.name ?? 'Umum',
             });
         }
      }

      final payload = {
        'message': text,
        'local_context': {
            'total_income': totalIncome,
            'total_expense': totalExpense,
            'recent_transactions': recentTxs,
            // Fitur 2: Lokasi kampus otomatis
            'campus_location': (await SharedPreferences.getInstance()).getString('user_campus_location') ?? '',
            // Fitur 1: Sisa hari di bulan ini untuk burn-rate
            'days_remaining_in_month': DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day - DateTime.now().day,
            // Fitur 3: K-previous messages (hemat token)
            'chat_history': _chatHistory
                .skip(_chatHistory.length > _kPreviousMessages ? _chatHistory.length - _kPreviousMessages : 0)
                .map((c) => {'prompt': c.prompt, 'response': c.response})
                .toList(),
        }
      };

      final response = await ApiClient.instance.post(
        '/ai/chat',
        data: payload,
      );

      if (response.statusCode == 200) {
        String finalReply = response.data['data']['reply'] as String;
        final createdTxs = response.data['data']['created_transactions'] as List?;
        final createdCats = response.data['data']['created_categories'] as List?;
        final updatedCats = response.data['data']['updated_categories'] as List?;
        final deletedCats = response.data['data']['deleted_categories'] as List?;
        
        bool requiresRefresh = false;

        if (createdTxs != null && createdTxs.isNotEmpty) {
          requiresRefresh = true;
          finalReply += "\n\nTransaksi sudah ditambahkan dengan detail:";
          for (var txData in createdTxs) {
            final model = TransactionModel(
              id: txData['id']?.toString(),
              title: txData['title'] ?? '',
              amount: (txData['amount'] as num).toDouble(),
              type: txData['type'] ?? 'expense',
              categoryId: (txData['category_id'] ?? 1).toString(),
              date: txData['date'] != null ? DateTime.parse(txData['date']) : DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              syncStatus: 0,
            );
            await getIt<TransactionLocalDataSource>().insertTransaction(model);
            
            final typeStr = model.type == 'expense' ? 'Pengeluaran' : 'Pemasukan';
            final dateStr = "${model.date.day} ${_getMonthName(model.date.month)} ${model.date.year}";
            
            finalReply += "\n==== $typeStr ====\n";
            finalReply += "- Nominal      : Rp ${_formatMoney(model.amount)}\n";
            finalReply += "- Kategori     : ${model.categoryId}\n";
            finalReply += "- Tanggal      : $dateStr\n";
            finalReply += "- Keterangan   : ${model.title}\n";
            finalReply += "=================";
          }
        }

        if (createdCats != null && createdCats.isNotEmpty) {
          requiresRefresh = true;
          for (var catData in createdCats) {
            final model = CategoryModel(
              id: catData['id']?.toString() ?? catData['name']?.toString() ?? '',
              name: catData['name'] ?? '',
              type: catData['type'] ?? 'expense',
              icon: catData['icon'] ?? '',
              color: catData['color'] ?? '',
            );
            await getIt<CategoryLocalDataSource>().insertCategory(model);
          }
        }

        if (updatedCats != null && updatedCats.isNotEmpty) {
          requiresRefresh = true;
          for (var catData in updatedCats) {
            final model = CategoryModel(
              id: catData['id']?.toString() ?? '',
              name: catData['name'] ?? '',
              type: catData['type'] ?? 'expense',
              icon: catData['icon'] ?? '',
              color: catData['color'] ?? '',
            );
            await getIt<CategoryLocalDataSource>().updateCategory(model);
          }
        }

        if (deletedCats != null && deletedCats.isNotEmpty) {
          requiresRefresh = true;
          for (var id in deletedCats) {
            await getIt<CategoryLocalDataSource>().deleteCategory(id.toString());
          }
        }

        if (requiresRefresh && mounted) {
          ToastHelper.showSuccess(context, 'Transaksi berhasil diproses');
          // Sync with backend to get any categories auto-created in the server by the AI service
          await getIt<SyncEngine>().syncData();
          if (mounted) {
            context.read<TransactionBloc>().add(FetchTransactions());
            if (createdTxs != null && createdTxs.isNotEmpty) {
              ToastHelper.showSuccess(context, 'Berhasil memasukkan transaksi dari AI');
            }
          }
        }

        final newChat = AiChatModel(prompt: text, response: finalReply, timestamp: DateTime.now());
        await getIt<AiChatLocalDataSource>().insertChat(newChat);
        setState(() {
          _messages.add(_Message(finalReply, false));
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
    final isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konsultan Keuangan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Obrolan',
            onPressed: () => _showHistorySheet(context, theme),
          ),
          const WindowButtonsRow(),
        ],
        flexibleSpace: import_io.Platform.isWindows || import_io.Platform.isLinux || import_io.Platform.isMacOS
            ? DragToMoveArea(child: Container(color: Colors.transparent))
            : null,
      ),
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
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
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

  void _showHistorySheet(BuildContext context, ThemeData theme) {
    PopupHelper.showAdaptivePopup(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 28, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text("Riwayat Obrolan", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Hapus Semua Riwayat',
                          onPressed: () async {
                            await getIt<AiChatLocalDataSource>().clearHistory();
                            _loadHistory();
                            if (mounted) {
                              Navigator.pop(sheetContext);
                              ToastHelper.showSuccess(context, 'Histori obrolan dihapus');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _chatHistory.isEmpty
                      ? const Center(child: Text("Belum ada riwayat", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          controller: scrollController,
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
                                Navigator.pop(sheetContext);
                              },
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
      },
    );
  }

  Widget _buildChatBubble(_Message msg, ThemeData theme) {
    final bgColor = msg.isUser 
        ? theme.colorScheme.primary.withValues(alpha: 0.2) 
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
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final extraPadding = (bottomInset > 0 || isDesktop) ? 0.0 : 100.0 + (MediaQuery.of(context).size.height * 0.03); // 100px to avoid navbar on mobile
    
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
