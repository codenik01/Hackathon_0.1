import 'package:care_plus/screen/home_screen.dart';
import 'package:care_plus/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EntryDecider(),
    );
  }
}

class EntryDecider extends StatefulWidget {
  @override
  _EntryDeciderState createState() => _EntryDeciderState();
}

class _EntryDeciderState extends State<EntryDecider> {
  bool _isLoading = true;
  bool _seenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkFirstSeen();
  }

  Future<void> _checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool('seenOnboarding') ?? false;

    setState(() {
      _seenOnboarding = seen;
      _isLoading = false;
    });
  }

  Future<void> _markOnboardingSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    setState(() {
      _seenOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_seenOnboarding) {
      return WelcomeScreen(onFinish: _markOnboardingSeen);
    }

    User? user = FirebaseAuth.instance.currentUser;
    return user != null ? HomeScreen() : LoginScreen();
  }
}

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const WelcomeScreen({Key? key, required this.onFinish}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "Welcome to Care+",
      "subtitle": "Your health, just a tap away",
      "image": "https://imgs.search.brave.com/HYwLNwoypuYp8OBRst56h5xO_QtLmk8idgO-hriepu8/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly90aHVt/YnMuZHJlYW1zdGlt/ZS5jb20vYi9tb3Jp/bmdhLWxlYXZlcy1n/b29kLWhlYWx0aC13/cml0dGVuLXNsYXRl/LXdodGllLWNoYWxr/LTQ1NjA4OTExLmpw/Zw"
    },
    {
      "title": "Track Your Wellness",
      "subtitle": "Monitor your health metrics easily",
      "image": "https://imgs.search.brave.com/0qTMsEbWFeuXHwHY6hcEj2tGDp3txuylRScGv8U649I/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pbWcu/ZnJlZXBpay5jb20v/cHJlbWl1bS1waG90/by9oZWFsdGgtcG5n/LWRpdmVyc2UtaGFu/ZHMtd2VsbG5lc3Mt/cmVtaXgtdHJhbnNw/YXJlbnQtYmFja2dy/b3VuZF81Mzg3Ni05/NDE3NTkuanBnP3Nl/bXQ9YWlzX2h5YnJp/ZCZ3PTc0MCZxPTgw"
    },
    {
      "title": "Stay Connected",
      "subtitle": "Access doctors, records, and reminders",
      "image": "https://imgs.search.brave.com/L6Z3zRVNvO-I1kdY46zm4uyWbTfXNMY613Z8eDaoz90/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pbWcu/ZnJlZXBpay5jb20v/ZnJlZS12ZWN0b3Iv/aGVhbHRoeS1wZW9w/bGUtY2Fycnlpbmct/ZGlmZmVyZW50LWlj/b25zXzUzODc2LTQz/MDY5LmpwZz9zZW10/PWFpc19oeWJyaWQm/dz03NDAmcT04MA"
    }
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onDone() {
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemBuilder: (context, idx) {
                    var page = _pages[idx];
                    return Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              page["image"]!,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.error,
                                    size: 100, color: Colors.red);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            page["title"]!,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            page["subtitle"]!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Row(
                  children: [
                    Row(
                      children: List.generate(_pages.length, (idx) {
                        bool isActive = idx == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 16 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.blueAccent : Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _onDone();
                        } else {
                          _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? "Get Started"
                            : "Next",
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
