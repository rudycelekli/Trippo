import 'dart:convert';
import 'package:dio/dio.dart';
import 'ai_provider_interface.dart';
import '../../Model/service_category_model.dart';

/// OpenAI GPT-4 Provider Implementation

class OpenAIProvider implements AIProviderInterface {
  final String apiKey;
  final Dio _dio;

  OpenAIProvider({required this.apiKey})
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://api.openai.com/v1',
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ));

  static const String _systemPrompt = '''
You are Homzy, an AI assistant specialized in home services and home care.
Your role is to help homeowners with any questions, issues, or needs related to their homes.

SCOPE: Only discuss topics related to:
- Home maintenance and repairs
- Cleaning and organization
- Plumbing, electrical, HVAC systems
- Lawn care and landscaping
- Home improvement projects
- Pest control
- Appliance repairs
- General home care advice

If a user asks about topics outside of home services (politics, medical advice, etc.),
politely redirect them back to home-related topics.

When analyzing a home issue:
1. Ask clarifying questions if needed
2. Identify the type of service required
3. Determine urgency (emergency vs routine)
4. Provide helpful advice or next steps
5. Suggest booking a professional when appropriate

Be friendly, helpful, and empathetic. Remember, homeowners may be stressed about issues.
''';

  @override
  Future<AIResponse> sendMessage({
    required String message,
    List<String>? imageUrls,
    required List<ChatMessage> conversationHistory,
  }) async {
    try {
      final messages = [
        {'role': 'system', 'content': _systemPrompt},
        ...conversationHistory.map((msg) => _formatMessage(msg)),
        if (imageUrls != null && imageUrls.isNotEmpty)
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': message},
              ...imageUrls.map((url) => {
                    'type': 'image_url',
                    'image_url': {'url': url}
                  }),
            ]
          }
        else
          {'role': 'user', 'content': message},
      ];

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-4-turbo',
          'messages': messages,
          'max_tokens': 1000,
          'temperature': 0.7,
        },
      );

      final aiMessage = response.data['choices'][0]['message']['content'];

      // Detect if this is a service request
      final detection = await _detectServiceFromResponse(message, aiMessage);

      return AIResponse(
        message: aiMessage,
        detectedService: detection,
        isServiceRequest: detection != null && detection.confidence > 0.7,
      );
    } catch (e) {
      throw AIProviderException('OpenAI error: $e');
    }
  }

  @override
  Future<ImageAnalysisResult> analyzeImage({
    required String imageUrl,
    String? userQuestion,
  }) async {
    try {
      final prompt = userQuestion ??
          'Analyze this image and identify any home maintenance issues or concerns. '
              'Provide a detailed description, diagnosis, and recommendations.';

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-4-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a home inspection expert. Analyze images for home issues.'
            },
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': imageUrl}
                },
              ]
            },
          ],
          'max_tokens': 1000,
        },
      );

      final result = response.data['choices'][0]['message']['content'];

      // Parse the response to extract structured data
      return ImageAnalysisResult(
        description: result,
        suggestedCategory: _extractServiceCategory(result),
        diagnosis: result,
        recommendations: _extractRecommendations(result),
      );
    } catch (e) {
      throw AIProviderException('OpenAI image analysis error: $e');
    }
  }

  @override
  Future<ServiceCategoryDetection> detectServiceCategory({
    required String message,
    List<String>? imageUrls,
  }) async {
    try {
      final prompt = '''
Analyze this home service request and determine the most appropriate service category.
Message: "$message"

Respond with a JSON object containing:
{
  "category": "one of: cleaning, plumbing, electrical, hvac, lawnCare, homeOrganization, painting, carpentry, applianceRepair, pestControl, locksmith, handyman, roofing, flooring, windowCleaning, garageDoorRepair, poolMaintenance, moving, deepCleaning, pressureWashing",
  "confidence": 0.0-1.0,
  "reasoning": "brief explanation",
  "urgency": "onDemand or scheduled"
}
''';

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'gpt-4-turbo',
          'messages': [
            {'role': 'system', 'content': 'You are a service classification expert.'},
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
          'max_tokens': 500,
        },
      );

      final jsonResult = response.data['choices'][0]['message']['content'];
      final parsed = _parseDetectionResult(jsonResult);

      return parsed;
    } catch (e) {
      // Fallback to handyman if detection fails
      return ServiceCategoryDetection(
        category: ServiceCategory.handyman,
        confidence: 0.5,
        reasoning: 'Unable to determine specific category',
        suggestedUrgency: ServiceUrgency.scheduled,
      );
    }
  }

  Map<String, dynamic> _formatMessage(ChatMessage msg) {
    if (msg.imageUrls != null && msg.imageUrls!.isNotEmpty) {
      return {
        'role': msg.role,
        'content': [
          {'type': 'text', 'text': msg.content},
          ...msg.imageUrls!.map((url) => {
                'type': 'image_url',
                'image_url': {'url': url}
              }),
        ]
      };
    }
    return {'role': msg.role, 'content': msg.content};
  }

  Future<ServiceCategoryDetection?> _detectServiceFromResponse(
      String userMessage, String aiResponse) async {
    // Simple keyword-based detection for now
    // In production, use more sophisticated NLP
    final keywords = {
      'plumb': ServiceCategory.plumbing,
      'leak': ServiceCategory.plumbing,
      'pipe': ServiceCategory.plumbing,
      'drain': ServiceCategory.plumbing,
      'electric': ServiceCategory.electrical,
      'wire': ServiceCategory.electrical,
      'outlet': ServiceCategory.electrical,
      'light': ServiceCategory.electrical,
      'clean': ServiceCategory.cleaning,
      'hvac': ServiceCategory.hvac,
      'heat': ServiceCategory.hvac,
      'air condition': ServiceCategory.hvac,
      'lawn': ServiceCategory.lawnCare,
      'grass': ServiceCategory.lawnCare,
      'paint': ServiceCategory.painting,
    };

    final combinedText = '${userMessage.toLowerCase()} ${aiResponse.toLowerCase()}';

    for (final entry in keywords.entries) {
      if (combinedText.contains(entry.key)) {
        return ServiceCategoryDetection(
          category: entry.value,
          confidence: 0.8,
          reasoning: 'Detected from keywords: ${entry.key}',
          suggestedUrgency: ServiceUrgency.scheduled,
        );
      }
    }

    return null;
  }

  ServiceCategory? _extractServiceCategory(String text) {
    final lowerText = text.toLowerCase();

    // Map keywords to service categories
    final Map<String, ServiceCategory> categoryKeywords = {
      'plumb': ServiceCategory.plumbing,
      'leak': ServiceCategory.plumbing,
      'pipe': ServiceCategory.plumbing,
      'faucet': ServiceCategory.plumbing,
      'drain': ServiceCategory.plumbing,
      'toilet': ServiceCategory.plumbing,
      'sink': ServiceCategory.plumbing,
      'electric': ServiceCategory.electrical,
      'wire': ServiceCategory.electrical,
      'wiring': ServiceCategory.electrical,
      'outlet': ServiceCategory.electrical,
      'switch': ServiceCategory.electrical,
      'light': ServiceCategory.electrical,
      'breaker': ServiceCategory.electrical,
      'clean': ServiceCategory.cleaning,
      'dust': ServiceCategory.cleaning,
      'vacuum': ServiceCategory.cleaning,
      'mop': ServiceCategory.cleaning,
      'hvac': ServiceCategory.hvac,
      'heat': ServiceCategory.hvac,
      'air condition': ServiceCategory.hvac,
      'furnace': ServiceCategory.hvac,
      'thermostat': ServiceCategory.hvac,
      'lawn': ServiceCategory.lawnCare,
      'grass': ServiceCategory.lawnCare,
      'mow': ServiceCategory.lawnCare,
      'garden': ServiceCategory.lawnCare,
      'landscape': ServiceCategory.lawnCare,
      'paint': ServiceCategory.painting,
      'wall': ServiceCategory.painting,
      'ceiling': ServiceCategory.painting,
      'carpenter': ServiceCategory.carpentry,
      'wood': ServiceCategory.carpentry,
      'cabinet': ServiceCategory.carpentry,
      'appliance': ServiceCategory.applianceRepair,
      'refrigerator': ServiceCategory.applianceRepair,
      'dishwasher': ServiceCategory.applianceRepair,
      'washer': ServiceCategory.applianceRepair,
      'dryer': ServiceCategory.applianceRepair,
      'pest': ServiceCategory.pestControl,
      'bug': ServiceCategory.pestControl,
      'insect': ServiceCategory.pestControl,
      'rodent': ServiceCategory.pestControl,
      'termite': ServiceCategory.pestControl,
      'lock': ServiceCategory.locksmith,
      'key': ServiceCategory.locksmith,
      'door lock': ServiceCategory.locksmith,
      'roof': ServiceCategory.roofing,
      'shingle': ServiceCategory.roofing,
      'gutter': ServiceCategory.roofing,
      'floor': ServiceCategory.flooring,
      'tile': ServiceCategory.flooring,
      'carpet': ServiceCategory.flooring,
      'hardwood': ServiceCategory.flooring,
      'window': ServiceCategory.windowCleaning,
      'garage door': ServiceCategory.garageDoorRepair,
      'pool': ServiceCategory.poolMaintenance,
      'move': ServiceCategory.moving,
      'relocat': ServiceCategory.moving,
      'pressure wash': ServiceCategory.pressureWashing,
      'power wash': ServiceCategory.pressureWashing,
      'organize': ServiceCategory.homeOrganization,
      'declutter': ServiceCategory.homeOrganization,
    };

    // Find first matching keyword
    for (final entry in categoryKeywords.entries) {
      if (lowerText.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default to handyman if no specific category found
    return ServiceCategory.handyman;
  }

  List<String> _extractRecommendations(String text) {
    final recommendations = <String>[];
    final lines = text.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      // Match bullet points (-, *, •) and numbered lists (1., 2., etc.)
      if (trimmed.startsWith('-') ||
          trimmed.startsWith('*') ||
          trimmed.startsWith('•') ||
          RegExp(r'^\d+\.').hasMatch(trimmed)) {
        // Remove the bullet/number prefix
        final cleaned = trimmed
            .replaceFirst(RegExp(r'^[-*•]'), '')
            .replaceFirst(RegExp(r'^\d+\.'), '')
            .trim();
        if (cleaned.isNotEmpty) {
          recommendations.add(cleaned);
        }
      }
    }

    // If no bullet points found, return the entire text as one recommendation
    return recommendations.isEmpty ? [text] : recommendations;
  }

  ServiceCategoryDetection _parseDetectionResult(String jsonString) {
    try {
      final json = _parseJson(jsonString);
      return ServiceCategoryDetection(
        category: ServiceCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ServiceCategory.handyman,
        ),
        confidence: (json['confidence'] as num).toDouble(),
        reasoning: json['reasoning'] ?? '',
        suggestedUrgency: ServiceUrgency.values.firstWhere(
          (e) => e.name == json['urgency'],
          orElse: () => ServiceUrgency.scheduled,
        ),
      );
    } catch (e) {
      return ServiceCategoryDetection(
        category: ServiceCategory.handyman,
        confidence: 0.5,
        reasoning: 'Parse error',
        suggestedUrgency: ServiceUrgency.scheduled,
      );
    }
  }

  Map<String, dynamic> _parseJson(String jsonString) {
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // If JSON parsing fails, return empty map
      return {};
    }
  }
}

class AIProviderException implements Exception {
  final String message;
  AIProviderException(this.message);

  @override
  String toString() => message;
}
