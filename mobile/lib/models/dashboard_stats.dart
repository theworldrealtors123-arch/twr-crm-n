class DashboardStats {
  const DashboardStats({
    required this.totalLeads,
    required this.newLeads,
    required this.hotLeads,
    required this.followUps,
    this.contactedLeads = 0,
    this.closedLeads = 0,
    this.byStatus = const <String, int>{},
    this.scope = 'ALL',
  });

  final int totalLeads;
  final int newLeads;
  final int hotLeads;
  final int followUps;
  final int contactedLeads;
  final int closedLeads;
  final Map<String, int> byStatus;
  final String scope;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final Map<String, int> statuses = <String, int>{};
    final Map<dynamic, dynamic> raw =
        (json['byStatus'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
    raw.forEach((dynamic key, dynamic value) {
      statuses['$key'] = (value as num).toInt();
    });

    return DashboardStats(
      totalLeads: (json['totalLeads'] ?? 0) as int,
      newLeads: (json['newLeads'] ?? 0) as int,
      hotLeads: (json['hotLeads'] ?? 0) as int,
      followUps: (json['followUps'] ?? 0) as int,
      contactedLeads: (json['contactedLeads'] ?? 0) as int,
      closedLeads: (json['closedLeads'] ?? 0) as int,
      byStatus: statuses,
      scope: (json['scope'] ?? 'ALL') as String,
    );
  }

  static const DashboardStats empty = DashboardStats(
    totalLeads: 0,
    newLeads: 0,
    hotLeads: 0,
    followUps: 0,
  );
}
