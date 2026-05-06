import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'pending_doctors_screen.dart';

enum AdminSection {
  none,
  patients,
  doctors,
  appointments,
  consultations,
  emergencies
}

class AdminDashboardScreen extends StatefulWidget {
  static const routeName = "/admin_dashboard";

  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {

  AdminSection _expanded = AdminSection.none;

  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  void _toggle(AdminSection section) {
    setState(() {
      _expanded = _expanded == section
          ? AdminSection.none
          : section;
    });
  }

  // ───────── USER ACTIONS ─────────

  Future<void> _toggleBlockUser(String uid, bool current) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'isBlocked': !current});
  }

  Future<void> _approveDoctor(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'isApproved': true});
  }

  Future<void> _deleteUser(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .delete();
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "System Overview",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // ───────── STATS ─────────
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  final users = snapshot.data?.docs ?? [];

                  final patients =
                      users.where((u) => u['role'] == 'patient').length;

                  final doctors =
                      users.where((u) => u['role'] == 'doctor').length;

                  return Row(
                    children: [
                      _statCard("Patients", patients, Colors.blue),
                      _statCard("Doctors", doctors, Colors.green),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // ───────── DOCTORS SECTION ─────────
              _buildSection(
                title: "🩺 Doctors",
                section: AdminSection.doctors,
                color: Colors.green,
                child: _buildDoctorsSection(),
              ),

              _buildSection(
                title: "👥 Patients",
                section: AdminSection.patients,
                color: Colors.blue,
                child: _buildUsers("patient"),
              ),

              _buildSection(
                title: "📅 Appointments",
                section: AdminSection.appointments,
                color: Colors.orange,
                child: _buildSimpleList('appointments'),
              ),

              _buildSection(
                title: "💬 Consultations",
                section: AdminSection.consultations,
                color: Colors.purple,
                child: _buildSimpleList('consultations'),
              ),

              _buildSection(
                title: "🚨 Emergency Alerts",
                section: AdminSection.emergencies,
                color: Colors.red,
                child: _buildSimpleList('emergency_alerts'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────── DOCTOR SECTION ─────────

  Widget _buildDoctorsSection() {
    return Column(
      children: [

        // 🔥 IMPORTANT BUTTON (ADDED HERE)
        ListTile(
          leading: const Icon(Icons.pending_actions, color: Colors.orange),
          title: const Text("Pending Doctor Requests"),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {
            Navigator.pushNamed(
              context,
              PendingDoctorsScreen.routeName,
            );
          },
        ),

        const Divider(),

        // ───────── DOCTOR LIST ─────────
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'doctor')
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            return Column(
              children: docs.map((d) {
                final data = d.data() as Map<String, dynamic>;

                final isBlocked = data['isBlocked'] ?? false;
                final isApproved = data['isApproved'] ?? false;

                return Card(
                  child: ListTile(
                    title: Text(data['name'] ?? ''),
                    subtitle: Text(data['email'] ?? ''),

                    trailing: Wrap(
                      spacing: 8,
                      children: [

                        // APPROVE
                        if (!isApproved)
                          IconButton(
                            icon: const Icon(Icons.verified,
                                color: Colors.green),
                            onPressed: () =>
                                _approveDoctor(d.id),
                          ),

                        // BLOCK
                        IconButton(
                          icon: Icon(
                            isBlocked
                                ? Icons.lock
                                : Icons.lock_open,
                            color: isBlocked
                                ? Colors.red
                                : Colors.green,
                          ),
                          onPressed: () =>
                              _toggleBlockUser(d.id, isBlocked),
                        ),

                        // DELETE
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () =>
                              _deleteUser(d.id),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ───────── SECTION WRAPPER ─────────

  Widget _buildSection({
    required String title,
    required AdminSection section,
    required Widget child,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _toggle(section),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color, radius: 5),
                const SizedBox(width: 10),
                Expanded(child: Text(title)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
            if (_expanded == section)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: child,
              )
          ],
        ),
      ),
    );
  }

  // ───────── PATIENT LIST ─────────

  Widget _buildUsers(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return Column(
          children: docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final isBlocked = data['isBlocked'] ?? false;

            return ListTile(
              title: Text(data['name'] ?? ''),
              subtitle: Text(data['email'] ?? ''),
              trailing: IconButton(
                icon: Icon(
                  isBlocked ? Icons.lock : Icons.lock_open,
                  color: isBlocked ? Colors.red : Colors.green,
                ),
                onPressed: () =>
                    _toggleBlockUser(d.id, isBlocked),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ───────── SIMPLE LIST ─────────

  Widget _buildSimpleList(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return Column(
          children: docs.map((d) {
            final data = d.data() as Map<String, dynamic>;

            return ListTile(
              title: Text(data['patientName'] ?? 'User'),
              subtitle: Text(data['status'] ?? ''),
            );
          }).toList(),
        );
      },
    );
  }

  // ───────── STATS ─────────

  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text("$value",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label),
          ],
        ),
      ),
    );
  }
}