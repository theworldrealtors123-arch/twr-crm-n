import 'package:flutter/material.dart';

import '../../../models/enums.dart';
import '../../../theme/app_colors.dart';

Color priorityColor(String priority) {
  switch (priority) {
    case LeadPriority.hot:
      return AppColors.hot;
    case LeadPriority.cold:
      return AppColors.cold;
    default:
      return AppColors.warm;
  }
}

Color statusColor(String status) {
  switch (status) {
    case LeadStatus.newLead:
      return AppColors.royalBlue;
    case LeadStatus.contacted:
    case LeadStatus.qualified:
    case LeadStatus.propertySent:
    case LeadStatus.siteVisit:
    case LeadStatus.negotiation:
      return AppColors.primaryLight;
    case LeadStatus.booking:
    case LeadStatus.closed:
      return AppColors.success;
    case LeadStatus.lost:
    case LeadStatus.notInterested:
    case LeadStatus.wrongNumber:
    case LeadStatus.duplicate:
      return AppColors.textSecondary;
    default:
      return AppColors.primary;
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.dense = false});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Color color = statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: AppColors.alpha(color, 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.alpha(color, 0.35)),
      ),
      child: Text(
        humanizeEnum(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class PriorityChip extends StatelessWidget {
  const PriorityChip({super.key, required this.priority, this.dense = false});

  final String priority;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Color color = priorityColor(priority);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: AppColors.white,
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
