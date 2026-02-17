import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fitlyfe_frontend/theme/app_theme.dart';
import 'package:fitlyfe_frontend/providers/translation_provider.dart';
import 'package:provider/provider.dart';

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final TextEditingController _messageController = TextEditingController();
  late List<ChatMessage> _messages;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final tp = Provider.of<TranslationProvider>(context);
      _messages = [
        ChatMessage(
          text: tp.translate('ai_coach_intro'),
          isUser: false,
        ),
      ];
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: _messageController.text,
        isUser: true,
      ));
      _messageController.clear();

      // Simulate AI response
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _messages.add(ChatMessage(
            text: "That's a great question! Here's some advice based on your goals...",
            isUser: false,
          ));
        });
      });
    });
  }

  void _handleTopicTap(String topicKey) {
    final tp = Provider.of<TranslationProvider>(context, listen: false);
    String topic = tp.translate(topicKey);
    String response = '';
    
    // Logic based on untranslated keys for internal consistency if needed, 
    // but here we check the translated value or just use the key.
    if (topicKey == 'body_type') {
        response = "Understanding your body type helps tailor your fitness approach. There are three main types: Ectomorph (naturally thin), Mesomorph (naturally muscular), and Endomorph (naturally stocky). Each responds differently to training and nutrition.";
    } else if (topicKey == 'consistency_tips') {
        response = "Consistency is key to success! Here are tips: 1) Set realistic goals, 2) Create a schedule and stick to it, 3) Track your progress, 4) Find an accountability partner, 5) Celebrate small wins, 6) Don't let one bad day derail you.";
    } else if (topicKey == 'daily_quote') {
        response = "\"The only bad workout is the one that didn't happen.\" - Unknown\n\nRemember, every step forward counts, no matter how small. You've got this! 💪";
    }

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TranslationProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppTheme.accentGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    tp.translate('ai_assistant'),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ],
              ),
            ),

            // Chat Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

            // Topic Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTopicButton(tp.translate('body_type'), 'body_type'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTopicButton(tp.translate('consistency_tips'), 'consistency_tips'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTopicButton(tp.translate('daily_quote'), 'daily_quote'),
                  ),
                ],
              ),
            ),

            // Input Field
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: AppTheme.primaryText),
                            decoration: InputDecoration(
                              hintText: tp.translate('ask_anything'),
                              hintStyle: TextStyle(
                                color: AppTheme.secondaryText.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppTheme.accentGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: AppTheme.backgroundColor,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppTheme.accentGreen
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: message.isUser
                ? AppTheme.backgroundColor
                : AppTheme.primaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildTopicButton(String label, String key) {
    return GestureDetector(
      onTap: () => _handleTopicTap(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentGreen,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.accentGreen,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
