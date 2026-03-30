import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Map<String, dynamic> _teamData = {
    'teamName': '',
    'description': '',
    'department': 'Development',
    'leaderName': '',
    'leaderId': '',
    'skills': '',
  };

  bool _isSaving = false;

  Future<void> _saveTeam() async {
    if (_teamData['teamName'].isEmpty || _teamData['leaderId'].isEmpty) {
      _showSnackBar("Team Name and Leader are required!", Colors.redAccent);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _db.collection('teams').add({
        ..._teamData,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1,
      });

      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Team '${_teamData['teamName']}' created successfully!", Colors.blueAccent);
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
        title: const Text("CREATE TEAM", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.blueAccent,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF001220)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel("CORE INFORMATION"),
              _inputTile("Team Name", _teamData['teamName'], (v) => setState(() => _teamData['teamName'] = v)),
              _inputTile("Description", _teamData['description'], (v) => setState(() => _teamData['description'] = v)),

              const SizedBox(height: 25),
              _sectionLabel("ORGANIZATION"),
              _inputTile("Department", _teamData['department'], (v) => setState(() => _teamData['department'] = v)),

              _leaderDropdownTile(),

              const SizedBox(height: 25),
              _sectionLabel("AI TARGETING"),
              _inputTile("Team Skills", _teamData['skills'], (v) => setState(() => _teamData['skills'] = v), hint: "Flutter, Firebase, etc."),

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
                  ),
                  onPressed: _saveTeam,
                  child: const Text("ESTABLISH TEAM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 10),
    child: Text(text, style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
  );

  Widget _inputTile(String label, String value, Function(String) onSave, {String hint = "Tap to define..."}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        title: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        subtitle: Text(value.isEmpty ? hint : value, style: const TextStyle(color: Colors.white, fontSize: 16)),
        trailing: const Icon(Icons.edit_note, color: Colors.blueAccent),
        onTap: () => _showStyledInputDialog(label, value, onSave),
      ),
    );
  }


  Widget _leaderDropdownTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Team Leader", style: TextStyle(color: Colors.white38, fontSize: 12)),
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('users').where('role_type', isEqualTo: 'employee').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();

              var employees = snapshot.data!.docs;

              return DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: const Color(0xFF0A0A0A),
                  isExpanded: true,
                  hint: const Text("Select Leader", style: TextStyle(color: Colors.white24)),
                  value: _teamData['leaderId'].isEmpty ? null : _teamData['leaderId'],
                  items: employees.map((emp) {
                    return DropdownMenuItem(
                      value: emp.id,
                      child: Text(emp['name'], style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    var selectedEmp = employees.firstWhere((e) => e.id == val);
                    setState(() {
                      _teamData['leaderId'] = val;
                      _teamData['leaderName'] = selectedEmp['name'];
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showStyledInputDialog(String title, String currentVal, Function(String) onSave) {
    TextEditingController controller = TextEditingController(text: currentVal);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.blueAccent, width: 1.5)),
        title: Text("Set $title", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}