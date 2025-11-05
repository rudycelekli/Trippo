import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../Container/Repositories/provider_application_repo.dart';
import '../../../../Model/provider_application_model.dart';
import '../../../Routes/routes.dart';

/// Provider Applications Management Screen
/// View and manage all provider applications

class ProviderApplicationsScreen extends ConsumerStatefulWidget {
  const ProviderApplicationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProviderApplicationsScreen> createState() =>
      _ProviderApplicationsScreenState();
}

class _ProviderApplicationsScreenState
    extends ConsumerState<ProviderApplicationsScreen> {
  final ProviderApplicationRepository _repo = ProviderApplicationRepository();
  ApplicationStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Provider Applications'),
        actions: [
          PopupMenuButton<ApplicationStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              setState(() => _filterStatus = status);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Applications'),
              ),
              ...ApplicationStatus.values.map((status) {
                return PopupMenuItem(
                  value: status,
                  child: Text(status.displayName),
                );
              }),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<ProviderApplication>>(
        stream: _repo.streamPendingApplications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading applications: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          var applications = snapshot.data ?? [];

          // Apply filter
          if (_filterStatus != null) {
            applications = applications
                .where((app) => app.status == _filterStatus)
                .toList();
          }

          if (applications.isEmpty) {
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
                    _filterStatus != null
                        ? 'No ${_filterStatus!.displayName.toLowerCase()} applications'
                        : 'No pending applications',
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
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              return _buildApplicationCard(application);
            },
          );
        },
      ),
    );
  }

  Widget _buildApplicationCard(ProviderApplication application) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF2C2C2C)),
      ),
      child: InkWell(
        onTap: () {
          context.pushNamed(
            Routes().adminApplicationDetail,
            extra: application.id,
          );
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
                  // Profile image
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: application.profileImageUrl.isNotEmpty
                        ? NetworkImage(application.profileImageUrl)
                        : null,
                    child: application.profileImageUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application.email,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  _buildStatusBadge(application.status),
                ],
              ),
              const SizedBox(height: 12),

              // Service categories
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: application.requestedCategories.map((category) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      category.displayName,
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 11,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Background check status
              if (application.backgroundCheckStatus !=
                  BackgroundCheckStatus.notStarted)
                _buildBackgroundCheckStatus(application),

              const SizedBox(height: 12),

              // Info row
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Submitted: ${DateFormat('MMM dd, yyyy').format(application.submittedAt)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.description,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${application.licenses.length} licenses',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
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

  Widget _buildStatusBadge(ApplicationStatus status) {
    Color color;
    switch (status) {
      case ApplicationStatus.pending:
        color = Colors.orange;
        break;
      case ApplicationStatus.backgroundCheckInProgress:
      case ApplicationStatus.backgroundCheckComplete:
        color = Colors.blue;
        break;
      case ApplicationStatus.underReview:
        color = Colors.purple;
        break;
      case ApplicationStatus.approved:
        color = Colors.green;
        break;
      case ApplicationStatus.rejected:
        color = Colors.red;
        break;
      case ApplicationStatus.moreInfoRequired:
        color = Colors.amber;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.icon,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCheckStatus(ProviderApplication application) {
    Color statusColor;
    String statusText;

    switch (application.backgroundCheckStatus) {
      case BackgroundCheckStatus.pending:
      case BackgroundCheckStatus.processing:
        statusColor = Colors.blue;
        statusText = '🔍 Background check in progress...';
        break;
      case BackgroundCheckStatus.completed:
        final result = application.backgroundCheckResult;
        if (result == 'clear') {
          statusColor = Colors.green;
          statusText = '✅ Background check: Clear';
        } else if (result == 'consider') {
          statusColor = Colors.orange;
          statusText = '⚠️ Background check: Needs consideration';
        } else {
          statusColor = Colors.red;
          statusText = '❌ Background check: Issues found';
        }
        break;
      case BackgroundCheckStatus.failed:
        statusColor = Colors.red;
        statusText = '❌ Background check failed';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.security, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
