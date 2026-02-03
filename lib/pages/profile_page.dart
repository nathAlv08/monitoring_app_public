import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Dialog Edit Nama
  void _showEditNameDialog() {
    final TextEditingController dialogNameController = TextEditingController(text: user?.displayName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Display Name"),
        content: TextField(
          controller: dialogNameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter new name", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (dialogNameController.text.trim().isNotEmpty) {
                try {
                  await user?.updateDisplayName(dialogNameController.text.trim());
                  await user?.reload();
                  setState(() {});
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name Updated!")));
                  }
                } catch (e) {
                  // Bypass error pigeon
                  await user?.reload();
                  setState(() {});
                  if (mounted) Navigator.pop(context);
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );
    }
  }

  // Widget Tombol Warna
  Widget _buildColorOption(BuildContext context, MaterialColor color, String name) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isSelected = themeProvider.primaryColor == color;

    return GestureDetector(
      onTap: () => themeProvider.changeTheme(color),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
          ),
          const SizedBox(height: 5),
          Text(name, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = user?.displayName ?? 'No Name';
    // Ambil warna tema sekarang buat background avatar biar matching
    final themeColor = Provider.of<ThemeProvider>(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: themeColor, // Warna dinamis
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Text(user?.email ?? 'No Email', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            // NAMA BOX
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: themeColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Full Name", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showEditNameDialog,
                    icon: Icon(Icons.edit, color: themeColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Divider(),
            const SizedBox(height: 10),

            // --- FITUR TEMA WARNA (GANTINYA FINGERPRINT) ---
            const Text("App Theme", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorOption(context, Colors.indigo, "Ocean"),
                _buildColorOption(context, Colors.red, "Sunset"),
                _buildColorOption(context, Colors.green, "Forest"),
                _buildColorOption(context, Colors.orange, "Citrus"),
                _buildColorOption(context, Colors.purple, "Berry"),
              ],
            ),
            // ------------------------------------------------

            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text("LOGOUT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}