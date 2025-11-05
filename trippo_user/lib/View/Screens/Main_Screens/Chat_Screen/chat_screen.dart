import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:image_picker/image_picker.dart';
import 'chat_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../Routes/routes.dart';

/// Homzy AI Chat Screen
/// Main interface where users interact with the AI assistant

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize chat with greeting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatMessagesProvider.notifier).addGreeting();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final currentUser = ref.watch(chatCurrentUserProvider);
    final homzyAI = ref.watch(chatAIUserProvider);
    final isTyping = ref.watch(chatIsTypingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.home_outlined, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Homzy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Your AI Home Assistant',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Service Dashboard Button
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            onPressed: () {
              context.pushNamed(Routes().serviceDashboard);
            },
            tooltip: 'My Services',
          ),
          // Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF2C2C2C),
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _showClearChatDialog();
                  break;
                case 'settings':
                  // Navigate to settings
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.white70),
                    SizedBox(width: 12),
                    Text('Clear Chat', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.white70),
                    SizedBox(width: 12),
                    Text('Settings', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Active Service Banner (if any)
          _buildActiveServiceBanner(),

          // Chat Interface
          Expanded(
            child: DashChat(
              currentUser: currentUser,
              messages: messages,
              onSend: (ChatMessage message) {
                ref.read(chatMessagesProvider.notifier).sendMessage(message);
              },
              typingUsers: isTyping ? [homzyAI] : [],
              messageOptions: MessageOptions(
                currentUserContainerColor: const Color(0xFF2196F3),
                currentUserTextColor: Colors.white,
                containerColor: const Color(0xFF2C2C2C),
                textColor: Colors.white,
                showTime: true,
                avatarBuilder: (user, onAvatarTap, onAvatarLongPress) {
                  if (user.id == homzyAI.id) {
                    return Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(17.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.home_outlined,
                            color: Colors.white, size: 18),
                      ),
                    );
                  }
                  return Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(17.5),
                    ),
                    child: Center(
                      child: Text(
                        user.firstName?[0].toUpperCase() ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
              inputOptions: InputOptions(
                inputDecoration: InputDecoration(
                  hintText: 'Ask me about your home...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                inputTextStyle: const TextStyle(color: Colors.white),
                trailing: [
                  // Image picker button
                  IconButton(
                    icon: const Icon(Icons.image, color: Colors.grey),
                    onPressed: _pickImage,
                  ),
                ],
              ),
            ),
          ),

          // Quick Actions (when no active service)
          if (!ref.watch(hasActiveServiceProvider))
            _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildActiveServiceBanner() {
    final activeService = ref.watch(activeServiceProvider);

    if (activeService == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeService['status'] ?? 'In Progress',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  activeService['providerName'] ?? 'Service Provider',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  activeService['category'] ?? 'Home Service',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.pushNamed(Routes().trackingMap,
                  extra: activeService['requestId']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Track'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _quickActionChip('🔧 Plumbing', 'I need a plumber'),
                _quickActionChip('⚡ Electrical', 'I need an electrician'),
                _quickActionChip('🧹 Cleaning', 'I need cleaning service'),
                _quickActionChip('🌱 Lawn Care', 'I need lawn maintenance'),
                _quickActionChip('❄️ HVAC', 'My AC needs service'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionChip(String label, String message) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        backgroundColor: const Color(0xFF2C2C2C),
        labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
        onPressed: () {
          ref.read(chatMessagesProvider.notifier).sendQuickMessage(message);
        },
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Upload image and send with message
        ref.read(chatMessagesProvider.notifier).sendImageMessage(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Clear Chat?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete all conversation history. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(chatMessagesProvider.notifier).clearChat();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
