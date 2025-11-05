import 'package:dio/dio.dart';
import 'ai_provider_interface.dart';
import '../../Model/service_category_model.dart';
import 'openai_provider.dart';

/// Google Gemini Provider Implementation

class GeminiProvider implements AIProviderInterface {
  final String apiKey;
  final Dio _dio;

  GeminiProvider({required this.apiKey})
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        ));

  static const String _systemPrompt = '''
You are Homzy, an AI assistant specialized in home services and home care.
Your role is to help homeowners with any questions, issues, or needs related to their homes.

SCOPE: Only discuss topics related to home maintenance, repairs, cleaning, and home improvement.
If users ask about other topics, politely redirect them to home-related matters.

Be friendly, helpful, and empathetic when analyzing home issues.
''';

  @override
  Future<AIResponse> sendMessage({
    required String message,
    List<String>? imageUrls,
    required List<ChatMessage> conversationHistory,
  }) async {
    try {
      final contents = [
        {'role': 'user', 'parts': [{'text': _systemPrompt}]},
        ...conversationHistory.map((msg) => _formatMessage(msg)),
        if (imageUrls != null && imageUrls.isNotEmpty)
          {
            'role': 'user',
            'parts': [
              {'text': message},
              ...imageUrls.map((url) => {'inlineData': {'mimeType': 'image/jpeg', 'data': url}}),
            ]
          }
        else
          {
            'role': 'user',
            'parts': [{'text': message}]
          },
      ];

      final response = await _dio.post(
        '/models/gemini-pro:generateContent',
        queryParameters: {'key': apiKey},
        data: {
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1000,
          },
        },
      );

      final aiMessage = response.data['candidates'][0]['content']['parts'][0]['text'];

      return AIResponse(
        message: aiMessage,
        detectedService: null,
        isServiceRequest: false,
      );
    } catch (e) {
      throw AIProviderException('Gemini error: $e');
    }
  }

  @override
  Future<ImageAnalysisResult> analyzeImage({
    required String imageUrl,
    String? userQuestion,
  }) async {
    try {
      final prompt = userQuestion ?? 'Analyze this image for home maintenance issues.';

      final response = await _dio.post(
        '/models/gemini-pro-vision:generateContent',
        queryParameters: {'key': apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {'inlineData': {'mimeType': 'image/jpeg', 'data': imageUrl}},
              ]
            }
          ],
        },
      );

      final result = response.data['candidates'][0]['content']['parts'][0]['text'];

      return ImageAnalysisResult(
        description: result,
        suggestedCategory: null,
        diagnosis: result,
        recommendations: [result],
      );
    } catch (e) {
      throw AIProviderException('Gemini image analysis error: $e');
    }
  }

  @override
  Future<ServiceCategoryDetection> detectServiceCategory({
    required String message,
    List<String>? imageUrls,
  }) async {
    // Gemini detection implementation
    return ServiceCategoryDetection(
      category: ServiceCategory.handyman,
      confidence: 0.8,
      reasoning: 'Gemini detection',
      suggestedUrgency: ServiceUrgency.scheduled,
    );
  }

  Map<String, dynamic> _formatMessage(ChatMessage msg) {
    return {
      'role': msg.role == 'assistant' ? 'model' : 'user',
      'parts': [
        {'text': msg.content}
      ]
    };
  }
}
