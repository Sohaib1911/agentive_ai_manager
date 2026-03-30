import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final Map<String, dynamic> _employeeData = {
    'name': '', 'email': '', 'password': '', 'phone': '',
    'role': 'Developer', 'department': 'IT', 'joiningDate': 'Select Date',
    'skills': '', 'level': 'Mid', 'prefTask': 'Development',
    'workload': 0, 'availHours': 8, 'maxTasks': 3,
  };

  bool _isSaving = false;

  Future<void> _saveEmployee() async {
    if (_employeeData['email'].isEmpty || _employeeData['password'].isEmpty) {
      _showSnackBar("Email & Password required", Colors.redAccent);
      return;
    }

    setState(() => _isSaving = true);
    try {

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _employeeData['email'],
        password: _employeeData['password'],
      );


      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        ..._employeeData,
        'role_type': 'employee',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Employee Added Successfully!", Colors.green);
    } catch (e) {
      _showSnackBar(e.toString(), Colors.redAccent);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("ADD NEW EMPLOYEE", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF001F3F)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader("BASIC INFORMATION"),
              _inputTile("Full Name", _employeeData['name'], (v) => setState(() => _employeeData['name'] = v)),
              _inputTile("Email", _employeeData['email'], (v) => setState(() => _employeeData['email'] = v)),
              _inputTile("Password", _employeeData['password'].isEmpty ? "" : "********", (v) => setState(() => _employeeData['password'] = v)),
              _inputTile("Phone Number", _employeeData['phone'], (v) => setState(() => _employeeData['phone'] = v)),

              const SizedBox(height: 25),
              _sectionHeader("JOB INFORMATION"),
              _inputTile("Role", _employeeData['role'], (v) => setState(() => _employeeData['role'] = v)),
              _inputTile("Department", _employeeData['department'], (v) => setState(() => _employeeData['department'] = v)),

              const SizedBox(height: 25),
              _sectionHeader("SKILLS & AI PARAMETERS"),
              _inputTile("Skills (comma separated)", _employeeData['skills'], (v) => setState(() => _employeeData['skills'] = v)),
              _inputTile("Experience Level", _employeeData['level'], (v) => setState(() => _employeeData['level'] = v)),
              _inputTile("Workload (%)", "${_employeeData['workload']}%", (v) => setState(() => _employeeData['workload'] = int.tryParse(v) ?? 0)),

              const SizedBox(height: 40),
              _isSaving
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _saveEmployee,
                  child: const Text("REGISTER EMPLOYEE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(title, style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  Widget _inputTile(String label, String value, Function(String) onSave) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        title: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        subtitle: Text(value.isEmpty ? "Tap to enter..." : value, style: const TextStyle(color: Colors.white, fontSize: 16)),
        trailing: const Icon(Icons.edit_note, color: Colors.blueAccent),
        onTap: () => _showStyledInputDialog(label, value, onSave),
      ),
    );
  }


  void _showStyledInputDialog(String title, String currentVal, Function(String) onSave) {
    TextEditingController controller = TextEditingController(
        text: (title == "Password" || currentVal == "Tap to enter...") ? "" : currentVal
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.blueAccent, width: 1.5)
        ),
        title: Text("Set $title", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          obscureText: title == "Password",
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            hintText: "Enter $title...",
            hintStyle: const TextStyle(color: Colors.white24),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.white38))
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(context);
              },
              child: const Text("SAVE", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }
}