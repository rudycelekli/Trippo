import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../Container/Repositories/provider_service_request_repo.dart';
import '../../../../Model/service_category_model.dart';
import '../../../../Model/job_milestone_model.dart';
import '../../../Routes/routes.dart';

/// Active Job Screen
/// Manage active job with milestone tracking

class ActiveJobScreen extends ConsumerStatefulWidget {
  final String serviceRequestId;

  const ActiveJobScreen({
    Key? key,
    required this.serviceRequestId,
  }) : super(key: key);

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  final ProviderServiceRequestRepository _repo =
      ProviderServiceRequestRepository();
  ServiceRequest? _request;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    final request = await _repo.getRequestById(widget.serviceRequestId);
    setState(() {
      _request = request;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_request == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Job Not Found'),
        ),
        body: const Center(
          child: Text(
            'Job not found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(_request!.category.displayName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildJobInfo(),
          const SizedBox(height: 16),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            _getStatusIcon(_request!.status),
            size: 64,
            color: _getStatusColor(_request!.status),
          ),
          const SizedBox(height: 16),
          Text(
            _request!.status.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusDescription(_request!.status),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.category, 'Category', _request!.category.displayName),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'Location', _request!.address),
          const SizedBox(height: 12),
          if (_request!.description.isNotEmpty) ...[
            _buildInfoRow(Icons.description, 'Description', _request!.description),
            const SizedBox(height: 12),
          ],
          _buildInfoRow(
            Icons.access_time,
            'Time',
            _request!.urgency == ServiceUrgency.onDemand
                ? 'On-Demand (ASAP)'
                : 'Scheduled',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        if (_request!.status == ServiceRequestStatus.accepted)
          _buildActionButton(
            'Mark En Route',
            Icons.navigation,
            Colors.blue,
            () => _markEnRoute(),
          ),
        if (_request!.status == ServiceRequestStatus.providerEnRoute)
          _buildActionButton(
            'Mark Arrived',
            Icons.location_on,
            Colors.purple,
            () => _markArrived(),
          ),
        if (_request!.status == ServiceRequestStatus.providerArrived)
          _buildActionButton(
            'Create Quote',
            Icons.receipt,
            Colors.orange,
            () => _navigateToQuoteBuilder(),
          ),
        if (_request!.status == ServiceRequestStatus.quoteAccepted)
          _buildActionButton(
            'Start Job',
            Icons.play_arrow,
            Colors.green,
            () => _startJob(),
          ),
        if (_request!.status == ServiceRequestStatus.inProgress)
          _buildActionButton(
            'Mark Completed',
            Icons.check_circle,
            Colors.green,
            () => _completeJob(),
          ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _markEnRoute() async {
    setState(() => _isProcessing = true);
    try {
      await _repo.markEnRoute(widget.serviceRequestId);
      await _loadRequest();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Marked as en route'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error updating status: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _markArrived() async {
    setState(() => _isProcessing = true);
    try {
      // Submit arrival milestone
      final milestone = JobMilestone(
        id: '',
        serviceRequestId: widget.serviceRequestId,
        type: MilestoneType.arrived,
        description: 'Provider arrived at location',
        status: MilestoneStatus.pending,
        createdAt: DateTime.now(),
      );

      await _repo.submitMilestone(milestone, widget.serviceRequestId);
      await _repo.markArrived(widget.serviceRequestId);
      await _loadRequest();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Arrival confirmed - waiting for customer confirmation'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error marking arrival: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _navigateToQuoteBuilder() async {
    context.pushNamed(
      Routes().quoteBuilder,
      extra: widget.serviceRequestId,
    );
  }

  Future<void> _startJob() async {
    setState(() => _isProcessing = true);
    try {
      // Submit started milestone
      final milestone = JobMilestone(
        id: '',
        serviceRequestId: widget.serviceRequestId,
        type: MilestoneType.started,
        description: 'Work started',
        status: MilestoneStatus.confirmed,
        createdAt: DateTime.now(),
      );

      await _repo.submitMilestone(milestone, widget.serviceRequestId);
      await _repo.startJob(widget.serviceRequestId);
      await _loadRequest();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Job started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error starting job: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _completeJob() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Complete Job',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure the job is completed? This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      // Submit completion milestone
      final milestone = JobMilestone(
        id: '',
        serviceRequestId: widget.serviceRequestId,
        type: MilestoneType.completed,
        description: 'Job completed',
        status: MilestoneStatus.pending,
        createdAt: DateTime.now(),
      );

      await _repo.submitMilestone(milestone, widget.serviceRequestId);
      await _repo.completeJob(widget.serviceRequestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Job marked as completed!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error completing job: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getStatusIcon(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.accepted:
        return Icons.check_circle;
      case ServiceRequestStatus.providerEnRoute:
        return Icons.navigation;
      case ServiceRequestStatus.providerArrived:
        return Icons.location_on;
      case ServiceRequestStatus.quotePending:
      case ServiceRequestStatus.quoteAccepted:
        return Icons.receipt;
      case ServiceRequestStatus.inProgress:
        return Icons.build;
      case ServiceRequestStatus.completed:
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.accepted:
        return Colors.blue;
      case ServiceRequestStatus.providerEnRoute:
        return Colors.orange;
      case ServiceRequestStatus.providerArrived:
        return Colors.purple;
      case ServiceRequestStatus.quotePending:
        return Colors.amber;
      case ServiceRequestStatus.quoteAccepted:
        return Colors.green;
      case ServiceRequestStatus.inProgress:
        return Colors.teal;
      case ServiceRequestStatus.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDescription(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.accepted:
        return 'You have accepted this job. Mark yourself en route when ready.';
      case ServiceRequestStatus.providerEnRoute:
        return 'You are on your way. Mark arrived when you reach the location.';
      case ServiceRequestStatus.providerArrived:
        return 'You have arrived. Create a quote for the customer.';
      case ServiceRequestStatus.quotePending:
        return 'Waiting for customer to review your quote.';
      case ServiceRequestStatus.quoteAccepted:
        return 'Quote accepted! You can start the job now.';
      case ServiceRequestStatus.inProgress:
        return 'Job in progress. Mark as completed when done.';
      case ServiceRequestStatus.completed:
        return 'Job completed successfully!';
      default:
        return '';
    }
  }
}
