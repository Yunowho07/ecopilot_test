import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class EcoAssistantScreen extends StatefulWidget {
  const EcoAssistantScreen({super.key});

  @override
  State<EcoAssistantScreen> createState() => _EcoAssistantScreenState();
}

class _EcoAssistantScreenState extends State<EcoAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  late final GenerativeModel _model;
  DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      debugPrint('⚠️ WARNING: GEMINI_API_KEY is not set in .env file');
    }

    _model = GenerativeModel(
      model: 'gemini-2.0-flash-lite', // More stable than experimental version
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 512, // Reduced to save quota
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
      systemInstruction: Content.text(
        '''You are EcoBot, a friendly and knowledgeable eco-assistant for the EcoPilot app. 
        Your role is to help users:
        1. Learn about recycling, waste sorting, and proper disposal methods for different materials  
        2. Understand eco-friendliness scores (A–E rating system) and what affects a product’s sustainability  
        3. Provide daily eco tips and guidance on sustainable living to help reduce carbon footprint  
        4. Assist users in navigating app features like Daily Eco Challenges, Eco Points, and Better Alternatives  
        5. Answer questions about product ingredients, packaging types, and their environmental impact  
        6. Suggest greener product alternatives or DIY eco-friendly solutions  
        7. Track user progress toward eco goals and encourage them to level up their Eco Rank  
        8. Explain how users can earn and redeem Eco Points for achievements and challenges  
        9. Share updates about environmental news, eco trends, and green innovations  
        10. Offer personalized recommendations based on users’ scanning history or recent activity  
        11. Provide educational facts about recycling symbols, materials, and local recycling centers  
        12. Motivate users with positive messages to stay consistent in their sustainability journey  
        13. Help troubleshoot app features or guide users on where to find certain functions  
        14. Support community engagement by suggesting ways to contribute (e.g., reporting missing product info or verifying eco data)
        
        Keep responses concise (2-3 sentences max), friendly, and actionable.
        Use emojis appropriately to make the conversation engaging.
        If asked about specific products, guide users to scan them using the app.
        Always promote sustainable practices and celebrate users' eco-efforts.''',
      ),
    );
    _sendWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendWelcomeMessage() {
    if (_messages.isEmpty) {
      final welcomeMessage = ChatMessage(
        text:
            "Hi! I'm your Eco Assistant! 🌱 Ask me anything about recycling, eco-scores, sustainable living, or how to use the app!",
        isUser: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(welcomeMessage);
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Rate limiting check
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please wait ${(_minRequestInterval.inSeconds - timeSinceLastRequest.inSeconds)} seconds before sending another message.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _messageController.clear();
    });

    _scrollToBottom();

    // Update last request time
    _lastRequestTime = DateTime.now();

    try {
      // Create a simpler, more direct prompt
      final response = await _model.generateContent([Content.text(text)]);

      // Check if response has text
      String botResponse;
      if (response.text != null && response.text!.isNotEmpty) {
        botResponse = response.text!;
      } else {
        // Check candidates
        if (response.candidates.isNotEmpty) {
          final candidate = response.candidates.first;
          botResponse = candidate.content.parts
              .whereType<TextPart>()
              .map((part) => part.text)
              .join('\n');

          if (botResponse.isEmpty) {
            botResponse =
                "I'm here to help! Could you rephrase your question? 🌱";
          }
        } else {
          botResponse =
              "I'm here to help! Could you rephrase your question? 🌱";
        }
      }

      final botMessage = ChatMessage(
        text: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(botMessage);
          _isLoading = false;
        });

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error getting AI response: $e');
      debugPrint('Error details: ${e.toString()}');

      String errorText = "Sorry, I encountered an error. Please try again! 😅";

      // Provide more specific error messages
      if (e.toString().contains('API key') ||
          e.toString().contains('INVALID_ARGUMENT')) {
        errorText =
            "⚠️ API key issue detected. Please check your Gemini API configuration in the .env file.";
      } else if (e.toString().contains('quota') ||
          e.toString().contains('RESOURCE_EXHAUSTED')) {
        errorText =
            "⏰ API usage limit reached. The free tier allows 15 requests per minute. Please wait a moment and try again.\n\nTip: You can get a new API key or upgrade at aistudio.google.com";
      } else if (e.toString().contains('network') ||
          e.toString().contains('Failed host lookup')) {
        errorText =
            "📡 Network error. Please check your internet connection and try again.";
      } else if (e.toString().contains('429')) {
        errorText =
            "⏰ Too many requests. Please wait 30-60 seconds before trying again.";
      }

      final errorMessage = ChatMessage(
        text: errorText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(errorMessage);
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Quick action buttons
  void _sendQuickAction(String question) {
    _messageController.text = question;
    _sendMessage(question);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/chatbot.png',
                width: 40,
                height: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eco Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Powered by AI',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat History'),
                  content: const Text(
                    'Are you sure you want to clear all messages?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                setState(() {
                  _messages.clear();
                });
                _sendWelcomeMessage();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick action buttons
          if (_messages.length <= 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Questions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickActionChip(
                        '♻️ How to recycle plastic?',
                        'How do I properly recycle plastic products?',
                      ),
                      _buildQuickActionChip(
                        '🌱 Daily Eco Challenge',
                        'Tell me about Daily Eco Challenges',
                      ),
                      _buildQuickActionChip(
                        '⭐ Earn Eco Points',
                        'How can I earn more Eco Points?',
                      ),
                      _buildQuickActionChip(
                        '📊 Eco Score Meaning',
                        'What do the eco-scores A-E mean?',
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kPrimaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Thinking...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything eco-friendly...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryGreen.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _sendMessage(_messageController.text),
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

  Widget _buildQuickActionChip(String label, String question) {
    return InkWell(
      onTap: () => _sendQuickAction(question),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kPrimaryGreen.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: kPrimaryGreen,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? LinearGradient(
                        colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.8)],
                      )
                    : null,
                color: message.isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.grey.shade800,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                DateFormat('h:mm a').format(message.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
