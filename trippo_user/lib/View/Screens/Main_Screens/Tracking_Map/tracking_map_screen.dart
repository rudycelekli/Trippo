import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../../../Container/Repositories/service_request_repo.dart';
import '../../../../Model/service_category_model.dart';
import 'package:intl/intl.dart';

/// Real-time Provider Tracking Map
/// Shows provider location when they're en route to the user

class TrackingMapScreen extends ConsumerStatefulWidget {
  final String serviceRequestId;

  const TrackingMapScreen({super.key, required this.serviceRequestId});

  @override
  ConsumerState<TrackingMapScreen> createState() => _TrackingMapScreenState();
}

class _TrackingMapScreenState extends ConsumerState<TrackingMapScreen> {
  GoogleMapController? _mapController;
  StreamSubscription? _providerLocationSubscription;
  ServiceRequest? _serviceRequest;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadServiceRequest();
  }

  @override
  void dispose() {
    _providerLocationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadServiceRequest() async {
    final request = await ServiceRequestRepository()
        .getServiceRequest(widget.serviceRequestId);

    if (request != null) {
      setState(() {
        _serviceRequest = request;
      });

      // Add user location marker
      _markers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(request.userLatitude, request.userLongitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: request.userAddress,
        ),
      ));

      // Start tracking provider location
      if (request.assignedProviderId != null) {
        _startTrackingProvider(request.assignedProviderId!);
      }
    }
  }

  void _startTrackingProvider(String providerId) {
    _providerLocationSubscription = ServiceRequestRepository()
        .streamProviderLocation(providerId)
        .listen((location) {
      if (location != null && _serviceRequest != null) {
        setState(() {
          // Update provider marker
          _markers.removeWhere((m) => m.markerId.value == 'provider');
          _markers.add(Marker(
            markerId: const MarkerId('provider'),
            position: LatLng(location['latitude']!, location['longitude']!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: _serviceRequest!.assignedProviderName ?? 'Provider',
              snippet: 'On the way',
            ),
          ));

          // Update polyline (route from provider to user)
          _updateRoute(
            LatLng(location['latitude']!, location['longitude']!),
            LatLng(_serviceRequest!.userLatitude,
                _serviceRequest!.userLongitude),
          );
        });

        // Auto-adjust camera to show both markers
        _fitMarkersInView();
      }
    });
  }

  void _updateRoute(LatLng start, LatLng end) {
    // Simple straight line for now
    // TODO: Use Google Directions API for actual route
    _polylines.clear();
    _polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points: [start, end],
      color: const Color(0xFF2196F3),
      width: 4,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    ));
  }

  void _fitMarkersInView() {
    if (_markers.length >= 2 && _mapController != null) {
      final bounds = _calculateBounds(_markers.map((m) => m.position).toList());
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (var pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_serviceRequest == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Loading...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2196F3)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_serviceRequest!.userLatitude,
                  _serviceRequest!.userLongitude),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;
              // Set dark theme
              controller.setMapStyle('''
                [
                  {
                    "elementType": "geometry",
                    "stylers": [{"color": "#212121"}]
                  },
                  {
                    "elementType": "labels.icon",
                    "stylers": [{"visibility": "off"}]
                  },
                  {
                    "elementType": "labels.text.fill",
                    "stylers": [{"color": "#757575"}]
                  },
                  {
                    "elementType": "labels.text.stroke",
                    "stylers": [{"color": "#212121"}]
                  }
                ]
              ''');
            },
          ),

          // Top Card - Provider Info
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          // Back Button
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          // Provider Avatar
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF2196F3),
                            child: Text(
                              _serviceRequest!.assignedProviderName?[0]
                                      .toUpperCase() ??
                                  'P',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Provider Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _serviceRequest!.assignedProviderName ??
                                      'Provider',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _serviceRequest!.status.displayName,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Call Button
                          IconButton(
                            icon: const Icon(Icons.phone,
                                color: Color(0xFF2196F3)),
                            onPressed: () {
                              // TODO: Implement call functionality
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Service Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _serviceRequest!.category.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _serviceRequest!.category.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Scheduled: ${DateFormat('MMM dd, hh:mm a').format(_serviceRequest!.createdAt)}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Card - ETA and Actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ETA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time,
                              color: Color(0xFF2196F3)),
                          const SizedBox(width: 8),
                          const Text(
                            'Estimated arrival: ',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '15 min',
                            style: const TextStyle(
                              color: Color(0xFF2196F3),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Message Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Open chat with provider
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Message Provider'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2196F3),
                            side: const BorderSide(color: Color(0xFF2196F3)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
