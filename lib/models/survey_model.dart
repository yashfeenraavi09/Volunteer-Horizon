import 'package:cloud_firestore/cloud_firestore.dart';

class Survey {
  final String id;
  final String residentName;
  final String category;
  final String description;
  final String severity;
  final DateTime? createdAt;
  final String? childrenCount;
  final bool? hasDisability;
  final String? houseType;
  final bool? isImmunized;
  final String? residentContact;
  final String? socialGroup;
  final String? submittedByVolunteerId;
  final String? toiletAccess;
  final String? totalMembers;
  final String? waterSource;
  final String? zoneLabel;

  Survey({
    required this.id,
    required this.residentName,
    required this.category,
    required this.description,
    required this.severity,
    this.createdAt,
    this.childrenCount,
    this.hasDisability,
    this.houseType,
    this.isImmunized,
    this.residentContact,
    this.socialGroup,
    this.submittedByVolunteerId,
    this.toiletAccess,
    this.totalMembers,
    this.waterSource,
    this.zoneLabel,
  });

  factory Survey.fromMap(Map<String, dynamic> data, String docId) {
    return Survey(
      id: docId,
      residentName: data['resident_name'] as String? ?? '',
      category: data['category'] as String? ?? 'Click to view details',
      description: data['text'] as String? ?? '',
      severity: data['severity_level'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      childrenCount: data['children_count']?.toString(),
      hasDisability: data['has_disability'] as bool? ?? false,
      houseType: data['house_type'] as String? ?? '',
      isImmunized: data['is_immunized'] as bool? ?? false,
      residentContact: data['resident_contact'] as String? ?? '',
      socialGroup: data['social_group'] as String? ?? '',
      submittedByVolunteerId: data['submitted_by_volunteer_id'] as String? ?? '',
      toiletAccess: data['toilet_access'] as String? ?? '',
      totalMembers: data['total_members']?.toString(),
      waterSource: data['water_source'] as String? ?? '',
      zoneLabel: data['zone_label'] as String? ?? '',
    );
  }
}
