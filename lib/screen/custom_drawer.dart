import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screen/login_screen.dart';
import '../screen/chat_screen.dart';

class CustomDrawer extends StatefulWidget {
  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  List<String> _chatSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
  }

  Future<void> _loadChatSessions() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? sessions = prefs.getStringList("chatSessions");
      
      setState(() {
        _chatSessions = sessions?.reversed.toList() ?? []; // Show newest first
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading chat sessions: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

Future<void> _createNewChat() async {
  try {
    String newChatId = DateTime.now().millisecondsSinceEpoch.toString();
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
   
    List<String> updatedSessions = List.from(_chatSessions);
    updatedSessions.add(newChatId);
    

    await prefs.setStringList("chatSessions", updatedSessions);
    await prefs.setString("chatName_$newChatId", "New Chat");
    
    setState(() {
      _chatSessions = updatedSessions.reversed.toList();
    });
    
  
    Navigator.pop(context); 
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: newChatId, showBackButton: true),
      ),
    );
  } catch (e) {
    print("Error creating new chat: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error creating new chat")),
    );
  }
}

Future<void> _loadChat(String chatId) async {
  
  Navigator.pop(context); 
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChatScreen(chatId: chatId, showBackButton: true),
    ),
  );
}

 
  Future<void> _deleteChat(String chatId, int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Chat"),
          content: Text("Are you sure you want to delete this chat?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                try {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  
        
                  List<String> updatedSessions = List.from(_chatSessions);
                  updatedSessions.removeAt(index);
                  
                  // Remove chat data
                  await prefs.remove("chatHistory_$chatId");
                  await prefs.remove("chatName_$chatId");
                  await prefs.setStringList("chatSessions", updatedSessions);
                  
                  setState(() {
                    _chatSessions = updatedSessions;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Chat deleted successfully")),
                  );
                } catch (e) {
                  print("Error deleting chat: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error deleting chat")),
                  );
                }
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } catch (e) {
      print("Logout error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFF2F3F7),
        child: Column(
          children: [
        
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 120,
              width: double.infinity,
              color: const Color(0xFFE5E7EB),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(),
                  const Text(
                    "MENU",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

         
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.add, color: Colors.white),
                  title: Text(
                    "New Chat",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                  onTap: _createNewChat,
                ),
              ),
            ),

            const SizedBox(height: 10),

            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      "Chat History",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : _chatSessions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
                                    SizedBox(height: 10),
                                    Text(
                                      "No chats yet",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                itemCount: _chatSessions.length,
                                itemBuilder: (context, index) {
                                  return _buildChatItem(_chatSessions[index], index);
                                },
                              ),
                  ),
                ],
              ),
            ),

     
            Padding(
              padding: const EdgeInsets.all(15),
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: () => logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(String chatId, int index) {
    return FutureBuilder<Map<String, String>>(
      future: _getChatInfo(chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.grey[300]),
              title: Container(
                height: 16,
                width: 100,
                color: Colors.grey[300],
              ),
              subtitle: Container(
                height: 12,
                width: 150,
                color: Colors.grey[200],
              ),
            ),
          );
        }

        final chatName = snapshot.data?['name'] ?? "Chat ${index + 1}";
        final lastMessage = snapshot.data?['lastMessage'] ?? "No messages yet";
        
        return Dismissible(
          key: Key(chatId),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) => _deleteChat(chatId, index),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(Icons.chat_bubble_outline, color: Colors.green[700]),
              title: Text(chatName),
              subtitle: Text(
                lastMessage,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () => _loadChat(chatId),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _getChatInfo(String chatId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String chatName = prefs.getString("chatName_$chatId") ?? "Chat";
      
      List<String>? chatHistory = prefs.getStringList("chatHistory_$chatId");
      String lastMessage = "No messages yet";
      
      if (chatHistory != null && chatHistory.isNotEmpty) {
        try {
          var lastMsgData = jsonDecode(chatHistory.last);
          lastMessage = lastMsgData["text"] ?? "No messages";
        
          if (lastMessage.length > 30) {
            lastMessage = lastMessage.substring(0, 30) + "...";
          }
        } catch (e) {
          lastMessage = "No messages";
        }
      }
      
      return {
        'name': chatName,
        'lastMessage': lastMessage,
      };
    } catch (e) {
      return {
        'name': "Chat",
        'lastMessage': "No messages yet",
      };
    }
  }
}