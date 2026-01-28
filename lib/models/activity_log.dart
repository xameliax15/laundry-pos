class ActivityLog {
  final String id;
  final String userId;
  final String action;
  final String? description;
  final String? tableName;
  final String? recordId;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.action,
    this.description,
    this.tableName,
    this.recordId,
    required this.createdAt,
  });

  // Convert from JSON
  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      action: json['action'] as String,
      description: json['description'] as String?,
      tableName: json['table_name'] as String?,
      recordId: json['record_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'description': description,
      'table_name': tableName,
      'record_id': recordId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}



