import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/widgets/vitals_card.dart';
import 'package:auramed/widgets/top_app_bar.dart';
import 'package:auramed/screens/profile_screen.dart';
import 'package:auramed/screens/appointments/appointments_list_screen.dart';
import 'package:auramed/screens/readings/readings_history_screen.dart';
import 'package:auramed/screens/health_tips_screen.dart';
import 'package:auramed/screens/readings/reading_detail_screen.dart';
import 'package:auramed/models/reading.dart';

class PatientDashboard extends StatefulWidget {
  static const routeName = '/patient_home';
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Handle Navigation based on index
    switch (index) {
      case 1:
        Navigator.pushNamed(context, AppointmentsListScreen.routeName);
        break;
      case 2:
        Navigator.pushNamed(context, ReadingsHistoryScreen.routeName);
        break;
      case 3:
        Navigator.pushNamed(context, ProfileScreen.routeName);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final readings = auth.getMyReadings();
    final last = readings.isNotEmpty ? readings.last : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: TopAppBar(
        title: 'AuraMed',
        showProfile: true,
        onProfileTap: () => Navigator.pushNamed(context, ProfileScreen.routeName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, ${auth.user?.name ?? 'Patient'} 👋",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E9EFF), Color(0xFFB2C2FF)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Vitals",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withAlpha(230),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  VitalsCard(
                    heartRate: last?.heartRate ?? 0,
                    bp: last?.bp ?? '--',
                    spo2: last?.spo2 ?? 0,
                    onEmergency: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Emergency triggered — Alerting doctor...')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // QUICK ACTIONS GRID
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _ActionCard(
                  icon: Icons.calendar_month,
                  label: 'Appointments',
                  color: Colors.orange.shade50,
                  iconColor: Colors.orange.shade700,
                  onTap: () => Navigator.pushNamed(context, AppointmentsListScreen.routeName),
                ),
                _ActionCard(
                  icon: Icons.monitor_heart,
                  label: 'Readings',
                  color: Colors.blue.shade50,
                  iconColor: Colors.blue.shade700,
                  onTap: () => Navigator.pushNamed(context, ReadingsHistoryScreen.routeName),
                ),
                _ActionCard(
                  icon: Icons.chat_bubble_outline,
                  label: 'Consultation',
                  color: Colors.purple.shade50,
                  iconColor: Colors.purple.shade700,
                  onTap: () => Navigator.pushNamed(context, AppointmentsListScreen.routeName), // Consultations are via Appts
                ),
                _ActionCard(
                  icon: Icons.lightbulb_outline,
                  label: 'Health Tips',
                  color: Colors.green.shade50,
                  iconColor: Colors.green.shade700,
                  onTap: () => Navigator.pushNamed(context, HealthTipsScreen.routeName),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            _UpdatedTrendCard(readings: readings),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Records",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, ReadingsHistoryScreen.routeName),
                  child: const Text("View All"),
                )
              ],
            ),
            const SizedBox(height: 12),
            if (readings.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text("No records yet", style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...List.generate(readings.length > 3 ? 3 : readings.length, (i) {
                final r = readings[readings.length - 1 - i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFCEB3FF),
                      child: Text(r.heartRate.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${r.bp} • SpO₂ ${r.spo2}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${r.timestamp}'.substring(0, 16)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final reading = Reading(
                        type: 'Vitals',
                        value: 'HR: ${r.heartRate}, BP: ${r.bp}, SpO2: ${r.spo2}%',
                        date: r.timestamp,
                      );
                      Navigator.pushNamed(context, ReadingDetailScreen.routeName, arguments: reading);
                    },
                  ),
                );
              }),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8E9EFF),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appts'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Readings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _UpdatedTrendCard extends StatelessWidget {
  final List readings;
  const _UpdatedTrendCard({required this.readings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Heart Rate Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFCEB3FF), Color(0xFFFFC1E3)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Text("Trend Chart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }
}
