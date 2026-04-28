import 'package:cloud_firestore/cloud_firestore.dart';

class Volunteer {
  final String id;
  final String name;
  final String skillType;
  final String availabilityStatus;
  final String assignedZone;
  final double currentLatitude;
  final double currentLongitude;
  final String contact;
  final String? activeAssignmentId;
  final String utilizationStatus;
  final DateTime createdAt;

  Volunteer({
    required this.id,
    required this.name,
    required this.skillType,
    required this.availabilityStatus,
    required this.assignedZone,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.contact,
    this.activeAssignmentId,
    required this.utilizationStatus,
    required this.createdAt,
  });

  factory Volunteer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Volunteer(
      id: doc.id,
      name: data['name'] ?? '',
      skillType: data['skill_type'] ?? 'general',
      availabilityStatus: data['availability_status'] ?? 'offline',
      assignedZone: data['assigned_zone'] ?? 'none',
      currentLatitude: (data['current_latitude'] ?? 0.0).toDouble(),
      currentLongitude: (data['current_longitude'] ?? 0.0).toDouble(),
      contact: data['contact'] ?? '',
      activeAssignmentId: data['active_assignment_id'],
      utilizationStatus: data['utilization_status'] ?? 'ready',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'skill_type': skillType,
      'availability_status': availabilityStatus,
      'assigned_zone': assignedZone,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'contact': contact,
      'active_assignment_id': activeAssignmentId,
      'utilization_status': utilizationStatus,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
