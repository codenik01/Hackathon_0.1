import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart'; // Add this import
import 'package:http/http.dart' as http;

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

  // Voice Input & Output
  stt.SpeechToText? _speech;
  FlutterTts? _flutterTts;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isFirstUserMessage = true;

  // Groq AI Configuration
  final String _groqApiKey = "";
  final String _groqModel = "qwen/qwen3-32b";

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _initializeTTS();
  }

  Future<void> _initializeChat() async {
    try {
      _currentChatId = widget.chatId ?? "default_chat_${DateTime.now().millisecondsSinceEpoch}";
      await _loadResponses();
      _speech = stt.SpeechToText();
      
      if (widget.chatId != null) {
        await _initializeNewChat();
      }
      
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

  // Initialize Text-to-Speech
  Future<void> _initializeTTS() async {
    _flutterTts = FlutterTts();
    
    // Configure TTS settings
    await _flutterTts?.setLanguage("en-US");
    await _flutterTts?.setSpeechRate(0.5); // Slightly slower for medical content
    await _flutterTts?.setVolume(1.0);
    await _flutterTts?.setPitch(1.0);
    
    // Set up completion handler
    _flutterTts?.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
    
    _flutterTts?.setErrorHandler((msg) {
      print("TTS Error: $msg");
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  // Speak the response
  Future<void> _speakResponse(String text) async {
    if (_flutterTts == null) return;
    
    try {
      setState(() {
        _isSpeaking = true;
      });
      
    
      String cleanText = _cleanTextForSpeech(text);
      
      await _flutterTts?.speak(cleanText);
    } catch (e) {
      print("Error in TTS: $e");
      setState(() {
        _isSpeaking = false;
      });
    }
  }

 
  Future<void> _stopSpeaking() async {
    if (_flutterTts == null) return;
    
    try {
      await _flutterTts?.stop();
      setState(() {
        _isSpeaking = false;
      });
    } catch (e) {
      print("Error stopping TTS: $e");
    }
  }

  String _cleanTextForSpeech(String text) {

    return text
        .replaceAll(RegExp(r'\*.*?\*'), '') // Remove bold text
        .replaceAll(RegExp(r'#'), '') // Remove headers
        .replaceAll(RegExp(r'\[.*?\]'), '') // Remove links
        .replaceAll(RegExp(r'\(.*?\)'), '') // Remove parentheses content
        .replaceAll(RegExp(r'[^\w\s.,!?;:]'), '') // Remove special characters but keep punctuation
        .replaceAll('🚨', 'Warning:') // Convert emojis to text
        .replaceAll('🤕', 'Headache')
        .replaceAll('🌀', 'Migraine')
        .replaceAll('🌡️', 'Fever')
        .replaceAll('🤧', 'Cold')
        .replaceAll('😷', 'Cough')
        .replaceAll('🤢', 'Stomach')
        .replaceAll('😌', 'Stress')
        .replaceAll('🧘', 'Anxiety')
        .replaceAll('😴', 'Sleep')
        .replaceAll('💪', 'Exercise')
        .replaceAll('🥗', 'Diet')
        .replaceAll('👋', 'Hello')
        .replaceAll('🙏', 'Thank you')
        .replaceAll('💚', '')
        .replaceAll('🤖', '')
        .replaceAll('✅', '')
        .replaceAll('❌', '')
        .replaceAll('⚠️', 'Note:')
        .trim();
  }

  Future<void> _initializeNewChat() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? sessions = prefs.getStringList("chatSessions") ?? [];
      
      if (!sessions.contains(_currentChatId)) {
        sessions.add(_currentChatId);
        await prefs.setStringList("chatSessions", sessions);
        await prefs.setString("chatName_$_currentChatId", "New Chat");
        
        _messages.add({
          "sender": "bot",
          "text": "Hello! I'm your AI healthcare assistant powered by Groq AI. I can help you with general health information, symptom guidance, and wellness advice. What would you like to know about today?",
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
      _responseData = [
        {
          "patterns": ["hello", "hi", "hey"],
          "response": "Hello! I'm your healthcare assistant. How can I help you today?"
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

    if (_isFirstUserMessage && widget.chatId != null) {
      _updateChatName(text);
      _isFirstUserMessage = false;
    }

    _getAIResponse(text);
  }

  Future<void> _getAIResponse(String userMessage) async {
    try {
      String response = "";
      
     
      String customResponse = _getSmartHealthResponse(userMessage);
      
    
      if (_shouldUseGroqAI(customResponse, userMessage)) {
        print("🔄 Using Groq AI for response...");
        response = await _getGroqResponse(userMessage);
      } else {
        print("✅ Using custom health response");
        response = customResponse;
    
        await Future.delayed(Duration(milliseconds: 1000 + (userMessage.length * 5)));
      }

      setState(() {
        _isTyping = false;
        _messages.add({
          "sender": "bot",
          "text": response,
          "time": DateTime.now(),
        });
      });

      _saveChatHistory();
      _scrollToBottom();

    
      _speakResponse(response);

    } catch (e) {
      print("Error getting AI response: $e");
      
  
      String fallbackResponse = _getSmartHealthResponse(userMessage);
      
      setState(() {
        _isTyping = false;
        _messages.add({
          "sender": "bot",
          "text": fallbackResponse,
          "time": DateTime.now(),
        });
      });
      
      _saveChatHistory();
      _scrollToBottom();
      

      _speakResponse(fallbackResponse);
    }
  }

  bool _shouldUseGroqAI(String customResponse, String userMessage) {
    String msg = userMessage.toLowerCase();
    
    if (!_isHealthRelated(msg)) {
      return true;
    }
    
    List<String> genericResponses = [
      "🤔 **Health Inquiry**",
      "💡 **Healthcare Assistant**",
      "Thank you for your message"
    ];
    
    bool isGenericResponse = genericResponses.any((pattern) => customResponse.contains(pattern));
    
    return isGenericResponse;
  }

  Future<String> _getGroqResponse(String input) async {
    final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $_groqApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": _groqModel,
          "messages": [
            {
              "role": "system",
              "content": """You are a helpful healthcare assistant. Provide general health information, symptom guidance, and wellness advice. 
              IMPORTANT: 
              - DO NOT repeat the user's question in your response
              - DO NOT include phrases like "thinking", "let me", "I understand you asked about"
              - Start directly with the answer
              - Be concise and professional
              - Always include medical disclaimers
              - Provide evidence-based information
              - Use clear, easy-to-understand language
              - Format responses with bullet points when helpful
              - Focus on general wellness and when to seek professional help"""
            },
            {"role": "user", "content": input}
          ],
          "temperature": 0.7,
          "max_tokens": 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          String aiResponse = data['choices'][0]['message']['content'] ?? "🤖 No response.";
          
        
          aiResponse = _cleanGroqResponse(aiResponse, input);
          
     
          if (!aiResponse.toLowerCase().contains('consult') && 
              !aiResponse.toLowerCase().contains('doctor') && 
              !aiResponse.toLowerCase().contains('professional')) {
            aiResponse += "\n\n*Please consult with a healthcare professional for personalized medical advice.*";
          }
          
          return aiResponse;
        } else {
          return "🤖 No valid response from AI.";
        }
      } else {
        return "❌ Error ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      return "⚠️ Network error: $e";
    }
  }

  String _cleanGroqResponse(String aiResponse, String userInput) {
    String cleaned = aiResponse;
    
    List<String> thinkingPhrases = [
      "thinking",
      "let me",
      "I understand you asked about",
      "you mentioned",
      "you asked about",
      "based on your question",
      "regarding your query"
    ];
    
    for (String phrase in thinkingPhrases) {
      if (cleaned.toLowerCase().contains(phrase)) {
        int phraseIndex = cleaned.toLowerCase().indexOf(phrase);
        if (phraseIndex != -1) {
          int endOfPhrase = cleaned.indexOf('.', phraseIndex);
          if (endOfPhrase != -1) {
            cleaned = cleaned.substring(endOfPhrase + 1).trim();
          }
        }
      }
    }
    
    if (cleaned.toLowerCase().contains(userInput.toLowerCase())) {
      cleaned = cleaned.replaceAll(userInput, '').trim();
    }
    
    if (cleaned.startsWith(':') || cleaned.startsWith('-')) {
      cleaned = cleaned.substring(1).trim();
    }
    
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    
    return cleaned;
  }


  void _startListening() async {
    if (_speech == null) return;

    try {
      bool available = await _speech!.initialize(
        onStatus: (val) => print('Speech Status: $val'),
        onError: (val) => print('Speech Error: $val'),
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
          
          // Auto-send when user stops speaking (if we have text)
          if (val.finalResult && val.recognizedWords.isNotEmpty) {
            _sendMessageFromVoice(val.recognizedWords);
          }
        },
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 3),
        cancelOnError: true,
        partialResults: true,
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

  void _sendMessageFromVoice(String text) {
    if (text.trim().isEmpty) return;

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

    if (_isFirstUserMessage && widget.chatId != null) {
      _updateChatName(text);
      _isFirstUserMessage = false;
    }

    _getAIResponse(text);
  }


  Widget _buildVoiceControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
    
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: _isListening ? Colors.red[100] : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _isListening ? Icons.mic_off : Icons.mic,
              color: _isListening ? Colors.red : Colors.green[700],
              size: 28,
            ),
            onPressed: () {
              if (_isListening) {
                _stopListening();
              } else {
                _startListening();
              }
            },
            tooltip: _isListening ? "Stop Recording" : "Start Voice Input",
          ),
        ),
        
        SizedBox(width: 20),
        
        // Speaker Button for Output
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: _isSpeaking ? Colors.green[100] : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
              color: _isSpeaking ? Colors.green[700] : Colors.grey[600],
              size: 28,
            ),
            onPressed: () {
              if (_isSpeaking) {
                _stopSpeaking();
              } else if (_messages.isNotEmpty && _messages.last["sender"] == "bot") {
                // Speak the last bot message
                _speakResponse(_messages.last["text"]);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("No response to speak")),
                );
              }
            },
            tooltip: _isSpeaking ? "Stop Speaking" : "Repeat Last Response",
          ),
        ),
      ],
    );
  }


  String _getSmartHealthResponse(String userMessage) {
  
    String msg = userMessage.toLowerCase();
    
    Map<String, String> healthDatabase = {
      'headache': """🤕 **Headache Management**

**Quick Relief:**
• Rest in a quiet, dark room
• Apply cool compress to forehead
• Stay hydrated with water
• Gentle neck stretches
• Consider OTC pain relief as directed

**When to See a Doctor:**
🚨 Sudden, severe headache
🚨 Headache with fever or stiff neck
🚨 Headache after head injury
🚨 Vision changes or confusion
🚨 Headache that worsens despite treatment

*For chronic headaches, consult a healthcare provider.*""",

      'migraine': """🌀 **Migraine Care**

**During Attack:**
• Rest in dark, quiet environment
• Cold packs to head/neck
• Stay hydrated
• Avoid strong smells and lights
• Use prescribed medications

**Prevention:**
• Identify triggers (food, stress, sleep)
• Regular sleep schedule
• Stress management
• Stay hydrated
• Consider preventive meds if frequent

*Keep a migraine diary to track patterns.*""",


      'fever': """🌡️ **Fever Management**

**Home Care:**
• Rest and hydrate well
• Use acetaminophen/ibuprofen as directed
• Light clothing
• Lukewarm baths if comfortable
• Monitor temperature regularly

**Seek Medical Care:**
🚨 Fever above 103°F (39.4°C)
🚨 Lasts more than 3 days
🚨 With rash, stiff neck, or confusion
🚨 Difficulty breathing
🚨 Signs of dehydration

*Infants with fever need immediate care.*""",

      
    };

    // Emergency detection
    if (_isEmergency(msg)) {
      return """🚨 **MEDICAL EMERGENCY**

**Call Emergency Services or Go to Hospital For:**
• Chest pain or pressure
• Difficulty breathing
• Severe bleeding
• Sudden weakness/confusion
• Suicidal thoughts
• Severe allergic reaction
• Stroke symptoms (FAST)

**Your safety is the top priority!**
Don't delay seeking appropriate medical care.""";
    }

    
    for (String keyword in healthDatabase.keys) {
      if (msg.contains(keyword)) {
        return healthDatabase[keyword]!;
      }
    }

   
    if (_isGreeting(msg)) {
      return """👋 **Hello! I'm Your Healthcare Assistant**

I can help with:
• **General health information**
• **Symptom guidance** 
• **Wellness advice**
• **Lifestyle recommendations**

**What would you like to know about today?**

*Note: I provide general information only. Always consult healthcare professionals for medical advice.*""";
    }

    if (_isThanks(msg)) {
      return """🙏 **You're Welcome!**

I'm glad I could help. Remember:
• **Persistent symptoms** - See a healthcare provider
• **Emergencies** - Seek immediate care
• **Personalized advice** - Consult your doctor

**Stay proactive about your health!** 💚""";
    }

    if (_isHealthRelated(msg)) {
      return """🤔 **Health Inquiry**

I understand you're asking about health topics. Here's how I can help:

**I can provide:**
• General wellness information
• Symptom explanation
• Lifestyle recommendations
• Preventive health tips

**Please consult professionals for:**
• Medical diagnoses
• Treatment plans
• Emergency situations
• Persistent symptoms

**What health information can I provide?**""";
    }

    return """💡 **Healthcare Assistant**

I specialize in general health information and wellness guidance. 

If you have questions about:
• Common symptoms and management
• Healthy lifestyle practices
• Wellness strategies
• When to seek medical care

I'd be happy to help!

**What would you like to know?**""";
  }


  bool _isEmergency(String message) {
    List<String> emergencies = [
      'chest pain', 'heart attack', 'stroke', 'can\'t breathe', 
      'difficulty breathing', 'severe pain', 'unconscious', 
      'suicidal', 'emergency', '911', 'bleeding heavily', 'choking'
    ];
    return emergencies.any((emergency) => message.contains(emergency));
  }

  bool _isHealthRelated(String message) {
    List<String> healthKeywords = [
      'pain', 'hurt', 'sick', 'ill', 'fever', 'cough', 'headache', 
      'stomach', 'nausea', 'vomit', 'dizzy', 'tired', 'sleep', 
      'stress', 'anxiety', 'medicine', 'drug', 'pill', 'doctor',
      'hospital', 'clinic', 'symptom', 'diagnosis', 'treatment',
      'health', 'wellness', 'exercise', 'diet', 'nutrition'
    ];
    return healthKeywords.any((keyword) => message.contains(keyword));
  }

  bool _isGreeting(String message) {
    List<String> greetings = ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening'];
    return greetings.any((greeting) => message.contains(greeting));
  }

  bool _isThanks(String message) {
    List<String> thanks = ['thank', 'thanks', 'appreciate', 'grateful'];
    return thanks.any((word) => message.contains(word));
  }


  void _updateChatName(String firstMessage) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? currentName = prefs.getString("chatName_$_currentChatId");
      
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
        _messages.add({
          "sender": "bot",
          "text": """👋 **Hello! I'm Your Healthcare Assistant**

I can help with:
• **General health information**
• **Symptom guidance** 
• **Wellness advice**
• **Lifestyle recommendations**

**What would you like to know about today?**

*Note: I provide general information only. Always consult healthcare professionals for medical advice.*""",
          "time": DateTime.now(),
        });
      }
    } catch (e) {
      print("Error loading chat history: $e");
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
                  
                  _messages.add({
                    "sender": "bot",
                    "text": """👋 **Hello! I'm Your Healthcare Assistant**

I'm here to help with general health information and wellness guidance. What would you like to know about today?""",
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
              Text("Initializing Healthcare Assistant..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Healthcare Assistant"),
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
            // Voice Controls
            Container(
              color: Colors.green[50],
              padding: EdgeInsets.symmetric(vertical: 8),
              child: _buildVoiceControls(),
            ),
            
            Expanded(
              child: _messages.isEmpty && !_isTyping
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services, size: 80, color: Colors.green[300]),
                          SizedBox(height: 20),
                          Text(
                            "Healthcare Assistant",
                            style: TextStyle(fontSize: 20, color: Colors.green[700], fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Use voice or text to ask about health concerns",
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "🎤 Tap microphone to speak\n🔊 Tap speaker to hear responses",
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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

            // Input Section
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
                        _isListening ? Icons.mic_off : Icons.mic,
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
                          hintText: "Type or use voice to ask about health...",
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
                  
                  // Send button
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
              "Assistant is thinking...",
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
          color: Colors.green[600],
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

  @override
  void dispose() {
    _stopSpeaking();
    _stopListening();
    _flutterTts?.stop();
    super.dispose();
  }
}
