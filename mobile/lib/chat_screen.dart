import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'models.dart';
import 'theme_helper.dart';

class ChatScreen extends StatefulWidget {
  final FinanceData financeData;
  final Map<String, dynamic> rawContext;
  final List<Map<String, String>> messages; 

  const ChatScreen({
    super.key, 
    required this.financeData, 
    required this.rawContext,
    required this.messages,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      widget.messages.add({"role": "user", "text": text});
      _isTyping = true;
      _controller.clear();
    });
    _scrollToBottom();

    final reply = await _apiService.sendChatMessage(text, widget.rawContext);

    if (mounted) {
      setState(() {
        _isTyping = false;
        widget.messages.add({"role": "ai", "text": reply});
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Фон берется из темы (белый или черный)
      appBar: AppBar(
        title: Text("AI Ассистент", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Кнопка переключения темы
          StatefulBuilder(
            builder: (context, setState) {
              return IconButton(
                icon: Icon(getThemeIcon()),
                tooltip: 'Переключить тему',
                onPressed: () {
                  toggleTheme();
                  // Принудительно обновляем иконку
                  setState(() {});
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: widget.messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == widget.messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text("AI печатает...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ),
                  );
                }
                final msg = widget.messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      // Цвет пузырей адаптируется
                      color: isUser 
                          ? const Color(0xFF2E3A59) 
                          : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser ? Radius.zero : null,
                        bottomLeft: !isUser ? Radius.zero : null,
                      ),
                      boxShadow: [
                        if (!isDark) const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
                      ],
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        // Цвет текста на пузырях
                        color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // Цвет нижней панели
              border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.black12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "Спроси о финансах...",
                      hintStyle: TextStyle(color: isDark ? Colors.grey : null),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: FloatingActionButton(
                    mini: true,
                    elevation: 0,
                    backgroundColor: const Color(0xFF2E3A59),
                    onPressed: _sendMessage,
                    child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
