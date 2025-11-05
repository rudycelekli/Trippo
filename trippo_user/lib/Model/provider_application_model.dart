import 'service_category_model.dart';

/// Provider Application Model
/// Manages provider onboarding with background checks and license verification

class ProviderApplication {
  final String id;
  final String applicantId; // Firebase Auth UID
  final String email;
  final String name;
  final String phoneNumber;
  final List<ServiceCategory> requestedCategories;
  final String bio;
  final String profileImageUrl;
  final String address;
  final double latitude;
  final double longitude;

  // Background Check Information
  final BackgroundCheckStatus backgroundCheckStatus;
  final String? checkrCandidateId; // Checkr API candidate ID
  final String? checkrReportId; // Checkr API report ID
  final DateTime? backgroundCheckCompletedAt;
  final String? backgroundCheckResult; // clear, consider, suspended
  final Map<String, dynamic>? backgroundCheckDetails;

  // License & Certifications
  final List<LicenseDocument> licenses;
  final List<String> certificationUrls;

  // Application Status
  final ApplicationStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy; // Admin user ID
  final String? rejectionReason;
  final AdminNote? adminNote;

  ProviderApplication({
    required this.id,
    required this.applicantId,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.requestedCategories,
    required this.bio,
    required this.profileImageUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.backgroundCheckStatus,
    this.checkrCandidateId,
    this.checkrReportId,
    this.backgroundCheckCompletedAt,
    this.backgroundCheckResult,
    this.backgroundCheckDetails,
    required this.licenses,
    required this.certificationUrls,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.adminNote,
  });

  factory ProviderApplication.fromFirestore(Map<String, dynamic> data, String id) {
    return ProviderApplication(
      id: id,
      applicantId: data['applicantId'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      requestedCategories: (data['requestedCategories'] as List<dynamic>?)
              ?.map((e) => ServiceCategory.values.firstWhere(
                    (cat) => cat.name == e,
                    orElse: () => ServiceCategory.handyman,
                  ))
              .toList() ??
          [],
      bio: data['bio'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      backgroundCheckStatus: BackgroundCheckStatus.values.firstWhere(
        (e) => e.name == data['backgroundCheckStatus'],
        orElse: () => BackgroundCheckStatus.notStarted,
      ),
      checkrCandidateId: data['checkrCandidateId'],
      checkrReportId: data['checkrReportId'],
      backgroundCheckCompletedAt: data['backgroundCheckCompletedAt'] != null
          ? DateTime.parse(data['backgroundCheckCompletedAt'])
          : null,
      backgroundCheckResult: data['backgroundCheckResult'],
      backgroundCheckDetails: data['backgroundCheckDetails'] != null
          ? Map<String, dynamic>.from(data['backgroundCheckDetails'])
          : null,
      licenses: (data['licenses'] as List<dynamic>?)
              ?.map((e) => LicenseDocument.fromFirestore(e))
              .toList() ??
          [],
      certificationUrls: List<String>.from(data['certificationUrls'] ?? []),
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ApplicationStatus.pending,
      ),
      submittedAt: data['submittedAt'] != null
          ? DateTime.parse(data['submittedAt'])
          : DateTime.now(),
      reviewedAt: data['reviewedAt'] != null
          ? DateTime.parse(data['reviewedAt'])
          : null,
      reviewedBy: data['reviewedBy'],
      rejectionReason: data['rejectionReason'],
      adminNote: data['adminNote'] != null
          ? AdminNote.fromFirestore(data['adminNote'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'applicantId': applicantId,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'requestedCategories': requestedCategories.map((e) => e.name).toList(),
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'backgroundCheckStatus': backgroundCheckStatus.name,
      'checkrCandidateId': checkrCandidateId,
      'checkrReportId': checkrReportId,
      'backgroundCheckCompletedAt': backgroundCheckCompletedAt?.toIso8601String(),
      'backgroundCheckResult': backgroundCheckResult,
      'backgroundCheckDetails': backgroundCheckDetails,
      'licenses': licenses.map((e) => e.toFirestore()).toList(),
      'certificationUrls': certificationUrls,
      'status': status.name,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'adminNote': adminNote?.toFirestore(),
    };
  }
}

/// License Document Model
class LicenseDocument {
  final String type; // e.g., "Plumbing License", "Electrical License"
  final String number;
  final String issuingState;
  final DateTime issueDate;
  final DateTime expirationDate;
  final String documentUrl; // Firebase Storage URL
  final LicenseVerificationStatus verificationStatus;
  final DateTime? verifiedAt;
  final String? verifiedBy; // Admin user ID

  LicenseDocument({
    required this.type,
    required this.number,
    required this.issuingState,
    required this.issueDate,
    required this.expirationDate,
    required this.documentUrl,
    required this.verificationStatus,
    this.verifiedAt,
    this.verifiedBy,
  });

  factory LicenseDocument.fromFirestore(Map<String, dynamic> data) {
    return LicenseDocument(
      type: data['type'] ?? '',
      number: data['number'] ?? '',
      issuingState: data['issuingState'] ?? '',
      issueDate: DateTime.parse(data['issueDate']),
      expirationDate: DateTime.parse(data['expirationDate']),
      documentUrl: data['documentUrl'] ?? '',
      verificationStatus: LicenseVerificationStatus.values.firstWhere(
        (e) => e.name == data['verificationStatus'],
        orElse: () => LicenseVerificationStatus.pending,
      ),
      verifiedAt: data['verifiedAt'] != null
          ? DateTime.parse(data['verifiedAt'])
          : null,
      verifiedBy: data['verifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'number': number,
      'issuingState': issuingState,
      'issueDate': issueDate.toIso8601String(),
      'expirationDate': expirationDate.toIso8601String(),
      'documentUrl': documentUrl,
      'verificationStatus': verificationStatus.name,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expirationDate);
  bool get isExpiringSoon =>
      DateTime.now().add(const Duration(days: 30)).isAfter(expirationDate);
}

/// Admin Note Model
class AdminNote {
  final String adminId;
  final String adminName;
  final String note;
  final DateTime createdAt;

  AdminNote({
    required this.adminId,
    required this.adminName,
    required this.note,
    required this.createdAt,
  });

  factory AdminNote.fromFirestore(Map<String, dynamic> data) {
    return AdminNote(
      adminId: data['adminId'] ?? '',
      adminName: data['adminName'] ?? '',
      note: data['note'] ?? '',
      createdAt: DateTime.parse(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adminId': adminId,
      'adminName': adminName,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Application Status Enum
enum ApplicationStatus {
  pending,              // Submitted, waiting for review
  backgroundCheckInProgress,  // Background check initiated
  backgroundCheckComplete,    // Background check done
  underReview,          // Admin is reviewing
  approved,             // Approved, provider account created
  rejected,             // Rejected
  moreInfoRequired,     // Need additional documents
}

extension ApplicationStatusExtension on ApplicationStatus {
  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Pending Review';
      case ApplicationStatus.backgroundCheckInProgress:
        return 'Background Check in Progress';
      case ApplicationStatus.backgroundCheckComplete:
        return 'Background Check Complete';
      case ApplicationStatus.underReview:
        return 'Under Admin Review';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.moreInfoRequired:
        return 'More Information Required';
    }
  }

  String get icon {
    switch (this) {
      case ApplicationStatus.pending:
        return '⏳';
      case ApplicationStatus.backgroundCheckInProgress:
        return '🔍';
      case ApplicationStatus.backgroundCheckComplete:
        return '✅';
      case ApplicationStatus.underReview:
        return '👨‍💼';
      case ApplicationStatus.approved:
        return '🎉';
      case ApplicationStatus.rejected:
        return '❌';
      case ApplicationStatus.moreInfoRequired:
        return '📋';
    }
  }
}

/// Background Check Status Enum
enum BackgroundCheckStatus {
  notStarted,
  pending,      // Sent to Checkr
  processing,   // Checkr is processing
  completed,    // Checkr completed
  failed,       // Checkr API error
}

extension BackgroundCheckStatusExtension on BackgroundCheckStatus {
  String get displayName {
    switch (this) {
      case BackgroundCheckStatus.notStarted:
        return 'Not Started';
      case BackgroundCheckStatus.pending:
        return 'Pending';
      case BackgroundCheckStatus.processing:
        return 'Processing';
      case BackgroundCheckStatus.completed:
        return 'Completed';
      case BackgroundCheckStatus.failed:
        return 'Failed';
    }
  }
}

/// License Verification Status Enum
enum LicenseVerificationStatus {
  pending,
  verified,
  rejected,
  expired,
}

extension LicenseVerificationStatusExtension on LicenseVerificationStatus {
  String get displayName {
    switch (this) {
      case LicenseVerificationStatus.pending:
        return 'Pending Verification';
      case LicenseVerificationStatus.verified:
        return 'Verified';
      case LicenseVerificationStatus.rejected:
        return 'Rejected';
      case LicenseVerificationStatus.expired:
        return 'Expired';
    }
  }
}
