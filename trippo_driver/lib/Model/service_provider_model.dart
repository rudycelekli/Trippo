import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_category_model.dart';

/// Service Provider Model
/// Replaces the Driver model for home service providers

class ServiceProvider {
  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final List<ServiceCategory> serviceCategories;
  final String bio;
  final String profileImageUrl;
  final double rating;
  final int totalJobs;
  final ProviderStatus status;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime joinedDate;
  final bool isVerified;
  final List<String> certifications;
  final Map<ServiceCategory, double>? customRates; // null if platform-defined
  final ProviderAvailability availability;

  ServiceProvider({
    required this.id,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.serviceCategories,
    required this.bio,
    required this.profileImageUrl,
    required this.rating,
    required this.totalJobs,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.joinedDate,
    required this.isVerified,
    required this.certifications,
    this.customRates,
    required this.availability,
  });

  factory ServiceProvider.fromFirestore(Map<String, dynamic> data, String id) {
    return ServiceProvider(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      serviceCategories: (data['serviceCategories'] as List<dynamic>?)
              ?.map((e) => ServiceCategory.values.firstWhere(
                    (cat) => cat.name == e,
                    orElse: () => ServiceCategory.handyman,
                  ))
              .toList() ??
          [],
      bio: data['bio'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalJobs: data['totalJobs'] ?? 0,
      status: ProviderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ProviderStatus.offline,
      ),
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      joinedDate: data['joinedDate'] != null
          ? DateTime.parse(data['joinedDate'])
          : DateTime.now(),
      isVerified: data['isVerified'] ?? false,
      certifications: List<String>.from(data['certifications'] ?? []),
      customRates: data['customRates'] != null
          ? (data['customRates'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                ServiceCategory.values.firstWhere((e) => e.name == key),
                (value as num).toDouble(),
              ),
            )
          : null,
      availability: ProviderAvailability.fromFirestore(
          data['availability'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'serviceCategories': serviceCategories.map((e) => e.name).toList(),
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'totalJobs': totalJobs,
      'status': status.name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'joinedDate': joinedDate.toIso8601String(),
      'isVerified': isVerified,
      'certifications': certifications,
      'customRates': customRates?.map((key, value) => MapEntry(key.name, value)),
      'availability': availability.toFirestore(),
    };
  }

  ServiceProvider copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    List<ServiceCategory>? serviceCategories,
    String? bio,
    String? profileImageUrl,
    double? rating,
    int? totalJobs,
    ProviderStatus? status,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? joinedDate,
    bool? isVerified,
    List<String>? certifications,
    Map<ServiceCategory, double>? customRates,
    ProviderAvailability? availability,
  }) {
    return ServiceProvider(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      serviceCategories: serviceCategories ?? this.serviceCategories,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rating: rating ?? this.rating,
      totalJobs: totalJobs ?? this.totalJobs,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      joinedDate: joinedDate ?? this.joinedDate,
      isVerified: isVerified ?? this.isVerified,
      certifications: certifications ?? this.certifications,
      customRates: customRates ?? this.customRates,
      availability: availability ?? this.availability,
    );
  }
}

enum ProviderStatus {
  online,
  offline,
  busy,
  idle,
}

extension ProviderStatusExtension on ProviderStatus {
  String get displayName {
    switch (this) {
      case ProviderStatus.online:
        return 'Online';
      case ProviderStatus.offline:
        return 'Offline';
      case ProviderStatus.busy:
        return 'Busy';
      case ProviderStatus.idle:
        return 'Idle';
    }
  }
}

/// Provider Availability Model
class ProviderAvailability {
  final Map<int, DayAvailability> weeklySchedule; // Key: 1-7 (Mon-Sun)
  final List<DateTimeRange> blockedSlots;

  ProviderAvailability({
    required this.weeklySchedule,
    required this.blockedSlots,
  });

  factory ProviderAvailability.fromFirestore(Map<String, dynamic> data) {
    return ProviderAvailability(
      weeklySchedule: (data['weeklySchedule'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              int.parse(key),
              DayAvailability.fromFirestore(value),
            ),
          ) ??
          {},
      blockedSlots: (data['blockedSlots'] as List<dynamic>?)
              ?.map((e) => DateTimeRange(
                    start: DateTime.parse(e['start']),
                    end: DateTime.parse(e['end']),
                  ))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'weeklySchedule': weeklySchedule.map(
        (key, value) => MapEntry(key.toString(), value.toFirestore()),
      ),
      'blockedSlots': blockedSlots
          .map((e) => {
                'start': e.start.toIso8601String(),
                'end': e.end.toIso8601String(),
              })
          .toList(),
    };
  }

  factory ProviderAvailability.defaultSchedule() {
    return ProviderAvailability(
      weeklySchedule: {
        1: DayAvailability(isAvailable: true, startTime: '09:00', endTime: '17:00'),
        2: DayAvailability(isAvailable: true, startTime: '09:00', endTime: '17:00'),
        3: DayAvailability(isAvailable: true, startTime: '09:00', endTime: '17:00'),
        4: DayAvailability(isAvailable: true, startTime: '09:00', endTime: '17:00'),
        5: DayAvailability(isAvailable: true, startTime: '09:00', endTime: '17:00'),
        6: DayAvailability(isAvailable: false, startTime: '09:00', endTime: '17:00'),
        7: DayAvailability(isAvailable: false, startTime: '09:00', endTime: '17:00'),
      },
      blockedSlots: [],
    );
  }
}

class DayAvailability {
  final bool isAvailable;
  final String startTime; // Format: "HH:mm"
  final String endTime; // Format: "HH:mm"

  DayAvailability({
    required this.isAvailable,
    required this.startTime,
    required this.endTime,
  });

  factory DayAvailability.fromFirestore(Map<String, dynamic> data) {
    return DayAvailability(
      isAvailable: data['isAvailable'] ?? false,
      startTime: data['startTime'] ?? '09:00',
      endTime: data['endTime'] ?? '17:00',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isAvailable': isAvailable,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}
