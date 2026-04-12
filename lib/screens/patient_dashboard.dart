import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/services/health_service.dart';
import 'package:auramed/widgets/vitals_card.dart';
import 'package:auramed/widgets/top_app_bar.dart';
import 'package:auramed/screens/profile_screen.dart';
import 'package:auramed/screens/appointments/appointments_list_screen.dart';
import 'package:auramed/screens/readings/readings_history_screen.dart';
import 'package:auramed/screens/health_tips_screen.dart';
import 'package:auramed/screens/readings/reading_detail_screen.dart';
import 'package:auramed/models/reading.dart';
import 'package:auramed/screens/consultation/consultation_list_screen.dart';
import 'package:auramed/screens/connect_device_screen.dart';

class PatientDashboard extends StatefulWidget {
  static const routeName = '/patient_home';
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;

  // ── Health Connect ────────────────────────────────────────────────────────
  final HealthService _healthService = HealthService();
  bool _watchConnected = false;
  int _liveHeartRate = 0;
  int _liveSpo2 = 0;
  String _liveBp = '--';
  Timer? _vitalsTimer;

  @override
  void initState() {
    super.initState();
    _checkWatchConnection();
  }

  @override
  void dispose() {
    _vitalsTimer?.cancel();
    super.dispose();
  }

  // ── Auto-check watch on load ──────────────────────────────────────────────
  Future<void> _checkWatchConnection() async {
    try {
      final hasPerms = await _healthService.hasPermissions();
      if (hasPerms && mounted) {
        setState(() => _watchConnected = true);
        await _loadLiveVitals();
        _startVitalsTimer();
      }
    } catch (e) {
      debugPrint('Dashboard: _checkWatchConnection error: $e');
    }
  }

  // ── Read live vitals from Health Connect ──────────────────────────────────
  Future<void> _loadLiveVitals() async {
    try {
      final vitals = await _healthService.getAllVitals();
      if (!mounted) return;
      setState(() {
        _liveHeartRate = vitals['heartRate'] as int? ?? 0;
        _liveSpo2 = vitals['spo2'] as int? ?? 0;
        _liveBp = vitals['bp'] as String? ?? '--';
      });
    } catch (e) {
      debugPrint('Dashboard: _loadLiveVitals error: $e');
    }
  }

  // ── Refresh every 60 seconds ──────────────────────────────────────────────
  void _startVitalsTimer() {
    _vitalsTimer?.cancel();
    _vitalsTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_watchConnected && mounted) _loadLiveVitals();
    });
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────
  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() => _selectedIndex = 0);
      return;
    }
    setState(() => _selectedIndex = index);
    switch (index) {
      case 1:
        Navigator.pushNamed(context, AppointmentsListScreen.routeName)
            .then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2:
        Navigator.pushNamed(context, ReadingsHistoryScreen.routeName)
            .then((_) => setState(() => _selectedIndex = 0));
        break;
      case 3:
        Navigator.pushNamed(context, ProfileScreen.routeName)
            .then((_) => setState(() => _selectedIndex = 0));
        break;
    }
  }

  void _safeNavigate(String routeName) {
    try {
      Navigator.pushNamed(context, routeName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigation error: $e')),
      );
    }
  }

  // ── Unread message badge stream ───────────────────────────────────────────
  Stream<int> _unreadStream(String patientId) {
    return FirebaseFirestore.instance
        .collection('consultations')
        .where('patientId', isEqualTo: patientId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
      int unreadCount = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lastSenderId = data['lastSenderId'] as String? ?? '';
        final lastMessage = data['lastMessage'] as String? ?? '';
        final isRead = data['isReadByPatient'] as bool? ?? true;
        if (lastMessage.isNotEmpty &&
            lastSenderId != patientId &&
            !isRead) {
          unreadCount++;
        }
      }
      return unreadCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final readings = auth.getMyReadings() ?? [];
    final last = readings.isNotEmpty ? readings.last : null;

    final displayName = auth.user?.name?.isNotEmpty == true
        ? auth.user!.name
        : auth.firebaseUser?.displayName?.isNotEmpty == true
        ? auth.firebaseUser!.displayName
        : auth.firebaseUser?.email?.split('@').first ?? 'Patient';

    final patientId = auth.user?.uid ?? auth.firebaseUser?.uid ?? '';

    // ✅ Use live watch vitals if available, else fall back to last saved reading
    final heartRate = _watchConnected && _liveHeartRate > 0
        ? _liveHeartRate
        : last?.heartRate ?? 0;
    final spo2 = _watchConnected && _liveSpo2 > 0
        ? _liveSpo2
        : last?.spo2 ?? 0;
    final bp = _watchConnected && _liveBp != '--'
        ? _liveBp
        : last?.bp ?? '--';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: TopAppBar(
        title: 'AuraMed',
        showProfile: true,
        onProfileTap: () =>
            Navigator.pushNamed(context, ProfileScreen.routeName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $displayName 👋",
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // ── TODAY'S VITALS CARD ───────────────────────────────────
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
                      offset: Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + watch status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Vitals",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // ✅ Watch badge — tap to go to connect screen
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, ConnectDeviceScreen.routeName)
                            .then((_) => _checkWatchConnection()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _watchConnected
                                ? Colors.green.withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _watchConnected
                                    ? Icons.watch
                                    : Icons.watch_outlined,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _watchConnected ? 'Live' : 'Connect',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  VitalsCard(
                    heartRate: heartRate,
                    bp: bp,
                    spo2: spo2,
                    onEmergency: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Emergency triggered — Alerting doctor...')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Connect watch banner — only shown when NOT connected
            if (!_watchConnected)
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                    context, ConnectDeviceScreen.routeName)
                    .then((_) => _checkWatchConnection()),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF8E9EFF), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E9EFF)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.watch_outlined,
                            color: Color(0xFF8E9EFF), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connect your Galaxy Fit 3',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                            Text(
                              'Tap to sync live health data from your watch',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Color(0xFF8E9EFF)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // ── QUICK ACTIONS GRID ────────────────────────────────────
            const Text(
              "Quick Actions",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
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
                  onTap: () =>
                      _safeNavigate(AppointmentsListScreen.routeName),
                ),
                _ActionCard(
                  icon: Icons.monitor_heart,
                  label: 'Readings',
                  color: Colors.blue.shade50,
                  iconColor: Colors.blue.shade700,
                  onTap: () =>
                      _safeNavigate(ReadingsHistoryScreen.routeName),
                ),

                // Consultation card with unread badge
                patientId.isEmpty
                    ? _ActionCard(
                  icon: Icons.chat_bubble_outline,
                  label: 'Consultation',
                  color: Colors.purple.shade50,
                  iconColor: Colors.purple.shade700,
                  onTap: () => _safeNavigate(
                      ConsultationListScreen.routeName),
                )
                    : StreamBuilder<int>(
                  stream: _unreadStream(patientId),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    return _ActionCardWithBadge(
                      icon: Icons.chat_bubble_outline,
                      label: 'Consultation',
                      color: Colors.purple.shade50,
                      iconColor: Colors.purple.shade700,
                      badgeCount: unreadCount,
                      onTap: () => _safeNavigate(
                          ConsultationListScreen.routeName),
                    );
                  },
                ),

                _ActionCard(
                  icon: Icons.lightbulb_outline,
                  label: 'Health Tips',
                  color: Colors.green.shade50,
                  iconColor: Colors.green.shade700,
                  onTap: () =>
                      _safeNavigate(HealthTipsScreen.routeName),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _UpdatedTrendCard(readings: readings),
            const SizedBox(height: 24),

            // ── RECENT RECORDS ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Records",
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black87),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                      context, ReadingsHistoryScreen.routeName),
                  child: const Text("View All"),
                )
              ],
            ),
            const SizedBox(height: 12),
            if (readings.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text("No records yet",
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...List.generate(
                  readings.length > 3 ? 3 : readings.length, (i) {
                final r = readings[readings.length - 1 - i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3))
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFCEB3FF),
                      child: Text(r.heartRate.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${r.bp} • SpO₂ ${r.spo2}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    subtitle:
                    Text('${r.timestamp}'.substring(0, 16)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final reading = Reading(
                        type: 'Vitals',
                        value:
                        'HR: ${r.heartRate}, BP: ${r.bp}, SpO2: ${r.spo2}%',
                        date: r.timestamp,
                      );
                      Navigator.pushNamed(
                          context, ReadingDetailScreen.routeName,
                          arguments: reading);
                    },
                  ),
                );
              }),
            const SizedBox(height: 20),
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
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Appts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Readings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ── Action Card ───────────────────────────────────────────────────────────────
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
            Text(label,
                style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Action Card With Badge ────────────────────────────────────────────────────
class _ActionCardWithBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final int badgeCount;
  final VoidCallback onTap;

  const _ActionCardWithBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.badgeCount,
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
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 32),
                  const SizedBox(height: 8),
                  Text(label,
                      style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                      minWidth: 22, minHeight: 22),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Trend Card ────────────────────────────────────────────────────────────────
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
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Heart Rate Trend',
              style:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFCEB3FF), Color(0xFFFFC1E3)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
                child: Text("Trend Chart",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }
}