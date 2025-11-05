import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../Model/service_category_model.dart';
import '../../../services/ai_providers/ai_provider_interface.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Container/Repositories/service_request_repo.dart';
import 'package:geolocator/geolocator.dart';

/// Service Request Action Dialog
/// Shows when AI detects a service need - user chooses on-demand or scheduled

class ServiceRequestDialog extends ConsumerStatefulWidget {
  final ServiceCategoryDetection detection;
  final List<String> imageUrls;
  final String userMessage;

  const ServiceRequestDialog({
    super.key,
    required this.detection,
    required this.imageUrls,
    required this.userMessage,
  });

  @override
  ConsumerState<ServiceRequestDialog> createState() =>
      _ServiceRequestDialogState();
}

class _ServiceRequestDialogState extends ConsumerState<ServiceRequestDialog> {
  ServiceUrgency _selectedUrgency = ServiceUrgency.onDemand;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        widget.detection.category.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.detection.category.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Confidence: ${(widget.detection.confidence * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // AI Reasoning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Color(0xFFFFC107), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.detection.reasoning,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Service Description
              const Text(
                'Your Request',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.userMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // Urgency Selection
              const Text(
                'When do you need this?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // On-Demand Option
              _buildUrgencyOption(
                urgency: ServiceUrgency.onDemand,
                icon: Icons.flash_on,
                title: 'On-Demand (ASAP)',
                subtitle: 'Get a provider as soon as possible',
                color: const Color(0xFFFF9800),
              ),
              const SizedBox(height: 12),

              // Scheduled Option
              _buildUrgencyOption(
                urgency: ServiceUrgency.scheduled,
                icon: Icons.calendar_today,
                title: 'Schedule for Later',
                subtitle: 'Choose a specific date and time',
                color: const Color(0xFF2196F3),
              ),

              // Date/Time Picker (if scheduled)
              if (_selectedUrgency == ServiceUrgency.scheduled) ...[
                const SizedBox(height: 16),
                _buildDateTimePicker(),
              ],

              const SizedBox(height: 24),

              // Estimated Cost
              _buildCostEstimate(),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createServiceRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Find Provider',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Widget _buildUrgencyOption({
    required ServiceUrgency urgency,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedUrgency == urgency;

    return InkWell(
      onTap: () => setState(() => _selectedUrgency = urgency),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? color : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24)
            else
              Icon(Icons.circle_outlined, color: Colors.grey[700], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Date Picker
          InkWell(
            onTap: _pickDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Color(0xFF2196F3), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _scheduledDate == null
                        ? 'Select Date'
                        : DateFormat('MMM dd, yyyy').format(_scheduledDate!),
                    style: TextStyle(
                      color:
                          _scheduledDate == null ? Colors.grey : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.grey, size: 16),
              ],
            ),
          ),
          const Divider(color: Colors.grey),
          // Time Picker
          InkWell(
            onTap: _pickTime,
            child: Row(
              children: [
                const Icon(Icons.access_time,
                    color: Color(0xFF2196F3), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _scheduledTime == null
                        ? 'Select Time'
                        : _scheduledTime!.format(context),
                    style: TextStyle(
                      color:
                          _scheduledTime == null ? Colors.grey : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.grey, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostEstimate() {
    final hourlyRate = widget.detection.category.defaultHourlyRate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_money,
                  color: Color(0xFF4CAF50), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Estimated Cost',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hourly Rate',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                '\$${hourlyRate.toStringAsFixed(2)}/hr',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Final cost will be determined after inspection',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
  }

  Future<void> _createServiceRequest() async {
    // Validate scheduled date/time if needed
    if (_selectedUrgency == ServiceUrgency.scheduled) {
      if (_scheduledDate == null || _scheduledTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both date and time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isCreating = true);

    try {
      // Get user location
      final position = await Geolocator.getCurrentPosition();

      // Get user info
      final user = FirebaseAuth.instance.currentUser!;

      // Create scheduled datetime if applicable
      DateTime? preferredDateTime;
      if (_selectedUrgency == ServiceUrgency.scheduled &&
          _scheduledDate != null &&
          _scheduledTime != null) {
        preferredDateTime = DateTime(
          _scheduledDate!.year,
          _scheduledDate!.month,
          _scheduledDate!.day,
          _scheduledTime!.hour,
          _scheduledTime!.minute,
        );
      }

      // Create service request
      final request = ServiceRequest(
        id: '',
        userId: user.uid,
        userName: user.displayName ?? 'User',
        userEmail: user.email ?? '',
        category: widget.detection.category,
        description: widget.userMessage,
        imageUrls: widget.imageUrls,
        urgency: _selectedUrgency,
        preferredDateTime: preferredDateTime,
        status: ServiceRequestStatus.searching,
        createdAt: DateTime.now(),
        userAddress: 'Loading address...', // TODO: Reverse geocode
        userLatitude: position.latitude,
        userLongitude: position.longitude,
      );

      // Save to Firestore
      final requestId =
          await ServiceRequestRepository().createServiceRequest(request);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedUrgency == ServiceUrgency.onDemand
                  ? '🔍 Searching for providers nearby...'
                  : '📅 Request scheduled successfully!',
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
