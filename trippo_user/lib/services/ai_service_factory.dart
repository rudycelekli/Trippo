import '../config/app_config.dart';
import 'ai_providers/ai_provider_interface.dart';
import 'ai_providers/openai_provider.dart';
import 'ai_providers/claude_provider.dart';
import 'ai_providers/gemini_provider.dart';

/// AI Service Factory
/// Creates the appropriate AI provider based on app configuration

class AIServiceFactory {
  static AIProviderInterface createProvider({
    required AIProvider provider,
    required String apiKey,
  }) {
    switch (provider) {
      case AIProvider.openai:
        return OpenAIProvider(apiKey: apiKey);
      case AIProvider.claude:
        return ClaudeProvider(apiKey: apiKey);
      case AIProvider.gemini:
        return GeminiProvider(apiKey: apiKey);
    }
  }
}
