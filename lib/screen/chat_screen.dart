import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = []; // { "sender": "...", "text": "..." }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({"sender": "user", "text": text});
      });
      _messageController.clear();

      // Trigger bot reply
      Future.delayed(Duration(milliseconds: 500), () {
        _botReply(text);
      });
    }
  }

  void _botReply(String userMessage) {
  String reply;

  userMessage = userMessage.toLowerCase();

  if (userMessage.contains("hello") || userMessage.contains("hi")) {
    reply = "Hello! How can I assist you today?";
  } else if (userMessage.contains("help")) {
    reply = "Sure! Tell me what issue you're facing.";
  } else if (userMessage.contains("doctor")) {
    reply = "I can help you find nearby hospitals or book a teleconsultation.";
  } else if (userMessage.contains("thanks") || userMessage.contains("thank you")) {
    reply = "You're welcome! 😊";
  } else if (userMessage.contains("i have headache")) {
    reply = "You can take Paracetamol 500mg. If it persists, please consult a doctor.";
  } else if (userMessage.contains("i have fever")) {
    reply = "You may use paracetamol and stay hydrated. If the fever continues, visit a doctor.";
  } else if (userMessage.contains("i have cold")) {
    reply = "Try steam inhalation and warm fluids. If it doesn't improve, consult a doctor.";
  } else if (userMessage.contains("i have cough")) {
    reply = "Warm water, honey, and steam may help. If the cough persists, consult a doctor.";
  } else if (userMessage.contains("i have type 2 diabetes")) {
    reply = "Metformin is commonly prescribed. Please follow your doctor's advice.";
  } else if (userMessage.contains("i have hypertension")) {
    reply = "ACE inhibitors and lifestyle changes may help. Consult your physician.";
  } else if (userMessage.contains("i have tuberculosis")) {
    reply = "Treatment includes isoniazid, rifampicin, etc. Please follow medical supervision.";
  } else if (userMessage.contains("i have malaria")) {
    reply = "Artemisinin combination therapies are commonly used. Visit a hospital immediately.";
  } else if (userMessage.contains("i have typhoid")) {
    reply = "Azithromycin or ceftriaxone may help. Seek medical care urgently.";
  } else if (userMessage.contains("i have dengue")) {
    reply = "Take rest, stay hydrated, and use paracetamol. Avoid NSAIDs. Consult a doctor if symptoms worsen.";
  } else if (userMessage.contains("i have hiv") || userMessage.contains("i have aids")) {
    reply = "Only ART treatment under a doctor’s supervision is recommended.";
  } else if (userMessage.contains("i have influenza")) {
    reply = "Get rest, fluids, and fever medication. If breathing issues occur, seek care.";
  } else {
    reply = "I didn’t fully understand, but I’m here to help!";
  }

  setState(() {
    _messages.add({"sender": "bot", "text": reply});
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = _messages[index]["sender"] == "user";
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _messages[index]["text"]!,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Field + Send Button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: Text("Send"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
