import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Model/job_milestone_model.dart';

/// Job Milestone Repository
/// Handles tracking of provider progress throughout the job

class MilestoneRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String milestonesCollection = 'jobMilestones';

  /// Create a new milestone
  Future<String> createMilestone(JobMilestone milestone) async {
    try {
      final docRef = await _firestore
          .collection(milestonesCollection)
          .add(milestone.toFirestore());
      return docRef.id;
    } catch (e) {
      throw MilestoneException('Failed to create milestone: $e');
    }
  }

  /// Get all milestones for a service request
  Stream<List<JobMilestone>> getMilestonesForRequest(String serviceRequestId) {
    return _firestore
        .collection(milestonesCollection)
        .where('serviceRequestId', isEqualTo: serviceRequestId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobMilestone.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Provider marks arrival
  Future<String> markProviderArrived({
    required String serviceRequestId,
    String? imageUrl,
    String? notes,
  }) async {
    final milestone = JobMilestone(
      id: '',
      serviceRequestId: serviceRequestId,
      type: MilestoneType.arrived,
      description: 'Provider has arrived at your location',
      createdAt: DateTime.now(),
      status: MilestoneStatus.pending,
      imageUrl: imageUrl,
      notes: notes,
    );

    return await createMilestone(milestone);
  }

  /// User confirms milestone
  Future<void> confirmMilestone(String milestoneId) async {
    try {
      await _firestore.collection(milestonesCollection).doc(milestoneId).update({
        'status': MilestoneStatus.confirmed.name,
        'confirmedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw MilestoneException('Failed to confirm milestone: $e');
    }
  }

  /// User disputes milestone
  Future<void> disputeMilestone({
    required String milestoneId,
    required String reason,
  }) async {
    try {
      await _firestore.collection(milestonesCollection).doc(milestoneId).update({
        'status': MilestoneStatus.disputed.name,
        'disputeReason': reason,
      });
    } catch (e) {
      throw MilestoneException('Failed to dispute milestone: $e');
    }
  }

  /// Provider adds progress update
  Future<String> addProgressUpdate({
    required String serviceRequestId,
    required String description,
    String? imageUrl,
    String? notes,
  }) async {
    final milestone = JobMilestone(
      id: '',
      serviceRequestId: serviceRequestId,
      type: MilestoneType.progress,
      description: description,
      createdAt: DateTime.now(),
      status: MilestoneStatus.confirmed, // Progress updates auto-confirmed
      imageUrl: imageUrl,
      notes: notes,
    );

    return await createMilestone(milestone);
  }

  /// Provider marks job started
  Future<String> markJobStarted({
    required String serviceRequestId,
    String? notes,
  }) async {
    final milestone = JobMilestone(
      id: '',
      serviceRequestId: serviceRequestId,
      type: MilestoneType.started,
      description: 'Job has started',
      createdAt: DateTime.now(),
      status: MilestoneStatus.confirmed,
      notes: notes,
    );

    return await createMilestone(milestone);
  }

  /// Provider marks job completed
  Future<String> markJobCompleted({
    required String serviceRequestId,
    String? imageUrl,
    String? notes,
  }) async {
    final milestone = JobMilestone(
      id: '',
      serviceRequestId: serviceRequestId,
      type: MilestoneType.completed,
      description: 'Job has been completed',
      createdAt: DateTime.now(),
      status: MilestoneStatus.pending,
      imageUrl: imageUrl,
      notes: notes,
    );

    return await createMilestone(milestone);
  }

  /// Get pending arrival confirmation
  Future<JobMilestone?> getPendingArrivalConfirmation(
      String serviceRequestId) async {
    try {
      final snapshot = await _firestore
          .collection(milestonesCollection)
          .where('serviceRequestId', isEqualTo: serviceRequestId)
          .where('type', isEqualTo: MilestoneType.arrived.name)
          .where('status', isEqualTo: MilestoneStatus.pending.name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return JobMilestone.fromFirestore(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      throw MilestoneException('Failed to get pending arrival: $e');
    }
  }

  /// Stream pending confirmations for user
  Stream<List<JobMilestone>> streamPendingConfirmations(String serviceRequestId) {
    return _firestore
        .collection(milestonesCollection)
        .where('serviceRequestId', isEqualTo: serviceRequestId)
        .where('status', isEqualTo: MilestoneStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobMilestone.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Check if arrival has been confirmed
  Future<bool> isArrivalConfirmed(String serviceRequestId) async {
    try {
      final snapshot = await _firestore
          .collection(milestonesCollection)
          .where('serviceRequestId', isEqualTo: serviceRequestId)
          .where('type', isEqualTo: MilestoneType.arrived.name)
          .where('status', isEqualTo: MilestoneStatus.confirmed.name)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

class MilestoneException implements Exception {
  final String message;
  MilestoneException(this.message);

  @override
  String toString() => message;
}
