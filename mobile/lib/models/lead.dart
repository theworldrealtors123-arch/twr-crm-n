import 'user.dart';

class Lead {
  const Lead({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.priority,
    required this.source,
    required this.createdAt,
    this.whatsapp,
    this.email,
    this.propertyType,
    this.bedrooms,
    this.budgetMin,
    this.budgetMax,
    this.preferredLocation,
    this.purpose,
    this.campaign,
    this.projectName,
    this.leadScore = 0,
    this.assignedAgentId,
    this.assignedAgent,
    this.updatedAt,
    this.lastContactedAt,
    this.nextFollowupAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? whatsapp;
  final String? email;
  final String? propertyType;
  final int? bedrooms;
  final double? budgetMin;
  final double? budgetMax;
  final String? preferredLocation;
  final String? purpose;
  final String source;
  final String? campaign;
  final String? projectName;
  final String status;
  final String priority;
  final int leadScore;
  final String? assignedAgentId;
  final AppUser? assignedAgent;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastContactedAt;
  final DateTime? nextFollowupAt;

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as String,
      fullName: (json['fullName'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      whatsapp: json['whatsapp'] as String?,
      email: json['email'] as String?,
      propertyType: json['propertyType'] as String?,
      bedrooms: json['bedrooms'] as int?,
      budgetMin: _toDouble(json['budgetMin']),
      budgetMax: _toDouble(json['budgetMax']),
      preferredLocation: json['preferredLocation'] as String?,
      purpose: json['purpose'] as String?,
      source: (json['source'] ?? 'MANUAL') as String,
      campaign: json['campaign'] as String?,
      projectName: json['projectName'] as String?,
      status: (json['status'] ?? 'NEW') as String,
      priority: (json['priority'] ?? 'WARM') as String,
      leadScore: (json['leadScore'] ?? 0) as int,
      assignedAgentId: json['assignedAgentId'] as String?,
      assignedAgent: json['assignedAgent'] == null
          ? null
          : AppUser.fromJson(Map<String, dynamic>.from(
              json['assignedAgent'] as Map<dynamic, dynamic>)),
      createdAt: _toDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(json['updatedAt']),
      lastContactedAt: _toDate(json['lastContactedAt']),
      nextFollowupAt: _toDate(json['nextFollowupAt']),
    );
  }
}

class LeadNote {
  const LeadNote({
    required this.id,
    required this.note,
    required this.createdAt,
    this.user,
  });

  final String id;
  final String note;
  final DateTime createdAt;
  final AppUser? user;

  factory LeadNote.fromJson(Map<String, dynamic> json) {
    return LeadNote(
      id: json['id'] as String,
      note: (json['note'] ?? '') as String,
      createdAt:
          DateTime.tryParse('${json['createdAt']}')?.toLocal() ?? DateTime.now(),
      user: json['user'] == null
          ? null
          : AppUser.fromJson(
              Map<String, dynamic>.from(json['user'] as Map<dynamic, dynamic>)),
    );
  }
}

class LeadActivity {
  const LeadActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.createdAt,
    this.user,
  });

  final String id;
  final String type;
  final String description;
  final DateTime createdAt;
  final AppUser? user;

  factory LeadActivity.fromJson(Map<String, dynamic> json) {
    return LeadActivity(
      id: json['id'] as String,
      type: (json['type'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      createdAt:
          DateTime.tryParse('${json['createdAt']}')?.toLocal() ?? DateTime.now(),
      user: json['user'] == null
          ? null
          : AppUser.fromJson(
              Map<String, dynamic>.from(json['user'] as Map<dynamic, dynamic>)),
    );
  }
}
