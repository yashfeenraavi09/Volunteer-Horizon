class Task {
  final String id;
  final String title;
  final String subtitle;
  final String location;
  final double distance;
  final PriorityLevel priority;
  final bool isAIAssigned;
  final bool isAIRecommended;
  final bool isAIVerified;
  final String description;

  Task({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.distance,
    required this.priority,
    required this.isAIAssigned,
    this.isAIRecommended = false,
    this.isAIVerified = false,
    required this.description,
  });
}

enum PriorityLevel { low, medium, high }
