import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationUtils {
  static Future<void> migrateLegacyData() async {
    final db = FirebaseFirestore.instance;

    // 1. Migrate Users to Volunteers
    final usersSnapshot = await db.collection('users').get();
    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      
      // Dual write to volunteers
      await db.collection('volunteers').doc(doc.id).set({
        'name': data['name'],
        'skill_type': (data['skills'] as List?)?.first ?? 'general',
        'availability_status': 'available',
        'assigned_zone': 'zone_1', // Default migration zone
        'current_latitude': 0.0,
        'current_longitude': 0.0,
        'contact': data['phone'] ?? '',
        'active_assignment_id': null,
        'utilization_status': 'ready',
        'created_at': data['createdAt'] ?? FieldValue.serverTimestamp(),
      });

      // Dual write to volunteer_users
      await db.collection('volunteer_users').doc(doc.id).set({
        'volunteer_id': doc.id,
        'email': '',
        'role': 'volunteer',
        'account_status': 'active',
        'created_at': data['createdAt'] ?? FieldValue.serverTimestamp(),
        'last_login_at': FieldValue.serverTimestamp(),
      });
    }

    // 2. Migrate Reports to snake_case
    final reportsSnapshot = await db.collection('reports').get();
    for (var doc in reportsSnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('volunteerId')) {
        await db.collection('reports').doc(doc.id).update({
          'source_type': 'volunteer',
          'submitted_by_id': data['volunteerId'],
          'description': data['data']?['description'] ?? '',
          'category': data['reportType'] ?? 'general',
          'severity_level': data['data']?['severity']?.toString().toLowerCase() ?? 'medium',
          'latitude': (data['data']?['location'] as GeoPoint?)?.latitude ?? 0.0,
          'longitude': (data['data']?['location'] as GeoPoint?)?.longitude ?? 0.0,
          'zone_label': 'zone_1',
          'created_at': data['createdAt'] ?? FieldValue.serverTimestamp(),
        });
      }
    }
  }
}
