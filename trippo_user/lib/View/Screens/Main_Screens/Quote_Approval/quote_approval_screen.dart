import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../Model/quote_model.dart';
import '../../../../Container/Repositories/quote_repo.dart';
import '../../../../Container/Repositories/payment_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Quote Approval Screen
/// User reviews line-by-line quote from provider and accepts or declines

class QuoteApprovalScreen extends ConsumerStatefulWidget {
  final String serviceRequestId;

  const QuoteApprovalScreen({super.key, required this.serviceRequestId});

  @override
  ConsumerState<QuoteApprovalScreen> createState() =>
      _QuoteApprovalScreenState();
}

class _QuoteApprovalScreenState extends ConsumerState<QuoteApprovalScreen> {
  bool _isProcessing = false;
  final TextEditingController _declineReasonController =
      TextEditingController();

  @override
  void dispose() {
    _declineReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Review Quote',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<ServiceQuote?>(
        stream: QuoteRepository().streamPendingQuote(widget.serviceRequestId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2196F3)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading quote: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final quote = snapshot.data;

          if (quote == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No quote found',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return _buildQuoteDetails(quote);
        },
      ),
    );
  }

  Widget _buildQuoteDetails(ServiceQuote quote) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Info Card
          _buildProviderCard(quote),
          const SizedBox(height: 20),

          // House Call Fee Section
          _buildHouseCallFeeSection(quote),
          const SizedBox(height: 20),

          // Line Items Section
          _buildLineItemsSection(quote),
          const SizedBox(height: 20),

          // Cost Breakdown
          _buildCostBreakdown(quote),
          const SizedBox(height: 20),

          // Notes (if any)
          if (quote.notes.isNotEmpty) ...[
            _buildNotesSection(quote),
            const SizedBox(height: 20),
          ],

          // Important Notice
          _buildNotice(),
          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(quote),
        ],
      ),
    );
  }

  Widget _buildProviderCard(ServiceQuote quote) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF2196F3),
              child: Text(
                quote.providerName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote.providerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                      SizedBox(width: 4),
                      Text(
                        '4.8 (127 reviews)',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Verified Professional',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseCallFeeSection(ServiceQuote quote) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.home_outlined,
                    color: Color(0xFF2196F3), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'House Call Fee',
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
                const Expanded(
                  child: Text(
                    'For coming to your location and assessing the issue',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                Text(
                  '\$${quote.houseCallFee.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFFFFC107), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This fee is charged even if you decline the quote',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemsSection(ServiceQuote quote) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long,
                    color: Color(0xFF4CAF50), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Job Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...quote.lineItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == quote.lineItems.length - 1;

              return Column(
                children: [
                  _buildLineItem(item),
                  if (!isLast)
                    const Divider(color: Colors.grey, height: 24),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem(QuoteLineItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Qty: ${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '\$${item.totalPrice.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCostBreakdown(ServiceQuote quote) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCostRow('Subtotal', quote.subtotal, false),
            const SizedBox(height: 12),
            _buildCostRow('Tax', quote.taxAmount, false),
            const Divider(color: Colors.grey, height: 24),
            _buildCostRow('Total', quote.totalAmount, true),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, double amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.grey,
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isTotal ? const Color(0xFF4CAF50) : Colors.white,
            fontSize: isTotal ? 22 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(ServiceQuote quote) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Provider Notes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              quote.notes,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC107), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFFC107), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'By accepting this quote, you agree to the estimated cost. Payment will be processed upon job completion.',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ServiceQuote quote) {
    return Column(
      children: [
        // Accept Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : () => _acceptQuote(quote),
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
                    'Accept Quote & Proceed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Decline Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isProcessing ? null : () => _showDeclineDialog(quote),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Decline Quote',
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

  Future<void> _acceptQuote(ServiceQuote quote) async {
    setState(() => _isProcessing = true);

    try {
      // Accept the quote
      await QuoteRepository().acceptQuote(
        quoteId: quote.id,
        serviceRequestId: widget.serviceRequestId,
      );

      // TODO: Navigate to payment method selection
      // For now, just show success

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Quote accepted! Job will start soon.'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting quote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeclineDialog(ServiceQuote quote) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Decline Quote?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You will still be charged the house call fee.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _declineReasonController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Reason for declining (optional)',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _declineReasonController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _declineQuote(quote);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  Future<void> _declineQuote(ServiceQuote quote) async {
    setState(() => _isProcessing = true);

    try {
      // Decline the quote
      await QuoteRepository().declineQuote(
        quoteId: quote.id,
        serviceRequestId: widget.serviceRequestId,
        reason: _declineReasonController.text.trim(),
      );

      // Charge house call fee
      final user = FirebaseAuth.instance.currentUser!;
      await PaymentRepository().processPayment(
        serviceRequestId: widget.serviceRequestId,
        userId: user.uid,
        providerId: quote.providerId,
        type: PaymentType.houseCallFee,
        amount: quote.houseCallFee,
        method: PaymentMethod.stripe, // TODO: Let user choose
        transactionId: 'mock_txn_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quote declined. House call fee of \$${quote.houseCallFee.toStringAsFixed(2)} charged.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining quote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
