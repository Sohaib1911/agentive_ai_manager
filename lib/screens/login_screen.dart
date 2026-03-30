import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manager_dashboard.dart';
import 'employee_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _isObscured = true;

  // Theme Colors
  final Color bgBlack = const Color(0xFF000000);
  final Color deepBlue = const Color(0xFF001F3F);
  final Color accentBlue = const Color(0xFF007BFF);

  void _handleLogin() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      UserCredential user = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(), password: _pass.text.trim());

      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.user!.uid).get();

      if (doc.exists && mounted) {
        String role = doc['role'];
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => role == 'manager' ? const ManagerDashboard() : const EmployeeDashboard()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text("Login Failed: ${e.toString()}")));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgBlack, deepBlue, bgBlack],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Icon(Icons.adb_outlined, size: 80, color: Colors.blueAccent),
                    const SizedBox(height: 25),

                    const Text(
                      "AGENTIVE AI",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const Text(
                      "Task Allocation & Deadline Suggestion",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 50),

                    _buildInputField(
                      controller: _email,
                      hint: "Email Address",
                      icon: Icons.alternate_email_rounded,
                    ),
                    const SizedBox(height: 20),

                    _buildInputField(
                      controller: _pass,
                      hint: "Password",
                      icon: Icons.lock_person_outlined,
                      isPassword: true,
                    ),

                    const SizedBox(height: 40),

                    _loading
                        ? const CircularProgressIndicator(color: Colors.blueAccent)
                        : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 12,
                          shadowColor: accentBlue.withOpacity(0.4),
                        ),
                        child: const Text(
                          "ACCESS DASHBOARD",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Powered by Sohaib Mohsin & Hammad Hussain",
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _isObscured : false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent, size: 22),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
            onPressed: () => setState(() => _isObscured = !_isObscured),
          )
              : null,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }
}