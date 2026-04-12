import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/screens/consultation/doctor_notes_screen.dart';

// ✅ Type-safe args passed between screens
class ConsultationChatArgs {
  final String consultationId;
  final String patientName;
  final String doctorName;
  final bool isActive;
  final bool isDoctor;

  const ConsultationChatArgs({
    required this.consultationId,
    required this.patientName,
    this.doctorName = 'Doctor',
    this.isActive = true,
    this.isDoctor = false,
  });
}

class ConsultationChatScreen extends StatefulWidget {
  static const routeName = '/consultation-chat';
  const ConsultationChatScreen({super.key});

  @override
  State<ConsultationChatScreen> createState() =>
      _ConsultationChatScreenState();
}

class _ConsultationChatScreenState extends State<ConsultationChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ NEW: Mark as read when screen opens
  // Clears the badge on the dashboard for whoever opened the chat
  void _markAsRead(String consultationId, bool isDoctor) {
    _firestore
        .collection('consultations')
        .doc(consultationId)
        .update({
      if (isDoctor) 'isReadByDoctor': true,
      if (!isDoctor) 'isReadByPatient': true,
    }).catchError((_) {});
  }

  // ✅ UPDATED: saves lastSenderId + flips read flag for the other person
  Future<void> _sendMessage(
      String consultationId,
      String senderName, {
        required bool isDoctor,
        required String senderId,
      }) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final batch = _firestore.batch();

    // Add message to subcollection
    final msgRef = _firestore
        .collection('consultations')
        .doc(consultationId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'text': text,
      'senderName': senderName,
      'senderId': senderId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ✅ Doctor sends → patient badge appears (isReadByPatient: false)
    // ✅ Patient sends → doctor badge appears (isReadByDoctor: false)
    final consultRef =
    _firestore.collection('consultations').doc(consultationId);
    batch.update(consultRef, {
      'lastMessage': text,
      'lastSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
      if (isDoctor) 'isReadByPatient': false,
      if (!isDoctor) 'isReadByDoctor': false,
    });

    await batch.commit();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Safe args extraction
    final args = ModalRoute.of(context)?.settings.arguments;
    final ConsultationChatArgs chatArgs = args is ConsultationChatArgs
        ? args
        : const ConsultationChatArgs(
      consultationId: 'unknown',
      patientName: 'Patient',
    );

    final auth = Provider.of<AuthProvider>(context);
    final currentUser = auth.user;
    final isDoctor = chatArgs.isDoctor;

    // Who is sending
    final senderName = isDoctor ? chatArgs.doctorName : chatArgs.patientName;
    final senderId = currentUser?.uid ?? senderName;

    // AppBar title shows the OTHER person's name
    final otherName = isDoctor ? chatArgs.patientName : chatArgs.doctorName;

    final refId = chatArgs.consultationId.length >= 5
        ? chatArgs.consultationId
        .substring(chatArgs.consultationId.length - 5)
        : chatArgs.consultationId;

    // ✅ Mark as read as soon as this screen opens — clears badge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead(chatArgs.consultationId, isDoctor);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherName,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Ref: #$refId',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          if (isDoctor)
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                DoctorNotesScreen.routeName,
                arguments: DoctorNotesArgs(
                  patientName: chatArgs.patientName,
                  consultationId: chatArgs.consultationId,
                ),
              ),
              icon: const Icon(Icons.note_add, color: Color(0xFF6C73FF)),
              label: const Text(
                "NOTES",
                style: TextStyle(
                    color: Color(0xFF6C73FF),
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Completed banner
          if (!chatArgs.isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: Colors.green.shade50,
              child: const Text(
                '✅ This consultation has been completed.',
                style: TextStyle(color: Colors.green, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          // ✅ Real-time messages from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('consultations')
                  .doc(chatArgs.consultationId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSay hello! 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                    docs[index].data() as Map<String, dynamic>;
                    final text = data['text'] as String? ?? '';
                    final msgSender =
                        data['senderName'] as String? ?? '';
                    final isMe = msgSender == senderName;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(
                          maxWidth:
                          MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF6C73FF)
                              : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft:
                            Radius.circular(isMe ? 16 : 4),
                            bottomRight:
                            Radius.circular(isMe ? 4 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                              Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                msgSender,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6C73FF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (!isMe) const SizedBox(height: 4),
                            Text(
                              text,
                              style: TextStyle(
                                color:
                                isMe ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Doctor notes button
          if (isDoctor)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  DoctorNotesScreen.routeName,
                  arguments: DoctorNotesArgs(
                    patientName: chatArgs.patientName,
                    consultationId: chatArgs.consultationId,
                  ),
                ),
                icon: const Icon(Icons.edit_note),
                label: const Text("📋 ADD MEDICAL NOTES"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade100,
                  foregroundColor: Colors.orange.shade900,
                  elevation: 0,
                ),
              ),
            ),

          // Input bar — hidden for completed consultations
          if (chatArgs.isActive)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(color: Colors.white),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          textCapitalization:
                          TextCapitalization.sentences,
                          // ✅ Updated call with isDoctor + senderId
                          onSubmitted: (_) => _sendMessage(
                            chatArgs.consultationId,
                            senderName,
                            isDoctor: isDoctor,
                            senderId: senderId,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Type message...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF6C73FF),
                      child: IconButton(
                        icon: const Icon(Icons.send,
                            color: Colors.white, size: 20),
                        // ✅ Updated call with isDoctor + senderId
                        onPressed: () => _sendMessage(
                          chatArgs.consultationId,
                          senderName,
                          isDoctor: isDoctor,
                          senderId: senderId,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}