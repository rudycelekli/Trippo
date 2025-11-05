/// Job Milestone Model
/// Tracks provider progress throughout the job

class JobMilestone {
  final String id;
  final String serviceRequestId;
  final MilestoneType type;
  final String description;
  final DateTime createdAt;
  final MilestoneStatus status;
  final DateTime? confirmedAt;
  final String? imageUrl; // Provider can attach photo proof
  final String? notes;

  JobMilestone({
    required this.id,
    required this.serviceRequestId,
    required this.type,
    required this.description,
    required this.createdAt,
    required this.status,
    this.confirmedAt,
    this.imageUrl,
    this.notes,
  });

  factory JobMilestone.fromFirestore(Map<String, dynamic> data, String id) {
    return JobMilestone(
      id: id,
      serviceRequestId: data['serviceRequestId'] ?? '',
      type: MilestoneType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MilestoneType.started,
      ),
      description: data['description'] ?? '',
      createdAt: DateTime.parse(data['createdAt']),
      status: MilestoneStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MilestoneStatus.pending,
      ),
      confirmedAt: data['confirmedAt'] != null
          ? DateTime.parse(data['confirmedAt'])
          : null,
      imageUrl: data['imageUrl'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceRequestId': serviceRequestId,
      'type': type.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'notes': notes,
    };
  }

  JobMilestone copyWith({
    String? id,
    String? serviceRequestId,
    MilestoneType? type,
    String? description,
    DateTime? createdAt,
    MilestoneStatus? status,
    DateTime? confirmedAt,
    String? imageUrl,
    String? notes,
  }) {
    return JobMilestone(
      id: id ?? this.id,
      serviceRequestId: serviceRequestId ?? this.serviceRequestId,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
    );
  }
}

enum MilestoneType {
  arrived,        // Provider arrived at location
  started,        // Job started (after quote accepted)
  progress,       // Custom progress update
  completed,      // Job completed
}

enum MilestoneStatus {
  pending,        // Awaiting user confirmation
  confirmed,      // User confirmed
  disputed,       // User disputed this milestone
}

extension MilestoneTypeExtension on MilestoneType {
  String get displayName {
    switch (this) {
      case MilestoneType.arrived:
        return 'Arrived at Location';
      case MilestoneType.started:
        return 'Job Started';
      case MilestoneType.progress:
        return 'Progress Update';
      case MilestoneType.completed:
        return 'Job Completed';
    }
  }

  String get icon {
    switch (this) {
      case MilestoneType.arrived:
        return '📍';
      case MilestoneType.started:
        return '🔨';
      case MilestoneType.progress:
        return '⚙️';
      case MilestoneType.completed:
        return '✅';
    }
  }

  /// Whether this milestone requires user confirmation
  bool get requiresConfirmation {
    return this == MilestoneType.arrived || this == MilestoneType.completed;
  }

  /// Whether this milestone triggers payment
  bool get triggersPayment {
    return this == MilestoneType.arrived; // House call fee
  }
}

extension MilestoneStatusExtension on MilestoneStatus {
  String get displayName {
    switch (this) {
      case MilestoneStatus.pending:
        return 'Awaiting Confirmation';
      case MilestoneStatus.confirmed:
        return 'Confirmed';
      case MilestoneStatus.disputed:
        return 'Disputed';
    }
  }
}
