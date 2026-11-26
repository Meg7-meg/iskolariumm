import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/class_service.dart';
import '../src/app_colors.dart';

/// Reusable weekly class-session editor for course creation and updates.
/// Each meeting row includes Day of the week, Start time, End time, and
/// a required Location selector (Online, Room Number, or TBA).
/// On smaller screens, fields arrange vertically instead of squeezing into one row.
class ClassScheduleEditor extends StatefulWidget {
  final List<ClassMeetingSchedule> schedules;
  final ValueChanged<List<ClassMeetingSchedule>> onChanged;
  final String? errorText;

  const ClassScheduleEditor({
    super.key,
    required this.schedules,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<ClassScheduleEditor> createState() => _ClassScheduleEditorState();
}

class _ClassScheduleEditorState extends State<ClassScheduleEditor> {
  final List<TextEditingController> _roomControllers = [];
  final List<MeetingLocationType> _locationTypes = [];

  @override
  void initState() {
    super.initState();
    _syncState();
  }

  @override
  void didUpdateWidget(covariant ClassScheduleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncState();
  }

  void _syncState() {
    while (_roomControllers.length < widget.schedules.length) {
      final idx = _roomControllers.length;
      final item = widget.schedules[idx];
      final locType = item.locationType;
      _locationTypes.add(locType);
      _roomControllers.add(
        TextEditingController(
          text: locType == MeetingLocationType.roomNumber ? item.room : '',
        ),
      );
    }
    while (_roomControllers.length > widget.schedules.length) {
      _roomControllers.removeLast().dispose();
      _locationTypes.removeLast();
    }
    for (var i = 0; i < widget.schedules.length; i++) {
      final item = widget.schedules[i];
      final locType = item.locationType;
      _locationTypes[i] = locType;
      if (locType == MeetingLocationType.roomNumber &&
          _roomControllers[i].text != item.room) {
        _roomControllers[i].text = item.room;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _roomControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMeeting() {
    final usedDays = widget.schedules.map((s) => s.dayOfWeek).toSet();
    final nextDay = ClassMeetingSchedule.daysOfWeek.firstWhere(
      (d) => !usedDays.contains(d),
      orElse: () => 'Monday',
    );
    final updated = [
      ...widget.schedules,
      ClassMeetingSchedule(
        dayOfWeek: nextDay,
        startMinutes: 8 * 60,
        endMinutes: 10 * 60,
        room: '',
      ),
    ];
    widget.onChanged(updated);
  }

  void _removeMeeting(int index) {
    _roomControllers[index].dispose();
    _roomControllers.removeAt(index);
    _locationTypes.removeAt(index);
    final updated = List<ClassMeetingSchedule>.from(widget.schedules)
      ..removeAt(index);
    widget.onChanged(updated);
  }

  void _updateMeeting(int index, ClassMeetingSchedule updatedItem) {
    final updated = List<ClassMeetingSchedule>.from(widget.schedules);
    updated[index] = updatedItem;
    widget.onChanged(updated);
  }

  void _onLocationTypeChanged(int index, MeetingLocationType newType) {
    setState(() {
      _locationTypes[index] = newType;
    });
    final item = widget.schedules[index];
    switch (newType) {
      case MeetingLocationType.online:
        _roomControllers[index].clear();
        _updateMeeting(index, item.copyWith(room: 'Online'));
        break;
      case MeetingLocationType.tba:
        _roomControllers[index].clear();
        _updateMeeting(index, item.copyWith(room: 'TBA'));
        break;
      case MeetingLocationType.roomNumber:
        final currentText = _roomControllers[index].text.trim();
        _updateMeeting(index, item.copyWith(room: currentText));
        break;
    }
  }

  Future<void> _pickTime({
    required BuildContext context,
    required int initialMinutes,
    required ValueChanged<int> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialMinutes ~/ 60,
        minute: initialMinutes % 60,
      ),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme
                .copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onPicked(picked.hour * 60 + picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'WEEKLY MEETINGS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addMeeting,
              icon: const Icon(LucideIcons.plus, size: 15),
              label: const Text('Add Meeting'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (widget.schedules.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.errorText != null
                    ? AppColors.danger
                    : AppColors.border,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  LucideIcons.calendarClock,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No sessions yet.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 380;
              return Column(
                children: List.generate(widget.schedules.length, (index) {
                  final item = widget.schedules[index];
                  final locType = _locationTypes[index];
                  final rowError = ClassMeetingSchedule.rowErrorText(
                    widget.schedules,
                    index,
                  );

                  final dayDropdown = DropdownButtonFormField<String>(
                    key: ValueKey('day_${index}_${item.dayOfWeek}'),
                    initialValue: item.dayOfWeek,
                    isExpanded: true,
                    decoration: _inputDecoration(label: 'Day of the week'),
                    items: ClassMeetingSchedule.daysOfWeek
                        .map(
                          (d) => DropdownMenuItem<String>(
                            value: d,
                            child: Text(
                              d,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _updateMeeting(index, item.copyWith(dayOfWeek: value));
                    },
                  );

                  final locationDropdown =
                      DropdownButtonFormField<MeetingLocationType>(
                        key: ValueKey('loc_${index}_${locType.name}'),
                        initialValue: locType,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          label: 'Location',
                          prefixIcon: Icon(
                            locType == MeetingLocationType.online
                                ? LucideIcons.video
                                : locType == MeetingLocationType.tba
                                ? LucideIcons.clock
                                : LucideIcons.mapPin,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        items: MeetingLocationType.values
                            .map(
                              (type) => DropdownMenuItem<MeetingLocationType>(
                                value: type,
                                child: Text(
                                  type.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          _onLocationTypeChanged(index, value);
                        },
                      );

                  final roomField = TextFormField(
                    controller: _roomControllers[index],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    decoration: _inputDecoration(
                      label: 'Room name or number',
                      hint: 'e.g. Room 301, Computer Lab 2',
                      prefixIcon: const Icon(
                        LucideIcons.doorOpen,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    validator: (val) {
                      if (_locationTypes[index] ==
                              MeetingLocationType.roomNumber &&
                          (val == null || val.trim().isEmpty)) {
                        return 'Enter a room name or number';
                      }
                      return null;
                    },
                    onChanged: (val) =>
                        _updateMeeting(index, item.copyWith(room: val)),
                  );

                  final startField = _TimePickerField(
                    label: 'Start time',
                    value: item.formattedStartTime,
                    hasError: rowError != null,
                    onTap: () => _pickTime(
                      context: context,
                      initialMinutes: item.startMinutes,
                      onPicked: (mins) => _updateMeeting(
                        index,
                        item.copyWith(startMinutes: mins),
                      ),
                    ),
                  );

                  final endField = _TimePickerField(
                    label: 'End time',
                    value: item.formattedEndTime,
                    hasError: rowError != null,
                    onTap: () => _pickTime(
                      context: context,
                      initialMinutes: item.endMinutes,
                      onPicked: (mins) => _updateMeeting(
                        index,
                        item.copyWith(endMinutes: mins),
                      ),
                    ),
                  );

                  return Container(
                    margin: EdgeInsets.only(
                      bottom: index == widget.schedules.length - 1 ? 0 : 10,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: rowError != null
                            ? AppColors.danger
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Meeting ${index + 1}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Remove meeting',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () => _removeMeeting(index),
                              icon: const Icon(
                                LucideIcons.trash2,
                                size: 16,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (isNarrow) ...[
                          dayDropdown,
                          const SizedBox(height: 10),
                          startField,
                          const SizedBox(height: 10),
                          endField,
                          const SizedBox(height: 10),
                          locationDropdown,
                          if (locType == MeetingLocationType.roomNumber) ...[
                            const SizedBox(height: 10),
                            roomField,
                          ],
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: dayDropdown),
                              const SizedBox(width: 10),
                              Expanded(flex: 5, child: locationDropdown),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: startField),
                              const SizedBox(width: 10),
                              Expanded(child: endField),
                            ],
                          ),
                          if (locType == MeetingLocationType.roomNumber) ...[
                            const SizedBox(height: 10),
                            roomField,
                          ],
                        ],
                        if (rowError != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.circleAlert,
                                size: 13,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  rowError,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        if (widget.errorText != null && widget.schedules.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final String value;
  final bool hasError;
  final VoidCallback onTap;

  const _TimePickerField({
    required this.label,
    required this.value,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? AppColors.danger : AppColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? AppColors.danger : AppColors.border,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.clock, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
