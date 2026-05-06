import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/widgets/top_app_bar.dart';

import 'package:auramed/screens/profile_screen.dart';
import 'package:auramed/screens/app_setting_screen.dart';
import 'package:auramed/screens/appointments/appointments_list_screen.dart';
import 'package:auramed/screens/consultation/consultation_list_screen.dart';

class DoctorDashboard extends StatefulWidget {
  static const routeName = '/doctor_dashboard';

  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;

  int pendingCount = 0;
  int consultationUnread = 0;
  int emergencyCount = 0;

  void _onBottomNav(int index) {
    setState(() => _selectedIndex = index);

    if (index == 1) {
      Navigator.pushNamed(context, AppointmentsListScreen.routeName)
          .then((_) => setState(() => _selectedIndex = 0));
    } else if (index == 2) {
      Navigator.pushNamed(context, ProfileScreen.routeName)
          .then((_) => setState(() => _selectedIndex = 0));
    } else if (index == 3) {
      Navigator.pushNamed(context, AppSettingsScreen.routeName)
          .then((_) => setState(() => _selectedIndex = 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final doctorId = auth.user?.uid;

    if (doctorId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: TopAppBar(
        title: "Doctor Dashboard",
        showProfile: true,
        onProfileTap: () =>
            Navigator.pushNamed(context, ProfileScreen.routeName),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('doctorId', isEqualTo: doctorId)
            .snapshots(),
        builder: (context, apptSnap) {
          final appts = apptSnap.data?.docs ?? [];

          final pending =
          appts.where((e) => e['status'] == 'pending').toList();

          pendingCount = pending.length;

          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('consultations')
                .where('doctorId', isEqualTo: doctorId)
                .snapshots(),
            builder: (context, consultSnap) {
              final consults = consultSnap.data?.docs ?? [];

              final active =
              consults.where((e) => e['status'] == 'active').toList();

              final completed =
              consults.where((e) => e['status'] == 'completed').toList();

              consultationUnread =
                  consults.where((e) => e['isReadByDoctor'] == false).length;

              return StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('emergency_alerts')
                    .where('doctorId', isEqualTo: doctorId)
                    .where('status', isEqualTo: 'open')
                    .snapshots(),
                builder: (context, emergencySnap) {
                  final emergencies = emergencySnap.data?.docs ?? [];
                  emergencyCount = emergencies.length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // HEADER
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C73FF), Color(0xFF9AA6FF)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            "Welcome, Dr. ${auth.user?.name ?? ''}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        _statsCard(),

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Expanded(
                              child: _modernCard(
                                "Appointments",
                                Icons.calendar_month,
                                pendingCount,
                                Colors.deepPurple,
                                    () => Navigator.pushNamed(
                                  context,
                                  AppointmentsListScreen.routeName,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _modernCard(
                                "Consultations",
                                Icons.chat_bubble,
                                consultationUnread,
                                Colors.blue,
                                    () => Navigator.pushNamed(
                                  context,
                                  ConsultationListScreen.routeName,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        _sectionCard(
                          "🚨 Emergency Cases",
                          emergencies,
                          Colors.redAccent,
                        ),

                        _sectionCard(
                          "⏳ Pending Appointments",
                          pending,
                          Colors.orange,
                        ),

                        _sectionCard(
                          "💬 Active Consultations",
                          active,
                          Colors.blue,
                        ),

                        _sectionCard(
                          "✅ Completed",
                          completed,
                          Colors.green,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onBottomNav,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: "Appts"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  // SAME UI (UNCHANGED)

  Widget _statsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat("Emergency", emergencyCount),
          _stat("Pending", pendingCount),
          _stat("Unread", consultationUnread),
        ],
      ),
    );
  }

  Widget _stat(String title, int value) {
    return Column(
      children: [
        Text(
          "$value",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _modernCard(
      String title,
      IconData icon,
      int count,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Icon(icon, size: 30, color: color),
                const SizedBox(height: 10),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            if (count > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$count",
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List list, Color color) {
    if (list.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              itemBuilder: (context, index) {
                final name = list[index]['patientName'] ?? 'Patient';

                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: color,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}