import 'package:care_plus/screen/chat_screen.dart';
import 'package:care_plus/screen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<String> getUsername() async {
    if (currentUser == null) return 'No username';
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (doc.exists) {
      return doc.data()?['username'] ?? 'No username';
    }
    return 'No username';
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = <Widget>[
      ChatScreen(), // Page 0
      // 👇 Hospitals List Page (Page 1)
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(Icons.local_hospital, color: Colors.blue),
            title: Text('City Care Hospital'),
            subtitle: Text('123 Main Street'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to hospital details screen if needed
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.local_hospital, color: Colors.green),
            title: Text('Green Valley Clinic'),
            subtitle: Text('456 Park Avenue'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.local_hospital, color: Colors.red),
            title: Text('Sunrise Medical Center'),
            subtitle: Text('789 Health Blvd'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
        ],
      ),
      // 👇 Profile Page (Page 2)
      FutureBuilder<String>(
        future: getUsername(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final username = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: currentUser?.photoURL != null
                      ? NetworkImage(currentUser!.photoURL!)
                      : AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                ),
                SizedBox(height: 20),
                Text(
                  username,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  currentUser?.email ?? 'No email',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
              ],
            ),
          );
        },
      ),
    ];

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: BoxDecoration(color: Colors.blue),
                    child: Text(
                      'Menu',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.home),
                    title: Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
      appBar: AppBar(title: Text("Welcome")),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital),
            label: 'hospitals',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
