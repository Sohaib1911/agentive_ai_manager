import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewTasksScreen extends StatefulWidget {
  const ViewTasksScreen({super.key});

  @override
  State<ViewTasksScreen> createState() => _ViewTasksScreenState();
}

class _ViewTasksScreenState extends State<ViewTasksScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- AI LOGIC: VALIDATION + DEADLINE SUGGESTION ---
  Future<void> _runAIAssignment(DocumentSnapshot taskDoc) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
    );

    try {
      QuerySnapshot employeeSnap = await _db.collection('users').where('role_type', isEqualTo: 'employee').get();

      if (employeeSnap.docs.isEmpty) {
        Navigator.pop(context);
        _showSnackBar("No employees found in database!", Colors.orange);
        return;
      }

      Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;
      String taskSkills = (taskData['skills'] ?? "").toString().toLowerCase();

      DocumentSnapshot? bestMatch;
      double highestScore = 0; // Starts at 0 to ensure only relevant matches are picked

      for (var emp in employeeSnap.docs) {
        Map<String, dynamic> empData = emp.data() as Map<String, dynamic>;
        double currentScore = 0;
        String empSkills = (empData['skills'] ?? "").toString().toLowerCase();
        int workload = empData['workload'] ?? 0;

        // Strict Skill Matching
        List<String> required = taskSkills.split(',').map((s) => s.trim()).toList();
        int matchCount = 0;
        for (var skill in required) {
          if (skill.isNotEmpty && empSkills.contains(skill)) {
            currentScore += 10;
            matchCount++;
          }
        }

        // Workload Penalty
        currentScore -= (workload / 10);

        // System Check: Must have at least one matching skill
        if (matchCount > 0 && currentScore > highestScore) {
          highestScore = currentScore;
          bestMatch = emp;
        }
      }

      Navigator.pop(context); // Close loading

      if (bestMatch != null) {
        _showAssignmentPopup(taskDoc, bestMatch);
      } else {
        // Show the alert if no qualified employee is found
        _showNoMatchAlert(taskSkills);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar("AI Error: $e", Colors.redAccent);
    }
  }

  // --- POPUP: NO QUALIFIED EMPLOYEE ---
  void _showNoMatchAlert(String missingSkills) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("NO QUALIFIED STAFF", style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          "No employee matches the required skills: \n\n[$missingSkills]\n\nPlease update the task or add a new employee with these skills.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // --- POPUP: ASSIGNMENT + DEADLINE SUGGESTION ---
  void _showAssignmentPopup(DocumentSnapshot task, DocumentSnapshot emp) {
    Map<String, dynamic> empData = emp.data() as Map<String, dynamic>;
    Map<String, dynamic> taskData = task.data() as Map<String, dynamic>;

    // DEADLINE ENGINE
    int daysToAdd = 5; // Default
    String priority = taskData['priority'] ?? "Medium";
    if (priority == "High") daysToAdd = 3;
    if (priority == "Urgent") daysToAdd = 1;

    DateTime suggestion = DateTime.now().add(Duration(days: daysToAdd));
    String formattedDate = "${suggestion.day}/${suggestion.month}/${suggestion.year}";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        title: const Text("AI RECOMMENDATION", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _popupText("Recommended:", empData['name'] ?? "Unknown"),
            _popupText("Current Workload:", "${empData['workload'] ?? 0}%"),
            const Divider(color: Colors.white24),
            const Text("AI DEADLINE SUGGESTION", style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available, color: Colors.blueAccent),
                  const SizedBox(width: 10),
                  Text(formattedDate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 5),
            const Text("Calculated via priority and employee capacity.", style: TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("REJECT", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              await _db.collection('tasks').doc(task.id).update({
                'status': 'assigned',
                'assignedTo': empData['name'] ?? "Unknown",
                'employeeId': emp.id,
                'deadline': formattedDate,
              });
              Navigator.pop(context);
              _showSnackBar("Task assigned to ${empData['name']}!", Colors.green);
            },
            child: const Text("ACCEPT & ASSIGN"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("TASK REPOSITORY", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF001220)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('tasks').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                String title = data['title'] ?? "Untitled Task";
                String desc = data['description'] ?? "No description.";
                String priority = data['priority'] ?? "Medium";
                String skills = data['skills'] ?? "N/A";
                String status = data['status'] ?? "pending";
                String assignedTo = data['assignedTo'] ?? "";
                String deadline = data['deadline'] ?? "";

                bool isAssigned = status == 'assigned';

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isAssigned ? Colors.green.withOpacity(0.3) : Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                          _priorityBadge(priority),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      if (deadline.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text("Deadline: $deadline", style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                      const Divider(color: Colors.white10, height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAssigned ? "Assigned: $assignedTo" : "Unassigned",
                            style: TextStyle(color: isAssigned ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          if (!isAssigned)
                            ElevatedButton.icon(
                              onPressed: () => _runAIAssignment(doc),
                              icon: const Icon(Icons.psychology, size: 18),
                              label: const Text("AI ASSIGN"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _popupText(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: "$label ", style: const TextStyle(color: Colors.white54, fontSize: 13)),
            TextSpan(text: val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _priorityBadge(String p) {
    Color c = p == "High" || p == "Urgent" ? Colors.redAccent : (p == "Medium" ? Colors.orangeAccent : Colors.blueAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.5))),
      child: Text(p, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}