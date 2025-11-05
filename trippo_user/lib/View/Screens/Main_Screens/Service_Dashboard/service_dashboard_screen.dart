import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../Model/service_category_model.dart';
import '../../../../Container/Repositories/service_request_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Routes/routes.dart';
import 'package:intl/intl.dart';

/// Service Dashboard
/// Shows all user's service requests: current, scheduled, and past

class ServiceDashboardScreen extends ConsumerStatefulWidget {
  const ServiceDashboardScreen({super.key});

  @override
  ConsumerState<ServiceDashboardScreen> createState() =>
      _ServiceDashboardScreenState();
}

class _ServiceDashboardScreenState
    extends ConsumerState<ServiceDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Services',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2196F3),
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Scheduled'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: StreamBuilder<List<ServiceRequest>>(
        stream: ServiceRequestRepository()
            .getUserServiceRequests(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2196F3)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading services: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final allRequests = snapshot.data ?? [];

          // Filter requests by status
          final activeRequests = allRequests.where((r) =>
              r.status == ServiceRequestStatus.searching ||
              r.status == ServiceRequestStatus.accepted ||
              r.status == ServiceRequestStatus.providerEnRoute ||
              r.status == ServiceRequestStatus.providerArrived ||
              r.status == ServiceRequestStatus.quotePending ||
              r.status == ServiceRequestStatus.quoteAccepted ||
              r.status == ServiceRequestStatus.inProgress).toList();

          final scheduledRequests = allRequests.where((r) =>
              r.status == ServiceRequestStatus.autoScheduled ||
              r.status == ServiceRequestStatus.pending).toList();

          final historyRequests = allRequests.where((r) =>
              r.status == ServiceRequestStatus.completed ||
              r.status == ServiceRequestStatus.cancelled ||
              r.status == ServiceRequestStatus.quoteDeclined).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildServiceList(activeRequests, 'active'),
              _buildServiceList(scheduledRequests, 'scheduled'),
              _buildServiceList(historyRequests, 'history'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServiceList(List<ServiceRequest> requests, String type) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'active'
                  ? Icons.construction
                  : type == 'scheduled'
                      ? Icons.calendar_today
                      : Icons.history,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'active'
                  ? 'No active services'
                  : type == 'scheduled'
                      ? 'No scheduled services'
                      : 'No service history',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildServiceCard(request);
      },
    );
  }

  Widget _buildServiceCard(ServiceRequest request) {
    final canTrack = request.status.canTrackProvider;
    final statusColor = _getStatusColor(request.status);

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showServiceDetails(request);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Service Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        request.category.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Service Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.category.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          request.status.displayName,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Track button (if applicable)
                  if (canTrack)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.pushNamed(Routes().trackingMap,
                            extra: request.id);
                      },
                      icon: const Icon(Icons.location_on, size: 18),
                      label: const Text('Track'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                request.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Details Row
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a')
                        .format(request.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (request.estimatedCost != null)
                    Text(
                      '\$${request.estimatedCost!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              // Provider Info (if assigned)
              if (request.assignedProviderName != null) ...[
                const SizedBox(height: 8),
                const Divider(color: Colors.grey),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[800],
                      child: const Icon(Icons.person,
                          size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      request.assignedProviderName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ServiceRequestStatus status) {
    switch (status) {
      case ServiceRequestStatus.searching:
        return Colors.orange;
      case ServiceRequestStatus.accepted:
      case ServiceRequestStatus.providerEnRoute:
      case ServiceRequestStatus.providerArrived:
        return const Color(0xFF2196F3);
      case ServiceRequestStatus.quotePending:
        return Colors.purple;
      case ServiceRequestStatus.inProgress:
      case ServiceRequestStatus.quoteAccepted:
        return Colors.green;
      case ServiceRequestStatus.completed:
        return const Color(0xFF4CAF50);
      case ServiceRequestStatus.cancelled:
      case ServiceRequestStatus.quoteDeclined:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showServiceDetails(ServiceRequest request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Text(
                  request.category.icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.category.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.status.displayName,
                        style: TextStyle(
                          color: _getStatusColor(request.status),
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
            // Description
            const Text(
              'Description',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              request.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            // Actions
            if (request.status == ServiceRequestStatus.quotePending)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to quote approval screen
                    context.pushNamed(Routes().quoteApproval,
                        extra: request.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Review Quote'),
                ),
              ),
            if (request.status.canTrackProvider)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.pushNamed(Routes().trackingMap, extra: request.id);
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Track Provider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
