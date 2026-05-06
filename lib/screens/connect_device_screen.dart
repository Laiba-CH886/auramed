// lib/screens/connect_device_screen.dart
//
// Connects Samsung Galaxy Fit 3 via Health Connect
// Reads live vitals and saves to Firebase

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/services/health_service.dart';
import 'package:auramed/models/reading.dart';

class ConnectDeviceScreen extends StatefulWidget {
  static const routeName = '/connect-device';
  const ConnectDeviceScreen({super.key});

  @override
  State<ConnectDeviceScreen> createState() => _ConnectDeviceScreenState();
}

class _ConnectDeviceScreenState extends State<ConnectDeviceScreen> {
  final HealthService _healthService = HealthService();

  bool _isConnected = false;
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _isSaving = false;
  String _statusMessage = 'Tap "Connect Watch" to start';

  int _heartRate = 0;
  int _spo2 = 0;
  String _bp = '--';
  int _steps = 0;

  int _sleepMinutes = 0;
  int _stressLevel = 0;
  double _waterLiters = 0;

  DateTime? _lastUpdated;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _autoCheckConnection();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _autoCheckConnection() async {
    try {
      final vitals = await _healthService.getAllVitals();

      if (!mounted) return;

      final hasAnyData = vitals['hasData'] == true ||
          (vitals['bp'] as String? ?? '--') != '--';

      if (hasAnyData) {
        setState(() {
          _isConnected = true;
          _statusMessage = 'Connected to Health Connect ✓';
        });
        await _refreshData();
        _startAutoRefresh();
      } else {
        setState(() {
          _isConnected = false;
          _statusMessage = 'Tap "Connect Watch" to start';
        });
      }
    } catch (e) {
      debugPrint('ConnectDeviceScreen: autoCheck error: $e');
    }
  }

  Future<void> _connectWatch() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to Health Connect...';
    });

    try {
      final granted = await _healthService.requestPermissions();
      if (!mounted) return;

      if (!granted) {
        setState(() {
          _isConnected = false;
          _statusMessage = 'Permission not granted';
        });

        _showError(
          'Open Health Connect → App Permissions → AuraMed → Allow all required health data.',
        );
        return;
      }

      final vitals = await _healthService.getAllVitals();
      if (!mounted) return;

      debugPrint('ConnectDeviceScreen: vitals after connect = $vitals');

      setState(() {
        _isConnected = true;
        _statusMessage = 'Connected to Health Connect ✓';
      });

      await _refreshData();
      _startAutoRefresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _statusMessage = 'Connection failed';
      });
      _showError('Failed to connect: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    if (!_isConnected) return;
    setState(() => _isSyncing = true);

    try {
      final vitals = await _healthService.getAllVitals();
      if (!mounted) return;

      setState(() {
        _heartRate = vitals['heartRate'] as int? ?? 0;
        _spo2 = vitals['spo2'] as int? ?? 0;
        _bp = vitals['bp'] as String? ?? '--';
        _steps = vitals['steps'] as int? ?? 0;
        _sleepMinutes = vitals['sleepMinutes'] as int? ?? 0;
        _stressLevel = vitals['stressLevel'] as int? ?? 0;
        _waterLiters = (vitals['waterLiters'] as num?)?.toDouble() ?? 0;
        _lastUpdated = DateTime.now();
        _statusMessage = vitals['hasData'] == true
            ? 'Live data from Galaxy Fit 3 ✓'
            : 'Connected. Make sure Galaxy Fit 3 is synced with Samsung Health.';
      });
    } catch (e) {
      debugPrint('ConnectDeviceScreen: refreshData error: $e');
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Connected, but no readable data found yet.';
      });
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_isConnected && mounted) {
        _refreshData();
      }
    });
  }

  Future<void> _saveToFirebase() async {
    if (_heartRate == 0 &&
        _spo2 == 0 &&
        _bp == '--' &&
        _steps == 0 &&
        _sleepMinutes == 0 &&
        _stressLevel == 0 &&
        _waterLiters == 0) {
      _showError(
        'No health data to save. Sync your Galaxy Fit 3 with Samsung Health first.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final uid = auth.user?.uid ?? auth.firebaseUser?.uid;

      if (uid == null) {
        _showError('User not logged in.');
        return;
      }

      final reading = PatientReading(
        heartRate: _heartRate,
        bp: _bp,
        spo2: _spo2,
        sleepMinutes: _sleepMinutes,
        stressLevel: _stressLevel,
        waterIntakeLiters: _waterLiters,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('readings')
          .add({
        'heartRate': _heartRate,
        'bp': _bp,
        'spo2': _spo2,
        'steps': _steps,
        'sleepMinutes': _sleepMinutes,
        'stressLevel': _stressLevel,
        'waterIntakeLiters': _waterLiters,
        'source': 'samsung_galaxy_fit3',
        'timestamp': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await auth.addReading(reading, fromWatch: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vitals saved to cloud successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to save: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatSleep(int minutes) {
    if (minutes <= 0) return '--';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  String _formatWater(double liters) {
    if (liters <= 0) return '--';
    return '${liters.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        title: const Text('Connect Watch'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_isConnected)
            IconButton(
              icon: _isSyncing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.refresh),
              onPressed: _isSyncing ? null : _refreshData,
              tooltip: 'Refresh data',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isConnected
                      ? [
                    const Color(0xFF43A047),
                    const Color(0xFF66BB6A),
                  ]
                      : [
                    const Color(0xFF8E9EFF),
                    const Color(0xFFB2C2FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _isConnected ? Icons.watch : Icons.watch_outlined,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isConnected ? 'Samsung Galaxy Fit 3' : 'No Watch Connected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_lastUpdated != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Last updated: ${_formatTime(_lastUpdated!)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!_isConnected)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _connectWatch,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.link, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Connecting...' : 'Connect Watch',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E9EFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            if (_isConnected) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Live Health Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _VitalCard(
                    icon: Icons.favorite,
                    iconColor: Colors.red,
                    label: 'Heart Rate',
                    value: _heartRate > 0 ? '$_heartRate' : '--',
                    unit: 'bpm',
                    bgColor: Colors.red.shade50,
                  ),
                  _VitalCard(
                    icon: Icons.water_drop,
                    iconColor: Colors.blue,
                    label: 'SpO₂',
                    value: _spo2 > 0 ? '$_spo2' : '--',
                    unit: '%',
                    bgColor: Colors.blue.shade50,
                  ),
                  _VitalCard(
                    icon: Icons.monitor_heart,
                    iconColor: Colors.purple,
                    label: 'Blood Pressure',
                    value: _bp,
                    unit: 'mmHg',
                    bgColor: Colors.purple.shade50,
                  ),
                  _VitalCard(
                    icon: Icons.directions_walk,
                    iconColor: Colors.green,
                    label: 'Steps Today',
                    value: _steps > 0 ? '$_steps' : '--',
                    unit: 'steps',
                    bgColor: Colors.green.shade50,
                  ),
                  _VitalCard(
                    icon: Icons.bedtime,
                    iconColor: Colors.indigo,
                    label: 'Sleep',
                    value: _formatSleep(_sleepMinutes),
                    unit: '',
                    bgColor: Colors.indigo.shade50,
                  ),
                  _VitalCard(
                    icon: Icons.psychology,
                    iconColor: Colors.deepPurple,
                    label: 'Stress',
                    value: _stressLevel > 0 ? '$_stressLevel' : '--',
                    unit: '%',
                    bgColor: Colors.deepPurple.shade50,
                  ),
                  _VitalCard(
                    icon: Icons.local_drink,
                    iconColor: Colors.cyan.shade700,
                    label: 'Water Intake',
                    value: _formatWater(_waterLiters),
                    unit: 'L',
                    bgColor: Colors.cyan.shade50,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_heartRate > 0 || _spo2 > 0) _HealthStatusCard(heartRate: _heartRate, spo2: _spo2),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSyncing ? null : _refreshData,
                      icon: _isSyncing
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.sync),
                      label: Text(_isSyncing ? 'Syncing...' : 'Refresh'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveToFirebase,
                      icon: _isSaving
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.cloud_upload, color: Colors.white),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save to Cloud',
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E9EFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Data auto-refreshes every 60 seconds. Tap "Save to Cloud" to share readings with your doctor.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (!_isConnected) const _HowItWorksCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final Color bgColor;

  const _VitalCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final suffix = unit.isNotEmpty ? ' • $unit' : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              Text(
                '$label$suffix',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthStatusCard extends StatelessWidget {
  final int heartRate;
  final int spo2;

  const _HealthStatusCard({
    required this.heartRate,
    required this.spo2,
  });

  String get _status {
    if (heartRate > 100) return '⚠️ High Heart Rate';
    if (heartRate < 50 && heartRate > 0) return '⚠️ Low Heart Rate';
    if (spo2 > 0 && spo2 < 95) return '⚠️ Low Blood Oxygen';
    return '✅ Vitals Normal';
  }

  Color get _statusColor {
    if (heartRate > 100 ||
        (heartRate < 50 && heartRate > 0) ||
        (spo2 > 0 && spo2 < 95)) {
      return Colors.orange;
    }
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.health_and_safety, color: _statusColor),
          const SizedBox(width: 10),
          Text(
            _status,
            style: TextStyle(
              color: _statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How it works',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _step('1', 'Make sure Galaxy Fit 3 is synced with Samsung Health'),
          _step('2', 'Tap "Connect Watch" and allow Health Connect permissions'),
          _step('3', 'Your live vitals appear automatically'),
          _step('4', 'Tap "Save to Cloud" to share readings with your doctor'),
        ],
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF8E9EFF),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}