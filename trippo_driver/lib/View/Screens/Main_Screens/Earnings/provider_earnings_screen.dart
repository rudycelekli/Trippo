import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../Container/Repositories/provider_service_request_repo.dart';
import '../../../../Model/service_category_model.dart';
import '../../../../Model/quote_model.dart';

/// Provider Earnings Screen
/// Display earnings summary and completed job history

class ProviderEarningsScreen extends ConsumerStatefulWidget {
  const ProviderEarningsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProviderEarningsScreen> createState() =>
      _ProviderEarningsScreenState();
}

class _ProviderEarningsScreenState
    extends ConsumerState<ProviderEarningsScreen> {
  final ProviderServiceRequestRepository _repo =
      ProviderServiceRequestRepository();
  Map<String, dynamic> _earningsSummary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    final summary = await _repo.getEarningsSummary();
    setState(() {
      _earningsSummary = summary;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('My Earnings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEarnings,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildEarningsSummary(),
                  const SizedBox(height: 24),
                  _buildCompletedJobsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildEarningsSummary() {
    final totalEarnings = _earningsSummary['totalEarnings'] ?? 0.0;
    final totalTips = _earningsSummary['totalTips'] ?? 0.0;
    final jobCount = _earningsSummary['jobCount'] ?? 0;
    final averageEarning = _earningsSummary['averageEarning'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earnings Summary',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'Total Earnings',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${totalEarnings.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Jobs Completed',
                jobCount.toString(),
                Icons.check_circle,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Average Earning',
                '\$${averageEarning.toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Tips',
                '\$${totalTips.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Success Rate',
                '100%',
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedJobsList() {
    return StreamBuilder<List<ServiceRequest>>(
      stream: _repo.streamMyCompletedRequests(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading jobs: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final jobs = snapshot.data ?? [];

        if (jobs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(Icons.work_off, size: 64, color: Colors.grey[700]),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completed Jobs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...jobs.map((job) => _buildCompletedJobCard(job)),
          ],
        );
      },
    );
  }

  Widget _buildCompletedJobCard(ServiceRequest job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(job.category),
                  size: 24,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.category.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(job.completedAt ?? job.createdAt),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              FutureBuilder<String>(
                future: _getJobEarning(job.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return Text(
                    snapshot.data ?? '\$0.00',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.address,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (job.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              job.description,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Future<String> _getJobEarning(String serviceRequestId) async {
    try {
      final request = await _repo.getRequestById(serviceRequestId);
      if (request == null || request.quoteId == null) {
        return '\$0.00';
      }

      // Fetch quote to get the total amount
      final quoteDoc = await FirebaseFirestore.instance
          .collection('quotes')
          .doc(request.quoteId)
          .get();

      if (!quoteDoc.exists || quoteDoc.data() == null) {
        return '\$0.00';
      }

      final quote = ServiceQuote.fromFirestore(quoteDoc.data()!, quoteDoc.id);
      return '\$${quote.totalAmount.toStringAsFixed(2)}';
    } catch (e) {
      return '\$0.00';
    }
  }

  IconData _getCategoryIcon(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.plumbing:
        return Icons.plumbing;
      case ServiceCategory.electrical:
        return Icons.electrical_services;
      case ServiceCategory.hvac:
        return Icons.ac_unit;
      case ServiceCategory.cleaning:
        return Icons.cleaning_services;
      case ServiceCategory.landscaping:
        return Icons.grass;
      case ServiceCategory.painting:
        return Icons.format_paint;
      case ServiceCategory.carpentry:
        return Icons.handyman;
      case ServiceCategory.appliance:
        return Icons.kitchen;
      case ServiceCategory.roofing:
        return Icons.roofing;
      case ServiceCategory.locksmith:
        return Icons.lock;
      case ServiceCategory.pestControl:
        return Icons.bug_report;
      default:
        return Icons.build;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
