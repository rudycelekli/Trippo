/// Service Category Model
/// Defines all home service types available in Homzy

enum ServiceCategory {
  cleaning,
  plumbing,
  electrical,
  hvac,
  lawnCare,
  homeOrganization,
  painting,
  carpentry,
  applianceRepair,
  pestControl,
  locksmith,
  handyman,
  roofing,
  flooring,
  windowCleaning,
  garageDoorRepair,
  poolMaintenance,
  moving,
  deepCleaning,
  pressureWashing,
}

extension ServiceCategoryExtension on ServiceCategory {
  String get displayName {
    switch (this) {
      case ServiceCategory.cleaning:
        return 'Cleaning';
      case ServiceCategory.plumbing:
        return 'Plumbing';
      case ServiceCategory.electrical:
        return 'Electrical';
      case ServiceCategory.hvac:
        return 'HVAC';
      case ServiceCategory.lawnCare:
        return 'Lawn Care';
      case ServiceCategory.homeOrganization:
        return 'Home Organization';
      case ServiceCategory.painting:
        return 'Painting';
      case ServiceCategory.carpentry:
        return 'Carpentry';
      case ServiceCategory.applianceRepair:
        return 'Appliance Repair';
      case ServiceCategory.pestControl:
        return 'Pest Control';
      case ServiceCategory.locksmith:
        return 'Locksmith';
      case ServiceCategory.handyman:
        return 'Handyman';
      case ServiceCategory.roofing:
        return 'Roofing';
      case ServiceCategory.flooring:
        return 'Flooring';
      case ServiceCategory.windowCleaning:
        return 'Window Cleaning';
      case ServiceCategory.garageDoorRepair:
        return 'Garage Door Repair';
      case ServiceCategory.poolMaintenance:
        return 'Pool Maintenance';
      case ServiceCategory.moving:
        return 'Moving';
      case ServiceCategory.deepCleaning:
        return 'Deep Cleaning';
      case ServiceCategory.pressureWashing:
        return 'Pressure Washing';
    }
  }

  String get icon {
    switch (this) {
      case ServiceCategory.cleaning:
        return '🧹';
      case ServiceCategory.plumbing:
        return '🔧';
      case ServiceCategory.electrical:
        return '⚡';
      case ServiceCategory.hvac:
        return '❄️';
      case ServiceCategory.lawnCare:
        return '🌱';
      case ServiceCategory.homeOrganization:
        return '📦';
      case ServiceCategory.painting:
        return '🎨';
      case ServiceCategory.carpentry:
        return '🪚';
      case ServiceCategory.applianceRepair:
        return '🔨';
      case ServiceCategory.pestControl:
        return '🐛';
      case ServiceCategory.locksmith:
        return '🔑';
      case ServiceCategory.handyman:
        return '🛠️';
      case ServiceCategory.roofing:
        return '🏠';
      case ServiceCategory.flooring:
        return '🪵';
      case ServiceCategory.windowCleaning:
        return '🪟';
      case ServiceCategory.garageDoorRepair:
        return '🚪';
      case ServiceCategory.poolMaintenance:
        return '🏊';
      case ServiceCategory.moving:
        return '📦';
      case ServiceCategory.deepCleaning:
        return '✨';
      case ServiceCategory.pressureWashing:
        return '💦';
    }
  }

  String get description {
    switch (this) {
      case ServiceCategory.cleaning:
        return 'Regular house cleaning services';
      case ServiceCategory.plumbing:
        return 'Pipes, drains, faucets, and water systems';
      case ServiceCategory.electrical:
        return 'Wiring, outlets, fixtures, and electrical repairs';
      case ServiceCategory.hvac:
        return 'Heating, ventilation, and air conditioning';
      case ServiceCategory.lawnCare:
        return 'Mowing, trimming, and lawn maintenance';
      case ServiceCategory.homeOrganization:
        return 'Decluttering and organizing spaces';
      case ServiceCategory.painting:
        return 'Interior and exterior painting services';
      case ServiceCategory.carpentry:
        return 'Woodwork, furniture repair, and custom builds';
      case ServiceCategory.applianceRepair:
        return 'Repair of household appliances';
      case ServiceCategory.pestControl:
        return 'Pest inspection and extermination';
      case ServiceCategory.locksmith:
        return 'Lock installation, repair, and emergency lockouts';
      case ServiceCategory.handyman:
        return 'General home repairs and maintenance';
      case ServiceCategory.roofing:
        return 'Roof repair, replacement, and maintenance';
      case ServiceCategory.flooring:
        return 'Floor installation and repair';
      case ServiceCategory.windowCleaning:
        return 'Professional window cleaning';
      case ServiceCategory.garageDoorRepair:
        return 'Garage door installation and repair';
      case ServiceCategory.poolMaintenance:
        return 'Pool cleaning and maintenance';
      case ServiceCategory.moving:
        return 'Moving and relocation services';
      case ServiceCategory.deepCleaning:
        return 'Thorough, intensive cleaning services';
      case ServiceCategory.pressureWashing:
        return 'Exterior pressure washing services';
    }
  }

  /// Default platform-defined hourly rate (in USD)
  double get defaultHourlyRate {
    switch (this) {
      case ServiceCategory.cleaning:
        return 35.0;
      case ServiceCategory.plumbing:
        return 85.0;
      case ServiceCategory.electrical:
        return 90.0;
      case ServiceCategory.hvac:
        return 95.0;
      case ServiceCategory.lawnCare:
        return 45.0;
      case ServiceCategory.homeOrganization:
        return 50.0;
      case ServiceCategory.painting:
        return 55.0;
      case ServiceCategory.carpentry:
        return 75.0;
      case ServiceCategory.applianceRepair:
        return 80.0;
      case ServiceCategory.pestControl:
        return 70.0;
      case ServiceCategory.locksmith:
        return 85.0;
      case ServiceCategory.handyman:
        return 60.0;
      case ServiceCategory.roofing:
        return 100.0;
      case ServiceCategory.flooring:
        return 65.0;
      case ServiceCategory.windowCleaning:
        return 40.0;
      case ServiceCategory.garageDoorRepair:
        return 75.0;
      case ServiceCategory.poolMaintenance:
        return 70.0;
      case ServiceCategory.moving:
        return 90.0;
      case ServiceCategory.deepCleaning:
        return 55.0;
      case ServiceCategory.pressureWashing:
        return 50.0;
    }
  }

  /// Whether this is typically an emergency service
  bool get isEmergencyCapable {
    switch (this) {
      case ServiceCategory.plumbing:
      case ServiceCategory.electrical:
      case ServiceCategory.hvac:
      case ServiceCategory.locksmith:
      case ServiceCategory.applianceRepair:
      case ServiceCategory.pestControl:
        return true;
      default:
        return false;
    }
  }
}

/// Service Request Model
class ServiceRequest {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final ServiceCategory category;
  final String description;
  final List<String> imageUrls;
  final ServiceUrgency urgency;
  final DateTime? preferredDateTime;
  final ServiceRequestStatus status;
  final String? assignedProviderId;
  final String? assignedProviderName;
  final double? estimatedCost;
  final double? finalCost;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String userAddress;
  final double userLatitude;
  final double userLongitude;

  ServiceRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.category,
    required this.description,
    required this.imageUrls,
    required this.urgency,
    this.preferredDateTime,
    required this.status,
    this.assignedProviderId,
    this.assignedProviderName,
    this.estimatedCost,
    this.finalCost,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    required this.userAddress,
    required this.userLatitude,
    required this.userLongitude,
  });

  factory ServiceRequest.fromFirestore(Map<String, dynamic> data, String id) {
    return ServiceRequest(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      category: ServiceCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ServiceCategory.handyman,
      ),
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      urgency: ServiceUrgency.values.firstWhere(
        (e) => e.name == data['urgency'],
        orElse: () => ServiceUrgency.scheduled,
      ),
      preferredDateTime: data['preferredDateTime'] != null
          ? DateTime.parse(data['preferredDateTime'])
          : null,
      status: ServiceRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ServiceRequestStatus.pending,
      ),
      assignedProviderId: data['assignedProviderId'],
      assignedProviderName: data['assignedProviderName'],
      estimatedCost: data['estimatedCost']?.toDouble(),
      finalCost: data['finalCost']?.toDouble(),
      createdAt: DateTime.parse(data['createdAt']),
      acceptedAt: data['acceptedAt'] != null ? DateTime.parse(data['acceptedAt']) : null,
      completedAt: data['completedAt'] != null ? DateTime.parse(data['completedAt']) : null,
      userAddress: data['userAddress'] ?? '',
      userLatitude: data['userLatitude']?.toDouble() ?? 0.0,
      userLongitude: data['userLongitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'category': category.name,
      'description': description,
      'imageUrls': imageUrls,
      'urgency': urgency.name,
      'preferredDateTime': preferredDateTime?.toIso8601String(),
      'status': status.name,
      'assignedProviderId': assignedProviderId,
      'assignedProviderName': assignedProviderName,
      'estimatedCost': estimatedCost,
      'finalCost': finalCost,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'userAddress': userAddress,
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
    };
  }
}

enum ServiceUrgency {
  onDemand,
  scheduled,
}

enum ServiceRequestStatus {
  pending,              // Request created, waiting for provider
  searching,            // Actively searching for providers
  accepted,             // Provider accepted the request
  providerEnRoute,      // Provider is on their way (real-time tracking active)
  providerArrived,      // Provider has arrived at location
  quotePending,         // Provider submitted quote, awaiting user approval
  quoteAccepted,        // User accepted the quote, job starting
  quoteDeclined,        // User declined the quote (charged house call fee)
  inProgress,           // Job is in progress
  completed,            // Job completed successfully
  cancelled,            // Request cancelled
  autoScheduled,        // No provider available, auto-scheduled for later
}

extension ServiceUrgencyExtension on ServiceUrgency {
  String get displayName {
    switch (this) {
      case ServiceUrgency.onDemand:
        return 'On-Demand (ASAP)';
      case ServiceUrgency.scheduled:
        return 'Schedule for Later';
    }
  }
}

extension ServiceRequestStatusExtension on ServiceRequestStatus {
  String get displayName {
    switch (this) {
      case ServiceRequestStatus.pending:
        return 'Pending';
      case ServiceRequestStatus.searching:
        return 'Searching for Provider...';
      case ServiceRequestStatus.accepted:
        return 'Provider Accepted';
      case ServiceRequestStatus.providerEnRoute:
        return 'Provider On The Way';
      case ServiceRequestStatus.providerArrived:
        return 'Provider Arrived';
      case ServiceRequestStatus.quotePending:
        return 'Quote Awaiting Approval';
      case ServiceRequestStatus.quoteAccepted:
        return 'Quote Accepted - Job Starting';
      case ServiceRequestStatus.quoteDeclined:
        return 'Quote Declined';
      case ServiceRequestStatus.inProgress:
        return 'In Progress';
      case ServiceRequestStatus.completed:
        return 'Completed';
      case ServiceRequestStatus.cancelled:
        return 'Cancelled';
      case ServiceRequestStatus.autoScheduled:
        return 'Auto-Scheduled';
    }
  }

  bool get canTrackProvider {
    return this == ServiceRequestStatus.providerEnRoute ||
           this == ServiceRequestStatus.providerArrived;
  }

  bool get requiresPayment {
    return this == ServiceRequestStatus.completed ||
           this == ServiceRequestStatus.quoteDeclined; // House call fee
  }
}
