import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/ai_service_factory.dart';
import '../../../../services/ai_providers/ai_provider_interface.dart';
import '../../../../config/app_config.dart';
import '../../../Widgets/service_request_dialog.dart';

/// Chat Providers for Homzy AI Chat

// Current user
final chatCurrentUserProvider = Provider<ChatUser>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return ChatUser(
    id: user?.uid ?? 'user',
    firstName: user?.displayName?.split(' ').first ?? 'User',
    lastName: user?.displayName?.split(' ').last,
  );
});

// Homzy AI user
final chatAIUserProvider = Provider<ChatUser>((ref) {
  return ChatUser(
    id: 'homzy_ai',
    firstName: 'Homzy',
    lastName: 'AI',
  );
});

// Chat messages state
final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier(ref);
});

// Typing indicator
final chatIsTypingProvider = StateProvider<bool>((ref) => false);

// Active service (if user has ongoing service)
final activeServiceProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Has active service checker
final hasActiveServiceProvider = Provider<bool>((ref) {
  return ref.watch(activeServiceProvider) != null;
});

/// Chat Messages Notifier
class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref ref;
  AIProviderInterface? _aiProvider;

  ChatMessagesNotifier(this.ref) : super([]) {
    _initializeAI();
  }

  void _initializeAI() {
    // TODO: Load config from Firestore
    // For now, use OpenAI as default
    _aiProvider = AIServiceFactory.createProvider(
      provider: AIProvider.openai,
      apiKey: 'YOUR_API_KEY_HERE', // Will be loaded from config
    );
  }

  /// Add initial greeting message
  void addGreeting() {
    final aiUser = ref.read(chatAIUserProvider);
    final greeting = ChatMessage(
      user: aiUser,
      text: '''Hi! 👋 I'm Homzy, your AI assistant for all things home.

I can help you with:
🔧 Plumbing issues
⚡ Electrical problems
🧹 Cleaning services
🌱 Lawn care
❄️ HVAC maintenance
...and much more!

What do you need help with today?''',
      createdAt: DateTime.now(),
    );

    state = [greeting, ...state];
  }

  /// Send a text message
  void sendMessage(ChatMessage message) async {
    // Add user message to chat
    state = [message, ...state];

    // Show typing indicator
    ref.read(chatIsTypingProvider.notifier).state = true;

    try {
      // Convert chat history to AI format
      final conversationHistory = state.reversed
          .map((msg) => ChatMessage(
                role: msg.user.id == 'homzy_ai' ? 'assistant' : 'user',
                content: msg.text,
                timestamp: msg.createdAt,
              ) as dynamic)
          .toList()
          .cast<ChatMessage>();

      // Send to AI provider
      final response = await _aiProvider!.sendMessage(
        message: message.text,
        conversationHistory: conversationHistory,
      );

      // Hide typing indicator
      ref.read(chatIsTypingProvider.notifier).state = false;

      // Add AI response
      final aiUser = ref.read(chatAIUserProvider);
      final aiMessage = ChatMessage(
        user: aiUser,
        text: response.message,
        createdAt: DateTime.now(),
      );

      state = [aiMessage, ...state];

      // Check if AI detected a service request
      if (response.isServiceRequest && response.detectedService != null) {
        _showServiceRequestDialog(response.detectedService!);
      }
    } catch (e) {
      ref.read(chatIsTypingProvider.notifier).state = false;

      // Show error message
      final aiUser = ref.read(chatAIUserProvider);
      final errorMessage = ChatMessage(
        user: aiUser,
        text: 'Sorry, I encountered an error. Please try again.',
        createdAt: DateTime.now(),
      );

      state = [errorMessage, ...state];
    }
  }

  /// Send quick message (from quick action chips)
  void sendQuickMessage(String text) {
    final currentUser = ref.read(chatCurrentUserProvider);
    final message = ChatMessage(
      user: currentUser,
      text: text,
      createdAt: DateTime.now(),
    );
    sendMessage(message);
  }

  /// Send image with message
  void sendImageMessage(String imagePath) async {
    // TODO: Upload image to Firebase Storage
    // For now, just send a placeholder message
    final currentUser = ref.read(chatCurrentUserProvider);
    final message = ChatMessage(
      user: currentUser,
      text: '[Image uploaded - awaiting analysis...]',
      createdAt: DateTime.now(),
    );
    sendMessage(message);
  }

  /// Clear all chat history
  void clearChat() {
    state = [];
    addGreeting();
  }

  /// Show service request dialog when AI detects a service need
  void _showServiceRequestDialog(ServiceCategoryDetection detection) {
    // This will be called from the UI layer, so context will be available
    // Store the detection for the UI to pick up
    ref.read(pendingServiceDetectionProvider.notifier).state = detection;
  }
}

// Provider for pending service detection
final pendingServiceDetectionProvider =
    StateProvider<ServiceCategoryDetection?>((ref) => null);
