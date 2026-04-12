// lib/services/health_service.dart
//
// Reads real-time health data from Samsung Galaxy Fit 3
// via Health Connect (Samsung Health → Health Connect → Flutter)
//
// Data flow:
// Galaxy Fit 3 → Samsung Health App → Health Connect → This service → Firebase

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();

  // ── Data types to read from Galaxy Fit 3 ─────────────────────────────────
  static const List<HealthDataType> _dataTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.STEPS,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ];

  // ── Request permissions ───────────────────────────────────────────────────
  Future<bool> requestPermissions() async {
    try {
      await Permission.activityRecognition.request();
      await _health.configure();

      final isAvailable = await _health.isHealthConnectAvailable();
      if (!isAvailable) {
        debugPrint('HealthService: Health Connect not available');
        return false;
      }

      final permissions =
      _dataTypes.map((_) => HealthDataAccess.READ).toList();

      final granted = await _health.requestAuthorization(
        _dataTypes,
        permissions: permissions,
      );

      debugPrint('HealthService: permissions granted = $granted');
      return granted;
    } catch (e) {
      debugPrint('HealthService: requestPermissions error: $e');
      return false;
    }
  }

  // ── Check if already authorized ──────────────────────────────────────────
  Future<bool> hasPermissions() async {
    try {
      await _health.configure();
      final permissions =
      _dataTypes.map((_) => HealthDataAccess.READ).toList();
      final result = await _health.hasPermissions(
        _dataTypes,
        permissions: permissions,
      );
      return result ?? false;
    } catch (e) {
      debugPrint('HealthService: hasPermissions error: $e');
      return false;
    }
  }

  // ── Latest Heart Rate ─────────────────────────────────────────────────────
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

  // ── Latest SpO2 ──────────────────────────────────────────────────────────
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

  // ── Latest Blood Pressure ─────────────────────────────────────────────────
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

  // ── Today's Steps ─────────────────────────────────────────────────────────
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

  // ── All vitals at once ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getAllVitals() async {
    try {
      final heartRate = await getLatestHeartRate();
      final spo2 = await getLatestSpO2();
      final bp = await getLatestBloodPressure();
      final steps = await getTodaySteps();

      return {
        'heartRate': heartRate,
        'spo2': spo2,
        'bp': bp,
        'steps': steps,
        'timestamp': DateTime.now(),
        'hasData': heartRate > 0 || spo2 > 0 || steps > 0,
      };
    } catch (e) {
      debugPrint('HealthService: getAllVitals error: $e');
      return {
        'heartRate': 0,
        'spo2': 0,
        'bp': '--',
        'steps': 0,
        'timestamp': DateTime.now(),
        'hasData': false,
      };
    }
  }

  // ── Heart Rate history last 7 days ────────────────────────────────────────
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
          'value': value is NumericHealthValue
              ? value.numericValue.toInt()
              : 0,
          'timestamp': point.dateTo,
        };
      }).toList();
    } catch (e) {
      debugPrint('HealthService: getHeartRateHistory error: $e');
      return [];
    }
  }
}