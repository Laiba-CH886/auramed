import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();

  static const List<HealthDataType> _dataTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.STEPS,
    HealthDataType.SLEEP_SESSION,
  ];

  // Secondary types that might fail on some devices
  static const List<HealthDataType> _optionalDataTypes = [
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.WATER,
  ];

  Future<bool> requestPermissions() async {
    try {
      await _health.configure();

      final isAvailable = await _health.isHealthConnectAvailable();
      if (!isAvailable) {
        debugPrint('HealthService: Health Connect not available');
        return false;
      }

      final activityStatus = await Permission.activityRecognition.request();
      debugPrint('HealthService: activityRecognition status = $activityStatus');

      // 1. Request core permissions first
      final coreGranted = await _health.requestAuthorization(
        _dataTypes,
        permissions: _dataTypes.map((_) => HealthDataAccess.READ).toList(),
      );
      debugPrint('HealthService: core authorization granted = $coreGranted');

      // 2. Try optional permissions if core succeeded or even if failed (some might be granted)
      try {
        await _health.requestAuthorization(
          _optionalDataTypes,
          permissions: _optionalDataTypes.map((_) => HealthDataAccess.READ).toList(),
        );
      } catch (e) {
        debugPrint('HealthService: optional permissions request error (non-fatal): $e');
      }

      // Check what we actually got
      final hasCore = await _health.hasPermissions(_dataTypes);
      debugPrint('HealthService: has core permissions after request = $hasCore');

      return hasCore ?? coreGranted;
    } catch (e) {
      debugPrint('HealthService: requestPermissions critical error: $e');
      return false;
    }
  }

  Future<bool> hasPermissions() async {
    try {
      await _health.configure();
      final isAvailable = await _health.isHealthConnectAvailable();
      if (!isAvailable) return false;

      final result = await _health.hasPermissions(_dataTypes);
      return result ?? false;
    } catch (e) {
      debugPrint('HealthService: hasPermissions error: $e');
      return false;
    }
  }

  Future<int> getLatestHeartRate() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));
      final data = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );

      if (data.isEmpty) return 0;

      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final value = data.first.value;

      if (value is NumericHealthValue) {
        return value.numericValue.toInt();
      }
      return 0;
    } catch (e) {
      debugPrint('HealthService: getLatestHeartRate error: $e');
      return 0;
    }
  }

  Future<int> getLatestSpO2() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));
      final data = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.BLOOD_OXYGEN],
      );

      if (data.isEmpty) return 0;

      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final value = data.first.value;

      if (value is NumericHealthValue) {
        return value.numericValue.toInt();
      }
      return 0;
    } catch (e) {
      debugPrint('HealthService: getLatestSpO2 error: $e');
      return 0;
    }
  }

  Future<String> getLatestBloodPressure() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      final systolicData = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.BLOOD_PRESSURE_SYSTOLIC],
      );
      final diastolicData = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [HealthDataType.BLOOD_PRESSURE_DIASTOLIC],
      );

      if (systolicData.isEmpty || diastolicData.isEmpty) return '--';

      systolicData.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      diastolicData.sort((a, b) => b.dateTo.compareTo(a.dateTo));

      final sys = systolicData.first.value;
      final dia = diastolicData.first.value;

      if (sys is NumericHealthValue && dia is NumericHealthValue) {
        return '${sys.numericValue.toInt()}/${dia.numericValue.toInt()}';
      }
      return '--';
    } catch (e) {
      debugPrint('HealthService: getLatestBloodPressure error: $e');
      return '--';
    }
  }

  Future<int> getTodaySteps() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(startOfDay, now);
      return steps ?? 0;
    } catch (e) {
      debugPrint('HealthService: getTodaySteps error: $e');
      return 0;
    }
  }

  Future<int> getLastNightSleepMinutes() async {
    try {
      final now = DateTime.now();
      final twoDaysAgo = now.subtract(const Duration(days: 2));

      final data = await _health.getHealthDataFromTypes(
        startTime: twoDaysAgo,
        endTime: now,
        types: [HealthDataType.SLEEP_SESSION],
      );

      if (data.isEmpty) return 0;

      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final latest = data.first;

      return latest.dateTo.difference(latest.dateFrom).inMinutes;
    } catch (e) {
      debugPrint('HealthService: getLastNightSleepMinutes error: $e');
      return 0;
    }
  }

  Future<double> getTodayWaterIntakeLiters() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final data = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: now,
        types: [HealthDataType.WATER],
      );

      if (data.isEmpty) return 0;

      double totalLiters = 0;

      for (final item in data) {
        final value = item.value;
        if (value is NumericHealthValue) {
          totalLiters += value.numericValue.toDouble();
        }
      }

      return totalLiters;
    } catch (e) {
      debugPrint('HealthService: getTodayWaterIntakeLiters error: $e');
      return 0;
    }
  }

  Future<int> getEstimatedStressLevel() async {
    try {
      final hr = await getLatestHeartRate();

      if (hr <= 0) return 0;
      if (hr < 75) return 25;
      if (hr < 90) return 45;
      if (hr < 105) return 65;
      return 85;
    } catch (e) {
      debugPrint('HealthService: getEstimatedStressLevel error: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> getAllVitals() async {
    try {
      final heartRate = await getLatestHeartRate();
      final spo2 = await getLatestSpO2();
      final bp = await getLatestBloodPressure();
      final steps = await getTodaySteps();
      final sleepMinutes = await getLastNightSleepMinutes();
      final stressLevel = await getEstimatedStressLevel();
      final waterLiters = await getTodayWaterIntakeLiters();

      return {
        'heartRate': heartRate,
        'spo2': spo2,
        'bp': bp,
        'steps': steps,
        'sleepMinutes': sleepMinutes,
        'stressLevel': stressLevel,
        'waterLiters': waterLiters,
        'timestamp': DateTime.now(),
        'hasData': heartRate > 0 ||
            spo2 > 0 ||
            steps > 0 ||
            sleepMinutes > 0 ||
            waterLiters > 0,
      };
    } catch (e) {
      debugPrint('HealthService: getAllVitals error: $e');
      return {
        'heartRate': 0,
        'spo2': 0,
        'bp': '--',
        'steps': 0,
        'sleepMinutes': 0,
        'stressLevel': 0,
        'waterLiters': 0.0,
        'timestamp': DateTime.now(),
        'hasData': false,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getHeartRateHistory() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final data = await _health.getHealthDataFromTypes(
        startTime: weekAgo,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );

      data.sort((a, b) => a.dateTo.compareTo(b.dateTo));

      return data.map((point) {
        final value = point.value;
        return {
          'value': value is NumericHealthValue ? value.numericValue.toInt() : 0,
          'timestamp': point.dateTo,
        };
      }).toList();
    } catch (e) {
      debugPrint('HealthService: getHeartRateHistory error: $e');
      return [];
    }
  }

  static bool isEmergencyVitals({
    required int heartRate,
    required int spo2,
    required String bp,
  }) {
    final parsed = parseBloodPressure(bp);
    final systolic = parsed['systolic'];
    final diastolic = parsed['diastolic'];

    final hrEmergency = heartRate >= 120 || (heartRate > 0 && heartRate <= 45);
    final spo2Emergency = spo2 > 0 && spo2 < 92;
    final bpEmergency =
        (systolic != null && (systolic >= 160 || systolic <= 85)) ||
            (diastolic != null && (diastolic >= 100 || diastolic <= 55));

    return hrEmergency || spo2Emergency || bpEmergency;
  }

  static List<String> emergencyReasons({
    required int heartRate,
    required int spo2,
    required String bp,
  }) {
    final parsed = parseBloodPressure(bp);
    final systolic = parsed['systolic'];
    final diastolic = parsed['diastolic'];

    final reasons = <String>[];

    if (heartRate >= 120) {
      reasons.add('High heart rate: $heartRate bpm');
    } else if (heartRate > 0 && heartRate <= 45) {
      reasons.add('Low heart rate: $heartRate bpm');
    }

    if (spo2 > 0 && spo2 < 92) {
      reasons.add('Low SpO₂: $spo2%');
    }

    if (systolic != null && diastolic != null) {
      if (systolic >= 160 || diastolic >= 100) {
        reasons.add('High blood pressure: $bp');
      } else if (systolic <= 85 || diastolic <= 55) {
        reasons.add('Low blood pressure: $bp');
      }
    }

    return reasons;
  }

  static Map<String, int?> parseBloodPressure(String bp) {
    try {
      final parts = bp.split('/');
      if (parts.length != 2) {
        return {'systolic': null, 'diastolic': null};
      }

      return {
        'systolic': int.tryParse(parts[0].trim()),
        'diastolic': int.tryParse(parts[1].trim()),
      };
    } catch (_) {
      return {'systolic': null, 'diastolic': null};
    }
  }
}