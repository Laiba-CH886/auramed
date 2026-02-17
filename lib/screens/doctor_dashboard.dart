import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/widgets/top_app_bar.dart';
import 'package:auramed/screens/profile_screen.dart';
import 'package:auramed/screens/appointments/appointments_list_screen.dart';
import 'package:auramed/screens/app_setting_screen.dart';
import 'package:auramed/screens/consultation/consultation_list_screen.dart';

class DoctorDashboard extends StatefulWidget {
  static const routeName = '/doctor_dashboard';
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 1:
        Navigator.pushNamed(context, AppointmentsListScreen.routeName);
        break;
      case 2:
        Navigator.pushNamed(context, ProfileScreen.routeName);
        break;
      case 3:
        Navigator.pushNamed(context, AppSettingsScreen.routeName);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final patients = auth.getAssignedPatients();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: TopAppBar(
        title: 'Doctor Portal',
        showProfile: true,
        onProfileTap: () => Navigator.pushNamed(context, ProfileScreen.routeName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WELCOME HEADER
            Text(
              "Welcome, Dr. ${auth.user?.name.split(' ').last ?? 'Doctor'} 👋",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // QUICK STATS CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C73FF), Color(0xFF8E9EFF)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics_outlined, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Text("Quick Stats", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem("Pending", "3"),
                      _buildStatDivider(),
                      _buildStatItem("Today", "5"),
                      _buildStatDivider(),
                      _buildStatItem("Done", "2"),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // ACTION GRID
            const Text(
              "Management Tools",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _ActionGridItem(
                  icon: Icons.calendar_month_outlined,
                  label: "Appointments",
                  color: Colors.blue.shade50,
                  iconColor: Colors.blue.shade700,
                  onTap: () => Navigator.pushNamed(context, AppointmentsListScreen.routeName),
                ),
                _ActionGridItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: "Consultation",
                  color: Colors.purple.shade50,
                  iconColor: Colors.purple.shade700,
                  onTap: () => Navigator.pushNamed(context, ConsultationListScreen.routeName),
                ),
                _ActionGridItem(
                  icon: Icons.person_outline_rounded,
                  label: "Profile",
                  color: Colors.orange.shade50,
                  iconColor: Colors.orange.shade700,
                  onTap: () => Navigator.pushNamed(context, ProfileScreen.routeName),
                ),
                _ActionGridItem(
                  icon: Icons.settings_outlined,
                  label: "Settings",
                  color: Colors.green.shade50,
                  iconColor: Colors.green.shade700,
                  onTap: () => Navigator.pushNamed(context, AppSettingsScreen.routeName),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6C73FF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Appts'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: Colors.white24);
  }
}

class _ActionGridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionGridItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
