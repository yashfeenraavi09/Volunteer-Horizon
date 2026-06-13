import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'dart:async';
enum ConnectionStateMode { online, offline }

class SyncState {
  final ConnectionStateMode connectionMode;
  final int pendingReportsCount;
  final int pendingSurveysCount;
  final bool isSyncing;

  SyncState({
    required this.connectionMode,
    required this.pendingReportsCount,
    required this.pendingSurveysCount,
    this.isSyncing = false,
  });

  SyncState copyWith({
    ConnectionStateMode? connectionMode,
    int? pendingReportsCount,
    int? pendingSurveysCount,
    bool? isSyncing,
  }) {
    return SyncState(
      connectionMode: connectionMode ?? this.connectionMode,
      pendingReportsCount: pendingReportsCount ?? this.pendingReportsCount,
      pendingSurveysCount: pendingSurveysCount ?? this.pendingSurveysCount,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  int get totalPending => pendingReportsCount + pendingSurveysCount;
}

final offlineSyncProvider = NotifierProvider<OfflineSyncNotifier, SyncState>(() {
  return OfflineSyncNotifier();
});

class OfflineSyncNotifier extends Notifier<SyncState> {
  
  
  late SharedPreferences _prefs;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  bool _initialized = false;
  bool _disposed = false;

  @override
  SyncState build() {
    ref.onDispose(() {
      _disposed = true;
      _connectivitySubscription?.cancel();
    });

    // Initial state before SharedPreferences loads
    _init();
    return SyncState(
      connectionMode: ConnectionStateMode.online,
      pendingReportsCount: 0,
      pendingSurveysCount: 0,
    );
  }

  Future<void> _init() async {
    if (_initialized) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _initialized = true;
      return;
    }
    _prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    _initialized = true;

    // Load counts from local storage
    _updateCounts();

    // Listen to network changes
    final subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });
    if (_disposed) {
      subscription.cancel();
      return;
    }
    _connectivitySubscription = subscription;

    // Initial check
    final initialResults = await _connectivity.checkConnectivity();
    if (_disposed) return;
    _handleConnectivityChange(initialResults);
  }

  bool _hasNetworkConnection(dynamic results) {
    if (results is List) {
      if (results.isEmpty) return false;
      return !results.contains(ConnectivityResult.none);
    } else if (results is ConnectivityResult) {
      return results != ConnectivityResult.none;
    }
    return false;
  }

  // Helper to quickly evaluate network presence. The detailed internet check is now handled in _handleConnectivityChange.
  Future<bool> _isInternetAvailable() async {
    // Retained for backward compatibility; returns true if any network is available.
    if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    return _hasNetworkConnection(await _connectivity.checkConnectivity());
  }

  Future<void> _handleConnectivityChange(dynamic results) async {
    final hasNet = _hasNetworkConnection(results);
    
    // Simplified: any network connection is considered online.
    final newMode = hasNet ? ConnectionStateMode.online : ConnectionStateMode.offline;
    state = state.copyWith(connectionMode: newMode);
    if (newMode == ConnectionStateMode.online) {
      // Auto sync when back online
      triggerSync();
    }
  }



  void _updateCounts() {
    if (!_initialized) return;
    final reportsList = _prefs.getStringList('pending_reports') ?? [];
    final surveysList = _prefs.getStringList('pending_surveys') ?? [];
    state = state.copyWith(
      pendingReportsCount: reportsList.length,
      pendingSurveysCount: surveysList.length,
    );
  }





  // ---------------------------------------------------------------------------
  // Submissions
  // ---------------------------------------------------------------------------

  Future<String> submitReport({
    required String uid,
    required String category,
    required String description,
    required String severity,
    required double lat,
    required double lng,
    required String locationName,
    required String zoneLabel,
  }) async {
    // Try to send directly to Firestore if internet is available.
    final isOnline = await _isInternetAvailable();
    if (isOnline) {
      await ref.read(databaseServiceProvider).submitReport(
        uid: uid,
        category: category,
        description: description,
        severity: severity,
        lat: lat,
        lng: lng,
        locationName: locationName,
        zoneLabel: zoneLabel,
      );
      return 'firebase';
    }

    // Offline – cache locally for later sync.
    await _cacheReport({
      'uid': uid,
      'category': category,
      'description': description,
      'severity': severity,
      'lat': lat,
      'lng': lng,
      'locationName': locationName,
      'zoneLabel': zoneLabel,
      'timestamp': DateTime.now().toIso8601String(),
    });
    return 'local';
  }

  /// Submits survey following Approach 3 (Hybrid)
  /// Returns: 'firebase' (online), or 'local' (queued locally)
  Future<String> submitSurvey({
    required String uid,
    required String residentName,
    required String residentContact,
    required Map<String, dynamic> surveyData,
    required String zoneLabel,
  }) async {
    // 1. Internet Available?
    final isOnline = await _isInternetAvailable();
    if (isOnline) {
      await ref.read(databaseServiceProvider).submitSurvey(
        uid: uid,
        residentName: residentName,
        residentContact: residentContact,
        surveyData: surveyData,
        zoneLabel: zoneLabel,
      );
      return 'firebase';
    }

    // 2. Offline – cache locally
    await _cacheSurvey({
      'uid': uid,
      'residentName': residentName,
      'residentContact': residentContact,
      'surveyData': surveyData,
      'zoneLabel': zoneLabel,
      'timestamp': DateTime.now().toIso8601String(),
    });
    return 'local';

  }

  // ---------------------------------------------------------------------------
  // Cache Management
  // ---------------------------------------------------------------------------

  Future<void> _cacheReport(Map<String, dynamic> reportData) async {
    if (!_initialized) _prefs = await SharedPreferences.getInstance();
    final reportsList = _prefs.getStringList('pending_reports') ?? [];
    reportsList.add(json.encode(reportData));
    await _prefs.setStringList('pending_reports', reportsList);
    _updateCounts();
  }

  Future<void> _cacheSurvey(Map<String, dynamic> surveyData) async {
    if (!_initialized) _prefs = await SharedPreferences.getInstance();
    final surveysList = _prefs.getStringList('pending_surveys') ?? [];
    surveysList.add(json.encode(surveyData));
    await _prefs.setStringList('pending_surveys', surveysList);
    _updateCounts();
  }

  // ---------------------------------------------------------------------------
  // Sync Operation
  // ---------------------------------------------------------------------------

  Future<void> triggerSync() async {
    if (state.isSyncing) return;
    if (!_initialized) _prefs = await SharedPreferences.getInstance();

    final reportsList = _prefs.getStringList('pending_reports') ?? [];
    final surveysList = _prefs.getStringList('pending_surveys') ?? [];

    if (reportsList.isEmpty && surveysList.isEmpty) return;

    state = state.copyWith(isSyncing: true);

    final List<String> successfullySyncedReports = [];
    final List<String> successfullySyncedSurveys = [];

    // Check internet first
    final isOnline = await _isInternetAvailable();
    if (!isOnline) {
      state = state.copyWith(isSyncing: false);
      return;
    }

    // 1. Sync Reports
    for (final reportStr in reportsList) {
      try {
        final data = json.decode(reportStr) as Map<String, dynamic>;
        await ref.read(databaseServiceProvider).submitReport(
          uid: data['uid'],
          category: data['category'],
          description: data['description'],
          severity: data['severity'],
          lat: data['lat'],
          lng: data['lng'],
          locationName: data['locationName'],
          zoneLabel: data['zoneLabel'],
        );
        successfullySyncedReports.add(reportStr);
      } catch (e) {
        debugPrint("Failed to sync cached report: $e");
        // Keep in queue for next time
      }
    }

    // Remove synced reports from local cache
    if (successfullySyncedReports.isNotEmpty) {
      reportsList.removeWhere((item) => successfullySyncedReports.contains(item));
      await _prefs.setStringList('pending_reports', reportsList);
    }

    // 2. Sync Surveys
    for (final surveyStr in surveysList) {
      try {
        final data = json.decode(surveyStr) as Map<String, dynamic>;
        await ref.read(databaseServiceProvider).submitSurvey(
          uid: data['uid'],
          residentName: data['residentName'],
          residentContact: data['residentContact'],
          surveyData: Map<String, dynamic>.from(data['surveyData']),
          zoneLabel: data['zoneLabel'],
        );
        successfullySyncedSurveys.add(surveyStr);
      } catch (e) {
        debugPrint("Failed to sync cached survey: $e");
        // Keep in queue
      }
    }

    // Remove synced surveys
    if (successfullySyncedSurveys.isNotEmpty) {
      surveysList.removeWhere((item) => successfullySyncedSurveys.contains(item));
      await _prefs.setStringList('pending_surveys', surveysList);
    }

    state = state.copyWith(isSyncing: false);
    _updateCounts();
  }


}
