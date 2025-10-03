import 'dart:convert';
import 'package:care_plus/AI_Model/custom_responses.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final bool showBackButton;

  const ChatScreen({Key? key, this.chatId, this.showBackButton = false}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  List<Map<String, dynamic>> _responseData = [];
  String _currentChatId = "";
  bool _isInitialized = false;

  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _isFirstUserMessage = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Generate or use provided chat ID
      _currentChatId = widget.chatId ?? "default_chat";
      
      // Load AI responses
      await _loadResponses();
      
      // Initialize speech to text
      _speech = stt.SpeechToText();
      
      // Initialize chat session if new
      if (widget.chatId != null) {
        await _initializeNewChat();
      }
      
      // Load chat history
      await _loadChatHistory();
      
      setState(() {
        _isInitialized = true;
      });
      
    } catch (e) {
      print("Error initializing chat: $e");
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _initializeNewChat() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? sessions = prefs.getStringList("chatSessions") ?? [];
      
      if (!sessions.contains(_currentChatId)) {
        sessions.add(_currentChatId);
        await prefs.setStringList("chatSessions", sessions);
        await prefs.setString("chatName_$_currentChatId", "New Chat");
        
        // Add welcome message for new chats
        _messages.add({
          "sender": "bot",
          "text": "Hello! I'm your healthcare assistant. How can I help you today?",
          "time": DateTime.now(),
        });
        await _saveChatHistory();
      }
    } catch (e) {
      print("Error initializing new chat: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadResponses() async {
    try {
      String data = await rootBundle.loadString('assets/health_responses.json');
      setState(() {
        _responseData = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    } catch (e) {
      print("Error loading responses: $e");
      // Fallback responses
      _responseData = [
        {
          "patterns": ["hello", "hi", "hey"],
          "response": "Hello! How can I assist you with your health concerns today?"
        },
        {
          "patterns": ["headache", "head pain"],
          "response": "Headaches can have various causes. Try resting in a quiet room, staying hydrated, and avoiding bright screens. If it persists or is severe, consult a doctor."
        },
        {
          "patterns": ["fever", "temperature"],
          "response": "For fever, rest and stay hydrated. You can take acetaminophen or ibuprofen as directed. If fever is above 103°F (39.4°C) or lasts more than 3 days, see a doctor."
        }
      ];
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        "sender": "user",
        "text": text,
        "time": DateTime.now(),
      });
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Update chat name with first user message
    if (_isFirstUserMessage && widget.chatId != null) {
      _updateChatName(text);
      _isFirstUserMessage = false;
    }

    Future.delayed(Duration(milliseconds: 700), () {
      _botReply(text);
    });
  }

  void _updateChatName(String firstMessage) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? currentName = prefs.getString("chatName_$_currentChatId");
      
      // If it's still the default name, update it with the first message
      if (currentName == "New Chat") {
        String newName = firstMessage.length > 20 
            ? "${firstMessage.substring(0, 20)}..." 
            : firstMessage;
        await prefs.setString("chatName_$_currentChatId", newName);
      }
    } catch (e) {
      print("Error updating chat name: $e");
    }
  }

  void _botReply(String userMessage) {
    String msg = userMessage.toLowerCase();
    String reply = "I'm not sure about that. For accurate medical advice, please consult a healthcare professional. I'm here to provide general health information.";

    for (var item in _responseData) {
      List patterns = item["patterns"];
      for (var pattern in patterns) {
        if (msg.contains(pattern.toLowerCase())) {
          reply = item["response"];
          break;
        }
      }
    }

    setState(() {
      _isTyping = false;
      _messages.add({
        "sender": "bot",
        "text": reply,
        "time": DateTime.now(),
      });
    });

    _saveChatHistory();
    _scrollToBottom();
  }

  Future<void> _saveChatHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> chatList = _messages
          .map((msg) => jsonEncode({
                "sender": msg["sender"],
                "text": msg["text"],
                "time": msg["time"].toString(),
              }))
          .toList();
      await prefs.setStringList("chatHistory_$_currentChatId", chatList);
    } catch (e) {
      print("Error saving chat history: $e");
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? chatList = prefs.getStringList("chatHistory_$_currentChatId");
      if (chatList != null && chatList.isNotEmpty) {
        setState(() {
          _messages.clear();
          _messages.addAll(chatList.map((item) {
            var decoded = jsonDecode(item);
            return {
              "sender": decoded["sender"],
              "text": decoded["text"],
              "time": DateTime.parse(decoded["time"]),
            };
          }));
        });
        _scrollToBottom();
      } else if (widget.chatId == null) {
        // Default welcome message for main chat
        _messages.add({
          "sender": "bot",
          "text": "Hello! I'm your healthcare assistant. How can I help you today?",
          "time": DateTime.now(),
        });
      }
    } catch (e) {
      print("Error loading chat history: $e");
    }
  }

  void _startListening() async {
    if (_speech == null) return;

    try {
      bool available = await _speech!.initialize(
        onStatus: (val) => print('Status: $val'),
        onError: (val) => print('Error: $val'),
      );

      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Speech recognition not available")),
        );
        return;
      }

      setState(() => _isListening = true);

      _speech!.listen(
        onResult: (val) {
          setState(() {
            _messageController.text = val.recognizedWords;
          });
        },
      );
    } catch (e) {
      print("Error starting speech recognition: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error starting speech recognition")),
      );
    }
  }

  void _stopListening() {
    try {
      setState(() => _isListening = false);
      _speech?.stop();
    } catch (e) {
      print("Error stopping speech recognition: $e");
    }
  }

  void _clearChat() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Clear Chat"),
          content: Text("Are you sure you want to clear all messages in this chat?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _messages.clear();
                });
                try {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.remove("chatHistory_$_currentChatId");
                  
                  // Add welcome message back
                  _messages.add({
                    "sender": "bot",
                    "text": "Hello! I'm your healthcare assistant. How can I help you today?",
                    "time": DateTime.now(),
                  });
                  await _saveChatHistory();
                  _scrollToBottom();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Chat cleared")),
                  );
                } catch (e) {
                  print("Error clearing chat: $e");
                }
              },
              child: Text("Clear", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, int index) {
    bool isUser = msg["sender"] == "user";
    Color bubbleColor = isUser ? Colors.green[100]! : Colors.white;
    Color textColor = isUser ? Colors.black : Colors.black87;
    Alignment alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Align(
        alignment: alignment,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: isUser ? Radius.circular(12) : Radius.circular(0),
              bottomRight: isUser ? Radius.circular(0) : Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                msg["text"] ?? "",
                style: TextStyle(fontSize: 16, color: textColor),
              ),
              SizedBox(height: 4),
              Text(
                _formatTime(msg["time"] as DateTime),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    String hh = t.hour.toString().padLeft(2, '0');
    String mm = t.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Initializing Chat..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("AI Healthcare Assistant"),
        backgroundColor: Colors.green[700],
        elevation: 0,
        leading: widget.showBackButton 
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            : null,
            
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _clearChat,
            tooltip: "Clear Chat",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat message list
            Expanded(
              child: _messages.isEmpty && !_isTyping
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
                          SizedBox(height: 20),
                          Text(
                            "Start a conversation",
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Ask me about health concerns or symptoms",
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(top: 12, bottom: 12),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, idx) {
                        if (_isTyping && idx == _messages.length) {
                          return _buildTypingIndicator();
                        } else {
                          return _buildBubble(_messages[idx], idx);
                        }
                      },
                    ),
            ),

            // Input bar at bottom
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red[100] : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        if (_isListening) {
                          _stopListening();
                        } else {
                          _startListening();
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Type or speak your message...",
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                        onSubmitted: (value) => _sendMessage(),
                        maxLines: null,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    child: ElevatedButton(
                      onPressed: _sendMessage,
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(12),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "AI is typing",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(width: 8),
            Row(
              children: [
                _buildTypingDot(0),
                _buildTypingDot(1),
                _buildTypingDot(2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey[600],
          shape: BoxShape.circle,
        ),
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: (index + 1) * 0.33 * value,
              child: child,
            );
          },
          child: Container(),
        ),
      ),
    );
  }
}