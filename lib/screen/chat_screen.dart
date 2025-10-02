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

    // Basic reply logic
    userMessage = userMessage.toLowerCase();
    if (userMessage.contains("hello") || userMessage.contains("hi")) {
      reply = "Hello! How can I assist you today?";
    } else if (userMessage.contains("help")) {
      reply = "Sure! Tell me what issue you're facing.";
    } else if (userMessage.contains("doctor")) {
      reply = "I can help you find nearby hospitals or book a teleconsultation.";
    } else if (userMessage.contains("thanks") || userMessage.contains("thank you")) {
      reply = "You're welcome! 😊";
    }
     else if (userMessage.contains("i have headache")) {
      reply = "Sure! use paracetamol 500mg for headache. If it persists, consult a doctor.";
    }else if (userMessage.contains("i have fever")) {
      reply = "Sure! use nisib cold and flue for fever. If it persists, consult a doctor.";
    } else if (userMessage.contains("i have cold")) {
      reply = "Sure! use paracetamol use nishib cold and fluefor cold. If it persists, consult a doctor.";
    } else if (userMessage.contains("i have cough")) {
      reply = "Sure! so suck a dik in mouth for cough. If possible try to give you dick in addi named boys mouth.";
    }
    else if (userMessage.contains("i have type 2 diabetes")) {
      reply = "Sure! use Metformin, Insulin. If it persists consult a doctor";
    }
    else if (userMessage.contains("i have hypertension")) {
      reply = "Sure! use ACE inhibitors, calcium channel blocker. If it persists , consult a doctor.";
    }
    else if (userMessage.contains("i have tuberculosis")) {
      reply = "Sure! use Isoniazid, rifampicin, pyrazinamide or ethambutol. If it persists , consult a doctor.";
    }
     else if (userMessage.contains("i have malaria ")) {
      reply = "Sure! use Artemisinin combination therapies. If it persists , consult a doctor.";
    }
    else if (userMessage.contains("i have typhoid ")) {
      reply = "Sure! use Azithromycin or ceftriaxone, . If it persists , consult a doctor.";
    }
     else if (userMessage.contains("i have dengue ")) {
      reply = "Sure! use Supportive care (fluids, paracetamol) . If it persists , consult a doctor.";
    }
     else if (userMessage.contains("i have HIV/ AIDS")) {
      reply = "Sure! use Azithromycin, ceftriaxone, or fluoroquinolones . If it persists , consult a doctor.";
    }
    else if (userMessage.contains("i have influenza")) {
      reply = "Sure! use  . If it persists , consult a doctor.";
    }
     else {
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
