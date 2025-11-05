import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Model/provider_application_model.dart';
import '../../Model/service_provider_model.dart';
import '../../services/checkr_background_check_service.dart';

/// Provider Application Repository
/// Manages provider onboarding workflow with background checks and admin approval

class ProviderApplicationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _applicationsCollection = 'providerApplications';
  static const String _providersCollection = 'serviceProviders';

  /// Submit a new provider application
  Future<String> submitApplication(ProviderApplication application) async {
    try {
      final docRef = await _firestore
          .collection(_applicationsCollection)
          .add(application.toFirestore());

      print('Application submitted: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }

  /// Get application by ID
  Future<ProviderApplication?> getApplication(String applicationId) async {
    try {
      final doc = await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .get();

      if (!doc.exists || doc.data() == null) return null;

      return ProviderApplication.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting application: $e');
      return null;
    }
  }

  /// Get application by applicant ID
  Future<ProviderApplication?> getApplicationByApplicantId(
      String applicantId) async {
    try {
      final snapshot = await _firestore
          .collection(_applicationsCollection)
          .where('applicantId', isEqualTo: applicantId)
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return ProviderApplication.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      print('Error getting application by applicant: $e');
      return null;
    }
  }

  /// Stream all pending applications (for admin dashboard)
  Stream<List<ProviderApplication>> streamPendingApplications() {
    return _firestore
        .collection(_applicationsCollection)
        .where('status', whereIn: [
          ApplicationStatus.pending.name,
          ApplicationStatus.backgroundCheckComplete.name,
          ApplicationStatus.underReview.name,
        ])
        .orderBy('submittedAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProviderApplication.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get all applications (for admin)
  Future<List<ProviderApplication>> getAllApplications({
    ApplicationStatus? filterByStatus,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection(_applicationsCollection);

      if (filterByStatus != null) {
        query = query.where('status', isEqualTo: filterByStatus.name);
      }

      final snapshot = await query
          .orderBy('submittedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProviderApplication.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting applications: $e');
      return [];
    }
  }

  /// Initiate background check with Checkr
  Future<void> initiateBackgroundCheck({
    required String applicationId,
    required CheckrBackgroundCheckService checkrService,
    required Map<String, String> candidateInfo, // SSN, DOB, etc.
  }) async {
    try {
      // Update status to background check in progress
      await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .update({
        'status': ApplicationStatus.backgroundCheckInProgress.name,
        'backgroundCheckStatus': BackgroundCheckStatus.pending.name,
      });

      // Get application details
      final app = await getApplication(applicationId);
      if (app == null) throw Exception('Application not found');

      // Create Checkr candidate
      final candidate = await checkrService.createCandidate(
        email: app.email,
        firstName: candidateInfo['firstName'] ?? app.name.split(' ').first,
        middleName: candidateInfo['middleName'] ?? '',
        lastName: candidateInfo['lastName'] ?? app.name.split(' ').last,
        phone: app.phoneNumber,
        dob: candidateInfo['dob'] ?? '', // Required: YYYY-MM-DD
        ssn: candidateInfo['ssn'] ?? '', // Required: XXX-XX-XXXX
        zipCode: candidateInfo['zipCode'] ?? '',
      );

      // Create background check report
      final report = await checkrService.createBackgroundCheck(
        candidateId: candidate.id,
        package: 'standard', // or 'basic', 'professional', 'premium'
      );

      // Update application with Checkr IDs
      await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .update({
        'checkrCandidateId': candidate.id,
        'checkrReportId': report.id,
        'backgroundCheckStatus': BackgroundCheckStatus.processing.name,
      });

      print('Background check initiated: ${report.id}');
    } catch (e) {
      // Update status to failed
      await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .update({
        'backgroundCheckStatus': BackgroundCheckStatus.failed.name,
      });

      throw Exception('Failed to initiate background check: $e');
    }
  }

  /// Update background check status (called by webhook or manual refresh)
  Future<void> updateBackgroundCheckStatus({
    required String applicationId,
    required CheckrReport report,
  }) async {
    try {
      final updateData = {
        'backgroundCheckStatus': report.isComplete
            ? BackgroundCheckStatus.completed.name
            : BackgroundCheckStatus.processing.name,
        'backgroundCheckResult': report.result,
        'backgroundCheckDetails': {
          'status': report.status,
          'result': report.result,
          'completedAt': report.completedAt?.toIso8601String(),
          'reportUrl': report.reportUrl,
          'screenings': report.screenings,
        },
      };

      if (report.isComplete) {
        updateData['backgroundCheckCompletedAt'] = DateTime.now().toIso8601String();
        updateData['status'] = ApplicationStatus.backgroundCheckComplete.name;
      }

      await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .update(updateData);

      print('Background check status updated: ${report.result}');
    } catch (e) {
      throw Exception('Failed to update background check status: $e');
    }
  }

  /// Admin approves application
  Future<void> approveApplication({
    required String applicationId,
    required String adminId,
    required String adminName,
    String? note,
  }) async {
    try {
      final app = await getApplication(applicationId);
      if (app == null) throw Exception('Application not found');

      // Create service provider account
      final provider = ServiceProvider(
        id: app.applicantId,
        email: app.email,
        name: app.name,
        phoneNumber: app.phoneNumber,
        serviceCategories: app.requestedCategories,
        bio: app.bio,
        profileImageUrl: app.profileImageUrl,
        rating: 0.0,
        totalJobs: 0,
        status: ProviderStatus.offline,
        latitude: app.latitude,
        longitude: app.longitude,
        address: app.address,
        joinedDate: DateTime.now(),
        isVerified: true,
        certifications: app.licenses
            .where((l) => l.verificationStatus == LicenseVerificationStatus.verified)
            .map((l) => '${l.type} - ${l.number}')
            .toList(),
        availability: ProviderAvailability.defaultSchedule(),
      );

      // Create provider in providers collection
      await _firestore
          .collection(_providersCollection)
          .doc(provider.id)
          .set(provider.toFirestore());

      // Update application status
      final updateData = {
        'status': ApplicationStatus.approved.name,
        'reviewedAt': DateTime.now().toIso8601String(),
        'reviewedBy': adminId,
      };

      if (note != null) {
        updateData['adminNote'] = AdminNote(
          adminId: adminId,
          adminName: adminName,
          note: note,
          createdAt: DateTime.now(),
        ).toFirestore();
      }

      await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .update(updateData);

      print('Application approved: $applicationId');
    } catch (e) {
      throw Exception('Failed to approve application: $e');
    }
  }

  /// Admin rejects application
  Future<void> rejectApplication({
    required String applicationId,
    required String adminId,
    required String adminName,
    required String reason,
    String? note,
  }) async {
    try {
      final updateData = {
        'status': ApplicationStatus.rejected.name,
        'reviewedAt': DateTime.now().toIso8601String(),
        'reviewedBy': adminId,
        'rejectionReason': reason,
      };

      if (note != null) {
        updateData['adminNote'] = AdminNote(
          adminId: adminId,
          adminName: adminName,
          note: note,
          createdAt: DateTime.now(),
        ).toFirestore();
      }

      await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .update(updateData);

      print('Application rejected: $applicationId');
    } catch (e) {
      throw Exception('Failed to reject application: $e');
    }
  }

  /// Request more information from applicant
  Future<void> requestMoreInfo({
    required String applicationId,
    required String adminId,
    required String adminName,
    required String note,
  }) async {
    try {
      await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .update({
        'status': ApplicationStatus.moreInfoRequired.name,
        'adminNote': AdminNote(
          adminId: adminId,
          adminName: adminName,
          note: note,
          createdAt: DateTime.now(),
        ).toFirestore(),
      });

      print('More info requested for application: $applicationId');
    } catch (e) {
      throw Exception('Failed to request more info: $e');
    }
  }

  /// Update license verification status
  Future<void> updateLicenseStatus({
    required String applicationId,
    required int licenseIndex,
    required LicenseVerificationStatus status,
    required String adminId,
  }) async {
    try {
      final app = await getApplication(applicationId);
      if (app == null) throw Exception('Application not found');

      if (licenseIndex >= app.licenses.length) {
        throw Exception('Invalid license index');
      }

      final licenses = List<LicenseDocument>.from(app.licenses);
      final license = licenses[licenseIndex];

      // Create updated license
      final updatedLicense = LicenseDocument(
        type: license.type,
        number: license.number,
        issuingState: license.issuingState,
        issueDate: license.issueDate,
        expirationDate: license.expirationDate,
        documentUrl: license.documentUrl,
        verificationStatus: status,
        verifiedAt: status == LicenseVerificationStatus.verified
            ? DateTime.now()
            : null,
        verifiedBy: status == LicenseVerificationStatus.verified ? adminId : null,
      );

      licenses[licenseIndex] = updatedLicense;

      await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .update({
        'licenses': licenses.map((l) => l.toFirestore()).toList(),
      });

      print('License status updated for application: $applicationId');
    } catch (e) {
      throw Exception('Failed to update license status: $e');
    }
  }

  /// Add certification URL to application
  Future<void> addCertification({
    required String applicationId,
    required String certificationUrl,
  }) async {
    try {
      await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .update({
        'certificationUrls': FieldValue.arrayUnion([certificationUrl]),
      });
    } catch (e) {
      throw Exception('Failed to add certification: $e');
    }
  }

  /// Get application statistics (for admin dashboard)
  Future<Map<String, int>> getApplicationStats() async {
    try {
      final snapshot = await _firestore
          .collection(_applicationsCollection)
          .get();

      final stats = <String, int>{
        'total': snapshot.docs.length,
        'pending': 0,
        'backgroundCheckInProgress': 0,
        'backgroundCheckComplete': 0,
        'underReview': 0,
        'approved': 0,
        'rejected': 0,
        'moreInfoRequired': 0,
      };

      for (final doc in snapshot.docs) {
        final status = doc.data()['status'] as String?;
        if (status != null) {
          stats[status] = (stats[status] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting stats: $e');
      return {};
    }
  }
}
