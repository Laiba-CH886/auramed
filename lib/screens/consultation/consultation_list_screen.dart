import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/models/user.dart';
import 'package:auramed/screens/consultation/consultation_chat_screen.dart';

class ConsultationListScreen extends StatelessWidget {
  static const routeName = '/consultation';
  const ConsultationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentUser = auth.user;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDoctor = currentUser.role == UserRole.doctor;
    final String filterField = isDoctor ? 'doctorId' : 'patientId';
    final String filterValue = currentUser.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text("Consultations"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('consultations')
            .where(filterField, isEqualTo: filterValue)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading consultations.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No consultations yet',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      isDoctor
                          ? 'Patients will appear here when they start a consultation.'
                          : 'Book an appointment to start a consultation.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          final active = docs
              .where((d) =>
          (d.data() as Map<String, dynamic>)['status'] == 'active')
              .toList();
          final completed = docs
              .where((d) =>
          (d.data() as Map<String, dynamic>)['status'] ==
              'completed')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader("💬 Active Consultations"),
              if (active.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 16),
                  child: Text("No active consultations",
                      style: TextStyle(color: Colors.grey)),
                )
              else
                ...active.map((doc) => _buildCard(
                  context,
                  doc,
                  isActive: true,
                  isDoctor: isDoctor,
                )),
              const SizedBox(height: 24),
              _buildSectionHeader("✅ Completed Consultations"),
              if (completed.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 16),
                  child: Text("No completed consultations",
                      style: TextStyle(color: Colors.grey)),
                )
              else
                ...completed.map((doc) => _buildCard(
                  context,
                  doc,
                  isActive: false,
                  isDoctor: isDoctor,
                )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context,
      QueryDocumentSnapshot doc, {
        required bool isActive,
        required bool isDoctor,
      }) {
    final data = doc.data() as Map<String, dynamic>;

    // Doctors see patient name, patients see doctor name
    final displayName = isDoctor
        ? (data['patientName'] as String? ?? 'Patient')
        : (data['doctorName'] as String? ?? 'Doctor');

    final lastMsg = data['lastMessage'] as String? ?? 'No messages yet';
    final createdAt = data['createdAt'] as Timestamp?;
    final timeStr =
    createdAt != null ? _formatTimestamp(createdAt.toDate()) : '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isActive
              ? const Color(0xFF6C73FF).withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.12),
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: TextStyle(
              color: isActive ? const Color(0xFF6C73FF) : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(displayName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lastMsg,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(timeStr,
                style:
                const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: isActive
            ? const Icon(Icons.chevron_right, color: Color(0xFF6C73FF))
            : const Icon(Icons.check_circle,
            color: Colors.green, size: 20),
        onTap: () {
          Navigator.pushNamed(
            context,
            ConsultationChatScreen.routeName,
            arguments: ConsultationChatArgs(
              consultationId: doc.id,
              patientName: data['patientName'] as String? ?? 'Patient',
              doctorName: data['doctorName'] as String? ?? 'Doctor',
              isActive: isActive,
              isDoctor: isDoctor,
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}