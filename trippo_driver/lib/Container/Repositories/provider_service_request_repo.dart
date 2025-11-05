import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Model/service_category_model.dart';
import '../../Model/quote_model.dart';
import '../../Model/job_milestone_model.dart';

/// Provider Service Request Repository
/// Manages service requests from provider perspective

class ProviderServiceRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _serviceRequestsCollection = 'serviceRequests';
  static const String _quotesCollection = 'quotes';
  static const String _milestonesCollection = 'milestones';

  String? get _providerId => _auth.currentUser?.uid;

  /// Stream nearby pending service requests for provider's categories
  Stream<List<ServiceRequest>> streamNearbyRequests({
    required double latitude,
    required double longitude,
    required double radiusMiles,
    required List<ServiceCategory> providerCategories,
  }) {
    // Convert categories to list of strings for query
    final categoryStrings = providerCategories.map((c) => c.name).toList();

    return _firestore
        .collection(_serviceRequestsCollection)
        .where('status', whereIn: [
          ServiceRequestStatus.pending.name,
          ServiceRequestStatus.searching.name,
        ])
        .where('category', whereIn: categoryStrings)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => ServiceRequest.fromFirestore(doc.data(), doc.id))
              .toList();

          // Filter by distance
          final radiusKm = radiusMiles * 1.60934;
          return requests.where((request) {
            final distance = _calculateDistance(
              latitude,
              longitude,
              request.userLatitude,
              request.userLongitude,
            );
            return distance <= radiusKm;
          }).toList();
        });
  }

  /// Stream provider's accepted/active requests
  Stream<List<ServiceRequest>> streamMyActiveRequests() {
    if (_providerId == null) return Stream.value([]);

    return _firestore
        .collection(_serviceRequestsCollection)
        .where('providerId', isEqualTo: _providerId)
        .where('status', whereIn: [
          ServiceRequestStatus.accepted.name,
          ServiceRequestStatus.providerEnRoute.name,
          ServiceRequestStatus.providerArrived.name,
          ServiceRequestStatus.quotePending.name,
          ServiceRequestStatus.quoteAccepted.name,
          ServiceRequestStatus.inProgress.name,
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ServiceRequest.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Stream provider's completed requests
  Stream<List<ServiceRequest>> streamMyCompletedRequests({int limit = 50}) {
    if (_providerId == null) return Stream.value([]);

    return _firestore
        .collection(_serviceRequestsCollection)
        .where('providerId', isEqualTo: _providerId)
        .where('status', isEqualTo: ServiceRequestStatus.completed.name)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ServiceRequest.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get service request by ID
  Future<ServiceRequest?> getRequestById(String requestId) async {
    try {
      final doc = await _firestore
          .collection(_serviceRequestsCollection)
          .doc(requestId)
          .get();

      if (!doc.exists || doc.data() == null) return null;

      return ServiceRequest.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting request: $e');
      return null;
    }
  }

  /// Accept a service request
  Future<void> acceptRequest(String requestId) async {
    if (_providerId == null) throw Exception('Provider not logged in');

    try {
      await _firestore
          .collection(_serviceRequestsCollection)
          .doc(requestId)
          .update({
        'providerId': _providerId,
        'status': ServiceRequestStatus.accepted.name,
        'acceptedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to accept request: $e');
    }
  }

  /// Update status to en route
  Future<void> markEnRoute(String requestId) async {
    await _updateStatus(requestId, ServiceRequestStatus.providerEnRoute);
  }

  /// Update status to arrived
  Future<void> markArrived(String requestId) async {
    await _updateStatus(requestId, ServiceRequestStatus.providerArrived);
  }

  /// Submit a quote
  Future<String> submitQuote(ServiceQuote quote, String requestId) async {
    try {
      // Create quote document
      final quoteDoc = await _firestore
          .collection(_quotesCollection)
          .add(quote.toFirestore());

      // Update request status
      await _firestore
          .collection(_serviceRequestsCollection)
          .doc(requestId)
          .update({
        'status': ServiceRequestStatus.quotePending.name,
        'quoteId': quoteDoc.id,
      });

      return quoteDoc.id;
    } catch (e) {
      throw Exception('Failed to submit quote: $e');
    }
  }

  /// Submit a milestone
  Future<String> submitMilestone(JobMilestone milestone, String requestId) async {
    try {
      final milestoneDoc = await _firestore
          .collection(_milestonesCollection)
          .add(milestone.toFirestore());

      // Update request with milestone
      await _firestore
          .collection(_serviceRequestsCollection)
          .doc(requestId)
          .update({
        'lastMilestoneId': milestoneDoc.id,
        'lastMilestoneType': milestone.type.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return milestoneDoc.id;
    } catch (e) {
      throw Exception('Failed to submit milestone: $e');
    }
  }

  /// Mark job as in progress
  Future<void> startJob(String requestId) async {
    await _updateStatus(requestId, ServiceRequestStatus.inProgress);
  }

  /// Mark job as completed
  Future<void> completeJob(String requestId) async {
    await _firestore
        .collection(_serviceRequestsCollection)
        .doc(requestId)
        .update({
      'status': ServiceRequestStatus.completed.name,
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Update provider location
  Future<void> updateLocation(double latitude, double longitude) async {
    if (_providerId == null) return;

    try {
      await _firestore
          .collection('serviceProviders')
          .doc(_providerId)
          .update({
        'latitude': latitude,
        'longitude': longitude,
        'lastLocationUpdate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Get provider earnings summary
  Future<Map<String, dynamic>> getEarningsSummary() async {
    if (_providerId == null) return {};

    try {
      final completedJobs = await _firestore
          .collection(_serviceRequestsCollection)
          .where('providerId', isEqualTo: _providerId)
          .where('status', isEqualTo: ServiceRequestStatus.completed.name)
          .get();

      double totalEarnings = 0;
      double totalTips = 0;
      int jobCount = completedJobs.docs.length;

      // Calculate earnings from quotes
      for (final job in completedJobs.docs) {
        final quoteId = job.data()['quoteId'];
        if (quoteId != null) {
          final quoteDoc = await _firestore
              .collection(_quotesCollection)
              .doc(quoteId)
              .get();

          if (quoteDoc.exists && quoteDoc.data() != null) {
            final quote = ServiceQuote.fromFirestore(quoteDoc.data()!, quoteDoc.id);
            totalEarnings += quote.totalAmount;
          }
        }
      }

      return {
        'totalEarnings': totalEarnings,
        'totalTips': totalTips,
        'jobCount': jobCount,
        'averageEarning': jobCount > 0 ? totalEarnings / jobCount : 0,
      };
    } catch (e) {
      print('Error getting earnings: $e');
      return {};
    }
  }

  Future<void> _updateStatus(String requestId, ServiceRequestStatus status) async {
    await _firestore
        .collection(_serviceRequestsCollection)
        .doc(requestId)
        .update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula for distance calculation
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        (lat1.toRadians).cos() *
            (lat2.toRadians).cos() *
            (dLon / 2).sin() *
            (dLon / 2).sin();

    final c = 2 * (a.sqrt()).asin();

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180.0);
  }
}

extension on double {
  double get toRadians => this * (3.141592653589793 / 180.0);
  double sin() => 0; // Placeholder
  double cos() => 0; // Placeholder
  double asin() => 0; // Placeholder
  double sqrt() => 0; // Placeholder
}
