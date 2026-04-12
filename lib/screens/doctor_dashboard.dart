import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/widgets/top_app_bar.dart';
import 'package:auramed/screens/profile_screen.dart';
import 'package:auramed/screens/appointments/appointments_list_screen.dart';
import 'package:auramed/screens/app_setting_screen.dart';
import 'package:auramed/screens/consultation/consultation_list_screen.dart';
import 'package:auramed/screens/consultation/consultation_chat_screen.dart';

// Which stat card is currently expanded
enum _ExpandedSection { none, pending, active, completed }

class DoctorDashboard extends StatefulWidget {
  static const routeName = '/doctor_dashboard';
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;
  _ExpandedSection _expanded = _ExpandedSection.none;

  void _onItemTapped(int index) {
    if (index == 0) { setState(() => _selectedIndex = 0); return; }
    setState(() => _selectedIndex = index);
    switch (index) {
      case 1:
        Navigator.pushNamed(context, AppointmentsListScreen.routeName)
            .then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2:
        Navigator.pushNamed(context, ProfileScreen.routeName)
            .then((_) => setState(() => _selectedIndex = 0));
        break;
      case 3:
        Navigator.pushNamed(context, AppSettingsScreen.routeName)
            .then((_) => setState(() => _selectedIndex = 0));
        break;
    }
  }

  void _toggleSection(_ExpandedSection section) {
    setState(() {
      _expanded = _expanded == section ? _ExpandedSection.none : section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final doctorId = auth.user?.uid;
    final nameParts = auth.user?.name.trim().split(' ') ?? [];
    final displayName = nameParts.isNotEmpty ? nameParts.last : 'Doctor';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: TopAppBar(
        title: 'Doctor Portal',
        showProfile: true,
        onProfileTap: () => Navigator.pushNamed(context, ProfileScreen.routeName),
      ),
      body: doctorId == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WELCOME
            Text(
              "Welcome, Dr. $displayName 👋",
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // STATS CARD with expandable sections
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('consultations')
                  .where('doctorId', isEqualTo: doctorId)
                  .snapshots(),
              builder: (context, consultSnap) {
                final consultDocs = consultSnap.data?.docs ?? [];
                final activeDocs = consultDocs
                    .where((d) => (d.data() as Map)['status'] == 'active')
                    .toList();
                final completedDocs = consultDocs
                    .where((d) => (d.data() as Map)['status'] == 'completed')
                    .toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .where('doctorId', isEqualTo: doctorId)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, apptSnap) {
                    final pendingDocs = apptSnap.data?.docs ?? [];

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C73FF), Color(0xFF8E9EFF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        children: [
                          // ── Stat Row ──
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.analytics_outlined,
                                        color: Colors.white70, size: 20),
                                    SizedBox(width: 8),
                                    Text("Quick Stats",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Tap a stat to see patients",
                                  style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    _StatTile(
                                      label: "Pending\nAppts",
                                      value: pendingDocs.length.toString(),
                                      isSelected: _expanded ==
                                          _ExpandedSection.pending,
                                      onTap: () => _toggleSection(
                                          _ExpandedSection.pending),
                                    ),
                                    _buildStatDivider(),
                                    _StatTile(
                                      label: "Active\nConsults",
                                      value: activeDocs.length.toString(),
                                      isSelected: _expanded ==
                                          _ExpandedSection.active,
                                      onTap: () => _toggleSection(
                                          _ExpandedSection.active),
                                    ),
                                    _buildStatDivider(),
                                    _StatTile(
                                      label: "Completed",
                                      value:
                                      completedDocs.length.toString(),
                                      isSelected: _expanded ==
                                          _ExpandedSection.completed,
                                      onTap: () => _toggleSection(
                                          _ExpandedSection.completed),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ── Expandable Patient List ──
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _expanded == _ExpandedSection.none
                                ? const SizedBox.shrink()
                                : Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Divider(
                                      color: Colors.white24,
                                      height: 1),
                                  Padding(
                                    padding:
                                    const EdgeInsets.fromLTRB(
                                        20, 12, 20, 4),
                                    child: Text(
                                      _expanded ==
                                          _ExpandedSection.pending
                                          ? "⏳ Pending Appointment Requests"
                                          : _expanded ==
                                          _ExpandedSection
                                              .active
                                          ? "💬 Active Consultations"
                                          : "✅ Completed Consultations",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                          FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ),
                                  // Build list based on section
                                  if (_expanded ==
                                      _ExpandedSection.pending)
                                    _buildPatientList(
                                      context,
                                      docs: pendingDocs,
                                      nameKey: 'patientName',
                                      subtitleKey: 'reason',
                                      emptyMsg:
                                      'No pending appointments',
                                      onTap: (_) =>
                                          Navigator.pushNamed(
                                              context,
                                              AppointmentsListScreen
                                                  .routeName),
                                    )
                                  else if (_expanded ==
                                      _ExpandedSection.active)
                                    _buildPatientList(
                                      context,
                                      docs: activeDocs,
                                      nameKey: 'patientName',
                                      subtitleKey: 'lastMessage',
                                      emptyMsg:
                                      'No active consultations',
                                      onTap: (doc) {
                                        final data = doc.data()
                                        as Map<String, dynamic>;
                                        Navigator.pushNamed(
                                          context,
                                          ConsultationChatScreen
                                              .routeName,
                                          arguments:
                                          ConsultationChatArgs(
                                            consultationId: doc.id,
                                            patientName:
                                            data['patientName']
                                            as String? ??
                                                'Patient',
                                            doctorName:
                                            data['doctorName']
                                            as String? ??
                                                'Doctor',
                                            isActive: true,
                                            isDoctor: true,
                                          ),
                                        );
                                      },
                                    )
                                  else
                                    _buildPatientList(
                                      context,
                                      docs: completedDocs,
                                      nameKey: 'patientName',
                                      subtitleKey: 'lastMessage',
                                      emptyMsg:
                                      'No completed consultations',
                                      onTap: (doc) {
                                        final data = doc.data()
                                        as Map<String, dynamic>;
                                        Navigator.pushNamed(
                                          context,
                                          ConsultationChatScreen
                                              .routeName,
                                          arguments:
                                          ConsultationChatArgs(
                                            consultationId: doc.id,
                                            patientName:
                                            data['patientName']
                                            as String? ??
                                                'Patient',
                                            doctorName:
                                            data['doctorName']
                                            as String? ??
                                                'Doctor',
                                            isActive: false,
                                            isDoctor: true,
                                          ),
                                        );
                                      },
                                    ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // ACTION GRID
            const Text(
              "Management Tools",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
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
                  onTap: () => Navigator.pushNamed(
                      context, AppointmentsListScreen.routeName),
                ),
                _ActionGridItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: "Consultation",
                  color: Colors.purple.shade50,
                  iconColor: Colors.purple.shade700,
                  onTap: () => Navigator.pushNamed(
                      context, ConsultationListScreen.routeName),
                ),
                _ActionGridItem(
                  icon: Icons.person_outline_rounded,
                  label: "Profile",
                  color: Colors.orange.shade50,
                  iconColor: Colors.orange.shade700,
                  onTap: () => Navigator.pushNamed(
                      context, ProfileScreen.routeName),
                ),
                _ActionGridItem(
                  icon: Icons.settings_outlined,
                  label: "Settings",
                  color: Colors.green.shade50,
                  iconColor: Colors.green.shade700,
                  onTap: () => Navigator.pushNamed(
                      context, AppSettingsScreen.routeName),
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
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined), label: 'Appts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  /// Builds the expandable patient list inside the stats card
  Widget _buildPatientList(
      BuildContext context, {
        required List<QueryDocumentSnapshot> docs,
        required String nameKey,
        required String subtitleKey,
        required String emptyMsg,
        required void Function(QueryDocumentSnapshot) onTap,
      }) {
    if (docs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(emptyMsg,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      );
    }

    return Column(
      children: docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data[nameKey] as String? ?? 'Patient';
        final subtitle = data[subtitleKey] as String? ?? '';

        return InkWell(
          onTap: () => onTap(doc),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'P',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Colors.white60, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatDivider() =>
      Container(height: 30, width: 1, color: Colors.white24);
}

// ── Tappable stat tile ────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatTile({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style:
                const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isSelected ? 28 : 0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Grid Item ──────────────────────────────────────────────────────────
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
              color: color, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(height: 12),
              Text(label,
                  style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}