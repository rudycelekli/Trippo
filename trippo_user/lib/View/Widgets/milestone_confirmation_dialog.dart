import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../Model/job_milestone_model.dart';
import '../../Container/Repositories/milestone_repo.dart';
import '../../Container/Repositories/payment_repo.dart';
import '../../Model/quote_model.dart';

/// Milestone Confirmation Dialog
/// Shows when provider marks arrival or completion - user must confirm

class MilestoneConfirmationDialog extends StatefulWidget {
  final JobMilestone milestone;
  final double? paymentAmount; // For house call fee or final payment

  const MilestoneConfirmationDialog({
    super.key,
    required this.milestone,
    this.paymentAmount,
  });

  @override
  State<MilestoneConfirmationDialog> createState() =>
      _MilestoneConfirmationDialogState();
}

class _MilestoneConfirmationDialogState
    extends State<MilestoneConfirmationDialog> {
  bool _isProcessing = false;
  final TextEditingController _disputeReasonController =
      TextEditingController();

  @override
  void dispose() {
    _disputeReasonController.dispose();
    super.dispose();
  }

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
              // Header with Icon
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getMilestoneColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        widget.milestone.type.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.milestone.type.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Please confirm to proceed',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.milestone.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),

              // Image Proof (if provided)
              if (widget.milestone.imageUrl != null) ...[
                const SizedBox(height: 20),
                _buildImageProof(),
              ],

              // Notes (if any)
              if (widget.milestone.notes != null &&
                  widget.milestone.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildNotes(),
              ],

              // Payment Information (if applicable)
              if (widget.paymentAmount != null) ...[
                const SizedBox(height: 20),
                _buildPaymentInfo(),
              ],

              const SizedBox(height: 24),

              // Important Notice
              _buildNotice(),

              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageProof() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.photo_camera, color: Color(0xFF2196F3), size: 20),
            SizedBox(width: 8),
            Text(
              'Photo Proof',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: widget.milestone.imageUrl!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              color: const Color(0xFF2C2C2C),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF2196F3)),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: const Color(0xFF2C2C2C),
              child: const Center(
                child: Icon(Icons.error, color: Colors.red, size: 48),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            // TODO: Show full-screen image viewer
          },
          icon: const Icon(Icons.fullscreen, size: 18),
          label: const Text('View Full Size'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes, color: Colors.grey, size: 18),
              SizedBox(width: 8),
              Text(
                'Provider Notes',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.milestone.notes!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final isHouseCallFee = widget.milestone.type == MilestoneType.arrived;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, color: Color(0xFF4CAF50), size: 20),
              const SizedBox(width: 8),
              Text(
                isHouseCallFee ? 'House Call Fee' : 'Final Payment',
                style: const TextStyle(
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
              Text(
                isHouseCallFee
                    ? 'To be charged upon confirmation'
                    : 'For completed work',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                '\$${widget.paymentAmount!.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isHouseCallFee) ...[
            const SizedBox(height: 8),
            Text(
              'This covers the provider\'s time to assess your issue',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFFC107), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.milestone.type == MilestoneType.arrived
                  ? 'Only confirm if the provider has actually arrived at your location.'
                  : 'Only confirm if you\'re satisfied with the completed work.',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Confirm Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _confirmMilestone,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Dispute Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _showDisputeDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Dispute',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getMilestoneColor() {
    switch (widget.milestone.type) {
      case MilestoneType.arrived:
        return const Color(0xFF2196F3);
      case MilestoneType.started:
        return const Color(0xFFFF9800);
      case MilestoneType.progress:
        return const Color(0xFF9C27B0);
      case MilestoneType.completed:
        return const Color(0xFF4CAF50);
    }
  }

  Future<void> _confirmMilestone() async {
    setState(() => _isProcessing = true);

    try {
      // Confirm milestone
      await MilestoneRepository().confirmMilestone(widget.milestone.id);

      // Process payment if applicable
      if (widget.paymentAmount != null) {
        // TODO: Capture authorized payment
        // For now, we'll create a mock transaction
        print('Payment of \$${widget.paymentAmount} processed');
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true for confirmed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.milestone.type == MilestoneType.arrived
                  ? '✅ Provider arrival confirmed!'
                  : '✅ Job completion confirmed!',
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming milestone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDisputeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Dispute Milestone',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please explain the issue:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _disputeReasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'What\'s wrong?',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            Text(
              'Customer support will review your dispute.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _disputeReasonController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _disputeMilestone();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Submit Dispute'),
          ),
        ],
      ),
    );
  }

  Future<void> _disputeMilestone() async {
    if (_disputeReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for the dispute'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Dispute milestone
      await MilestoneRepository().disputeMilestone(
        milestoneId: widget.milestone.id,
        reason: _disputeReasonController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, false); // Return false for disputed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ Dispute submitted. Support will contact you shortly.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting dispute: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
