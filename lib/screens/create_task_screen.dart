import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  // Data Map to store inputs - Ensure "skills" is handled for the AI match
  final Map<String, dynamic> _taskData = {
    'title': '',
    'description': '',
    'category': 'Development',
    'priority': 'Medium',
    'skills': '', // This is the Required Skills field
    'status': 'pending',
    'aiSuggestedEmployee': 'Analyzing...',
  };

  bool _isSaving = false;

  // Save Task to Firestore
  Future<void> _saveTask() async {
    // Validation: Title and Skills are critical for the AI Agent
    if (_taskData['title'].isEmpty || _taskData['skills'].isEmpty) {
      _showSnackBar("Title and Required Skills are mandatory!", Colors.redAccent);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('tasks').add({
        ..._taskData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Task deployed to AI Agent!", Colors.blueAccent);
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}", Colors.redAccent);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("CREATE TASK", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF001220), Color(0xFF000000)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel("TASK IDENTIFICATION"),
              _inputTile("Task Title", _taskData['title'], (v) => setState(() => _taskData['title'] = v)),
              _inputTile("Description", _taskData['description'], (v) => setState(() => _taskData['description'] = v)),

              const SizedBox(height: 25),
              _sectionLabel("CLASSIFICATION"),
              _inputTile("Task Category", _taskData['category'], (v) => setState(() => _taskData['category'] = v)),
              _inputTile("Priority Level", _taskData['priority'], (v) => setState(() => _taskData['priority'] = v)),

              const SizedBox(height: 25),
              _sectionLabel("AI ENGINE REQUIREMENTS"),
              // This tile handles the Required Skills
              _inputTile("Required Skills", _taskData['skills'], (v) => setState(() => _taskData['skills'] = v)),

              const SizedBox(height: 50),
              _isSaving
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 10,
                    shadowColor: Colors.blueAccent.withOpacity(0.5),
                  ),
                  onPressed: _saveTask,
                  child: const Text("DEPLOY TO AI AGENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(text, style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        title: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        subtitle: Text(
          value.isEmpty ? "Not defined" : value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.edit_square, color: Colors.blueAccent, size: 20),
        onTap: () => _showStyledInputDialog(label, value, onSave),
      ),
    );
  }

  void _showStyledInputDialog(String title, String currentVal, Function(String) onSave) {
    TextEditingController controller = TextEditingController(text: currentVal == "Not defined" ? "" : currentVal);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF007BFF), width: 1.5),
        ),
        title: Text("Define $title", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: title == "Description" ? 4 : 1,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter $title...",
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 1),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}