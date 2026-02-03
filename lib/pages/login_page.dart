import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  bool isLoading = false;
  String? errorMessage = '';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Login Manual
  Future<void> _handleSubmit() async {
    setState(() { isLoading = true; errorMessage = ''; });
    try {
      if (isLogin) {
        await AuthService().signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await AuthService().signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      if (mounted) _goToHome();
    } catch (e) {
      if (FirebaseAuth.instance.currentUser != null) {
        if (mounted) _goToHome();
      } else {
        setState(() => errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Google Login
  Future<void> _handleGoogleLogin() async {
    setState(() => isLoading = true);
    try {
      await AuthService().signInWithGoogle();
      if (mounted) _goToHome();
    } catch (e) {
      if (FirebaseAuth.instance.currentUser != null) {
        if (mounted) _goToHome();
      } else {
        setState(() => errorMessage = "Google Login Failed: $e");
      }
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_alt, size: 80, color: Theme.of(context).primaryColor),
              const SizedBox(height: 20),
              Text("Task Monitor Elite", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              TextFormField(controller: _emailController, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextFormField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),

              if (errorMessage != null && errorMessage!.isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 10), child: Text(errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor, // Ikut Tema
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(isLogin ? "LOGIN" : "REGISTER"),
                ),
              ),

              const SizedBox(height: 16),
              const Text("OR", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: isLoading ? null : _handleGoogleLogin,
                icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                label: const Text("Continue with Google"),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20)),
              ),

              const SizedBox(height: 20),
              TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? "Create Account" : "Back to Login")),
            ],
          ),
        ),
      ),
    );
  }
}