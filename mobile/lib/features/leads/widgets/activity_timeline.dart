import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/enums.dart';
import '../../../models/lead.dart';
import '../../../theme/app_colors.dart';

class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({super.key, required this.activities});

  final List<LeadActivity> activities;

  IconData _iconFor(String type) {
    switch (type) {
      case ActivityType.leadCreated:
        return Icons.person_add_alt_1_outlined;
      case ActivityType.statusChanged:
        return Icons.swap_horiz;
      case ActivityType.assigned:
        return Icons.assignment_ind_outlined;
      case ActivityType.noteAdded:
        return Icons.sticky_note_2_outlined;
      default:
        return Icons.edit_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No activity recorded yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: List<Widget>.generate(activities.length, (int index) {
        final LeadActivity activity = activities[index];
        final bool isLast = index == activities.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.alpha(AppColors.primary, 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFor(activity.type),
                      size: 17,
                      color: AppColors.primary,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 1.4, color: AppColors.border),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        Formatters.timestamp(activity.createdAt),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activity.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (activity.user != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          'by ${activity.user!.fullName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
