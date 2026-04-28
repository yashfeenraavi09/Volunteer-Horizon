import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String? id;
  final String reportSource; // 'volunteer_app'
  final String submittedByVolunteerId;
  final String text;
  final String category;
  final String reportStatus; // 'new'
  final String residentName;
  final String residentContact;
  final String locationName;
  final double latitude;
  final double longitude;
  final String zoneLabel;
  final DateTime createdAt;

  Report({
    this.id,
    required this.reportSource,
    required this.submittedByVolunteerId,
    required this.text,
    required this.category,
    required this.reportStatus,
    required this.residentName,
    required this.residentContact,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.zoneLabel,
    required this.createdAt,
  });

  factory Report.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      reportSource: data['report_source'] ?? 'volunteer_app',
      submittedByVolunteerId: data['submitted_by_volunteer_id'] ?? '',
      text: data['text'] ?? '',
      category: data['category'] ?? 'general',
      reportStatus: data['report_status'] ?? 'new',
      residentName: data['resident_name'] ?? 'Self Reported',
      residentContact: data['resident_contact'] ?? '',
      locationName: data['location_name'] ?? 'Unknown',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      zoneLabel: data['zone_label'] ?? 'none',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'report_source': reportSource,
      'submitted_by_volunteer_id': submittedByVolunteerId,
      'text': text,
      'category': category,
      'report_status': reportStatus,
      'resident_name': residentName,
      'resident_contact': residentContact,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'zone_label': zoneLabel,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
