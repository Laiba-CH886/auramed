import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/screens/consultation/doctor_notes_screen.dart';

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

// ─────────────────────────────────────────────────────────────────────────────

class ConsultationChatScreen extends StatefulWidget {
  static const routeName = '/consultation-chat';
  const ConsultationChatScreen({super.key});

  @override
  State<ConsultationChatScreen> createState() => _ConsultationChatScreenState();
}

class _ConsultationChatScreenState extends State<ConsultationChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _messageAlertSubscription;
  bool _didSetupMessageListener = false;
  String? _lastSeenMessageDocId;

  // Stable messages stream — created once per consultationId
  Stream<QuerySnapshot>? _messagesStream;
  String? _cachedConsultationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is! ConsultationChatArgs) return;

      // listen: false — we don't need a rebuild here
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final isDoctor = args.isDoctor;
      final senderName = isDoctor ? args.doctorName : args.patientName;
      final senderId = auth.user?.uid ?? senderName;

      _markAsRead(args.consultationId, isDoctor);
      _setupMessageAlertListener(chatArgs: args, mySenderId: senderId);
    });
  }

  @override
  void dispose() {
    _messageAlertSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureStreams(String consultationId) {
    if (_cachedConsultationId == consultationId) return;
    _cachedConsultationId = consultationId;
    _messagesStream = _firestore
        .collection('consultations')
        .doc(consultationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  void _markAsRead(String consultationId, bool isDoctor) {
    _firestore.collection('consultations').doc(consultationId).update({
      if (isDoctor) 'isReadByDoctor': true,
      if (!isDoctor) 'isReadByPatient': true,
    }).catchError((_) {});
  }

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

    final msgRef = _firestore
        .collection('consultations')
        .doc(consultationId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'text': text,
      'senderName': senderName,
      'senderId': senderId,
      'isSystemMessage': false,
      'messageType': 'text',
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(
      _firestore.collection('consultations').doc(consultationId),
      {
        'lastMessage': text,
        'lastSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
        if (isDoctor) 'isReadByPatient': false,
        if (!isDoctor) 'isReadByDoctor': false,
      },
    );

    await batch.commit();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _setupMessageAlertListener({
    required ConsultationChatArgs chatArgs,
    required String mySenderId,
  }) {
    if (_didSetupMessageListener) return;
    _didSetupMessageListener = true;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    _messageAlertSubscription = _firestore
        .collection('consultations')
        .doc(chatArgs.consultationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || snapshot.docs.isEmpty) return;

      final latestDoc = snapshot.docs.last;
      final latestData = latestDoc.data() as Map<String, dynamic>;
      final latestSenderId = latestData['senderId'] as String? ?? '';
      final latestSenderName =
          latestData['senderName'] as String? ?? 'New message';
      final latestText = latestData['text'] as String? ?? '';

      if (_lastSeenMessageDocId == null) {
        _lastSeenMessageDocId = latestDoc.id;
        return;
      }
      if (_lastSeenMessageDocId == latestDoc.id) return;
      _lastSeenMessageDocId = latestDoc.id;

      if (latestSenderId != mySenderId &&
          auth.notificationSettings.chatMessages) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$latestSenderName: $latestText'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      _markAsRead(chatArgs.consultationId, chatArgs.isDoctor);
    });
  }

  String _formatSleep(dynamic v) {
    final m = v is int ? v : int.tryParse('$v');
    if (m == null || m <= 0) return '--';
    return '${m ~/ 60}h ${m % 60}m';
  }

  String _formatStress(dynamic v) {
    final s = v is int ? v : int.tryParse('$v');
    if (s == null || s <= 0) return '--';
    return '$s%';
  }

  String _formatWater(dynamic v) {
    final w = v is num ? v.toDouble() : double.tryParse('$v');
    if (w == null || w <= 0) return '--';
    return '${w.toStringAsFixed(1)} L';
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final ConsultationChatArgs chatArgs = args is ConsultationChatArgs
        ? args
        : const ConsultationChatArgs(
      consultationId: 'unknown',
      patientName: 'Patient',
    );

    _ensureStreams(chatArgs.consultationId);

    // listen: false — we only need senderId/senderName, not reactive rebuilds
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isDoctor = chatArgs.isDoctor;
    final senderName = isDoctor ? chatArgs.doctorName : chatArgs.patientName;
    final senderId = auth.user?.uid ?? senderName;
    final otherName = isDoctor ? chatArgs.patientName : chatArgs.doctorName;

    final refId = chatArgs.consultationId.length >= 5
        ? chatArgs.consultationId
        .substring(chatArgs.consultationId.length - 5)
        : chatArgs.consultationId;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Ref: #$refId',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
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
              icon: Icon(Icons.note_add, color: colorScheme.primary),
              label: Text(
                'NOTES',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Completed banner ──
          if (!chatArgs.isActive)
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark
                  ? Colors.green.withOpacity(0.16)
                  : Colors.green.shade50,
              child: const Text(
                '✅ This consultation has been completed.',
                style: TextStyle(color: Colors.green, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          // ── Patient history strip ──
          // Always in the tree. Owns its own streams, never flickers.
          _PatientHistoryStrip(
            consultationId: chatArgs.consultationId,
            formatSleep: _formatSleep,
            formatStress: _formatStress,
            formatWater: _formatWater,
          ),

          // ── Messages ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.\nSay hello! 👋',
                      textAlign: TextAlign.center,
                      style:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || !_scrollController.hasClients) return;
                  _markAsRead(chatArgs.consultationId, chatArgs.isDoctor);
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final text = data['text'] as String? ?? '';
                    final msgSender = data['senderName'] as String? ?? '';
                    final msgSenderId = data['senderId'] as String? ?? '';
                    final isSystemMessage =
                        data['isSystemMessage'] as bool? ?? false;
                    final messageType =
                        data['messageType'] as String? ?? 'text';

                    final isMe = !isSystemMessage &&
                        (msgSenderId == senderId || msgSender == senderName);

                    if (isSystemMessage) {
                      return _buildSystemMessageCard(
                          context, data, messageType, text);
                    }

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
                              ? colorScheme.primary
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              Text(
                                msgSender,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              text,
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
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

          // ── Doctor notes button ──
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
                label: const Text('📋 ADD MEDICAL NOTES'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.orange.withOpacity(0.18)
                      : Colors.orange.shade100,
                  foregroundColor: isDark
                      ? Colors.orange.shade200
                      : Colors.orange.shade900,
                  elevation: 0,
                ),
              ),
            ),

          // ── Message input ──
          if (chatArgs.isActive)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration:
              BoxDecoration(color: Theme.of(context).cardColor),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          textCapitalization:
                          TextCapitalization.sentences,
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
                      backgroundColor: colorScheme.primary,
                      child: IconButton(
                        icon: const Icon(Icons.send,
                            color: Colors.white, size: 20),
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

  Widget _buildSystemMessageCard(
      BuildContext context,
      Map<String, dynamic> data,
      String messageType,
      String text,
      ) {
    final bool isEmergency = messageType == 'emergency_vitals';
    final hr = data['heartRate']?.toString();
    final bp = data['bp']?.toString();
    final spo2 = data['spo2']?.toString();
    final reasons = (data['reasons'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        <String>[];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEmergency
            ? Colors.red.withOpacity(0.10)
            : Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEmergency
              ? Colors.redAccent.withOpacity(0.45)
              : Theme.of(context).colorScheme.primary.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isEmergency
                    ? Icons.warning_amber_rounded
                    : Icons.monitor_heart_outlined,
                color: isEmergency
                    ? Colors.redAccent
                    : Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isEmergency ? 'Emergency Vitals Alert' : 'Vitals Update',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isEmergency
                      ? Colors.redAccent
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hr != null) _vitalChip(context, 'HR', '$hr bpm'),
              if (bp != null) _vitalChip(context, 'BP', bp),
              if (spo2 != null) _vitalChip(context, 'SpO₂', '$spo2%'),
              _vitalChip(context, 'Sleep', _formatSleep(data['sleepMinutes'])),
              _vitalChip(context, 'Stress', _formatStress(data['stressLevel'])),
              _vitalChip(context, 'Water', _formatWater(data['waterIntakeLiters'])),
            ],
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...reasons.map(
                  (r) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $r',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          ],
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _vitalChip(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PatientHistoryStrip
//
// THE FIX EXPLAINED:
//
// Previous versions used StreamBuilder<DocumentSnapshot> on the consultation
// document to get patientId. Every time _markAsRead() wrote to that document
// the stream emitted a new snapshot. During Firestore's pending-write cycle,
// snapshot.data?.data() momentarily returned null → SizedBox.shrink() was
// returned → the inner readings StreamBuilder was destroyed → history gone.
//
// Solution: fetch patientId ONCE with a Future in initState().
// patientId never changes during a consultation so it doesn't need a stream.
// Only the readings subcollection is streamed (for live vitals updates).
// This widget is placed unconditionally in the parent Column so it is
// never unmounted, and its streams are never recreated.
// ─────────────────────────────────────────────────────────────────────────────
class _PatientHistoryStrip extends StatefulWidget {
  final String consultationId;
  final String Function(dynamic) formatSleep;
  final String Function(dynamic) formatStress;
  final String Function(dynamic) formatWater;

  const _PatientHistoryStrip({
    required this.consultationId,
    required this.formatSleep,
    required this.formatStress,
    required this.formatWater,
  });

  @override
  State<_PatientHistoryStrip> createState() => _PatientHistoryStripState();
}

class _PatientHistoryStripState extends State<_PatientHistoryStrip> {
  // patientId is fetched once — it never changes for a consultation
  String? _patientId;
  bool _loadingPatientId = true;

  // readings stream is created once after patientId is known
  Stream<QuerySnapshot>? _readingsStream;

  @override
  void initState() {
    super.initState();
    _fetchPatientId();
  }

  /// Reads patientId from Firestore exactly once.
  /// No stream — writing to the consultation doc (e.g. markAsRead)
  /// cannot affect this value.
  Future<void> _fetchPatientId() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('consultations')
          .doc(widget.consultationId)
          .get();

      final patientId = (doc.data() ?? {})['patientId'] as String?;

      if (!mounted) return;

      if (patientId != null) {
        setState(() {
          _patientId = patientId;
          _loadingPatientId = false;
          // Create the readings stream now that we have patientId.
          // This is the ONLY time it is ever created.
          _readingsStream = FirebaseFirestore.instance
              .collection('users')
              .doc(patientId)
              .collection('readings')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .snapshots();
        });
      } else {
        setState(() => _loadingPatientId = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPatientId = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Still fetching patientId — show nothing (no layout jump)
    if (_loadingPatientId) return const SizedBox.shrink();

    // patientId not found in consultation doc
    if (_patientId == null || _readingsStream == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _readingsStream, // stable — never recreated
      builder: (context, readingSnap) {
        final isLoading =
            readingSnap.connectionState == ConnectionState.waiting;
        final history = readingSnap.data?.docs ?? [];

        // Don't collapse the header while loading — prevents layout jump
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Patient History',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  'No history available',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              )
            else
              SizedBox(
                height: 115,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final itemData = history[index].data() as Map<String, dynamic>;
                    return _HistoryCard(
                      data: itemData,
                    );
                  },
                ),
              ),
            const Divider(height: 24),
          ],
        );
      },
    );
  }
}

// ── Individual history card — pure display ──
class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _HistoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final hr = data['heartRate']?.toString() ?? '--';
    final bp = data['bp']?.toString() ?? '--';
    final spo2 = data['spo2']?.toString() ?? '--';
    final ts = data['timestamp'];
    final createdAt = data['createdAt'];

    String timeStr = 'Recent';
    if (createdAt is Timestamp) {
      final d = createdAt.toDate();
      timeStr = '${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } else if (ts is Timestamp) {
      final d = ts.toDate();
      timeStr = '${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 135,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _vRow(Icons.favorite, Colors.redAccent, "$hr bpm"),
          const SizedBox(height: 2),
          _vRow(Icons.bloodtype, Colors.blueAccent, bp),
          const SizedBox(height: 2),
          _vRow(Icons.water_drop, Colors.cyan, "SpO₂: $spo2%"),
        ],
      ),
    );
  }

  Widget _vRow(IconData icon, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}