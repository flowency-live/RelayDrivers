import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusConfig.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusConfig.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusConfig.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  statusConfig.icon,
                  color: statusConfig.iconColor,
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
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusConfig.badgeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatStatus(status),
                        style: TextStyle(
                          color: statusConfig.badgeTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status message
          Text(
            _getStatusMessage(status, company),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withAlpha(200),
                ),
          ),

          // Contact options (for onboarding/pending/suspended)
          if (status == 'onboarding' || status == 'pending' || status == 'suspended') ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Text(
              'Need help? Contact $company:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withAlpha(150),
                  ),
            ),
            const SizedBox(height: 8),

            // Contact buttons row
            Row(
              children: [
                if (supportPhone != null && supportPhone!.isNotEmpty)
                  Expanded(
                    child: _ContactButton(
                      icon: Icons.phone,
                      label: 'Call',
                      onTap: () => _launchPhone(supportPhone!),
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
                    ),
                  ),
                ],
              ],
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
          iconColor: const Color(0xFF2ECC71),
          iconBackgroundColor: const Color(0xFF2ECC71).withAlpha(25),
          backgroundColor: const Color(0xFF2ECC71).withAlpha(15),
          borderColor: const Color(0xFF2ECC71).withAlpha(50),
          badgeColor: const Color(0xFF2ECC71),
          badgeTextColor: Colors.white,
        ),
      'onboarding' => _StatusConfig(
          title: 'Complete Your Profile',
          icon: Icons.edit_document,
          iconColor: const Color(0xFFF39C12),
          iconBackgroundColor: const Color(0xFFF39C12).withAlpha(25),
          backgroundColor: const Color(0xFFF39C12).withAlpha(15),
          borderColor: const Color(0xFFF39C12).withAlpha(50),
          badgeColor: const Color(0xFFF39C12),
          badgeTextColor: Colors.white,
        ),
      'pending' => _StatusConfig(
          title: 'Application Under Review',
          icon: Icons.hourglass_empty,
          iconColor: const Color(0xFF3498DB),
          iconBackgroundColor: const Color(0xFF3498DB).withAlpha(25),
          backgroundColor: const Color(0xFF3498DB).withAlpha(15),
          borderColor: const Color(0xFF3498DB).withAlpha(50),
          badgeColor: const Color(0xFF3498DB),
          badgeTextColor: Colors.white,
        ),
      'suspended' => _StatusConfig(
          title: 'Account Suspended',
          icon: Icons.block,
          iconColor: const Color(0xFFE63946),
          iconBackgroundColor: const Color(0xFFE63946).withAlpha(25),
          backgroundColor: const Color(0xFFE63946).withAlpha(15),
          borderColor: const Color(0xFFE63946).withAlpha(50),
          badgeColor: const Color(0xFFE63946),
          badgeTextColor: Colors.white,
        ),
      _ => _StatusConfig(
          title: 'Account Status',
          icon: Icons.info,
          iconColor: const Color(0xFF6C757D),
          iconBackgroundColor: const Color(0xFF6C757D).withAlpha(25),
          backgroundColor: const Color(0xFF6C757D).withAlpha(15),
          borderColor: const Color(0xFF6C757D).withAlpha(50),
          badgeColor: const Color(0xFF6C757D),
          badgeTextColor: Colors.white,
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
      'active' =>
        'Your account is active and you can start accepting jobs.',
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
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color badgeColor;
  final Color badgeTextColor;

  const _StatusConfig({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.badgeColor,
    required this.badgeTextColor,
  });
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _ContactButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isPrimary
                ? null
                : Border.all(
                    color: Theme.of(context).colorScheme.outline.withAlpha(50),
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
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
