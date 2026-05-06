import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingDoctorsScreen extends StatefulWidget {
  static const routeName = "/pending_doctors";

  const PendingDoctorsScreen({super.key});

  @override
  State<PendingDoctorsScreen> createState() =>
      _PendingDoctorsScreenState();
}

class _PendingDoctorsScreenState extends State<PendingDoctorsScreen> {

  // ───────────────── APPROVE DOCTOR ─────────────────
  Future<void> approveDoctor(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isApproved': true,
      'rejectionReason': null,
    });
  }

  // ───────────────── REJECT DOCTOR ─────────────────
  Future<void> rejectDoctor(String uid, String reason) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isApproved': false,
      'rejectionReason': reason,
    });
  }

  // ───────────────── BLOCK USER ─────────────────
  Future<void> toggleBlock(String uid, bool current) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isBlocked': !current,
    });
  }

  // ───────────────── REJECTION DIALOG ─────────────────
  void _showRejectDialog(String uid) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Doctor"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter rejection reason",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Reject"),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              await rejectDoctor(uid, controller.text.trim());
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Doctors"),
        backgroundColor: Colors.deepPurple,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'doctor')
            .where('isApproved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doctors = snapshot.data!.docs;

          if (doctors.isEmpty) {
            return const Center(
              child: Text(
                "No pending doctor requests",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doc = doctors[index];
              final data = doc.data() as Map<String, dynamic>;

              final isBlocked = data['isBlocked'] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),

                  title: Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['email'] ?? ''),
                      const SizedBox(height: 4),

                      if (data['rejectionReason'] != null)
                        Text(
                          "Rejected: ${data['rejectionReason']}",
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),

                  trailing: Wrap(
                    spacing: 6,
                    children: [

                      // ✅ APPROVE
                      IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: Colors.green),
                        onPressed: () => approveDoctor(doc.id),
                      ),

                      // ❌ REJECT
                      IconButton(
                        icon: const Icon(Icons.cancel,
                            color: Colors.orange),
                        onPressed: () => _showRejectDialog(doc.id),
                      ),

                      // 🔴 BLOCK
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
                            toggleBlock(doc.id, isBlocked),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}