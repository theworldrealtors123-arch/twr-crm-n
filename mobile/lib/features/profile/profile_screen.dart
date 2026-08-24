import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../models/enums.dart';
import '../../models/user.dart';
import '../../routes/app_router.dart';
import '../../shared/widgets/state_views.dart';
import '../../theme/app_colors.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('You will need to sign in again to access the CRM.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('LOG OUT', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }
    await context.read<AuthProvider>().logout();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: <Widget>[
                Center(
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.alpha(AppColors.gold, 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          humanizeEnum(user.role),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SectionCard(
                  title: 'Account',
                  child: Column(
                    children: <Widget>[
                      LabelValueRow(label: 'Email', value: user.email),
                      LabelValueRow(label: 'Phone', value: user.phone ?? '-'),
                      LabelValueRow(
                        label: 'Status',
                        value: user.isActive ? 'Active' : 'Inactive',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Permissions',
                  child: user.permissions.isEmpty
                      ? const Text(
                          'No permissions loaded.',
                          style: TextStyle(color: AppColors.textSecondary),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.permissions
                              .map(
                                (String permission) => Chip(
                                  label: Text(
                                    permission,
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                  backgroundColor: AppColors.lightGrey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'About',
                  child: const Column(
                    children: <Widget>[
                      LabelValueRow(label: 'Application', value: AppConfig.appName),
                      LabelValueRow(label: 'Company', value: AppConfig.companyName),
                      LabelValueRow(label: 'Version', value: '1.0.0 (Day 1)'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  key: const Key('logout_button'),
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: const Text('LOG OUT'),
                ),
              ],
            ),
    );
  }
}
