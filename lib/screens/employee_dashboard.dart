import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const EmployeeDashboardPage(),
    const EmployeeProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F0F0F),
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white38,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt_rounded), label: "My Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.face_unlock_rounded), label: "Profile"),
        ],
      ),
    );
  }
}

class EmployeeDashboardPage extends StatelessWidget {
  const EmployeeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000000), Color(0xFF001F3F)],
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            var userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userData['role']?.toUpperCase() ?? "EMPLOYEE",
                              style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          Text(userData['name'] ?? "User",
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                          Text("Team: ${userData['department'] ?? 'Independent'}",
                              style: const TextStyle(color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                      const CircleAvatar(radius: 25, backgroundColor: Colors.white10, child: Icon(Icons.notifications_active_outlined, color: Colors.cyanAccent)),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Text("OVERVIEW STATS", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 15),
                  _taskSummaryGrid(user?.uid ?? ""),

                  const SizedBox(height: 30),
                  const Text("ACTIVE MISSIONS", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 15),


                  _employeeTaskList(user?.uid ?? ""),

                  const SizedBox(height: 50),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _taskSummaryGrid(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tasks').where('employeeId', isEqualTo: uid).snapshots(),
      builder: (context, snapshot) {
        int total = snapshot.data?.docs.length ?? 0;
        int pending = snapshot.data?.docs.where((d) => d['status'] == 'assigned').length ?? 0;
        int active = snapshot.data?.docs.where((d) => d['status'] == 'in-progress').length ?? 0;
        int completed = snapshot.data?.docs.where((d) => d['status'] == 'completed').length ?? 0;

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _miniStatCard("Total Tasks", total.toString(), Colors.blueAccent),
            _miniStatCard("New Requests", pending.toString(), Colors.orangeAccent),
            _miniStatCard("In Progress", active.toString(), Colors.cyanAccent),
            _miniStatCard("Completed", completed.toString(), Colors.greenAccent),
          ],
        );
      },
    );
  }

  Widget _miniStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2))
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _employeeTaskList(String uid) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tasks').where('employeeId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 50),
                child: Text("No tasks found in your record.", style: TextStyle(color: Colors.white24)),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var task = snapshot.data!.docs[index];
              return _taskActionTile(context, task);
            },
          );
        }
    );
  }

  Widget _taskActionTile(BuildContext context, DocumentSnapshot task) {
    String status = task['status'] ?? 'assigned';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(task['title'] ?? 'No Title',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          Text(task['description'] ?? 'No description provided.',
              style: const TextStyle(color: Colors.white60, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 14, color: Colors.cyanAccent),
              const SizedBox(width: 5),
              Text("Deadline: ${task['deadline']}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(color: Colors.white10, height: 30),

          if (status == 'assigned')
            Row(
              children: [
                Expanded(child: _actionBtn("REJECT", Colors.redAccent, () => _updateStatus(task.id, 'rejected'))),
                const SizedBox(width: 12),
                Expanded(child: _actionBtn("ACCEPT", Colors.greenAccent, () => _updateStatus(task.id, 'in-progress'))),
              ],
            )
          else if (status == 'in-progress')
            _actionBtn("MARK AS COMPLETED", Colors.cyanAccent, () => _updateStatus(task.id, 'completed'))
          else
            const Center(child: Text("TASK FINISHED", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color chipColor = status == 'completed' ? Colors.greenAccent : Colors.cyanAccent;
    if (status == 'rejected') chipColor = Colors.redAccent;
    if (status == 'assigned') chipColor = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: chipColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: chipColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionBtn(String title, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 45,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            elevation: 0,
            side: BorderSide(color: color.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        ),
        child: Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _updateStatus(String taskId, String newStatus) {
    FirebaseFirestore.instance.collection('tasks').doc(taskId).update({'status': newStatus});
  }
}


class EmployeeProfilePage extends StatelessWidget {
  const EmployeeProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF001F3F)]),
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          String employeeName = "Loading...";
          if (snapshot.hasData && snapshot.data!.exists) {
            employeeName = snapshot.data!['name'] ?? "User";
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white10,
                  child: Icon(Icons.person, size: 70, color: Colors.cyanAccent)),
              const SizedBox(height: 25),
              const Text("Employee Account",
                  style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1)),
              Text(employeeName, // Dynamic Name below text
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 60),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () async {
                  // This is all you need now!
                  // The AuthWrapper in main.dart will handle the screen switch automatically.
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text("LOGOUT SESSION",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}