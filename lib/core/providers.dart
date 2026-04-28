import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assignment_model.dart';
import '../models/report_model.dart';
import '../models/volunteer_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/map_service.dart';

class HighPriorityModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Listen for high-priority tasks in the pending list
    ref.listen(pendingAssignmentsProvider, (previous, next) {
      final tasks = next.value;
      if (tasks != null && tasks.isNotEmpty) {
        // Priority Rank 1 or 2 is considered High/Critical
        final hasCritical = tasks.any((t) => t.priorityRank <= 2);
        if (hasCritical && !state) {
          state = true;
        }
      }
    });

    // Listen for high-priority tasks in the active mission
    ref.listen(currentAssignmentProvider, (previous, next) {
      final assignment = next.value;
      if (assignment != null) {
        if (assignment.priorityRank <= 2 && !state) {
          state = true;
        }
      }
    });

    return false;
  }

  void toggle(bool value) {
    state = value;
  }
}

final highPriorityModeProvider = NotifierProvider<HighPriorityModeNotifier, bool>(() {
  return HighPriorityModeNotifier();
});

/// Streams the volunteer profile from the professional 'volunteers' collection
final volunteerProfileProvider = StreamProvider<Volunteer?>((ref) {
  final authState = ref.watch(authStateProvider);
  final db = ref.watch(databaseServiceProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection('volunteers')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) => snapshot.exists ? Volunteer.fromFirestore(snapshot) : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Streams assignments that are 'pending' and assigned directly to this volunteer
final pendingAssignmentsProvider = StreamProvider<List<Assignment>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value([]);

  final db = ref.watch(databaseServiceProvider);
  return db.streamPendingAssignments(authState.uid).map(
    (list) => list.map((data) => Assignment.fromFirestore(_mockDoc(data))).toList()
  );
});

/// Streams the current active assignment for the volunteer
final currentAssignmentProvider = StreamProvider<Assignment?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);

  final db = ref.watch(databaseServiceProvider);
  return db.streamCurrentAssignment(authState.uid).map(
    (data) => data != null ? Assignment.fromFirestore(_mockDoc(data)) : null
  );
});

/// Streams a single assignment by its ID for real-time detail views
final singleAssignmentProvider = StreamProvider.family<Assignment?, String>((ref, id) {
  return FirebaseFirestore.instance
      .collection('assignments')
      .doc(id)
      .snapshots()
      .map((snapshot) => snapshot.exists ? Assignment.fromFirestore(snapshot) : null);
});

/// Streams a single report by its ID for mission context
final reportStreamProvider = StreamProvider.family<Report?, String>((ref, id) {
  return FirebaseFirestore.instance
      .collection('reports')
      .doc(id)
      .snapshots()
      .map((snapshot) => snapshot.exists ? Report.fromFirestore(snapshot) : null);
});

/// Helper to convert Map back to a mock DocumentSnapshot for our model factories
DocumentSnapshot _mockDoc(Map<String, dynamic> data) {
  final id = data.remove('id');
  return _MockDocumentSnapshot(id, data);
}

class _MockDocumentSnapshot implements DocumentSnapshot {
  @override
  final String id;
  final Map<String, dynamic>? _data;

  _MockDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic operator [](Object field) => _data?[field];

  @override
  bool get exists => _data != null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
final mapServiceProvider = Provider<MapService>((ref) => MapService());

final mapDataProvider = FutureProvider<MapData>((ref) async {
  final service = ref.watch(mapServiceProvider);
  return service.fetchMapData();
});
