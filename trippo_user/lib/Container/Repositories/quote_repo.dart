import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/quote_model.dart';
import '../../Model/service_category_model.dart';

/// Quote Repository
/// Handles all Firestore operations for quotes and estimates

class QuoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String quotesCollection = 'quotes';
  static const String serviceRequestsCollection = 'serviceRequests';

  /// Create a new quote
  Future<String> createQuote(ServiceQuote quote) async {
    try {
      final docRef =
          await _firestore.collection(quotesCollection).add(quote.toFirestore());

      // Update service request status to quotePending
      await _firestore
          .collection(serviceRequestsCollection)
          .doc(quote.serviceRequestId)
          .update({
        'status': ServiceRequestStatus.quotePending.name,
        'estimatedCost': quote.totalAmount,
      });

      return docRef.id;
    } catch (e) {
      throw QuoteException('Failed to create quote: $e');
    }
  }

  /// Get quote by ID
  Future<ServiceQuote?> getQuote(String quoteId) async {
    try {
      final doc = await _firestore.collection(quotesCollection).doc(quoteId).get();

      if (!doc.exists) return null;

      return ServiceQuote.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw QuoteException('Failed to get quote: $e');
    }
  }

  /// Get quotes for a service request
  Stream<List<ServiceQuote>> getQuotesForRequest(String serviceRequestId) {
    return _firestore
        .collection(quotesCollection)
        .where('serviceRequestId', isEqualTo: serviceRequestId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceQuote.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Accept a quote
  Future<void> acceptQuote({
    required String quoteId,
    required String serviceRequestId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update quote status
      batch.update(
        _firestore.collection(quotesCollection).doc(quoteId),
        {
          'status': QuoteStatus.accepted.name,
          'acceptedAt': DateTime.now().toIso8601String(),
        },
      );

      // Update service request status
      batch.update(
        _firestore.collection(serviceRequestsCollection).doc(serviceRequestId),
        {
          'status': ServiceRequestStatus.quoteAccepted.name,
        },
      );

      await batch.commit();
    } catch (e) {
      throw QuoteException('Failed to accept quote: $e');
    }
  }

  /// Decline a quote
  Future<void> declineQuote({
    required String quoteId,
    required String serviceRequestId,
    required String reason,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update quote status
      batch.update(
        _firestore.collection(quotesCollection).doc(quoteId),
        {
          'status': QuoteStatus.declined.name,
          'declinedAt': DateTime.now().toIso8601String(),
          'userDeclineReason': reason,
        },
      );

      // Update service request status to quoteDeclined
      // User will be charged house call fee
      batch.update(
        _firestore.collection(serviceRequestsCollection).doc(serviceRequestId),
        {
          'status': ServiceRequestStatus.quoteDeclined.name,
        },
      );

      await batch.commit();
    } catch (e) {
      throw QuoteException('Failed to decline quote: $e');
    }
  }

  /// Update quote (provider can modify before submitting)
  Future<void> updateQuote({
    required String quoteId,
    required List<QuoteLineItem> lineItems,
    required double subtotal,
    required double taxAmount,
    required double totalAmount,
    String? notes,
  }) async {
    try {
      await _firestore.collection(quotesCollection).doc(quoteId).update({
        'lineItems': lineItems.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'taxAmount': taxAmount,
        'totalAmount': totalAmount,
        if (notes != null) 'notes': notes,
      });
    } catch (e) {
      throw QuoteException('Failed to update quote: $e');
    }
  }

  /// Get pending quote for a service request (if any)
  Future<ServiceQuote?> getPendingQuote(String serviceRequestId) async {
    try {
      final snapshot = await _firestore
          .collection(quotesCollection)
          .where('serviceRequestId', isEqualTo: serviceRequestId)
          .where('status', isEqualTo: QuoteStatus.pending.name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return ServiceQuote.fromFirestore(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      throw QuoteException('Failed to get pending quote: $e');
    }
  }

  /// Stream pending quote for real-time updates
  Stream<ServiceQuote?> streamPendingQuote(String serviceRequestId) {
    return _firestore
        .collection(quotesCollection)
        .where('serviceRequestId', isEqualTo: serviceRequestId)
        .where('status', isEqualTo: QuoteStatus.pending.name)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ServiceQuote.fromFirestore(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }
}

class QuoteException implements Exception {
  final String message;
  QuoteException(this.message);

  @override
  String toString() => message;
}
