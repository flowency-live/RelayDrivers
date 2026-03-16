import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/relay_colors.dart';

/// Status info card with tenant contact information
/// Shows different messages based on driver status and provides
/// contact options for support
class StatusInfoCard extends StatelessWidget {
  final String status;
  final String? companyName;
  final String? supportEmail;
  final String? supportPhone;
  final VoidCallback? onMessageTap;

  const StatusInfoCard({
    super.key,
    required this.status,
    this.companyName,
    this.supportEmail,
    this.supportPhone,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(status);
    final company = companyName ?? 'your operator';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? RelayColors.darkSurface1 : RelayColors.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: isDark ? RelayColors.darkBorderSubtle : RelayColors.lightBorderSubtle,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with accent bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusConfig.backgroundColor,
              border: Border(
                left: BorderSide(
                  color: statusConfig.accentColor,
                  width: AppTheme.accentBarWidth,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusConfig.accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(
                      color: statusConfig.accentColor.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    statusConfig.icon,
                    color: statusConfig.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusConfig.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? RelayColors.darkTextPrimary
                                  : RelayColors.lightTextPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusConfig.accentColor,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        ),
                        child: Text(
                          _formatStatus(status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status message
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _getStatusMessage(status, company),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? RelayColors.darkTextSecondary
                        : RelayColors.lightTextSecondary,
                  ),
            ),
          ),

          // Contact options (for onboarding/pending/suspended)
          if (status == 'onboarding' ||
              status == 'pending' ||
              status == 'suspended') ...[
            Divider(
              height: 1,
              color: isDark
                  ? RelayColors.darkBorderSubtle
                  : RelayColors.lightBorderSubtle,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need help? Contact $company:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? RelayColors.darkTextMuted
                              : RelayColors.lightTextMuted,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Contact buttons row
                  Row(
                    children: [
                      if (supportPhone != null && supportPhone!.isNotEmpty)
                        Expanded(
                          child: _ContactButton(
                            icon: Icons.phone,
                            label: 'Call',
                            onTap: () => _launchPhone(supportPhone!),
                            isDark: isDark,
                          ),
                        ),
                      if (supportPhone != null &&
                          supportPhone!.isNotEmpty &&
                          supportEmail != null &&
                          supportEmail!.isNotEmpty)
                        const SizedBox(width: 8),
                      if (supportEmail != null && supportEmail!.isNotEmpty)
                        Expanded(
                          child: _ContactButton(
                            icon: Icons.email,
                            label: 'Email',
                            onTap: () => _launchEmail(supportEmail!),
                            isDark: isDark,
                          ),
                        ),
                      if (onMessageTap != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ContactButton(
                            icon: Icons.chat,
                            label: 'Message',
                            onTap: onMessageTap,
                            isPrimary: true,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    return switch (status) {
      'active' => _StatusConfig(
          title: 'Ready to Work',
          icon: Icons.check_circle,
          accentColor: RelayColors.success,
          backgroundColor: RelayColors.successBackground,
        ),
      'onboarding' => _StatusConfig(
          title: 'Complete Your Profile',
          icon: Icons.edit_document,
          accentColor: RelayColors.warning,
          backgroundColor: RelayColors.warningBackground,
        ),
      'pending' => _StatusConfig(
          title: 'Application Under Review',
          icon: Icons.hourglass_empty,
          accentColor: RelayColors.info,
          backgroundColor: RelayColors.infoBackground,
        ),
      'suspended' => _StatusConfig(
          title: 'Account Suspended',
          icon: Icons.block,
          accentColor: RelayColors.danger,
          backgroundColor: RelayColors.dangerBackground,
        ),
      _ => _StatusConfig(
          title: 'Account Status',
          icon: Icons.info,
          accentColor: RelayColors.darkTextMuted,
          backgroundColor: RelayColors.darkBorderSubtle,
        ),
    };
  }

  String _formatStatus(String status) {
    return switch (status) {
      'active' => 'Active',
      'onboarding' => 'Onboarding',
      'pending' => 'Pending Review',
      'suspended' => 'Suspended',
      _ => status,
    };
  }

  String _getStatusMessage(String status, String company) {
    return switch (status) {
      'active' => 'Your account is active and you can start accepting jobs.',
      'onboarding' =>
        'You have been invited to drive with $company. Please complete all required information below.',
      'pending' =>
        'Your application is being reviewed by $company. We\'ll notify you once approved.',
      'suspended' =>
        'Your account has been suspended. Please contact $company for assistance.',
      _ => 'Unknown status',
    };
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _StatusConfig {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;

  const _StatusConfig({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.backgroundColor,
  });
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isDark;

  const _ContactButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary
          ? RelayColors.primary
          : (isDark ? RelayColors.darkSurface2 : RelayColors.lightSurfaceElevated),
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: isPrimary
                ? null
                : Border.all(
                    color: isDark
                        ? RelayColors.darkBorderDefault
                        : RelayColors.lightBorderDefault,
                    width: 1,
                  ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary
                    ? Colors.white
                    : (isDark
                        ? RelayColors.darkTextPrimary
                        : RelayColors.lightTextPrimary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? Colors.white
                      : (isDark
                          ? RelayColors.darkTextPrimary
                          : RelayColors.lightTextPrimary),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
