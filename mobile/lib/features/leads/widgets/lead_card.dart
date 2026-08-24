import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/lead.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_colors.dart';
import 'lead_chips.dart';

class LeadCard extends StatelessWidget {
  const LeadCard({super.key, required this.lead, this.onTap});

  final Lead lead;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          lead.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lead.phone,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PriorityChip(priority: lead.priority, dense: true),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Icon(Icons.home_work_outlined,
                      size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      Formatters.requirement(
                        propertyType: lead.propertyType,
                        bedrooms: lead.bedrooms,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  const Icon(Icons.payments_outlined,
                      size: 15, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    Formatters.budgetRange(lead.budgetMin, lead.budgetMax),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (lead.preferredLocation != null &&
                      lead.preferredLocation!.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 10),
                    const Icon(Icons.place_outlined,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lead.preferredLocation!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  StatusChip(status: lead.status, dense: true),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      lead.assignedAgent == null
                          ? 'Unassigned'
                          : 'Assigned: ${lead.assignedAgent!.firstName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    Formatters.relative(lead.createdAt),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
