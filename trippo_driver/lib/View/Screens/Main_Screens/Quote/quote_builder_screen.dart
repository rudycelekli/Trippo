import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../Container/Repositories/provider_service_request_repo.dart';
import '../../../../Model/quote_model.dart';

/// Quote Builder Screen
/// Allows providers to create detailed quotes for service requests

class QuoteBuilderScreen extends ConsumerStatefulWidget {
  final String serviceRequestId;

  const QuoteBuilderScreen({
    Key? key,
    required this.serviceRequestId,
  }) : super(key: key);

  @override
  ConsumerState<QuoteBuilderScreen> createState() => _QuoteBuilderScreenState();
}

class _QuoteBuilderScreenState extends ConsumerState<QuoteBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProviderServiceRequestRepository _repo =
      ProviderServiceRequestRepository();

  // Controllers
  final TextEditingController _houseCallFeeController = TextEditingController();
  final List<LineItemData> _lineItems = [];
  double _taxRate = 0.0875; // 8.75% default tax rate
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _houseCallFeeController.text = '50.00'; // Default house call fee
    _addLineItem(); // Start with one line item
  }

  @override
  void dispose() {
    _houseCallFeeController.dispose();
    for (final item in _lineItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add(LineItemData());
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      final item = _lineItems.removeAt(index);
      item.dispose();
    });
  }

  double get _subtotal {
    double sum = 0;
    for (final item in _lineItems) {
      final qty = double.tryParse(item.quantityController.text) ?? 0;
      final price = double.tryParse(item.priceController.text) ?? 0;
      sum += qty * price;
    }
    return sum;
  }

  double get _houseCallFee {
    return double.tryParse(_houseCallFeeController.text) ?? 0;
  }

  double get _taxAmount {
    return (_subtotal + _houseCallFee) * _taxRate;
  }

  double get _total {
    return _subtotal + _houseCallFee + _taxAmount;
  }

  Future<void> _submitQuote() async {
    if (!_formKey.currentState!.validate()) return;

    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one line item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create quote line items
      final List<QuoteLineItem> items = _lineItems.map((item) {
        final qty = double.parse(item.quantityController.text);
        final price = double.parse(item.priceController.text);
        return QuoteLineItem(
          description: item.descriptionController.text,
          quantity: qty,
          unitPrice: price,
          totalPrice: qty * price,
        );
      }).toList();

      // Create quote
      final quote = ServiceQuote(
        id: '', // Will be set by Firestore
        serviceRequestId: widget.serviceRequestId,
        providerId: '', // Will be set by repository
        houseCallFee: _houseCallFee,
        lineItems: items,
        subtotal: _subtotal,
        taxAmount: _taxAmount,
        totalAmount: _total,
        status: QuoteStatus.pending,
        createdAt: DateTime.now(),
      );

      // Submit quote
      await _repo.submitQuote(quote, widget.serviceRequestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Quote submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting quote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Create Quote'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // House call fee
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2C2C2C)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'House Call Fee',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _houseCallFeeController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.attach_money, color: Colors.grey),
                            hintText: '50.00',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: const Color(0xFF121212),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fee charged when you arrive at the location',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Line items header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Service Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addLineItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Item'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Line items
                  ...List.generate(_lineItems.length, (index) {
                    return _buildLineItem(index);
                  }),

                  const SizedBox(height: 20),

                  // Summary
                  _buildSummary(),
                ],
              ),
            ),

            // Submit button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border(
                  top: BorderSide(color: Colors.grey[800]!),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Quote',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem(int index) {
    final item = _lineItems[index];

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_lineItems.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeLineItem(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          TextFormField(
            controller: item.descriptionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'e.g., Replace kitchen faucet',
              labelStyle: const TextStyle(color: Colors.grey),
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: const Color(0xFF121212),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Description required';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Quantity and Price
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.quantityController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    hintText: '1',
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF121212),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: item.priceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Unit Price',
                    hintText: '0.00',
                    prefixText: '\$ ',
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: const Color(0xFF121212),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),

          // Total for this line item
          if (item.quantityController.text.isNotEmpty &&
              item.priceController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: \$${((double.tryParse(item.quantityController.text) ?? 0) * (double.tryParse(item.priceController.text) ?? 0)).toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.green[300],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('House Call Fee', _houseCallFee),
          const SizedBox(height: 8),
          _buildSummaryRow('Subtotal', _subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('Tax (${(_taxRate * 100).toStringAsFixed(2)}%)', _taxAmount),
          const Divider(color: Color(0xFF2C2C2C), height: 24),
          _buildSummaryRow('Total', _total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : Colors.grey[400],
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isTotal ? Colors.green[300] : Colors.white,
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Helper class to manage line item controllers
class LineItemData {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  LineItemData() {
    quantityController.text = '1';
  }

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}
