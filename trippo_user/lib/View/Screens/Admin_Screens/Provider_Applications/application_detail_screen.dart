import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../Container/Repositories/provider_application_repo.dart';
import '../../../../Container/Repositories/user_repo.dart';
import '../../../../Model/provider_application_model.dart';

/// Application Detail Screen
/// View full application details and approve/reject

class ApplicationDetailScreen extends ConsumerStatefulWidget {
  final String applicationId;

  const ApplicationDetailScreen({
    Key? key,
    required this.applicationId,
  }) : super(key: key);

  @override
  ConsumerState<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState
    extends ConsumerState<ApplicationDetailScreen> {
  final ProviderApplicationRepository _repo = ProviderApplicationRepository();
  final UserRepository _userRepo = UserRepository();

  ProviderApplication? _application;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    setState(() => _isLoading = true);

    final app = await _repo.getApplication(widget.applicationId);

    setState(() {
      _application = app;
      _isLoading = false;
    });
  }

  Future<void> _approveApplication() async {
    if (_application == null) return;

    final confirmed = await _showConfirmDialog(
      'Approve Application',
      'Are you sure you want to approve this application? A provider account will be created.',
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      final currentUser = await _userRepo.getCurrentUser();
      if (currentUser == null) throw Exception('User not logged in');

      await _repo.approveApplication(
        applicationId: widget.applicationId,
        adminId: currentUser.id,
        adminName: currentUser.name,
        note: 'Application approved - all checks passed',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Application approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectApplication() async {
    if (_application == null) return;

    final reason = await _showRejectDialog();
    if (reason == null) return;

    setState(() => _isProcessing = true);

    try {
      final currentUser = await _userRepo.getCurrentUser();
      if (currentUser == null) throw Exception('User not logged in');

      await _repo.rejectApplication(
        applicationId: widget.applicationId,
        adminId: currentUser.id,
        adminName: currentUser.name,
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Application rejected'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _verifyLicense(int licenseIndex) async {
    if (_application == null) return;

    setState(() => _isProcessing = true);

    try {
      final currentUser = await _userRepo.getCurrentUser();
      if (currentUser == null) throw Exception('User not logged in');

      await _repo.updateLicenseStatus(
        applicationId: widget.applicationId,
        licenseIndex: licenseIndex,
        status: LicenseVerificationStatus.verified,
        adminId: currentUser.id,
      );

      await _loadApplication();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ License verified'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying license: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_application == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Application Not Found'),
        ),
        body: const Center(
          child: Text(
            'Application not found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Application Details'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildApplicantInfo(),
                const SizedBox(height: 20),
                _buildBackgroundCheckSection(),
                const SizedBox(height: 20),
                _buildLicensesSection(),
                const SizedBox(height: 20),
                _buildCertificationsSection(),
                const SizedBox(height: 100), // Space for action buttons
              ],
            ),
          ),

          // Action buttons
          if (_application!.status != ApplicationStatus.approved &&
              _application!.status != ApplicationStatus.rejected)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildActionButtons(),
            ),
        ],
      ),
    );
  }

  Widget _buildApplicantInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        children: [
          // Profile image
          CircleAvatar(
            radius: 50,
            backgroundImage: _application!.profileImageUrl.isNotEmpty
                ? CachedNetworkImageProvider(_application!.profileImageUrl)
                : null,
            child: _application!.profileImageUrl.isEmpty
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _application!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Email & Phone
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                _application!.email,
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                _application!.phoneNumber,
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bio
          if (_application!.bio.isNotEmpty) ...[
            const Divider(color: Color(0xFF2C2C2C)),
            const SizedBox(height: 16),
            Text(
              _application!.bio,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2C2C2C)),
          const SizedBox(height: 16),

          // Service categories
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _application!.requestedCategories.map((category) {
              return Chip(
                label: Text(category.displayName),
                backgroundColor: Colors.blue.withOpacity(0.1),
                side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                labelStyle: const TextStyle(color: Colors.blue),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCheckSection() {
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
            'Background Check',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Status',
            _application!.backgroundCheckStatus.displayName,
            icon: Icons.security,
          ),
          if (_application!.backgroundCheckResult != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Result',
              _application!.backgroundCheckResult!.toUpperCase(),
              icon: Icons.check_circle,
              valueColor: _application!.backgroundCheckResult == 'clear'
                  ? Colors.green
                  : Colors.orange,
            ),
          ],
          if (_application!.backgroundCheckCompletedAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Completed',
              DateFormat('MMM dd, yyyy HH:mm')
                  .format(_application!.backgroundCheckCompletedAt!),
              icon: Icons.calendar_today,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLicensesSection() {
    if (_application!.licenses.isEmpty) {
      return const SizedBox.shrink();
    }

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
            'Licenses',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_application!.licenses.length, (index) {
            final license = _application!.licenses[index];
            return _buildLicenseCard(license, index);
          }),
        ],
      ),
    );
  }

  Widget _buildLicenseCard(LicenseDocument license, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  license.type,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildLicenseStatusBadge(license.verificationStatus),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('License Number', license.number, icon: Icons.badge),
          const SizedBox(height: 8),
          _buildInfoRow('State', license.issuingState, icon: Icons.location_on),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Expires',
            DateFormat('MMM dd, yyyy').format(license.expirationDate),
            icon: Icons.event,
            valueColor: license.isExpired
                ? Colors.red
                : license.isExpiringSoon
                    ? Colors.orange
                    : null,
          ),
          const SizedBox(height: 12),
          if (license.documentUrl.isNotEmpty) ...[
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Open document URL
              },
              icon: const Icon(Icons.file_present, size: 18),
              label: const Text('View Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.1),
                foregroundColor: Colors.blue,
                elevation: 0,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (license.verificationStatus == LicenseVerificationStatus.pending)
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _verifyLicense(index),
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Verify License'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.1),
                foregroundColor: Colors.green,
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLicenseStatusBadge(LicenseVerificationStatus status) {
    Color color;
    switch (status) {
      case LicenseVerificationStatus.pending:
        color = Colors.orange;
        break;
      case LicenseVerificationStatus.verified:
        color = Colors.green;
        break;
      case LicenseVerificationStatus.rejected:
        color = Colors.red;
        break;
      case LicenseVerificationStatus.expired:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCertificationsSection() {
    if (_application!.certificationUrls.isEmpty) {
      return const SizedBox.shrink();
    }

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
            'Certifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_application!.certificationUrls.length, (index) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified, color: Colors.green),
              title: Text(
                'Certification ${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.open_in_new, color: Colors.blue),
              onTap: () {
                // TODO: Open certification URL
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _rejectApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _approveApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.1),
                foregroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Approve'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
        ],
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    String? selectedReason;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Reject Application',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Reason'),
              items: const [
                DropdownMenuItem(
                  value: 'Incomplete documentation',
                  child: Text('Incomplete documentation'),
                ),
                DropdownMenuItem(
                  value: 'Failed background check',
                  child: Text('Failed background check'),
                ),
                DropdownMenuItem(
                  value: 'Invalid licenses',
                  child: Text('Invalid licenses'),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Text('Other'),
                ),
              ],
              onChanged: (value) => selectedReason = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Additional notes',
                hintText: 'Enter additional details...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = selectedReason ?? controller.text;
              if (reason.isNotEmpty) {
                Navigator.pop(context, reason);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    return result;
  }
}
