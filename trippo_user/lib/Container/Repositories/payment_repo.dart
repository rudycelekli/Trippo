import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/quote_model.dart';

/// Payment Repository
/// Handles all payment transactions through Stripe, PayPal, Apple Pay, Google Pay

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String paymentsCollection = 'paymentTransactions';

  /// Create a payment authorization (not captured yet)
  /// For house call fee - authorize when provider accepts, capture when they arrive
  Future<String> authorizePayment({
    required String serviceRequestId,
    required String userId,
    required String providerId,
    required PaymentType type,
    required double amount,
    required PaymentMethod method,
  }) async {
    try {
      final payment = PaymentTransaction(
        id: '',
        serviceRequestId: serviceRequestId,
        userId: userId,
        providerId: providerId,
        type: type,
        amount: amount,
        status: PaymentStatus.pending,
        method: method,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(paymentsCollection)
          .add(payment.toFirestore());

      return docRef.id;
    } catch (e) {
      throw PaymentException('Failed to authorize payment: $e');
    }
  }

  /// Capture authorized payment (charge the card)
  /// Called when user confirms provider arrival or job completion
  Future<void> capturePayment({
    required String paymentId,
    required String transactionId,
  }) async {
    try {
      await _firestore.collection(paymentsCollection).doc(paymentId).update({
        'status': PaymentStatus.completed.name,
        'transactionId': transactionId,
        'completedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw PaymentException('Failed to capture payment: $e');
    }
  }

  /// Cancel authorized payment
  /// Called if user disputes arrival or declines service
  Future<void> cancelPayment(String paymentId) async {
    try {
      await _firestore.collection(paymentsCollection).doc(paymentId).update({
        'status': PaymentStatus.cancelled.name,
      });
    } catch (e) {
      throw PaymentException('Failed to cancel payment: $e');
    }
  }

  /// Process immediate payment (authorize + capture)
  /// Used for final job payment after completion confirmation
  Future<String> processPayment({
    required String serviceRequestId,
    required String userId,
    required String providerId,
    required PaymentType type,
    required double amount,
    required PaymentMethod method,
    required String transactionId,
  }) async {
    try {
      final payment = PaymentTransaction(
        id: '',
        serviceRequestId: serviceRequestId,
        userId: userId,
        providerId: providerId,
        type: type,
        amount: amount,
        status: PaymentStatus.completed,
        method: method,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        transactionId: transactionId,
      );

      final docRef = await _firestore
          .collection(paymentsCollection)
          .add(payment.toFirestore());

      return docRef.id;
    } catch (e) {
      throw PaymentException('Failed to process payment: $e');
    }
  }

  /// Refund payment
  Future<void> refundPayment({
    required String paymentId,
    required String refundTransactionId,
  }) async {
    try {
      await _firestore.collection(paymentsCollection).doc(paymentId).update({
        'status': PaymentStatus.refunded.name,
        'refundTransactionId': refundTransactionId,
      });
    } catch (e) {
      throw PaymentException('Failed to refund payment: $e');
    }
  }

  /// Get payment by ID
  Future<PaymentTransaction?> getPayment(String paymentId) async {
    try {
      final doc =
          await _firestore.collection(paymentsCollection).doc(paymentId).get();

      if (!doc.exists) return null;

      return PaymentTransaction.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw PaymentException('Failed to get payment: $e');
    }
  }

  /// Get all payments for a service request
  Future<List<PaymentTransaction>> getPaymentsForRequest(
      String serviceRequestId) async {
    try {
      final snapshot = await _firestore
          .collection(paymentsCollection)
          .where('serviceRequestId', isEqualTo: serviceRequestId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => PaymentTransaction.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw PaymentException('Failed to get payments: $e');
    }
  }

  /// Get pending house call fee payment
  Future<PaymentTransaction?> getPendingHouseCallFee(
      String serviceRequestId) async {
    try {
      final snapshot = await _firestore
          .collection(paymentsCollection)
          .where('serviceRequestId', isEqualTo: serviceRequestId)
          .where('type', isEqualTo: PaymentType.houseCallFee.name)
          .where('status', isEqualTo: PaymentStatus.pending.name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return PaymentTransaction.fromFirestore(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      throw PaymentException('Failed to get pending house call fee: $e');
    }
  }

  /// Mark payment as failed
  Future<void> markPaymentFailed({
    required String paymentId,
    required String errorMessage,
  }) async {
    try {
      await _firestore.collection(paymentsCollection).doc(paymentId).update({
        'status': PaymentStatus.failed.name,
        'errorMessage': errorMessage,
      });
    } catch (e) {
      throw PaymentException('Failed to mark payment as failed: $e');
    }
  }

  /// Get user's payment history
  Stream<List<PaymentTransaction>> getUserPaymentHistory(String userId) {
    return _firestore
        .collection(paymentsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: PaymentStatus.completed.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentTransaction.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get provider's earnings
  Stream<List<PaymentTransaction>> getProviderEarnings(String providerId) {
    return _firestore
        .collection(paymentsCollection)
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: PaymentStatus.completed.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentTransaction.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);

  @override
  String toString() => message;
}
