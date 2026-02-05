import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auramed/providers/auth_provider.dart';
import 'package:auramed/widgets/vitals_card.dart';

class PatientDetailScreen extends StatelessWidget {
  static const routeName = '/patient_detail';
  const PatientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final patientId = args != null ? args['id'] as String : 'p1';
    final patientName = args != null ? args['name'] as String : 'Patient';

    final auth = Provider.of<AuthProvider>(context);
    final readings = auth.readingsFor(patientId);

    return Scaffold(
      appBar: AppBar(
        title: Text(patientName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          VitalsCard(
            heartRate: readings.isNotEmpty ? readings.last.heartRate : 0,
            bp: readings.isNotEmpty ? readings.last.bp : '--',
            spo2: readings.isNotEmpty ? readings.last.spo2 : 0,
            onEmergency: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert sent (mock)')));
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Notes'),
                  const SizedBox(height: 6),
                  Text('No notes yet — add your recommendation below.', style: Theme.of(context).textTheme.bodySmall),
                ]),
                ElevatedButton.icon(
                  onPressed: () {
                    // Open a dialog to add a note (mock)
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Add Recommendation'),
                        content: const TextField(maxLines: 4, decoration: InputDecoration(hintText: 'Type recommendation...')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.note_add),
                  label: const Text('Add'),
                )
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: readings.length,
              itemBuilder: (ctx, i) {
                final r = readings[readings.length - 1 - i];
                return ListTile(
                  leading: CircleAvatar(child: Text(r.heartRate.toString())),
                  title: Text('${r.bp} — SpO₂ ${r.spo2}%'),
                  subtitle: Text('${r.timestamp}'),
                );
              },
            ),
          )
        ]),
      ),
    );
  }
}
