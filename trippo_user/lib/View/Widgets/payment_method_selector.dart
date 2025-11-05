import 'package:flutter/material.dart';
import '../../Model/quote_model.dart';

/// Payment Method Selector Widget
/// Allows users to choose how they want to pay

class PaymentMethodSelector extends StatefulWidget {
  final Function(PaymentMethod) onMethodSelected;
  final PaymentMethod? selectedMethod;

  const PaymentMethodSelector({
    super.key,
    required this.onMethodSelected,
    this.selectedMethod,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  late PaymentMethod _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedMethod ?? PaymentMethod.stripe;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildPaymentOption(
          method: PaymentMethod.stripe,
          title: 'Credit/Debit Card',
          subtitle: 'Visa, Mastercard, Amex',
          icon: Icons.credit_card,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          method: PaymentMethod.paypal,
          title: 'PayPal',
          subtitle: 'Pay with your PayPal account',
          icon: Icons.account_balance_wallet,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          method: PaymentMethod.applePay,
          title: 'Apple Pay',
          subtitle: 'Pay with Apple Pay',
          icon: Icons.apple,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          method: PaymentMethod.googlePay,
          title: 'Google Pay',
          subtitle: 'Pay with Google Pay',
          icon: Icons.phone_android,
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selected == method;

    return InkWell(
      onTap: () {
        setState(() => _selected = method);
        widget.onMethodSelected(method);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2196F3).withOpacity(0.2)
              : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2196F3)
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF2196F3) : Colors.white,
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
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2196F3),
                size: 28,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: Colors.grey[700],
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}

/// Payment Method Selection Dialog
void showPaymentMethodDialog({
  required BuildContext context,
  required Function(PaymentMethod) onMethodSelected,
  PaymentMethod? currentMethod,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Payment Method',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PaymentMethodSelector(
              selectedMethod: currentMethod,
              onMethodSelected: (method) {
                Navigator.pop(context);
                onMethodSelected(method);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
