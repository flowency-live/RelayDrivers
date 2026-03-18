import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../../../core/design_system/tokens/radii.dart';
import '../../application/calendar_providers.dart';
import '../../domain/models/working_pattern.dart';

/// Card showing the driver's working hours pattern
class WorkingHoursCard extends ConsumerWidget {
  const WorkingHoursCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workingPattern = ref.watch(workingPatternProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(DesignSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? DesignColors.surface.withOpacity(0.5)
            : DesignColors.lightSurface,
        borderRadius: BorderRadius.circular(DesignRadii.card),
        border: Border.all(
          color: isDark
              ? DesignColors.borderSubtle
              : DesignColors.lightBorderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 20,
                    color: DesignColors.accent,
                  ),
                  const SizedBox(width: DesignSpacing.sm),
                  Text(
                    'Working Hours',
                    style: DesignTypography.labelMedium.copyWith(
                      color: isDark
                          ? DesignColors.textPrimary
                          : DesignColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showEditSheet(context, workingPattern),
                style: TextButton.styleFrom(
                  foregroundColor: DesignColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignSpacing.sm,
                    vertical: DesignSpacing.xxs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Edit'),
              ),
            ],
          ),

          const SizedBox(height: DesignSpacing.md),

          // Working days
          _InfoRow(
            label: 'Days',
            value: workingPattern.formattedDays,
            isDark: isDark,
          ),

          const SizedBox(height: DesignSpacing.sm),

          // Working hours
          _InfoRow(
            label: 'Hours',
            value: workingPattern.formattedHours,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WorkingPattern current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditWorkingHoursSheet(currentPattern: current),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: DesignTypography.bodySmall.copyWith(
            color: isDark
                ? DesignColors.textSecondary
                : DesignColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: DesignTypography.bodyMedium.copyWith(
            color: isDark
                ? DesignColors.textPrimary
                : DesignColors.lightTextPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet for editing working hours
class _EditWorkingHoursSheet extends ConsumerStatefulWidget {
  final WorkingPattern currentPattern;

  const _EditWorkingHoursSheet({required this.currentPattern});

  @override
  ConsumerState<_EditWorkingHoursSheet> createState() =>
      _EditWorkingHoursSheetState();
}

class _EditWorkingHoursSheetState
    extends ConsumerState<_EditWorkingHoursSheet> {
  late Set<Weekday> _selectedDays;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.currentPattern.workingDays.toSet();
    _startTime = _parseTime(widget.currentPattern.workingHoursStart) ??
        const TimeOfDay(hour: 9, minute: 0);
    _endTime = _parseTime(widget.currentPattern.workingHoursEnd) ??
        const TimeOfDay(hour: 18, minute: 0);
  }

  TimeOfDay? _parseTime(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _toggleDay(Weekday day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    // TODO: Call profile update API to save working pattern
    // For now, just close the sheet
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Working hours update coming soon'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? DesignColors.surface : DesignColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        DesignSpacing.lg,
        DesignSpacing.md,
        DesignSpacing.lg,
        mediaQuery.viewInsets.bottom + DesignSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? DesignColors.borderSubtle
                    : DesignColors.lightBorderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: DesignSpacing.lg),

          // Title
          Text(
            'Set Working Hours',
            style: DesignTypography.headlineSmall.copyWith(
              color: isDark
                  ? DesignColors.textPrimary
                  : DesignColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: DesignSpacing.xl),

          // Working days
          Text(
            'Working Days',
            style: DesignTypography.labelMedium.copyWith(
              color: isDark
                  ? DesignColors.textSecondary
                  : DesignColors.lightTextSecondary,
            ),
          ),

          const SizedBox(height: DesignSpacing.sm),

          Wrap(
            spacing: DesignSpacing.sm,
            runSpacing: DesignSpacing.sm,
            children: Weekday.values.map((day) {
              final isSelected = _selectedDays.contains(day);
              return FilterChip(
                label: Text(day.shortName),
                selected: isSelected,
                onSelected: (_) => _toggleDay(day),
                selectedColor: DesignColors.accent.withOpacity(0.2),
                checkmarkColor: DesignColors.accent,
                labelStyle: TextStyle(
                  color: isSelected
                      ? DesignColors.accent
                      : (isDark
                          ? DesignColors.textSecondary
                          : DesignColors.lightTextSecondary),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: DesignSpacing.xl),

          // Time pickers
          Row(
            children: [
              // Start time
              Expanded(
                child: _TimePicker(
                  label: 'Start Time',
                  time: _startTime,
                  onTap: _selectStartTime,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: DesignSpacing.lg),
              // End time
              Expanded(
                child: _TimePicker(
                  label: 'End Time',
                  time: _endTime,
                  onTap: _selectEndTime,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignSpacing.xl),

          // Save button
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: DesignSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignRadii.button),
              ),
            ),
            child: _isSaving
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  final bool isDark;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onTap,
    required this.isDark,
  });

  String get _formattedTime {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DesignTypography.labelSmall.copyWith(
            color: isDark
                ? DesignColors.textSecondary
                : DesignColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: DesignSpacing.xs),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSpacing.md,
              vertical: DesignSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? DesignColors.surfaceElevated
                  : DesignColors.lightBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? DesignColors.borderSubtle
                    : DesignColors.lightBorderSubtle,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formattedTime,
                  style: DesignTypography.bodyLarge.copyWith(
                    color: isDark
                        ? DesignColors.textPrimary
                        : DesignColors.lightTextPrimary,
                  ),
                ),
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: isDark
                      ? DesignColors.textMuted
                      : DesignColors.lightTextMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
