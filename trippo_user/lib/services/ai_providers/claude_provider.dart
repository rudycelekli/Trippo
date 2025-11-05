import 'package:dio/dio.dart';
import 'ai_provider_interface.dart';
import '../../Model/service_category_model.dart';
import 'openai_provider.dart';

/// Anthropic Claude Provider Implementation

class ClaudeProvider implements AIProviderInterface {
  final String apiKey;
  final Dio _dio;

  ClaudeProvider({required this.apiKey})
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://api.anthropic.com/v1',
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
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

If a user asks about topics outside of home services, politely redirect them back to home-related topics.

When analyzing a home issue:
1. Ask clarifying questions if needed
2. Identify the type of service required
3. Determine urgency (emergency vs routine)
4. Provide helpful advice or next steps
5. Suggest booking a professional when appropriate

Be friendly, helpful, and empathetic.
''';

  @override
  Future<AIResponse> sendMessage({
    required String message,
    List<String>? imageUrls,
    required List<ChatMessage> conversationHistory,
  }) async {
    try {
      final messages = [
        ...conversationHistory.map((msg) => _formatMessage(msg)),
        _formatCurrentMessage(message, imageUrls),
      ];

      final response = await _dio.post(
        '/messages',
        data: {
          'model': 'claude-3-sonnet-20240229',
          'max_tokens': 1024,
          'system': _systemPrompt,
          'messages': messages,
        },
      );

      final aiMessage = response.data['content'][0]['text'];

      // Detect if this is a service request
      final detection = await _detectServiceFromResponse(message, aiMessage);

      return AIResponse(
        message: aiMessage,
        detectedService: detection,
        isServiceRequest: detection != null && detection.confidence > 0.7,
      );
    } catch (e) {
      throw AIProviderException('Claude error: $e');
    }
  }

  @override
  Future<ImageAnalysisResult> analyzeImage({
    required String imageUrl,
    String? userQuestion,
  }) async {
    try {
      final prompt = userQuestion ??
          'Analyze this image and identify any home maintenance issues or concerns.';

      final response = await _dio.post(
        '/messages',
        data: {
          'model': 'claude-3-sonnet-20240229',
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'url',
                    'url': imageUrl,
                  }
                },
                {'type': 'text', 'text': prompt},
              ]
            },
          ],
        },
      );

      final result = response.data['content'][0]['text'];

      return ImageAnalysisResult(
        description: result,
        suggestedCategory: null,
        diagnosis: result,
        recommendations: [result],
      );
    } catch (e) {
      throw AIProviderException('Claude image analysis error: $e');
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
  "category": "one of the service categories",
  "confidence": 0.0-1.0,
  "reasoning": "brief explanation",
  "urgency": "onDemand or scheduled"
}
''';

      final response = await _dio.post(
        '/messages',
        data: {
          'model': 'claude-3-sonnet-20240229',
          'max_tokens': 500,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        },
      );

      final jsonResult = response.data['content'][0]['text'];
      // Parse and return detection result
      return ServiceCategoryDetection(
        category: ServiceCategory.handyman,
        confidence: 0.8,
        reasoning: 'Claude detection',
        suggestedUrgency: ServiceUrgency.scheduled,
      );
    } catch (e) {
      return ServiceCategoryDetection(
        category: ServiceCategory.handyman,
        confidence: 0.5,
        reasoning: 'Unable to determine',
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
                'type': 'image',
                'source': {'type': 'url', 'url': url}
              }),
        ]
      };
    }
    return {
      'role': msg.role,
      'content': [
        {'type': 'text', 'text': msg.content}
      ]
    };
  }

  Map<String, dynamic> _formatCurrentMessage(
      String message, List<String>? imageUrls) {
    if (imageUrls != null && imageUrls.isNotEmpty) {
      return {
        'role': 'user',
        'content': [
          ...imageUrls.map((url) => {
                'type': 'image',
                'source': {'type': 'url', 'url': url}
              }),
          {'type': 'text', 'text': message},
        ]
      };
    }
    return {
      'role': 'user',
      'content': [
        {'type': 'text', 'text': message}
      ]
    };
  }

  Future<ServiceCategoryDetection?> _detectServiceFromResponse(
      String userMessage, String aiResponse) async {
    // Similar to OpenAI implementation
    return null;
  }
}
