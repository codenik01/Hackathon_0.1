import 'package:care_plus/screen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String username;
  HomeScreen({required this.username});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome $username"),
        actions: [
          IconButton(
              onPressed: () => logout(context), icon: Icon(Icons.logout))
        ],
      ),
      body: Center(
        child: Text(
          "Hello, $username!",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
