import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../config/app_config.dart';

/// Repository for managing App Configuration
/// Loads from Firestore with environment variable fallback

class AppConfigRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _configCollection = 'appConfig';
  static const String _configDocId = 'settings';

  /// Stream the app configuration from Firestore
  Stream<AppConfig> streamConfig() {
    return _firestore
        .collection(_configCollection)
        .doc(_configDocId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return AppConfig.fromFirestore(snapshot.data()!);
      } else {
        // Fallback to environment variables
        return _getConfigFromEnv();
      }
    });
  }

  /// Get app configuration once
  Future<AppConfig> getConfig() async {
    try {
      final doc = await _firestore
          .collection(_configCollection)
          .doc(_configDocId)
          .get();

      if (doc.exists && doc.data() != null) {
        return AppConfig.fromFirestore(doc.data()!);
      } else {
        // Fallback to environment variables
        return _getConfigFromEnv();
      }
    } catch (e) {
      print('Error loading config from Firestore: $e');
      return _getConfigFromEnv();
    }
  }

  /// Update app configuration in Firestore
  Future<void> updateConfig(AppConfig config) async {
    await _firestore
        .collection(_configCollection)
        .doc(_configDocId)
        .set(config.toFirestore(), SetOptions(merge: true));
  }

  /// Initialize default configuration in Firestore (for first-time setup)
  Future<void> initializeDefaultConfig() async {
    final doc = await _firestore
        .collection(_configCollection)
        .doc(_configDocId)
        .get();

    if (!doc.exists) {
      final defaultConfig = _getConfigFromEnv();
      await _firestore
          .collection(_configCollection)
          .doc(_configDocId)
          .set(defaultConfig.toFirestore());
    }
  }

  /// Get configuration from environment variables
  AppConfig _getConfigFromEnv() {
    return AppConfig(
      // AI Provider Settings
      openAiApiKey: dotenv.env['OPENAI_API_KEY'] ?? '',
      claudeApiKey: dotenv.env['CLAUDE_API_KEY'] ?? '',
      geminiApiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      defaultAiProvider: _parseAIProvider(
        dotenv.env['DEFAULT_AI_PROVIDER'] ?? 'openai',
      ),

      // Service Area Settings
      serviceRadiusMiles: double.tryParse(
            dotenv.env['SERVICE_RADIUS_MILES'] ?? '15',
          ) ??
          15.0,

      // Pricing Settings
      pricingModel: _parsePricingModel(
        dotenv.env['PRICING_MODEL'] ?? 'platformDefined',
      ),
      platformCommissionPercentage: double.tryParse(
            dotenv.env['PLATFORM_COMMISSION_PERCENTAGE'] ?? '20',
          ) ??
          20.0,

      // Emergency Service Settings
      emergencySurchargeEnabled:
          dotenv.env['EMERGENCY_SURCHARGE_ENABLED']?.toLowerCase() == 'true',
      emergencySurchargePercentage: double.tryParse(
            dotenv.env['EMERGENCY_SURCHARGE_PERCENTAGE'] ?? '50',
          ) ??
          50.0,

      // Payment Gateway Settings
      stripePublishableKey: dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '',
      stripeSecretKey: dotenv.env['STRIPE_SECRET_KEY'] ?? '',
      paypalClientId: dotenv.env['PAYPAL_CLIENT_ID'] ?? '',
      paypalSecret: dotenv.env['PAYPAL_SECRET'] ?? '',

      // Calendar Settings
      googleCalendarClientId: dotenv.env['GOOGLE_CALENDAR_CLIENT_ID'] ?? '',
      googleCalendarClientSecret:
          dotenv.env['GOOGLE_CALENDAR_CLIENT_SECRET'] ?? '',

      // Background Check Settings
      checkrApiKey: dotenv.env['CHECKR_API_KEY'] ?? '',
      backgroundCheckRequired:
          dotenv.env['BACKGROUND_CHECK_REQUIRED']?.toLowerCase() == 'true',
    );
  }

  AIProvider _parseAIProvider(String value) {
    try {
      return AIProvider.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => AIProvider.openai,
      );
    } catch (e) {
      return AIProvider.openai;
    }
  }

  PricingModel _parsePricingModel(String value) {
    try {
      return PricingModel.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => PricingModel.platformDefined,
      );
    } catch (e) {
      return PricingModel.platformDefined;
    }
  }
}
