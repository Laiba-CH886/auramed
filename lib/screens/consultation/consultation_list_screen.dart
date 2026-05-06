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
      appBar: AppBar(
        title: const Text("Consultations"),
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
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context).hintColor.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No consultations yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      isDoctor
                          ? 'Patients will appear here when they start a consultation.'
                          : 'Book an appointment to start a consultation.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final active = docs
              .where(
                (d) =>
            (d.data() as Map<String, dynamic>)['status'] == 'active',
          )
              .toList();

          final completed = docs
              .where(
                (d) =>
            (d.data() as Map<String, dynamic>)['status'] == 'completed',
          )
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader(context, "💬 Active Consultations"),
              if (active.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 16),
                  child: Text(
                    "No active consultations",
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                )
              else
                ...active.map(
                      (doc) => _buildCard(
                    context,
                    doc,
                    isActive: true,
                    isDoctor: isDoctor,
                    currentUserId: currentUser.uid,
                  ),
                ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, "✅ Completed Consultations"),
              if (completed.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 16),
                  child: Text(
                    "No completed consultations",
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                )
              else
                ...completed.map(
                      (doc) => _buildCard(
                    context,
                    doc,
                    isActive: false,
                    isDoctor: isDoctor,
                    currentUserId: currentUser.uid,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context,
      QueryDocumentSnapshot doc, {
        required bool isActive,
        required bool isDoctor,
        required String currentUserId,
      }) {
    final data = doc.data() as Map<String, dynamic>;

    final displayName = isDoctor
        ? (data['patientName'] as String? ?? 'Patient')
        : (data['doctorName'] as String? ?? 'Doctor');

    final lastMsg = data['lastMessage'] as String? ?? 'No messages yet';
    final createdAt = data['createdAt'] as Timestamp?;
    final timeStr = createdAt != null ? _formatTimestamp(createdAt.toDate()) : '';

    final latestVitals = data['latestVitals'] as Map<String, dynamic>?;
    final hasEmergency = data['hasEmergency'] as bool? ?? false;
    final isUnread = isDoctor
        ? !(data['isReadByDoctor'] as bool? ?? true)
        : !(data['isReadByPatient'] as bool? ?? true);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: isActive
                  ? const Color(0xFF6C73FF).withOpacity(0.12)
                  : Colors.grey.withOpacity(0.12),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isActive ? const Color(0xFF6C73FF) : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (hasEmergency)
              const Positioned(
                top: -2,
                right: -2,
                child: CircleAvatar(
                  radius: 7,
                  backgroundColor: Colors.redAccent,
                  child: Icon(
                    Icons.priority_high,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (latestVitals != null) ...[
              const SizedBox(height: 4),
              Text(
                'HR ${latestVitals['heartRate'] ?? '--'} • BP ${latestVitals['bp'] ?? '--'} • SpO₂ ${latestVitals['spo2'] ?? '--'}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: hasEmergency ? Colors.redAccent : Theme.of(context).hintColor,
                  fontWeight: hasEmergency ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        trailing: hasEmergency
            ? const Icon(Icons.warning_amber_rounded, color: Colors.redAccent)
            : isActive
            ? const Icon(Icons.chevron_right, color: Color(0xFF6C73FF))
            : const Icon(Icons.check_circle, color: Colors.green, size: 20),
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