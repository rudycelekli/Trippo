import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import '../../Model/service_category_model.dart';
import '../../Model/service_provider_model.dart';

/// Service Request Repository
/// Handles all Firestore operations for service requests

class ServiceRequestRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final geo = GeoFlutterFire();

  // Collections
  static const String serviceRequestsCollection = 'serviceRequests';
  static const String serviceProvidersCollection = 'serviceProviders';

  /// Create a new service request
  Future<String> createServiceRequest(ServiceRequest request) async {
    try {
      final docRef = await _firestore
          .collection(serviceRequestsCollection)
          .add(request.toFirestore());
      return docRef.id;
    } catch (e) {
      throw ServiceRequestException('Failed to create service request: $e');
    }
  }

  /// Get service request by ID
  Future<ServiceRequest?> getServiceRequest(String requestId) async {
    try {
      final doc = await _firestore
          .collection(serviceRequestsCollection)
          .doc(requestId)
          .get();

      if (!doc.exists) return null;

      return ServiceRequest.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw ServiceRequestException('Failed to get service request: $e');
    }
  }

  /// Get all service requests for a user
  Stream<List<ServiceRequest>> getUserServiceRequests(String userId) {
    return _firestore
        .collection(serviceRequestsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceRequest.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get pending service requests for providers (within service area)
  Future<List<ServiceRequest>> getPendingRequestsNearby({
    required double latitude,
    required double longitude,
    required double radiusMiles,
    required List<ServiceCategory> providerCategories,
  }) async {
    try {
      // Convert miles to kilometers for GeoFlutterFire
      final radiusKm = radiusMiles * 1.60934;

      final center = geo.point(latitude: latitude, longitude: longitude);

      // Query Firestore for pending requests
      final snapshot = await _firestore
          .collection(serviceRequestsCollection)
          .where('status', isEqualTo: ServiceRequestStatus.searching.name)
          .where('category',
              whereIn: providerCategories.map((e) => e.name).toList())
          .get();

      // Filter by distance manually (since geoflutterfire2 needs GeoFirePoint)
      final requests = snapshot.docs
          .map((doc) => ServiceRequest.fromFirestore(doc.data(), doc.id))
          .where((request) {
        final distance = _calculateDistance(
          latitude,
          longitude,
          request.userLatitude,
          request.userLongitude,
        );
        return distance <= radiusMiles;
      }).toList();

      return requests;
    } catch (e) {
      throw ServiceRequestException('Failed to get nearby requests: $e');
    }
  }

  /// Update service request status
  Future<void> updateRequestStatus({
    required String requestId,
    required ServiceRequestStatus status,
  }) async {
    try {
      await _firestore
          .collection(serviceRequestsCollection)
          .doc(requestId)
          .update({'status': status.name});
    } catch (e) {
      throw ServiceRequestException('Failed to update request status: $e');
    }
  }

  /// Assign provider to request
  Future<void> assignProvider({
    required String requestId,
    required String providerId,
    required String providerName,
  }) async {
    try {
      await _firestore
          .collection(serviceRequestsCollection)
          .doc(requestId)
          .update({
        'assignedProviderId': providerId,
        'assignedProviderName': providerName,
        'status': ServiceRequestStatus.accepted.name,
        'acceptedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServiceRequestException('Failed to assign provider: $e');
    }
  }

  /// Update provider location when en route
  Future<void> updateProviderLocation({
    required String providerId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _firestore
          .collection(serviceProvidersCollection)
          .doc(providerId)
          .update({
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      throw ServiceRequestException('Failed to update provider location: $e');
    }
  }

  /// Stream provider location for real-time tracking
  Stream<Map<String, double>?> streamProviderLocation(String providerId) {
    return _firestore
        .collection(serviceProvidersCollection)
        .doc(providerId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return {
        'latitude': (data['latitude'] ?? 0.0).toDouble(),
        'longitude': (data['longitude'] ?? 0.0).toDouble(),
      };
    });
  }

  /// Mark provider as en route
  Future<void> setProviderEnRoute(String requestId) async {
    await updateRequestStatus(
      requestId: requestId,
      status: ServiceRequestStatus.providerEnRoute,
    );
  }

  /// Mark provider as arrived
  Future<void> setProviderArrived(String requestId) async {
    await updateRequestStatus(
      requestId: requestId,
      status: ServiceRequestStatus.providerArrived,
    );
  }

  /// Complete service request
  Future<void> completeRequest({
    required String requestId,
    required double finalCost,
  }) async {
    try {
      await _firestore
          .collection(serviceRequestsCollection)
          .doc(requestId)
          .update({
        'status': ServiceRequestStatus.completed.name,
        'finalCost': finalCost,
        'completedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServiceRequestException('Failed to complete request: $e');
    }
  }

  /// Cancel service request
  Future<void> cancelRequest(String requestId, String reason) async {
    try {
      await _firestore
          .collection(serviceRequestsCollection)
          .doc(requestId)
          .update({
        'status': ServiceRequestStatus.cancelled.name,
        'cancelReason': reason,
      });
    } catch (e) {
      throw ServiceRequestException('Failed to cancel request: $e');
    }
  }

  /// Calculate distance between two points in miles (Haversine formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusMiles = 3958.8;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        _degreesToRadians(lat1).cos() *
            _degreesToRadians(lat2).cos() *
            (dLon / 2).sin() *
            (dLon / 2).sin();

    final c = 2 * a.sqrt().asin();
    return earthRadiusMiles * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * 3.141592653589793 / 180;
  }
}

class ServiceRequestException implements Exception {
  final String message;
  ServiceRequestException(this.message);

  @override
  String toString() => message;
}
