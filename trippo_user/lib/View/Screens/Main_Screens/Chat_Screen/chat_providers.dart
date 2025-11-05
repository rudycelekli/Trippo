import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart' as dash;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/ai_service_factory.dart';
import '../../../../services/ai_providers/ai_provider_interface.dart';
import '../../../../services/image_upload_service.dart';
import '../../../../config/app_config.dart';
import '../../../../Container/Repositories/app_config_repo.dart';
import '../../../../Container/Repositories/conversation_history_repo.dart';
import '../../../Widgets/service_request_dialog.dart';

/// Chat Providers for Homzy AI Chat

// App Configuration Stream
final appConfigProvider = StreamProvider<AppConfig>((ref) {
  return AppConfigRepository().streamConfig();
});

// Current user
final chatCurrentUserProvider = Provider<dash.ChatUser>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return dash.ChatUser(
    id: user?.uid ?? 'user',
    firstName: user?.displayName?.split(' ').first ?? 'User',
    lastName: user?.displayName?.split(' ').last,
  );
});

// Homzy AI user
final chatAIUserProvider = Provider<dash.ChatUser>((ref) {
  return dash.ChatUser(
    id: 'homzy_ai',
    firstName: 'Homzy',
    lastName: 'AI',
  );
});

// Chat messages state
final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, List<dash.ChatMessage>>((ref) {
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
class ChatMessagesNotifier extends StateNotifier<List<dash.ChatMessage>> {
  final Ref ref;
  AIProviderInterface? _aiProvider;
  final ConversationHistoryRepository _conversationRepo =
      ConversationHistoryRepository();

  ChatMessagesNotifier(this.ref) : super([]) {
    _initializeAI();
    _loadConversationHistory();
  }

  void _initializeAI() async {
    try {
      // Load configuration from Firestore/env
      final config = await AppConfigRepository().getConfig();

      // Create AI provider based on config
      String apiKey;
      switch (config.defaultAiProvider) {
        case AIProvider.openai:
          apiKey = config.openAiApiKey;
          break;
        case AIProvider.claude:
          apiKey = config.claudeApiKey;
          break;
        case AIProvider.gemini:
          apiKey = config.geminiApiKey;
          break;
      }

      if (apiKey.isEmpty) {
        print('Warning: No API key configured for ${config.defaultAiProvider.displayName}');
        return;
      }

      _aiProvider = AIServiceFactory.createProvider(
        provider: config.defaultAiProvider,
        apiKey: apiKey,
      );

      print('AI provider initialized: ${config.defaultAiProvider.displayName}');
    } catch (e) {
      print('Error initializing AI provider: $e');
    }
  }

  /// Load conversation history from Firestore
  void _loadConversationHistory() async {
    try {
      final messages = await _conversationRepo.getMessages(limit: 100);

      if (messages.isEmpty) {
        // No history, show greeting
        addGreeting();
        return;
      }

      // Convert Firestore messages to DashChat messages
      final currentUser = ref.read(chatCurrentUserProvider);
      final aiUser = ref.read(chatAIUserProvider);

      final dashMessages = messages.map((msg) {
        final user = msg.senderId == 'homzy_ai' ? aiUser : currentUser;

        // Convert image URLs to ChatMedia if present
        List<dash.ChatMedia>? medias;
        if (msg.imageUrls != null && msg.imageUrls!.isNotEmpty) {
          medias = msg.imageUrls!
              .map((url) => dash.ChatMedia(
                    url: url,
                    fileName: 'image',
                    type: dash.MediaType.image,
                  ))
              .toList();
        }

        return dash.ChatMessage(
          user: user,
          text: msg.text,
          createdAt: msg.timestamp,
          medias: medias,
        );
      }).toList();

      state = dashMessages;
      print('Loaded ${dashMessages.length} messages from history');
    } catch (e) {
      print('Error loading conversation history: $e');
      // If loading fails, show greeting
      addGreeting();
    }
  }

  /// Save a message to Firestore
  Future<void> _saveMessageToFirestore(dash.ChatMessage message) async {
    try {
      // Extract image URLs if present
      List<String>? imageUrls;
      if (message.medias != null && message.medias!.isNotEmpty) {
        imageUrls = message.medias!
            .where((media) => media.type == dash.MediaType.image)
            .map((media) => media.url)
            .toList();
      }

      final conversationMessage = ConversationMessage(
        id: '${message.user.id}_${message.createdAt.millisecondsSinceEpoch}',
        senderId: message.user.id,
        senderName: message.user.firstName ?? '',
        text: message.text,
        timestamp: message.createdAt,
        imageUrls: imageUrls,
      );

      await _conversationRepo.saveMessage(conversationMessage);
    } catch (e) {
      print('Error saving message to Firestore: $e');
    }
  }

  /// Add initial greeting message
  void addGreeting() async {
    final aiUser = ref.read(chatAIUserProvider);
    final greeting = dash.ChatMessage(
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

    // Save greeting to Firestore
    await _saveMessageToFirestore(greeting);
  }

  /// Send a text message
  void sendMessage(dash.ChatMessage message) async {
    // Add user message to chat
    state = [message, ...state];

    // Save user message to Firestore
    await _saveMessageToFirestore(message);

    // Show typing indicator
    ref.read(chatIsTypingProvider.notifier).state = true;

    try {
      if (_aiProvider == null) {
        throw Exception('AI provider not initialized. Please check your API key configuration.');
      }

      // Extract image URLs from message if any
      List<String>? imageUrls;
      if (message.medias != null && message.medias!.isNotEmpty) {
        imageUrls = message.medias!
            .where((media) => media.type == dash.MediaType.image)
            .map((media) => media.url)
            .toList();
      }

      // Convert chat history to AI format
      final conversationHistory = state.reversed
          .map((msg) {
            // Extract image URLs from each message
            List<String>? msgImages;
            if (msg.medias != null && msg.medias!.isNotEmpty) {
              msgImages = msg.medias!
                  .where((media) => media.type == dash.MediaType.image)
                  .map((media) => media.url)
                  .toList();
            }

            return ChatMessage(
              role: msg.user.id == 'homzy_ai' ? 'assistant' : 'user',
              content: msg.text,
              imageUrls: msgImages,
              timestamp: msg.createdAt,
            );
          })
          .toList();

      // Send to AI provider
      final response = await _aiProvider!.sendMessage(
        message: message.text,
        imageUrls: imageUrls,
        conversationHistory: conversationHistory,
      );

      // Hide typing indicator
      ref.read(chatIsTypingProvider.notifier).state = false;

      // Add AI response
      final aiUser = ref.read(chatAIUserProvider);
      final aiMessage = dash.ChatMessage(
        user: aiUser,
        text: response.message,
        createdAt: DateTime.now(),
      );

      state = [aiMessage, ...state];

      // Save AI response to Firestore
      await _saveMessageToFirestore(aiMessage);

      // Check if AI detected a service request
      if (response.isServiceRequest && response.detectedService != null) {
        _showServiceRequestDialog(response.detectedService!);
      }
    } catch (e) {
      ref.read(chatIsTypingProvider.notifier).state = false;

      // Show error message
      final aiUser = ref.read(chatAIUserProvider);
      final errorMessage = dash.ChatMessage(
        user: aiUser,
        text: 'Sorry, I encountered an error: ${e.toString()}\n\nPlease check your API key configuration or try again.',
        createdAt: DateTime.now(),
      );

      state = [errorMessage, ...state];

      // Save error message to Firestore
      await _saveMessageToFirestore(errorMessage);

      print('Error sending message to AI: $e');
    }
  }

  /// Send quick message (from quick action chips)
  void sendQuickMessage(String text) {
    final currentUser = ref.read(chatCurrentUserProvider);
    final message = dash.ChatMessage(
      user: currentUser,
      text: text,
      createdAt: DateTime.now(),
    );
    sendMessage(message);
  }

  /// Send image with message
  void sendImageMessage(String imagePath) async {
    try {
      // Upload image to Firebase Storage
      final ImageUploadService uploadService = ImageUploadService();
      final downloadUrl = await uploadService.uploadChatImage(imagePath);

      // Send message with image - the AI will analyze it automatically
      final currentUser = ref.read(chatCurrentUserProvider);
      final message = dash.ChatMessage(
        user: currentUser,
        text: 'Can you help me with this issue?',
        createdAt: DateTime.now(),
        medias: [
          dash.ChatMedia(
            url: downloadUrl,
            fileName: 'image',
            type: dash.MediaType.image,
          ),
        ],
      );

      sendMessage(message);
    } catch (e) {
      // Show error
      final aiUser = ref.read(chatAIUserProvider);
      final errorMessage = dash.ChatMessage(
        user: aiUser,
        text: 'Sorry, I couldn\'t process that image. Please try again.\n\nError: ${e.toString()}',
        createdAt: DateTime.now(),
      );
      state = [errorMessage, ...state];
      print('Error uploading image: $e');
    }
  }

  /// Clear all chat history
  void clearChat() async {
    // Clear local state
    state = [];

    // Clear Firestore history
    await _conversationRepo.clearHistory();

    // Add new greeting
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
