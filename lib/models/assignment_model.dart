import 'package:cloud_firestore/cloud_firestore.dart';

class Assignment {
  final String id;
  final String reportId;
  final String? decisionId;
  final String category;
  final int priorityRank;
  final double? finalScore;
  final String? assignedTeam;
  final String? recommendedResource;
  final String? responseTimeline;
  final String? deploymentStatus;
  final String? missionDescription;
  final String locationName;
  final double latitude;
  final double longitude;
  final String zoneLabel;
  final DateTime createdAt;
  
  // Volunteer specific fields
  final String? assignedVolunteerId;
  final String assignmentStatus; // pending, accepted, en_route, on_site, completed
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  Assignment({
    required this.id,
    required this.reportId,
    this.decisionId,
    required this.category,
    required this.priorityRank,
    this.finalScore,
    this.assignedTeam,
    this.recommendedResource,
    this.responseTimeline,
    this.deploymentStatus,
    this.missionDescription,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.zoneLabel,
    required this.createdAt,
    this.assignedVolunteerId,
    required this.assignmentStatus,
    this.acceptedAt,
    this.completedAt,
  });

  factory Assignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Assignment(
      id: doc.id,
      reportId: data['report_id'] ?? '',
      decisionId: data['decision_id'],
      category: data['category'] ?? 'general',
      priorityRank: data['priority_rank'] ?? 5,
      finalScore: (data['final_score'] as num?)?.toDouble(),
      assignedTeam: data['assigned_team'],
      recommendedResource: data['recommended_resource'],
      responseTimeline: data['response_timeline'],
      deploymentStatus: data['deployment_status'],
      missionDescription: data['mission_description'],
      locationName: data['location_name'] ?? 'Unknown Location',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      zoneLabel: data['zone_label'] ?? 'none',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedVolunteerId: data['assigned_volunteer_id'],
      assignmentStatus: data['assignment_status'] ?? 'pending',
      acceptedAt: (data['accepted_at'] as Timestamp?)?.toDate(),
      completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'report_id': reportId,
      'decision_id': decisionId,
      'category': category,
      'priority_rank': priorityRank,
      'final_score': finalScore,
      'assigned_team': assignedTeam,
      'recommended_resource': recommendedResource,
      'response_timeline': responseTimeline,
      'deployment_status': deploymentStatus,
      'mission_description': missionDescription,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'zone_label': zoneLabel,
      'created_at': createdAt, // This is usually Dashboard-written, but just in case
      'assigned_volunteer_id': assignedVolunteerId,
      'assignment_status': assignmentStatus,
      'accepted_at': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completed_at': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}
