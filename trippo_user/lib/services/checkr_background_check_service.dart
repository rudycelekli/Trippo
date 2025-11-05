import 'package:dio/dio.dart';
import 'dart:convert';

/// Checkr Background Check Service
/// Integrates with Checkr API for provider background checks
/// Documentation: https://docs.checkr.com

class CheckrBackgroundCheckService {
  final String _apiKey;
  final Dio _dio;
  static const String _baseUrl = 'https://api.checkr.com/v1';

  CheckrBackgroundCheckService({required String apiKey})
      : _apiKey = apiKey,
        _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          headers: {
            'Authorization': 'Basic ${base64Encode(utf8.encode('$apiKey:'))}',
            'Content-Type': 'application/json',
          },
        ));

  /// Create a candidate in Checkr
  /// Required before running a background check
  Future<CheckrCandidate> createCandidate({
    required String email,
    required String firstName,
    required String middleName,
    required String lastName,
    required String phone,
    required String dob, // Format: 1990-01-31
    required String ssn, // Format: 123-45-6789
    required String zipCode,
  }) async {
    try {
      final response = await _dio.post(
        '/candidates',
        data: {
          'email': email,
          'first_name': firstName,
          'middle_name': middleName,
          'last_name': lastName,
          'phone': phone,
          'dob': dob,
          'ssn': ssn,
          'zipcode': zipCode,
        },
      );

      return CheckrCandidate.fromJson(response.data);
    } catch (e) {
      throw CheckrException('Failed to create candidate: $e');
    }
  }

  /// Create a background check report
  /// Package options: 'basic', 'standard', 'professional', 'premium'
  Future<CheckrReport> createBackgroundCheck({
    required String candidateId,
    String package = 'standard',
  }) async {
    try {
      final response = await _dio.post(
        '/reports',
        data: {
          'candidate_id': candidateId,
          'package': package,
        },
      );

      return CheckrReport.fromJson(response.data);
    } catch (e) {
      throw CheckrException('Failed to create background check: $e');
    }
  }

  /// Get report status and results
  Future<CheckrReport> getReport(String reportId) async {
    try {
      final response = await _dio.get('/reports/$reportId');
      return CheckrReport.fromJson(response.data);
    } catch (e) {
      throw CheckrException('Failed to get report: $e');
    }
  }

  /// Get candidate details
  Future<CheckrCandidate> getCandidate(String candidateId) async {
    try {
      final response = await _dio.get('/candidates/$candidateId');
      return CheckrCandidate.fromJson(response.data);
    } catch (e) {
      throw CheckrException('Failed to get candidate: $e');
    }
  }

  /// List all reports for a candidate
  Future<List<CheckrReport>> getCandidateReports(String candidateId) async {
    try {
      final response = await _dio.get(
        '/reports',
        queryParameters: {'candidate_id': candidateId},
      );

      final data = response.data['data'] as List;
      return data.map((item) => CheckrReport.fromJson(item)).toList();
    } catch (e) {
      throw CheckrException('Failed to get candidate reports: $e');
    }
  }

  /// Cancel a pending report
  Future<void> cancelReport(String reportId) async {
    try {
      await _dio.delete('/reports/$reportId');
    } catch (e) {
      throw CheckrException('Failed to cancel report: $e');
    }
  }

  /// Set up webhook for real-time updates
  /// Webhook will be called when report status changes
  Future<CheckrWebhook> createWebhook({
    required String url,
    List<String> events = const ['report.completed', 'report.upgraded'],
  }) async {
    try {
      final response = await _dio.post(
        '/webhooks',
        data: {
          'url': url,
          'events': events,
        },
      );

      return CheckrWebhook.fromJson(response.data);
    } catch (e) {
      throw CheckrException('Failed to create webhook: $e');
    }
  }
}

/// Checkr Candidate Model
class CheckrCandidate {
  final String id;
  final String email;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String phone;
  final String? dob;
  final String? zipcode;
  final DateTime createdAt;

  CheckrCandidate({
    required this.id,
    required this.email,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.phone,
    this.dob,
    this.zipcode,
    required this.createdAt,
  });

  factory CheckrCandidate.fromJson(Map<String, dynamic> json) {
    return CheckrCandidate(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      dob: json['dob'],
      zipcode: json['zipcode'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Checkr Report Model
class CheckrReport {
  final String id;
  final String candidateId;
  final String status; // pending, processing, complete, disputed
  final String? result; // clear, consider, suspended
  final String package;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? reportUrl;
  final Map<String, dynamic>? screenings;

  CheckrReport({
    required this.id,
    required this.candidateId,
    required this.status,
    this.result,
    required this.package,
    required this.createdAt,
    this.completedAt,
    this.reportUrl,
    this.screenings,
  });

  factory CheckrReport.fromJson(Map<String, dynamic> json) {
    return CheckrReport(
      id: json['id'],
      candidateId: json['candidate_id'],
      status: json['status'],
      result: json['result'],
      package: json['package'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      reportUrl: json['report_url'],
      screenings: json['screenings'],
    );
  }

  bool get isComplete => status == 'complete';
  bool get isClear => result == 'clear';
  bool get needsConsideration => result == 'consider';
  bool get isSuspended => result == 'suspended';
}

/// Checkr Webhook Model
class CheckrWebhook {
  final String id;
  final String url;
  final List<String> events;
  final DateTime createdAt;

  CheckrWebhook({
    required this.id,
    required this.url,
    required this.events,
    required this.createdAt,
  });

  factory CheckrWebhook.fromJson(Map<String, dynamic> json) {
    return CheckrWebhook(
      id: json['id'],
      url: json['url'],
      events: List<String>.from(json['events']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Checkr Exception
class CheckrException implements Exception {
  final String message;
  CheckrException(this.message);

  @override
  String toString() => 'CheckrException: $message';
}
