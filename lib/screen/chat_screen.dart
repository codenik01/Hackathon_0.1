import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; 
  bool _isTyping = false;

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
    String reply;
    String msg = userMessage.toLowerCase();

    if (msg.contains("hello") || msg.contains("hi")) {
      reply = "Hello! How can I assist you today?";
    } else if (msg.contains("help")) {
      reply = "Sure! Tell me what issue you're facing.";
    } else if (msg.contains("doctor")) {
      reply = "I can help you find nearby hospitals or book a teleconsultation.";
    } else if (msg.contains("thanks") || msg.contains("thank you")) {
      reply = "You're welcome! 😊";
    } else if (msg.contains("i have headache")) {
      reply = "You may consider paracetamol 500 mg for headache. If it persists, consult a doctor.";
    } else if (msg.contains("i have fever")) {
      reply = "You may use a fever-reducing medicine like paracetamol. If it persists, consult a doctor.";
    } else if (msg.contains("i have cold")) {
      reply = "Rest, warm fluids, and OTC cold remedies can help. If it persists, see a doctor.";
    } else if (msg.contains("i have cough")) {
      reply = "You might try a suitable cough syrup. If symptoms worsen, consult a doctor.";
    } else if (msg.contains("i have type 2 diabetes")) {
      reply = "Common medicines include metformin and insulin. Please consult a doctor for specifics.";
    } else if (msg.contains("i have hypertension")) {
      reply = "Medicines like ACE inhibitors or calcium channel blockers may be used. Please consult your physician.";
    } else if (msg.contains("i have tuberculosis")) {
      reply = "Standard treatment includes isoniazid, rifampicin, pyrazinamide, and ethambutol.";
    } else if (msg.contains("i have malaria")) {
      reply = "Artemisinin combination therapies are commonly used. Please consult a doctor.";
    } else if (msg.contains("i have typhoid")) {
      reply = "Azithromycin or ceftriaxone may be used depending on local resistance.";
    } else if (msg.contains("i have dengue")) {
      reply = "Supportive care (fluids, rest, paracetamol) is recommended. Avoid NSAIDs due to bleeding risk.";
    } else if (msg.contains("i have hiv") || msg.contains("i have aids")) {
      reply = "Antiretroviral therapy is used for HIV/AIDS. Please consult a specialist.";
    } else if (msg.contains("i have influenza")) {
      reply = "Antivirals (like oseltamivir) may be used in severe cases. See a doctor.";
    } else {
      reply = "I’m sorry, I didn’t fully understand. I’m not a doctor — please consult a healthcare professional.";
    }

    setState(() {
      _isTyping = false;
      _messages.add({
        "sender": "bot",
        "text": reply,
        "time": DateTime.now(),
      });
    });
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
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
