import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(FirebaseFirestore.instance);
});



class DatabaseService {
  final FirebaseFirestore _db;

  DatabaseService(this._db);

  /// Saves the complete volunteer profile to 'volunteers' and 'volunteer_users'
  Future<void> createVolunteerProfile({
    required String uid,
    required String name,
    required String phone,
    required String assignedZone,
    required String skillType,
    List<String> skills = const [],
    String skillLevel = 'Beginner',
    List<String> availability = const [],
    List<String> taskPreferences = const [],
    double latitude = 0.0,
    double longitude = 0.0,
  }) async {
    final batch = _db.batch();

    // 1. Operational data for the NGO dashboard
    final volunteerRef = _db.collection('volunteers').doc(uid);
    batch.set(volunteerRef, {
      'name': name,
      'skill_type': skillType,             // Primary skill (first selected)
      'skills': skills,                    // All selected skills as a list
      'skill_level': skillLevel,           // Beginner / Intermediate / Expert
      'availability': availability,        // Selected availability windows
      'task_preferences': taskPreferences, // Preferred task categories
      'availability_status': 'available',
      'assigned_zone': assignedZone,
      'current_latitude': latitude,
      'current_longitude': longitude,
      'contact': phone,
      'active_assignment_id': null,
      'utilization_status': 'ready',
      'created_at': FieldValue.serverTimestamp(),
    });

    // 2. Auth/Identity metadata for the app
    final userRef = _db.collection('volunteer_users').doc(uid);
    batch.set(userRef, {
      'volunteer_id': uid,
      'email': FirebaseAuth.instance.currentUser?.email ?? '',
      'role': 'volunteer',
      'account_status': 'active',
      'created_at': FieldValue.serverTimestamp(),
      'last_login_at': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Grabs data from the 'volunteers' collection
  Future<Map<String, dynamic>?> getVolunteerProfile(String uid) async {
    try {
      final snapshot = await _db.collection('volunteers').doc(uid).get();
      return snapshot.data();
    } catch (e) {
      rethrow;
    }
  }

  /// Submits a report to the shared 'reports' collection with the required production schema
  Future<void> submitReport({
    required String uid,
    required String category,
    required String description,
    required String severity,
    required double lat,
    required double lng,
    required String locationName,
    required String zoneLabel,
  }) async {
    try {
      await _db.collection('reports').add({
        'report_source': 'volunteer_app',
        'report_status': 'new',           // Aligned with Screenshot 2
        'resident_name': 'Self Reported',  // Aligned with Screenshot 2
        'resident_contact': '',           // Aligned with Screenshot 2
        'submitted_by_volunteer_id': uid,
        'text': description,
        'category': category,
        'severity_level': severity.toLowerCase(),
        'latitude': lat,
        'longitude': lng,
        'location_name': locationName,
        'zone_label': zoneLabel,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves list of surveys submitted by the volunteer (one-time fetch)
  Future<List<Map<String, dynamic>>> getVolunteerSurveys(String uid) async {
    try {
      final snapshot = await _db
          .collection('surveys')
          .where('submitted_by_volunteer_id', isEqualTo: uid)
          .get();
      
      final docs = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      
      // Sort in-memory to avoid FAILED_PRECONDITION (missing index) error
      docs.sort((a, b) {
        final t1 = a['created_at'] as Timestamp?;
        final t2 = b['created_at'] as Timestamp?;
        if (t1 == null || t2 == null) return 0;
        return t2.compareTo(t1); // Sort Descending (Newest first)
      });
      
      return docs;
    } catch (e) {
      rethrow;
    }
  }

  /// Streams surveys submitted by the volunteer for real‑time updates
  Stream<List<Map<String, dynamic>>> streamVolunteerSurveys(String uid) {
    try {
      return _db
          .collection('surveys')
          .where('submitted_by_volunteer_id', isEqualTo: uid)
          .snapshots()
          .map((snapshot) {
        final docs = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        // In‑memory sort to maintain order without requiring Firestore index
        docs.sort((a, b) {
          final t1 = a['created_at'] as Timestamp?;
          final t2 = b['created_at'] as Timestamp?;
          if (t1 == null || t2 == null) return 0;
          return t2.compareTo(t1);
        });
        return docs;
      });
    } catch (e) {
      // If the stream setup fails, rethrow to let callers handle it
      rethrow;
    }
  }

  /// Submits or updates a resident survey (deduplication via resident name + contact)
  Future<void> submitSurvey({
    required String uid,
    required String residentName,
    required String residentContact,
    required Map<String, dynamic> surveyData,
    required String zoneLabel,
  }) async {
    try {
      // 1. Check for existing survey for this person (Composite Key)
      final existing = await _db.collection('surveys')
          .where('resident_name', isEqualTo: residentName)
          .where('resident_contact', isEqualTo: residentContact)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        // 2. Update existing instead of creating new (Remove Redundancy)
        await existing.docs.first.reference.update({
          ...surveyData,
          'updated_at': FieldValue.serverTimestamp(),
          'updated_by_id': uid,
        });
      } else {
        // 3. Create new if unique
        await _db.collection('surveys').add({
          'resident_name': residentName,
          'resident_contact': residentContact,
          'submitted_by_volunteer_id': uid,
          'zone_label': zoneLabel,
          'created_at': FieldValue.serverTimestamp(),
          ...surveyData,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches recent reports in the last 30 minutes for deduplication
  Future<List<Map<String, dynamic>>> findRecentReports() async {
    final thirtyMinsAgo = DateTime.now().subtract(const Duration(minutes: 30));
    final snapshot = await _db.collection('reports')
        .where('created_at', isGreaterThan: thirtyMinsAgo)
        .get();
    
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Transactional logic to accept an assignment
  Future<bool> acceptAssignment(String volunteerId, String assignmentId) async {
    final assignmentRef = _db.collection('assignments').doc(assignmentId);
    final volunteerRef = _db.collection('volunteers').doc(volunteerId);

    try {
      return await _db.runTransaction((transaction) async {
        final assignmentSnapshot = await transaction.get(assignmentRef);
        
        if (!assignmentSnapshot.exists || 
            assignmentSnapshot.data()?['assignment_status'] != 'pending') {
          return false;
        }

        // 1. Update Assignment
        transaction.update(assignmentRef, {
          'assigned_volunteer_id': volunteerId,
          'assignment_status': 'accepted',
          'accepted_at': FieldValue.serverTimestamp(),
        });

        // 2. Update Volunteer Status
        transaction.update(volunteerRef, {
          'active_assignment_id': assignmentId,
          'availability_status': 'busy',
          'utilization_status': 'assigned',
        });

        return true;
      });
    } catch (e) {
      return false;
    }
  }

  /// Update assignment status - Lifecycle enforcement handled by Backend
  Future<void> updateAssignmentStatus(String assignmentId, String newStatus, String volunteerId) async {
    try {
      // "Volunteer Release" is handled by Backend. 
      // App only updates the assignment status.
      await _db.collection('assignments').doc(assignmentId).update({
        'assignment_status': newStatus,
        if (newStatus == 'completed') 'completed_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Stream assignments assigned directly to this volunteer
  Stream<List<Map<String, dynamic>>> streamPendingAssignments(String volunteerId) {
    return _db
        .collection('assignments')
        .where('assigned_volunteer_id', isEqualTo: volunteerId)
        .where('assignment_status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          
          // Sort in-memory to avoid FAILED_PRECONDITION (missing index) error
          docs.sort((a, b) {
            final t1 = a['created_at'] as Timestamp?;
            final t2 = b['created_at'] as Timestamp?;
            if (t1 == null || t2 == null) return 0;
            return t2.compareTo(t1); // Sort Descending (Newest first)
          });
          
          return docs;
        });
  }

  /// Stream the current active assignment for a volunteer
  Stream<Map<String, dynamic>?> streamCurrentAssignment(String volunteerId) {
    return _db
        .collection('assignments')
        .where('assigned_volunteer_id', isEqualTo: volunteerId)
        .where('assignment_status', whereIn: ['accepted', 'en_route', 'on_site'])
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? {'id': snapshot.docs.first.id, ...snapshot.docs.first.data()} : null);
  }
}
