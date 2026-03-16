import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/relay_colors.dart';

/// A profile field that is locked and cannot be edited directly
///
/// Shows the field value with a lock icon and provides
/// a "Request Change" option to contact support.
class LockedProfileField extends StatelessWidget {
  const LockedProfileField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.lockReason = 'Set during onboarding',
    this.masked = false,
    this.onRequestChange,
  });

  /// Field label
  final String label;

  /// Field value (can be null/empty)
  final String? value;

  /// Leading icon
  final IconData icon;

  /// Reason the field is locked
  final String lockReason;

  /// Whether to mask the value (show last 4 chars)
  final bool masked;

  /// Callback when "Request Change" is tapped
  final VoidCallback? onRequestChange;

  String get displayValue {
    if (value == null || value!.isEmpty) return 'Not set';

    if (masked && value!.length > 4) {
      return '${'*' * (value!.length - 4)}${value!.substring(value!.length - 4)}';
    }

    return value!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value != null && value!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? RelayColors.darkSurface2 : RelayColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: isDark ? RelayColors.darkBorderSubtle : RelayColors.lightBorderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Icon(
            icon,
            size: 20,
            color: isDark ? RelayColors.darkTextMuted : RelayColors.lightTextMuted,
          ),
          const SizedBox(width: 12),

          // Label and value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? RelayColors.darkTextMuted
                            : RelayColors.lightTextMuted,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: hasValue
                            ? (isDark
                                ? RelayColors.darkTextPrimary
                                : RelayColors.lightTextPrimary)
                            : (isDark
                                ? RelayColors.darkTextMuted
                                : RelayColors.lightTextMuted),
                      ),
                ),
              ],
            ),
          ),

          // Lock icon with tooltip
          Tooltip(
            message: lockReason,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? RelayColors.darkBorderSubtle
                    : RelayColors.lightBorderSubtle,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 16,
                color: isDark
                    ? RelayColors.darkTextMuted
                    : RelayColors.lightTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A group of locked fields with a "Request Change" button
class LockedFieldsSection extends StatelessWidget {
  const LockedFieldsSection({
    super.key,
    required this.title,
    required this.fields,
    this.onRequestChange,
  });

  /// Section title
  final String title;

  /// List of locked field widgets
  final List<LockedProfileField> fields;

  /// Callback when "Request Change" is tapped
  final VoidCallback? onRequestChange;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isDark
                          ? RelayColors.darkTextSecondary
                          : RelayColors.lightTextSecondary,
                    ),
              ),
              const Spacer(),
              // Completion indicator (locked fields are always "complete")
              Icon(
                Icons.check_circle,
                size: 16,
                color: RelayColors.success,
              ),
            ],
          ),
        ),

        // Fields
        ...fields.map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: field,
            )),

        // Request change button
        if (onRequestChange != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRequestChange,
              icon: const Icon(Icons.support_agent, size: 18),
              label: const Text('Request Changes'),
              style: TextButton.styleFrom(
                foregroundColor: RelayColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Support contact dialog for requesting profile changes
class RequestChangeDialog extends StatelessWidget {
  const RequestChangeDialog({
    super.key,
    required this.companyName,
    this.supportEmail,
    this.supportPhone,
    required this.onEmailTap,
    required this.onPhoneTap,
  });

  final String? companyName;
  final String? supportEmail;
  final String? supportPhone;
  final VoidCallback onEmailTap;
  final VoidCallback onPhoneTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Request Profile Changes'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To update your personal details (Date of Birth, National Insurance), please contact ${companyName ?? 'your operator'}:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          if (supportEmail != null) ...[
            _ContactOption(
              icon: Icons.email_outlined,
              label: 'Email',
              value: supportEmail!,
              onTap: onEmailTap,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
          ],

          if (supportPhone != null)
            _ContactOption(
              icon: Icons.phone_outlined,
              label: 'Call',
              value: supportPhone!,
              onTap: onPhoneTap,
              isDark: isDark,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ContactOption extends StatelessWidget {
  const _ContactOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? RelayColors.darkSurface2 : RelayColors.lightSurfaceElevated,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: RelayColors.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? RelayColors.darkTextMuted
                              : RelayColors.lightTextMuted,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: RelayColors.primary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
