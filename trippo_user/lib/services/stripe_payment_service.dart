import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';
import '../Model/quote_model.dart';

/// Stripe Payment Service
/// Handles authorize/capture flow for Homzy payments

class StripePaymentService {
  final Dio _dio = Dio();
  String? _publishableKey;
  String? _serverUrl; // Your backend URL for payment intents

  /// Initialize Stripe with keys
  Future<void> initialize({
    required String publishableKey,
    String? serverUrl,
  }) async {
    _publishableKey = publishableKey;
    _serverUrl = serverUrl ?? 'https://your-backend.com/api';

    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  /// Authorize payment (hold funds, don't capture yet)
  /// Used for house call fee - authorize when provider accepts
  Future<PaymentAuthResult> authorizePayment({
    required double amount,
    required String description,
    required Map<String, String> metadata,
  }) async {
    try {
      // 1. Create Payment Intent on your backend
      final paymentIntentResponse = await _dio.post(
        '$_serverUrl/create-payment-intent',
        data: {
          'amount': (amount * 100).toInt(), // Convert to cents
          'currency': 'usd',
          'description': description,
          'capture_method': 'manual', // Important: Manual capture
          'metadata': metadata,
        },
      );

      final clientSecret = paymentIntentResponse.data['clientSecret'] as String;
      final paymentIntentId = paymentIntentResponse.data['id'] as String;

      // 2. Confirm payment with Stripe SDK
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      return PaymentAuthResult(
        success: true,
        paymentIntentId: paymentIntentId,
        amount: amount,
      );
    } on StripeException catch (e) {
      return PaymentAuthResult(
        success: false,
        error: e.error.localizedMessage ?? 'Payment failed',
      );
    } catch (e) {
      return PaymentAuthResult(
        success: false,
        error: 'Payment error: $e',
      );
    }
  }

  /// Capture authorized payment
  /// Called when user confirms milestone (arrival or completion)
  Future<PaymentCaptureResult> capturePayment({
    required String paymentIntentId,
    double? amount, // Optional: Capture partial amount
  }) async {
    try {
      final response = await _dio.post(
        '$_serverUrl/capture-payment-intent',
        data: {
          'paymentIntentId': paymentIntentId,
          if (amount != null) 'amount': (amount * 100).toInt(),
        },
      );

      return PaymentCaptureResult(
        success: true,
        transactionId: response.data['id'] as String,
        amount: (response.data['amount'] as int) / 100,
      );
    } catch (e) {
      return PaymentCaptureResult(
        success: false,
        error: 'Capture failed: $e',
      );
    }
  }

  /// Cancel authorized payment
  /// Called when user disputes or cancels before capture
  Future<bool> cancelAuthorization(String paymentIntentId) async {
    try {
      await _dio.post(
        '$_serverUrl/cancel-payment-intent',
        data: {'paymentIntentId': paymentIntentId},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Process immediate payment (authorize + capture)
  /// Used when capture_method is 'automatic'
  Future<PaymentResult> processImmediatePayment({
    required double amount,
    required String description,
    required Map<String, String> metadata,
  }) async {
    try {
      // 1. Create Payment Intent (automatic capture)
      final paymentIntentResponse = await _dio.post(
        '$_serverUrl/create-payment-intent',
        data: {
          'amount': (amount * 100).toInt(),
          'currency': 'usd',
          'description': description,
          'capture_method': 'automatic', // Auto-capture
          'metadata': metadata,
        },
      );

      final clientSecret = paymentIntentResponse.data['clientSecret'] as String;
      final paymentIntentId = paymentIntentResponse.data['id'] as String;

      // 2. Confirm payment (will auto-capture)
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      return PaymentResult(
        success: true,
        transactionId: paymentIntentId,
        amount: amount,
      );
    } on StripeException catch (e) {
      return PaymentResult(
        success: false,
        error: e.error.localizedMessage ?? 'Payment failed',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'Payment error: $e',
      );
    }
  }

  /// Present payment sheet (recommended for better UX)
  Future<PaymentResult> presentPaymentSheet({
    required double amount,
    required String description,
    required Map<String, String> metadata,
    bool captureManually = false,
  }) async {
    try {
      // 1. Create Payment Intent
      final paymentIntentResponse = await _dio.post(
        '$_serverUrl/create-payment-intent',
        data: {
          'amount': (amount * 100).toInt(),
          'currency': 'usd',
          'description': description,
          'capture_method': captureManually ? 'manual' : 'automatic',
          'metadata': metadata,
        },
      );

      final clientSecret = paymentIntentResponse.data['clientSecret'] as String;
      final customerId = paymentIntentResponse.data['customer'] as String?;
      final ephemeralKey = paymentIntentResponse.data['ephemeralKey'] as String?;

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Homzy',
          customerId: customerId,
          customerEphemeralKeySecret: ephemeralKey,
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF2196F3),
              background: Color(0xFF1E1E1E),
              componentBackground: Color(0xFF2C2C2C),
            ),
          ),
        ),
      );

      // 3. Present the payment sheet
      await Stripe.instance.presentPaymentSheet();

      return PaymentResult(
        success: true,
        transactionId: paymentIntentResponse.data['id'] as String,
        amount: amount,
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return PaymentResult(
          success: false,
          error: 'Payment cancelled by user',
        );
      }
      return PaymentResult(
        success: false,
        error: e.error.localizedMessage ?? 'Payment failed',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        error: 'Payment error: $e',
      );
    }
  }

  /// Process refund
  Future<bool> refundPayment({
    required String paymentIntentId,
    double? amount, // Optional: Partial refund
    String? reason,
  }) async {
    try {
      await _dio.post(
        '$_serverUrl/refund-payment',
        data: {
          'paymentIntentId': paymentIntentId,
          if (amount != null) 'amount': (amount * 100).toInt(),
          if (reason != null) 'reason': reason,
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check payment status
  Future<String?> getPaymentStatus(String paymentIntentId) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/payment-intent/$paymentIntentId',
      );
      return response.data['status'] as String?;
    } catch (e) {
      return null;
    }
  }
}

/// Payment Authorization Result
class PaymentAuthResult {
  final bool success;
  final String? paymentIntentId;
  final double? amount;
  final String? error;

  PaymentAuthResult({
    required this.success,
    this.paymentIntentId,
    this.amount,
    this.error,
  });
}

/// Payment Capture Result
class PaymentCaptureResult {
  final bool success;
  final String? transactionId;
  final double? amount;
  final String? error;

  PaymentCaptureResult({
    required this.success,
    this.transactionId,
    this.amount,
    this.error,
  });
}

/// Payment Result (immediate payment)
class PaymentResult {
  final bool success;
  final String? transactionId;
  final double? amount;
  final String? error;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.amount,
    this.error,
  });
}
