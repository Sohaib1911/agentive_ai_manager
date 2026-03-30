import 'package:ai_task_manager/screens/view_tasks_screen.dart';
import 'package:ai_task_manager/screens/view_teams_screen.dart';
import 'package:ai_task_manager/screens/view_employees_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_employee_screen.dart';
import 'create_task_screen.dart';
import 'create_team_screen.dart';
import 'login_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F0F0F),
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white38,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _showNotificationPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.blueAccent, width: 1),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_rounded, color: Colors.blueAccent, size: 50),
            const SizedBox(height: 15),
            const Text(
              "No notifications available right now.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            const Text(
              "We'll let you know when something happens.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("DISMISS", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000000), Color(0xFF001F3F)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Manager Dashboard", style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                      Text("Hello Manager", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _showNotificationPopup(context),
                    icon: const Icon(Icons.notifications_active_outlined, color: Colors.blueAccent, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.3,
                children: [
                  _actionBox(context, "Add Employee", Icons.person_add, Colors.blue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEmployeeScreen()))),
                  _actionBox(context, "View Task", Icons.task_alt, Colors.cyan,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewTasksScreen()))),
                  _actionBox(context, "Create Task", Icons.add_circle_outline, Colors.indigo,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTaskScreen()))),
                  _actionBox(context, "Create Team", Icons.group_add_outlined, Colors.orange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTeamScreen()))),
                  _actionBox(context, "View Teams", Icons.groups_rounded, Colors.blueGrey,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewTeamsScreen()))),
                  _actionBox(context, "View Employees", Icons.badge_outlined, Colors.deepPurpleAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewEmployeesScreen()))),
                ],
              ),

              const SizedBox(height: 30),
              const Text("Real-time Statistics", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statBox("Employees", "users", [Colors.blue, Colors.black]),
                    _statBox("Total Tasks", "tasks", [Colors.purple, Colors.black]),
                    _statBox("Completed", "tasks", [Colors.green, Colors.black], isCompleted: true),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _systemStatusBox(),
              const SizedBox(height: 30),
              const Text("Project Progress", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _graphBox(),
              const SizedBox(height: 30),
              const Text("Recent Tasks", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('tasks').orderBy('createdAt', descending: true).limit(5).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return Column(children: snapshot.data!.docs.map((doc) => _taskTile(doc)).toList());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _actionBox(BuildContext context, String title, IconData icon, Color color, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String collection, List<Color> colors, {bool isCompleted = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          if (isCompleted) {
            count = snapshot.data!.docs.where((d) => (d.data() as Map<String, dynamic>).containsKey('status') && d['status'] == 'completed').length;
          } else {
            count = snapshot.data!.docs.length;
          }
        }
        return Container(
          margin: const EdgeInsets.only(right: 15),
          padding: const EdgeInsets.all(20),
          width: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _systemStatusBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 40),
          SizedBox(height: 10),
          Text("System Status: Optimal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text("All AI agents and systems are running normally.", style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _graphBox() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: CustomPaint(painter: ChartPainter()),
    );
  }

  Widget _taskTile(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(data['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Text(data['status'] ?? 'pending', style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24),
      ),
    );
  }
}


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF000000), Color(0xFF001F3F)]),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 60, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 70, color: Colors.blueAccent)),
          const SizedBox(height: 20),
          const Text("System Manager", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 60),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            child: const Text("LOGOUT SESSION",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.4, size.width * 0.4, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.2, size.width, size.height * 0.5);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}