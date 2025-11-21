import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'models.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text("AI Ассистент", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
                      color: isUser ? const Color(0xFF2E3A59) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                      boxShadow: [
                        if (!isUser) const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
                      ],
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
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
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end, // 🔥 Кнопка всегда внизу, если поле растет
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    // 🔥 ВОТ ЭТИ ТРИ СТРОЧКИ РЕШАЮТ ПРОБЛЕМУ:
                    minLines: 1,
                    maxLines: 5, // Расти до 5 строк, потом скроллить
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences, // Первая буква заглавная
                    
                    decoration: InputDecoration(
                      hintText: "Спроси о финансах...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4), // Чуть поднять кнопку, чтобы ровно стояла
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