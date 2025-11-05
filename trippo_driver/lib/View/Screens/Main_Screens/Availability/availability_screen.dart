import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Availability Screen
/// Manage provider working hours and schedule

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AvailabilityScreen> createState() =>
      _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  final Map<String, DayAvailability> _schedule = {
    'Monday': DayAvailability(day: 'Monday', isEnabled: true),
    'Tuesday': DayAvailability(day: 'Tuesday', isEnabled: true),
    'Wednesday': DayAvailability(day: 'Wednesday', isEnabled: true),
    'Thursday': DayAvailability(day: 'Thursday', isEnabled: true),
    'Friday': DayAvailability(day: 'Friday', isEnabled: true),
    'Saturday': DayAvailability(day: 'Saturday', isEnabled: false),
    'Sunday': DayAvailability(day: 'Sunday', isEnabled: false),
  };

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Availability Schedule'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveSchedule,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save, color: Colors.blue),
            label: const Text(
              'Save',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 24),
          ..._schedule.entries.map((entry) => _buildDayCard(entry.value)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade700),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Set your weekly availability. You will only receive job requests during these hours.',
              style: TextStyle(
                color: Colors.blue.shade100,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _enableAllDays,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Enable All'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _disableWeekends,
            icon: const Icon(Icons.weekend_outlined, size: 18),
            label: const Text('Weekdays Only'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(DayAvailability day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: day.isEnabled ? Colors.green.shade700 : const Color(0xFF2C2C2C),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  day.day,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: day.isEnabled,
                onChanged: (value) {
                  setState(() {
                    _schedule[day.day]!.isEnabled = value;
                  });
                },
                activeColor: Colors.green,
              ),
            ],
          ),
          if (day.isEnabled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    'Start Time',
                    day.startTime,
                    (time) {
                      setState(() {
                        _schedule[day.day]!.startTime = time;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeSelector(
                    'End Time',
                    day.endTime,
                    (time) {
                      setState(() {
                        _schedule[day.day]!.endTime = time;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  '${_calculateHours(day)} hours',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Not available on this day',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelector(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.blue,
                  surface: Color(0xFF1E1E1E),
                ),
              ),
              child: child!,
            );
          },
        );
        if (newTime != null) {
          onChanged(newTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time.format(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.schedule, color: Colors.blue, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _calculateHours(DayAvailability day) {
    final start = day.startTime.hour + day.startTime.minute / 60;
    final end = day.endTime.hour + day.endTime.minute / 60;
    final hours = end - start;
    return hours.toStringAsFixed(1);
  }

  void _enableAllDays() {
    setState(() {
      for (final day in _schedule.values) {
        day.isEnabled = true;
      }
    });
  }

  void _disableWeekends() {
    setState(() {
      for (final entry in _schedule.entries) {
        if (entry.key == 'Saturday' || entry.key == 'Sunday') {
          entry.value.isEnabled = false;
        } else {
          entry.value.isEnabled = true;
        }
      }
    });
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);

    // TODO: Save schedule to Firestore
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Availability schedule saved'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}

class DayAvailability {
  final String day;
  bool isEnabled;
  TimeOfDay startTime;
  TimeOfDay endTime;

  DayAvailability({
    required this.day,
    this.isEnabled = false,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  })  : startTime = startTime ?? const TimeOfDay(hour: 9, minute: 0),
        endTime = endTime ?? const TimeOfDay(hour: 17, minute: 0);
}
