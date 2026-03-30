import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewTeamsScreen extends StatefulWidget {
  const ViewTeamsScreen({super.key});

  @override
  State<ViewTeamsScreen> createState() => _ViewTeamsScreenState();
}

class _ViewTeamsScreenState extends State<ViewTeamsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("TEAM REGISTRY", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
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
          stream: _db.collection('teams').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));

            if (snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No teams established yet.", style: TextStyle(color: Colors.white24)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var team = snapshot.data!.docs[index];
                Map<String, dynamic> teamData = team.data() as Map<String, dynamic>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ExpansionTile(
                    iconColor: Colors.blueAccent,
                    collapsedIconColor: Colors.white38,
                    shape: const RoundedRectangleBorder(side: BorderSide.none),
                    title: Text(teamData['teamName'] ?? "Unnamed Team",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text("${teamData['department']} | Leader: ${teamData['leaderName']}",
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("TEAM ROSTER", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
                            const SizedBox(height: 10),
                            // FETCHING MEMBERS OF THIS TEAM
                            StreamBuilder<QuerySnapshot>(
                              stream: _db.collection('users')
                                  .where('teamId', isEqualTo: team.id)
                                  .snapshots(),
                              builder: (context, memberSnap) {
                                if (!memberSnap.hasData) return const LinearProgressIndicator();

                                var members = memberSnap.data!.docs;

                                if (members.isEmpty) {
                                  return const Text("No members assigned yet.", style: TextStyle(color: Colors.white24, fontSize: 12));
                                }

                                return Column(
                                  children: members.map((m) {
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const CircleAvatar(backgroundColor: Colors.blueAccent, radius: 15,
                                          child: Icon(Icons.person, size: 15, color: Colors.white)),
                                      title: Text(m['name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                                      subtitle: Text(m['skills'] ?? "No skills listed", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      )
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
}