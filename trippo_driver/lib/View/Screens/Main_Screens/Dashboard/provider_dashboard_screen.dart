import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../Container/Repositories/provider_service_request_repo.dart';
import '../../../../Model/service_category_model.dart';
import '../../../Routes/routes.dart';

/// Provider Dashboard Screen
/// Shows available jobs and active jobs for the provider

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState
    extends ConsumerState<ProviderDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProviderServiceRequestRepository _repo =
      ProviderServiceRequestRepository();

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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Homzy Provider'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              context.pushNamed(Routes().providerEarnings);
            },
            tooltip: 'Earnings',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableJobsTab(),
          _buildActiveJobsTab(),
          _buildCompletedJobsTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableJobsTab() {
    // TODO: Get provider location and categories from provider profile
    return StreamBuilder<List<ServiceRequest>>(
      stream: _repo.streamNearbyRequests(
        latitude: 37.7749, // TODO: Get from provider location
        longitude: -122.4194,
        radiusMiles: 15.0, // TODO: Get from provider settings
        providerCategories: [
          ServiceCategory.plumbing,
          ServiceCategory.electrical,
        ], // TODO: Get from provider profile
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading requests: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey[700],
                ),
                const SizedBox(height: 16),
                Text(
                  'No available jobs nearby',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
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
            return _buildJobCard(
              request: request,
              showAcceptButton: true,
            );
          },
        );
      },
    );
  }

  Widget _buildActiveJobsTab() {
    return StreamBuilder<List<ServiceRequest>>(
      stream: _repo.streamMyActiveRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading active jobs: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_off,
                  size: 64,
                  color: Colors.grey[700],
                ),
                const SizedBox(height: 16),
                Text(
                  'No active jobs',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
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
            return _buildJobCard(
              request: request,
              showAcceptButton: false,
              isActive: true,
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedJobsTab() {
    return StreamBuilder<List<ServiceRequest>>(
      stream: _repo.streamMyCompletedRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading completed jobs: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[700],
                ),
                const SizedBox(height: 16),
                Text(
                  'No completed jobs yet',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
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
            return _buildJobCard(
              request: request,
              showAcceptButton: false,
              isCompleted: true,
            );
          },
        );
      },
    );
  }

  Widget _buildJobCard({
    required ServiceRequest request,
    bool showAcceptButton = false,
    bool isActive = false,
    bool isCompleted = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF2C2C2C)),
      ),
      child: InkWell(
        onTap: () {
          if (showAcceptButton) {
            context.pushNamed(
              Routes().jobDetail,
              extra: request.id,
            );
          } else if (isActive) {
            context.pushNamed(
              Routes().activeJob,
              extra: request.id,
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      request.category.icon,
                      color: Colors.blue,
                      size: 24,
                    ),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.urgency == ServiceUrgency.onDemand
                              ? '🔴 On-Demand'
                              : '📅 Scheduled',
                          style: TextStyle(
                            color: request.urgency == ServiceUrgency.onDemand
                                ? Colors.red[300]
                                : Colors.blue[300],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  if (!showAcceptButton)
                    _buildStatusBadge(request.status),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              if (request.description.isNotEmpty) ...[
                Text(
                  request.description,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Info row
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.address,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    request.urgency == ServiceUrgency.onDemand
                        ? 'ASAP'
                        : DateFormat('MMM dd, yyyy HH:mm')
                            .format(request.scheduledFor!),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (request.estimatedCost != null) ...[
                    Icon(
                      Icons.attach_money,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    Text(
                      '\$${request.estimatedCost!.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.green[300],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),

              // Accept button
              if (showAcceptButton) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _acceptJob(request.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Accept Job'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ServiceRequestStatus status) {
    Color color;
    String text;

    switch (status) {
      case ServiceRequestStatus.accepted:
        color = Colors.blue;
        text = 'Accepted';
        break;
      case ServiceRequestStatus.providerEnRoute:
        color = Colors.orange;
        text = 'En Route';
        break;
      case ServiceRequestStatus.providerArrived:
        color = Colors.purple;
        text = 'Arrived';
        break;
      case ServiceRequestStatus.quotePending:
        color = Colors.amber;
        text = 'Quote Pending';
        break;
      case ServiceRequestStatus.quoteAccepted:
        color = Colors.green;
        text = 'Quote Accepted';
        break;
      case ServiceRequestStatus.inProgress:
        color = Colors.teal;
        text = 'In Progress';
        break;
      case ServiceRequestStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      default:
        color = Colors.grey;
        text = status.displayName;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _acceptJob(String requestId) async {
    try {
      await _repo.acceptRequest(requestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Job accepted!'),
            backgroundColor: Colors.green,
          ),
        );

        // Switch to Active tab
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
