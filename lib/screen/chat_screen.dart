import 'dart:convert';

import 'package:care_plus/AI_Model/custom_responses.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; 
  bool _isTyping = false;
  List<Map<String, dynamic>> _responseData = [];

  stt.SpeechToText? _speech;

bool _isListening = false;



  @override
void initState() {
  super.initState();
  _loadResponses();
  _loadChatHistory();
  _speech = stt.SpeechToText();
  

}


Future<void> _loadResponses() async {
  String data = await rootBundle.loadString('assets/health_responses.json');
  setState(() {
    _responseData = List<Map<String, dynamic>>.from(jsonDecode(data));
  });
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

    Future.delayed(Duration(milliseconds: 700), () {
      _botReply(text);
    });
  }

void _botReply(String userMessage) {
  String msg = userMessage.toLowerCase();
  String reply = "I'm not sure. Please consult a healthcare professional.";

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

  _saveChatHistory(); // Coming in next step
}


Future<void> _saveChatHistory() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> chatList = _messages
      .map((msg) => jsonEncode({
            "sender": msg["sender"],
            "text": msg["text"],
            "time": msg["time"].toString(),
          }))
      .toList();
  await prefs.setStringList("chatHistory", chatList);
}

Future<void> _loadChatHistory() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? chatList = prefs.getStringList("chatHistory");
  if (chatList != null) {
    setState(() {
      _messages.clear();
      _messages.addAll(chatList.map((item) => {
            "sender": jsonDecode(item)["sender"],
            "text": jsonDecode(item)["text"],
            "time": DateTime.parse(jsonDecode(item)["time"]),
          }));
    });
  }
}

void _startListening() async {
  if (_speech == null) return;

  bool available = await _speech!.initialize(
    onStatus: (val) => print('Status: $val'),
    onError: (val) => print('Error: $val'),
  );

  if (!available) return;

  setState(() => _isListening = true);

  _speech!.listen(
    onResult: (val) {
      setState(() {
        _messageController.text = val.recognizedWords;
      });
    },
  );
}



void _stopListening() {
  setState(() => _isListening = false);
  _speech!.stop();
}




  Widget _buildBubble(Map<String, dynamic> msg) {
    bool isUser = msg["sender"] == "user";
    Color bubbleColor = isUser ? Colors.green[200]! : Colors.white;
    Color textColor = isUser ? Colors.black : Colors.black87;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
    );
  }

  String _formatTime(DateTime t) {
    String hh = t.hour.toString().padLeft(2, '0');
    String mm = t.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("AI Healthcare Assistant"),
        backgroundColor: Colors.green[700],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat message list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 12, bottom: 12),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, idx) {
                  if (_isTyping && idx == _messages.length) {
                    // show typing indicator bubble
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
                        child: Text(
                          "Typing...",
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ),
                    );
                  } else {
                    return _buildBubble(_messages[idx]);
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
    IconButton(
      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
      onPressed: () {
        if (_isListening) {
          _stopListening();
        } else {
          _startListening();
        }
      },
    ),
    Expanded(
      child: TextField(
        controller: _messageController,
        decoration: InputDecoration(
          hintText: "Type or speak your message...",
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    ),
    SizedBox(width: 8),
    ElevatedButton(
      onPressed: _sendMessage,
      child: Text("Send"),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    ),
  ],
)

            ),
          ],
        ),
      ),
    );
  }
}
