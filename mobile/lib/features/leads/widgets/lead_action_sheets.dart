import 'package:flutter/material.dart';

import '../../../models/enums.dart';
import '../../../models/user.dart';
import '../../../theme/app_colors.dart';
import 'lead_chips.dart';

/// Status picker. Returns the chosen status, or null when dismissed.
Future<String?> showStatusPicker(BuildContext context, {required String current}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Change status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: LeadStatus.all.map((String status) {
                  final bool isCurrent = status == current;
                  return ListTile(
                    leading: Icon(
                      isCurrent
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                    ),
                    title: Text(humanizeEnum(status)),
                    trailing: StatusChip(status: status, dense: true),
                    enabled: !isCurrent,
                    onTap: isCurrent ? null : () => Navigator.of(context).pop(status),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

/// Agent picker. Returns the chosen agent id, or null when dismissed.
Future<String?> showAgentPicker(
  BuildContext context, {
  required List<AppUser> agents,
  String? currentAgentId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Assign agent',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (agents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No active agents available.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: agents.map((AppUser agent) {
                    final bool isCurrent = agent.id == currentAgentId;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          agent.initials,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(agent.fullName),
                      subtitle: Text(agent.email),
                      trailing: isCurrent
                          ? const Icon(Icons.check_circle, color: AppColors.success)
                          : null,
                      enabled: !isCurrent,
                      onTap:
                          isCurrent ? null : () => Navigator.of(context).pop(agent.id),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

/// Note composer. Returns the note text, or null when dismissed.
Future<String?> showAddNoteSheet(BuildContext context) {
  final TextEditingController controller = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Add note',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('note_input_field'),
              controller: controller,
              autofocus: true,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: 'e.g. Customer interested in 2BR in Dubai Marina.',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final String text = controller.text.trim();
                if (text.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(text);
              },
              child: const Text('SAVE NOTE'),
            ),
          ],
        ),
      );
    },
  );
}
