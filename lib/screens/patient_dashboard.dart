import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/services/health_service.dart';
import 'package:auramed/widgets/vitals_card.dart';
import 'package:auramed/widgets/top_app_bar.dart';
import 'package:auramed/widgets/health_card.dart';
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

  final HealthService _healthService = HealthService();
  bool _watchConnected = false;

  int _liveHeartRate = 0;
  int _liveSpo2 = 0;
  String _liveBp = '--';
  int _sleepMinutes = 0;
  int _stressLevel = 0;
  double _waterLiters = 0;

  Timer? _vitalsTimer;

  String? _lastSyncedVitalsKey;
  String? _lastEmergencyAlertKey;

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

  Future<void> _checkWatchConnection() async {
    try {
      final vitals = await _healthService.getAllVitals();
      if (!mounted) return;

      final hasAnyData = vitals['hasData'] == true ||
          (vitals['bp'] as String? ?? '--') != '--' ||
          (vitals['heartRate'] as int? ?? 0) > 0 ||
          (vitals['spo2'] as int? ?? 0) > 0 ||
          (vitals['sleepMinutes'] as int? ?? 0) > 0 ||
          ((vitals['waterLiters'] as num?)?.toDouble() ?? 0) > 0;

      setState(() {
        _watchConnected = hasAnyData;
      });

      if (hasAnyData) {
        await _loadLiveVitals();
        _startVitalsTimer();
      }
    } catch (e) {
      debugPrint('Dashboard: _checkWatchConnection error: $e');
    }
  }

  Future<void> _loadLiveVitals() async {
    try {
      final vitals = await _healthService.getAllVitals();
      if (!mounted) return;

      final heartRate = vitals['heartRate'] as int? ?? 0;
      final spo2 = vitals['spo2'] as int? ?? 0;
      final bp = vitals['bp'] as String? ?? '--';
      final sleepMinutes = vitals['sleepMinutes'] as int? ?? 0;
      final stressLevel = vitals['stressLevel'] as int? ?? 0;
      final waterLiters = (vitals['waterLiters'] as num?)?.toDouble() ?? 0;

      final hasAnyData = vitals['hasData'] == true ||
          bp != '--' ||
          heartRate > 0 ||
          spo2 > 0 ||
          sleepMinutes > 0 ||
          waterLiters > 0;

      setState(() {
        _watchConnected = hasAnyData;
        _liveHeartRate = heartRate;
        _liveSpo2 = spo2;
        _liveBp = bp;
        _sleepMinutes = sleepMinutes;
        _stressLevel = stressLevel;
        _waterLiters = waterLiters;
      });

      await _syncWatchReadingIfNeeded(
        heartRate: heartRate,
        spo2: spo2,
        bp: bp,
      );
    } catch (e) {
      debugPrint('Dashboard: _loadLiveVitals error: $e');
    }
  }

  Future<void> _syncWatchReadingIfNeeded({
    required int heartRate,
    required int spo2,
    required String bp,
  }) async {
    if (!_watchConnected) return;
    if (heartRate <= 0 &&
        spo2 <= 0 &&
        bp == '--' &&
        _sleepMinutes <= 0 &&
        _stressLevel <= 0 &&
        _waterLiters <= 0) {
      return;
    }

    final key =
        '$heartRate|$spo2|$bp|$_sleepMinutes|$_stressLevel|${_waterLiters.toStringAsFixed(2)}';

    if (_lastSyncedVitalsKey == key) return;
    _lastSyncedVitalsKey = key;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final reading = PatientReading(
      timestamp: DateTime.now(),
      heartRate: heartRate,
      bp: bp,
      spo2: spo2,
      sleepMinutes: _sleepMinutes,
      stressLevel: _stressLevel,
      waterIntakeLiters: _waterLiters,
    );

    await auth.addReading(reading, fromWatch: true);

    if (!mounted) return;

    if (auth.isEmergencyReading(reading)) {
      if (_lastEmergencyAlertKey != key) {
        _lastEmergencyAlertKey = key;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency triggered — Alerting doctor...'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _startVitalsTimer() {
    _vitalsTimer?.cancel();
    _vitalsTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        _loadLiveVitals();
      }
    });
  }

  Future<void> _openConnectScreen() async {
    await Navigator.pushNamed(context, ConnectDeviceScreen.routeName);
    if (!mounted) return;
    await _checkWatchConnection();
    await _loadLiveVitals();
  }

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
        if (lastMessage.isNotEmpty && lastSenderId != patientId && !isRead) {
          unreadCount++;
        }
      }
      return unreadCount;
    });
  }

  String _formatSleep(int totalMinutes) {
    if (totalMinutes <= 0) return '--';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String _stressLabel(int level) {
    if (level <= 0) return 'No data';
    if (level < 35) return 'Relaxed';
    if (level < 60) return 'Moderate';
    if (level < 80) return 'Elevated';
    return 'High';
  }

  String _formatWater(double? liters) {
    if (liters == null || liters <= 0) return '--';
    return '${liters.toStringAsFixed(1)} L';
  }

  String _buildRecordSummary(PatientReading r) {
    return 'HR ${r.heartRate} bpm • BP ${r.bp} • SpO₂ ${r.spo2}%';
  }

  String _buildRecordExtras(PatientReading r) {
    return 'Sleep ${r.sleepMinutes != null ? _formatSleep(r.sleepMinutes!) : '--'} • '
        'Stress ${r.stressLevel != null && r.stressLevel! > 0 ? '${r.stressLevel}%' : '--'} • '
        'Water ${_formatWater(r.waterIntakeLiters)}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final readings = auth.getMyReadings();
    final last = readings.isNotEmpty ? readings.last : null;

    final displayName = auth.user != null && auth.user!.name.isNotEmpty
        ? auth.user!.name
        : auth.firebaseUser?.displayName?.isNotEmpty == true
        ? auth.firebaseUser!.displayName!
        : auth.firebaseUser?.email?.split('@').first ?? 'Patient';

    final patientId = auth.user?.uid ?? auth.firebaseUser?.uid ?? '';

    final heartRate = _watchConnected && _liveHeartRate > 0
        ? _liveHeartRate
        : last?.heartRate ?? 0;
    final spo2 = _watchConnected && _liveSpo2 > 0
        ? _liveSpo2
        : last?.spo2 ?? 0;
    final bp = _watchConnected && _liveBp != '--' ? _liveBp : last?.bp ?? '--';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: TopAppBar(
        title: 'AuraMed',
        showProfile: true,
        onProfileTap: () =>
            Navigator.pushNamed(context, ProfileScreen.routeName),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLiveVitals,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, $displayName 👋",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Vitals",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: _openConnectScreen,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _watchConnected
                                  ? Colors.green.withOpacity(0.85)
                                  : Colors.white.withOpacity(0.25),
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
                                    fontWeight: FontWeight.bold,
                                  ),
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
                      onEmergency: () async {
                        final manualReading = PatientReading(
                          timestamp: DateTime.now(),
                          heartRate: heartRate,
                          bp: bp,
                          spo2: spo2,
                          sleepMinutes: _sleepMinutes,
                          stressLevel: _stressLevel,
                          waterIntakeLiters: _waterLiters,
                        );

                        await Provider.of<AuthProvider>(context, listen: false)
                            .addReading(manualReading, fromWatch: _watchConnected);

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Emergency triggered — Alerting doctor...',
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!_watchConnected)
                GestureDetector(
                  onTap: _openConnectScreen,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.watch_outlined,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Connect your Galaxy Fit 3',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Tap to sync live health data from your watch',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                "Health Summary",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              HealthCard(
                title: 'Sleep Tracking',
                value: _formatSleep(_sleepMinutes),
                subtitle: _sleepMinutes > 0
                    ? 'Last recorded sleep session'
                    : 'No sleep data found',
                icon: Icons.bedtime_rounded,
                iconColor: Colors.indigo,
                backgroundColor: Colors.indigo.shade50,
              ),
              const SizedBox(height: 12),
              HealthCard(
                title: 'Stress Level',
                value: _stressLevel > 0 ? '$_stressLevel%' : '--',
                subtitle: _stressLabel(_stressLevel),
                icon: Icons.psychology_rounded,
                iconColor: Colors.deepPurple,
                backgroundColor: Colors.deepPurple.shade50,
              ),
              const SizedBox(height: 12),
              HealthCard(
                title: 'Water Intake',
                value: _waterLiters > 0 ? '${_waterLiters.toStringAsFixed(1)} L' : '--',
                subtitle: _waterLiters > 0
                    ? 'Today\'s hydration'
                    : 'No hydration data found',
                icon: Icons.water_drop_rounded,
                iconColor: Colors.blue,
                backgroundColor: Colors.blue.shade50,
              ),
              const SizedBox(height: 24),
              Text(
                "Quick Actions",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                  patientId.isEmpty
                      ? _ActionCard(
                    icon: Icons.chat_bubble_outline,
                    label: 'Consultation',
                    color: Colors.purple.shade50,
                    iconColor: Colors.purple.shade700,
                    onTap: () => _safeNavigate(
                      ConsultationListScreen.routeName,
                    ),
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
                          ConsultationListScreen.routeName,
                        ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Records",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      ReadingsHistoryScreen.routeName,
                    ),
                    child: const Text("View All"),
                  )
                ],
              ),
              const SizedBox(height: 12),
              if (readings.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      "No records yet",
                      style: TextStyle(color: theme.hintColor),
                    ),
                  ),
                )
              else
                ...List.generate(readings.length > 3 ? 3 : readings.length, (i) {
                  final r = readings[readings.length - 1 - i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFCEB3FF),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        _buildRecordSummary(r),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${_buildRecordExtras(r)}\n${r.timestamp.toString().substring(0, 16)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          height: 1.4,
                        ),
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        final reading = Reading(
                          type: 'Vitals',
                          value:
                          'HR: ${r.heartRate}, BP: ${r.bp}, SpO2: ${r.spo2}%, Sleep: ${r.sleepMinutes != null ? _formatSleep(r.sleepMinutes!) : '--'}, Stress: ${r.stressLevel != null ? '${r.stressLevel}%' : '--'}, Water: ${_formatWater(r.waterIntakeLiters)}',
                          date: r.timestamp,
                          notes:
                          'Heart Rate: ${r.heartRate} bpm\n'
                              'Blood Pressure: ${r.bp}\n'
                              'SpO₂: ${r.spo2}%\n'
                              'Sleep: ${r.sleepMinutes != null ? _formatSleep(r.sleepMinutes!) : '--'}\n'
                              'Stress: ${r.stressLevel != null ? '${r.stressLevel}%' : '--'}\n'
                              'Water Intake: ${_formatWater(r.waterIntakeLiters)}',
                        );
                        Navigator.pushNamed(
                          context,
                          ReadingDetailScreen.routeName,
                          arguments: reading,
                        );
                      },
                    ),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Readings',
          ),
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
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                  Text(
                    label,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
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
                    minWidth: 22,
                    minHeight: 22,
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
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

class _UpdatedTrendCard extends StatelessWidget {
  final List readings;

  const _UpdatedTrendCard({required this.readings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recentReadings =
    readings.length > 7 ? readings.sublist(readings.length - 7) : readings;

    final heartRates = recentReadings
        .map<int>((r) => (r.heartRate as int?) ?? 0)
        .where((v) => v > 0)
        .toList();

    final hasData = heartRates.isNotEmpty;

    final latestHr = hasData ? heartRates.last : null;
    final minHr = hasData ? heartRates.reduce((a, b) => a < b ? a : b) : null;
    final maxHr = hasData ? heartRates.reduce((a, b) => a > b ? a : b) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Heart Rate Trend',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (hasData)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _trendStatChip(
                  context,
                  label: 'Latest',
                  value: '$latestHr bpm',
                  color: Colors.redAccent,
                ),
                _trendStatChip(
                  context,
                  label: 'Min',
                  value: '$minHr',
                  color: Colors.blueAccent,
                ),
                _trendStatChip(
                  context,
                  label: 'Max',
                  value: '$maxHr',
                  color: Colors.green,
                ),
              ],
            ),
          const SizedBox(height: 14),
          Container(
            height: 160,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.brightness == Brightness.dark
                    ? [
                  const Color(0xFF6C4CCF),
                  const Color(0xFF9B5FA8),
                ]
                    : [
                  const Color(0xFFCEB3FF),
                  const Color(0xFFFFC1E3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: hasData
                ? Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: _HeartRateChartPainter(
                      values: heartRates,
                      lineColor: Colors.white,
                      pointColor: Colors.white,
                      gridColor: Colors.white.withOpacity(0.18),
                    ),
                    child: Container(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    heartRates.length,
                        (index) => Expanded(
                      child: Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
                : Center(
              child: Text(
                'No heart rate data yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendStatChip(
      BuildContext context, {
        required String label,
        required String value,
        required Color color,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartRateChartPainter extends CustomPainter {
  final List<int> values;
  final Color lineColor;
  final Color pointColor;
  final Color gridColor;

  _HeartRateChartPainter({
    required this.values,
    required this.lineColor,
    required this.pointColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

    final minVal = values.reduce((a, b) => a < b ? a : b).toDouble();
    final maxVal = values.reduce((a, b) => a > b ? a : b).toDouble();
    final range = (maxVal - minVal).abs() < 1 ? 1.0 : (maxVal - minVal);

    const leftPad = 6.0;
    const rightPad = 6.0;
    const topPad = 8.0;
    const bottomPad = 10.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    for (int i = 0; i < 4; i++) {
      final y = topPad + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );
    }

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final dx = values.length == 1
          ? leftPad + chartWidth / 2
          : leftPad + (chartWidth / (values.length - 1)) * i;

      final normalized = (values[i] - minVal) / range;
      final dy = topPad + chartHeight - (normalized * chartHeight);

      final point = Offset(dx, dy);
      points.add(point);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeartRateChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}