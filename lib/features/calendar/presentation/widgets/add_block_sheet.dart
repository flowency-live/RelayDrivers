import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';
import '../../../../core/design_system/tokens/radii.dart';
import '../../application/calendar_providers.dart';

/// Bottom sheet for adding a new availability block
class AddBlockSheet extends ConsumerStatefulWidget {
  /// Pre-selected date (when tapping a day on the calendar)
  final DateTime? initialDate;

  const AddBlockSheet({
    super.key,
    this.initialDate,
  });

  @override
  ConsumerState<AddBlockSheet> createState() => _AddBlockSheetState();
}

class _AddBlockSheetState extends ConsumerState<AddBlockSheet> {
  late DateTime _selectedDate;
  bool _isAllDay = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: DesignColors.accent,
                    surface: DesignColors.surface,
                  )
                : ColorScheme.light(
                    primary: DesignColors.accent,
                    surface: DesignColors.lightSurface,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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

    final notifier = ref.read(calendarStateProvider.notifier);
    final dateStr = _formatDateForApi(_selectedDate);
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    bool success;
    if (_isAllDay) {
      success = await notifier.blockAllDay(date: dateStr, note: note);
    } else {
      success = await notifier.blockTimeRange(
        date: dateStr,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        note: note,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Time blocked successfully' : 'Failed to block time',
          ),
          backgroundColor: success ? DesignColors.success : DesignColors.danger,
          duration: const Duration(seconds: 2),
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
      child: SingleChildScrollView(
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
              'Block Time Off',
              style: DesignTypography.headlineSmall.copyWith(
                color: isDark
                    ? DesignColors.textPrimary
                    : DesignColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: DesignSpacing.xl),

            // Date selector
            _SectionLabel(label: 'Date', isDark: isDark),
            const SizedBox(height: DesignSpacing.sm),
            _DateSelector(
              date: _selectedDate,
              formattedDate: _formatDate(_selectedDate),
              onTap: _selectDate,
              isDark: isDark,
            ),

            const SizedBox(height: DesignSpacing.xl),

            // All day toggle
            _AllDayToggle(
              isAllDay: _isAllDay,
              onChanged: (value) => setState(() => _isAllDay = value),
              isDark: isDark,
            ),

            // Time pickers (only shown if not all day)
            if (!_isAllDay) ...[
              const SizedBox(height: DesignSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _TimePicker(
                      label: 'Start Time',
                      time: _startTime,
                      formattedTime: _formatTime(_startTime),
                      onTap: _selectStartTime,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: DesignSpacing.lg),
                  Expanded(
                    child: _TimePicker(
                      label: 'End Time',
                      time: _endTime,
                      formattedTime: _formatTime(_endTime),
                      onTap: _selectEndTime,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: DesignSpacing.xl),

            // Note field
            _SectionLabel(label: 'Note (optional)', isDark: isDark),
            const SizedBox(height: DesignSpacing.sm),
            TextField(
              controller: _noteController,
              style: DesignTypography.bodyMedium.copyWith(
                color: isDark
                    ? DesignColors.textPrimary
                    : DesignColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g., Dentist appointment',
                hintStyle: DesignTypography.bodyMedium.copyWith(
                  color: isDark
                      ? DesignColors.textMuted
                      : DesignColors.lightTextMuted,
                ),
                filled: true,
                fillColor: isDark
                    ? DesignColors.surfaceElevated
                    : DesignColors.lightBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? DesignColors.borderSubtle
                        : DesignColors.lightBorderSubtle,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? DesignColors.borderSubtle
                        : DesignColors.lightBorderSubtle,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: DesignColors.accent),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignSpacing.md,
                  vertical: DesignSpacing.sm,
                ),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: DesignSpacing.xl),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: DesignSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignRadii.button),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Block This Time'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: DesignTypography.labelMedium.copyWith(
        color: isDark
            ? DesignColors.textSecondary
            : DesignColors.lightTextSecondary,
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final String formattedDate;
  final VoidCallback onTap;
  final bool isDark;

  const _DateSelector({
    required this.date,
    required this.formattedDate,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
              formattedDate,
              style: DesignTypography.bodyLarge.copyWith(
                color: isDark
                    ? DesignColors.textPrimary
                    : DesignColors.lightTextPrimary,
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 18,
              color: isDark
                  ? DesignColors.textMuted
                  : DesignColors.lightTextMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _AllDayToggle extends StatelessWidget {
  final bool isAllDay;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _AllDayToggle({
    required this.isAllDay,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'All Day',
          style: DesignTypography.bodyMedium.copyWith(
            color: isDark
                ? DesignColors.textPrimary
                : DesignColors.lightTextPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: isAllDay,
          onChanged: onChanged,
          activeColor: DesignColors.accent,
        ),
      ],
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final String formattedTime;
  final VoidCallback onTap;
  final bool isDark;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.formattedTime,
    required this.onTap,
    required this.isDark,
  });

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
                  formattedTime,
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

/// Helper function to show the add block sheet
void showAddBlockSheet(BuildContext context, {DateTime? initialDate}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddBlockSheet(initialDate: initialDate),
  );
}
