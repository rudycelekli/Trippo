/// Homzy App Configuration
/// This file manages all owner-configurable settings
/// Settings are stored in Firestore for real-time updates

class AppConfig {
  // AI Provider Settings
  final String openAiApiKey;
  final String claudeApiKey;
  final String geminiApiKey;
  final AIProvider defaultAiProvider;

  // Service Area Settings
  final double serviceRadiusMiles;

  // Pricing Settings
  final PricingModel pricingModel;
  final double platformCommissionPercentage;

  // Emergency Service Settings
  final bool emergencySurchargeEnabled;
  final double emergencySurchargePercentage;

  // Payment Gateway Settings
  final String stripePublishableKey;
  final String stripeSecretKey;
  final String paypalClientId;
  final String paypalSecret;

  // Calendar Settings
  final String googleCalendarClientId;
  final String googleCalendarClientSecret;

  const AppConfig({
    required this.openAiApiKey,
    required this.claudeApiKey,
    required this.geminiApiKey,
    required this.defaultAiProvider,
    required this.serviceRadiusMiles,
    required this.pricingModel,
    required this.platformCommissionPercentage,
    required this.emergencySurchargeEnabled,
    required this.emergencySurchargePercentage,
    required this.stripePublishableKey,
    required this.stripeSecretKey,
    required this.paypalClientId,
    required this.paypalSecret,
    required this.googleCalendarClientId,
    required this.googleCalendarClientSecret,
  });

  factory AppConfig.fromFirestore(Map<String, dynamic> data) {
    return AppConfig(
      openAiApiKey: data['openAiApiKey'] ?? '',
      claudeApiKey: data['claudeApiKey'] ?? '',
      geminiApiKey: data['geminiApiKey'] ?? '',
      defaultAiProvider: AIProvider.values.firstWhere(
        (e) => e.name == data['defaultAiProvider'],
        orElse: () => AIProvider.openai,
      ),
      serviceRadiusMiles: (data['serviceRadiusMiles'] ?? 15.0).toDouble(),
      pricingModel: PricingModel.values.firstWhere(
        (e) => e.name == data['pricingModel'],
        orElse: () => PricingModel.platformDefined,
      ),
      platformCommissionPercentage: (data['platformCommissionPercentage'] ?? 20.0).toDouble(),
      emergencySurchargeEnabled: data['emergencySurchargeEnabled'] ?? true,
      emergencySurchargePercentage: (data['emergencySurchargePercentage'] ?? 50.0).toDouble(),
      stripePublishableKey: data['stripePublishableKey'] ?? '',
      stripeSecretKey: data['stripeSecretKey'] ?? '',
      paypalClientId: data['paypalClientId'] ?? '',
      paypalSecret: data['paypalSecret'] ?? '',
      googleCalendarClientId: data['googleCalendarClientId'] ?? '',
      googleCalendarClientSecret: data['googleCalendarClientSecret'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'openAiApiKey': openAiApiKey,
      'claudeApiKey': claudeApiKey,
      'geminiApiKey': geminiApiKey,
      'defaultAiProvider': defaultAiProvider.name,
      'serviceRadiusMiles': serviceRadiusMiles,
      'pricingModel': pricingModel.name,
      'platformCommissionPercentage': platformCommissionPercentage,
      'emergencySurchargeEnabled': emergencySurchargeEnabled,
      'emergencySurchargePercentage': emergencySurchargePercentage,
      'stripePublishableKey': stripePublishableKey,
      'stripeSecretKey': stripeSecretKey,
      'paypalClientId': paypalClientId,
      'paypalSecret': paypalSecret,
      'googleCalendarClientId': googleCalendarClientId,
      'googleCalendarClientSecret': googleCalendarClientSecret,
    };
  }

  AppConfig copyWith({
    String? openAiApiKey,
    String? claudeApiKey,
    String? geminiApiKey,
    AIProvider? defaultAiProvider,
    double? serviceRadiusMiles,
    PricingModel? pricingModel,
    double? platformCommissionPercentage,
    bool? emergencySurchargeEnabled,
    double? emergencySurchargePercentage,
    String? stripePublishableKey,
    String? stripeSecretKey,
    String? paypalClientId,
    String? paypalSecret,
    String? googleCalendarClientId,
    String? googleCalendarClientSecret,
  }) {
    return AppConfig(
      openAiApiKey: openAiApiKey ?? this.openAiApiKey,
      claudeApiKey: claudeApiKey ?? this.claudeApiKey,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      defaultAiProvider: defaultAiProvider ?? this.defaultAiProvider,
      serviceRadiusMiles: serviceRadiusMiles ?? this.serviceRadiusMiles,
      pricingModel: pricingModel ?? this.pricingModel,
      platformCommissionPercentage: platformCommissionPercentage ?? this.platformCommissionPercentage,
      emergencySurchargeEnabled: emergencySurchargeEnabled ?? this.emergencySurchargeEnabled,
      emergencySurchargePercentage: emergencySurchargePercentage ?? this.emergencySurchargePercentage,
      stripePublishableKey: stripePublishableKey ?? this.stripePublishableKey,
      stripeSecretKey: stripeSecretKey ?? this.stripeSecretKey,
      paypalClientId: paypalClientId ?? this.paypalClientId,
      paypalSecret: paypalSecret ?? this.paypalSecret,
      googleCalendarClientId: googleCalendarClientId ?? this.googleCalendarClientId,
      googleCalendarClientSecret: googleCalendarClientSecret ?? this.googleCalendarClientSecret,
    );
  }
}

/// AI Provider Options
enum AIProvider {
  openai,
  claude,
  gemini,
}

extension AIProviderExtension on AIProvider {
  String get displayName {
    switch (this) {
      case AIProvider.openai:
        return 'OpenAI GPT-4';
      case AIProvider.claude:
        return 'Anthropic Claude';
      case AIProvider.gemini:
        return 'Google Gemini';
    }
  }
}

/// Pricing Model Options
enum PricingModel {
  platformDefined,
  providerDefined,
}

extension PricingModelExtension on PricingModel {
  String get displayName {
    switch (this) {
      case PricingModel.platformDefined:
        return 'Platform-Defined Pricing';
      case PricingModel.providerDefined:
        return 'Provider-Defined Pricing';
    }
  }

  String get description {
    switch (this) {
      case PricingModel.platformDefined:
        return 'Homzy sets standard rates for all services';
      case PricingModel.providerDefined:
        return 'Providers set their own hourly rates';
    }
  }
}
