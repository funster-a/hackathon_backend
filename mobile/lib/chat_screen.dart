import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'models.dart';
import 'localization.dart';
import 'theme_helper.dart';
import 'usage_manager.dart';
import 'premium_screen.dart';

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

  // 🔥 БЫСТРЫЕ ПРОМПТЫ (будут обновляться при изменении языка)
  List<String> get _suggestions => [
    AppStrings.get('chat_suggestion1'),
    AppStrings.get('chat_suggestion2'),
    AppStrings.get('chat_suggestion3'),
    AppStrings.get('chat_suggestion4'),
    AppStrings.get('chat_suggestion5'),
    AppStrings.get('chat_suggestion6'),
  ];

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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Проверяем лимит перед отправкой сообщения
    final usageManager = UsageManager();
    final canProceed = await usageManager.canAction();
    
    if (!canProceed) {
      // Показываем диалог о лимите
      if (!mounted) return;
      final shouldGoToPremium = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppStrings.get('limit_exceeded_title')),
          content: Text(AppStrings.get('limit_exceeded_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.get('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3A59),
              ),
              child: Text(AppStrings.get('go_to_premium'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      
      if (shouldGoToPremium == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
      }
      return;
    }

    setState(() {
      widget.messages.add({"role": "user", "text": text});
      _isTyping = true;
      _controller.clear();
    });
    _scrollToBottom();

    final reply = await _apiService.sendChatMessage(text, widget.rawContext);

    // Увеличиваем счетчик использований только при успешной отправке
    await usageManager.incrementUsage();

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
    return ValueListenableBuilder<Language>(
      valueListenable: AppStrings.languageNotifier,
      builder: (context, language, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7);
        final bubbleUser = const Color(0xFF2E3A59);
        final bubbleAi = isDark ? const Color(0xFF2C2C2C) : Colors.white;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text(AppStrings.get('chat_title'), style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text(AppStrings.get('chat_typing'), style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
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
                      color: isUser ? bubbleUser : bubbleAi,
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
                        color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 🔥 ПАНЕЛЬ БЫСТРЫХ ВОПРОСОВ
          if (!_isTyping)
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ActionChip(
                    label: Text(_suggestions[index]),
                    backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _sendMessage(_suggestions[index]),
                  );
                },
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    enableInteractiveSelection: true,
                    enableSuggestions: true,
                    autocorrect: true,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: AppStrings.get('chat_hint'),
                      hintStyle: TextStyle(color: isDark ? Colors.grey : null),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    // Убираем onSubmitted для многострочного ввода - отправка только по кнопке
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: FloatingActionButton(
                    mini: true,
                    elevation: 0,
                    backgroundColor: const Color(0xFF2E3A59),
                    onPressed: () => _sendMessage(_controller.text),
                    child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}