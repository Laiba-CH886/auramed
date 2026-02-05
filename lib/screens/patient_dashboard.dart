// dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/widgets/vitals_card.dart';
import 'package:auramed/widgets/top_app_bar.dart';
import 'package:auramed/screens/profile_screen.dart';

class PatientDashboard extends StatelessWidget {
  static const routeName = '/patient_home';
  const PatientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final readings = auth.getMyReadings();
    final last = readings.isNotEmpty ? readings.last : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: TopAppBar(
        title: 'Patient Dashboard',
        showProfile: true,
        onProfileTap: () => Navigator.pushNamed(context, ProfileScreen.routeName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Vitals",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  VitalsCard(
                    heartRate: last?.heartRate ?? 0,
                    bp: last?.bp ?? '--',
                    spo2: last?.spo2 ?? 0,
                    onEmergency: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Emergency triggered — mock')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _UpdatedTrendCard(readings: readings),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "History",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.black87),
                ),
                Text(
                  "${readings.length} records",
                  style: TextStyle(color: Colors.grey.shade600),
                )
              ],
            ),
            const SizedBox(height: 12),
            if (readings.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Text(
                  "No history available",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
              )
            else
              Column(
                children: List.generate(readings.length, (i) {
                  final r = readings[readings.length - 1 - i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFCEB3FF),
                        child: Text(
                          r.heartRate.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      title: Text(
                        '${r.bp}   •   SpO₂ ${r.spo2}%',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${r.timestamp}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                    ),
                  );
                }),
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
    final points = readings.map((r) => (r as dynamic).heartRate.toDouble()).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Heart Rate Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              Text(
                points.isNotEmpty ? '${points.last.toInt()} bpm' : '--',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blueGrey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFCEB3FF), Color(0xFFFFC1E3)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                points.isEmpty ? "No Data" : "Trend Chart (Mock)",
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
