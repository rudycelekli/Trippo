import '../../Model/service_category_model.dart';

/// AI Provider Interface
/// All AI providers must implement this interface

abstract class AIProviderInterface {
  /// Sends a message to the AI and gets a response
  Future<AIResponse> sendMessage({
    required String message,
    List<String>? imageUrls,
    required List<ChatMessage> conversationHistory,
  });

  /// Analyzes an image and provides insights
  Future<ImageAnalysisResult> analyzeImage({
    required String imageUrl,
    String? userQuestion,
  });

  /// Detects service category from user message
  Future<ServiceCategoryDetection> detectServiceCategory({
    required String message,
    List<String>? imageUrls,
  });
}

/// AI Response Model
class AIResponse {
  final String message;
  final ServiceCategoryDetection? detectedService;
  final bool isServiceRequest;

  AIResponse({
    required this.message,
    this.detectedService,
    this.isServiceRequest = false,
  });
}

/// Chat Message Model
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final List<String>? imageUrls;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    this.imageUrls,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'imageUrls': imageUrls,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'],
      content: json['content'],
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : null,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Service Category Detection Result
class ServiceCategoryDetection {
  final ServiceCategory category;
  final double confidence; // 0.0 to 1.0
  final String reasoning;
  final ServiceUrgency? suggestedUrgency;

  ServiceCategoryDetection({
    required this.category,
    required this.confidence,
    required this.reasoning,
    this.suggestedUrgency,
  });
}

/// Image Analysis Result
class ImageAnalysisResult {
  final String description;
  final ServiceCategory? suggestedCategory;
  final String diagnosis;
  final List<String> recommendations;

  ImageAnalysisResult({
    required this.description,
    this.suggestedCategory,
    required this.diagnosis,
    required this.recommendations,
  });
}
