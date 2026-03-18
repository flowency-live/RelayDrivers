import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../../../core/design_system/tokens/spacing.dart';

/// Premium status info card with glass morphism
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

    if (!isDark) {
      return _buildLightModeCard(context, statusConfig, company);
    }

    // Dark mode: Premium glass card
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: DesignColors.glassBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DesignColors.glassBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignColors.glassShadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, statusConfig, isDark),

              // Status message
              Padding(
                padding: const EdgeInsets.all(DesignSpacing.lg),
                child: Text(
                  _getStatusMessage(status, company),
                  style: DesignTypography.bodyMedium.copyWith(
                    color: DesignColors.textSecondary,
                  ),
                ),
              ),

              // Contact options
              if (_shouldShowContactOptions()) ...[
                Container(
                  height: 1,
                  color: DesignColors.glassBorder,
                ),
                _buildContactSection(context, company, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLightModeCard(
    BuildContext context,
    _StatusConfig statusConfig,
    String company,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.88),
                Colors.white.withOpacity(0.78),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: statusConfig.accentColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, statusConfig, false),
              Padding(
                padding: const EdgeInsets.all(DesignSpacing.lg),
                child: Text(
                  _getStatusMessage(status, company),
                  style: DesignTypography.bodyMedium.copyWith(
                    color: DesignColors.lightTextSecondary,
                  ),
                ),
              ),
              if (_shouldShowContactOptions()) ...[
                Container(
                  height: 1,
                  color: DesignColors.lightBorderSubtle,
                ),
                _buildContactSection(context, company, false),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    _StatusConfig statusConfig,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(DesignSpacing.lg),
      child: Row(
        children: [
          // Glowing icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusConfig.accentColor.withOpacity(isDark ? 0.15 : 0.12),
              borderRadius: BorderRadius.circular(14),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: statusConfig.accentColor.withOpacity(0.25),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              statusConfig.icon,
              color: statusConfig.accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: DesignSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusConfig.title,
                  style: DesignTypography.cardTitle.copyWith(
                    color: isDark
                        ? DesignColors.textPrimary
                        : DesignColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusConfig.accentColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: statusConfig.accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
    );
  }

  Widget _buildContactSection(
    BuildContext context,
    String company,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(DesignSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need help? Contact $company:',
            style: DesignTypography.labelSmall.copyWith(
              color: isDark
                  ? DesignColors.textMuted
                  : DesignColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: DesignSpacing.md),
          Row(
            children: [
              if (supportPhone != null && supportPhone!.isNotEmpty)
                Expanded(
                  child: _ContactButton(
                    icon: Icons.phone_rounded,
                    label: 'Call',
                    onTap: () => _launchPhone(supportPhone!),
                    isDark: isDark,
                  ),
                ),
              if (supportPhone != null &&
                  supportPhone!.isNotEmpty &&
                  supportEmail != null &&
                  supportEmail!.isNotEmpty)
                const SizedBox(width: DesignSpacing.sm),
              if (supportEmail != null && supportEmail!.isNotEmpty)
                Expanded(
                  child: _ContactButton(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    onTap: () => _launchEmail(supportEmail!),
                    isDark: isDark,
                  ),
                ),
              if (onMessageTap != null) ...[
                const SizedBox(width: DesignSpacing.sm),
                Expanded(
                  child: _ContactButton(
                    icon: Icons.chat_bubble_rounded,
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
    );
  }

  bool _shouldShowContactOptions() {
    return status == 'onboarding' ||
        status == 'pending' ||
        status == 'suspended';
  }

  _StatusConfig _getStatusConfig(String status) {
    return switch (status) {
      'active' => _StatusConfig(
          title: 'Ready to Work',
          icon: Icons.check_circle_rounded,
          accentColor: DesignColors.success,
        ),
      'onboarding' => _StatusConfig(
          title: 'Complete Your Profile',
          icon: Icons.edit_document,
          accentColor: DesignColors.warning,
        ),
      'pending' => _StatusConfig(
          title: 'Application Under Review',
          icon: Icons.hourglass_empty_rounded,
          accentColor: DesignColors.info,
        ),
      'suspended' => _StatusConfig(
          title: 'Account Suspended',
          icon: Icons.block_rounded,
          accentColor: DesignColors.danger,
        ),
      _ => _StatusConfig(
          title: 'Account Status',
          icon: Icons.info_rounded,
          accentColor: DesignColors.textMuted,
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

  const _StatusConfig({
    required this.title,
    required this.icon,
    required this.accentColor,
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
    if (isPrimary) {
      // Premium gradient button
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                DesignColors.accent,
                DesignColors.accentDark,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: DesignColors.accentGlow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Secondary button with glass effect
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark
                  ? DesignColors.textSecondary
                  : DesignColors.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? DesignColors.textPrimary
                    : DesignColors.lightTextPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
