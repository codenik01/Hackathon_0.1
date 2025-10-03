import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screen/login_screen.dart';

class CustomDrawer extends StatelessWidget {
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFF2F3F7), // Light background like your design
        child: Column(
          children: [
            // ✅ Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 120,
              width: double.infinity,
              color: const Color(0xFFE5E7EB), // Light grey header
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(), // to center the title visually
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

            // ✅ Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                children: [
                  _buildMenuCard(
                    icon: Icons.home,
                    title: "Home",
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildMenuCard(
                    icon: Icons.chat_bubble_outline,
                    title: "Chat",
                    onTap: () {},
                  ),
                  _buildMenuCard(
                    icon: Icons.local_hospital,
                    title: "Hospital Locator",
                    onTap: () {},
                  ),
                  _buildMenuCard(
                    icon: Icons.settings,
                    title: "Settings",
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // ✅ Logout Button at Bottom
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

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, size: 24),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
