import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Repository for managing conversation history
/// Stores all chat messages in Firestore for persistence

class ConversationHistoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _conversationsCollection = 'conversations';
  static const String _messagesSubcollection = 'messages';

  /// Get the current user's conversation ID
  String? _getCurrentConversationId() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    // Each user has one active conversation
    return 'conv_$userId';
  }

  /// Stream all messages for the current user
  Stream<List<ConversationMessage>> streamMessages() {
    final conversationId = _getCurrentConversationId();
    if (conversationId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConversationMessage.fromFirestore(doc.data()))
          .toList();
    });
  }

  /// Get messages once (for initial load)
  Future<List<ConversationMessage>> getMessages({int limit = 100}) async {
    final conversationId = _getCurrentConversationId();
    if (conversationId == null) return [];

    try {
      final snapshot = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesSubcollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ConversationMessage.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Error loading conversation history: $e');
      return [];
    }
  }

  /// Save a new message
  Future<void> saveMessage(ConversationMessage message) async {
    final conversationId = _getCurrentConversationId();
    if (conversationId == null) return;

    try {
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesSubcollection)
          .doc(message.id)
          .set(message.toFirestore());

      // Update conversation metadata
      await _updateConversationMetadata(conversationId, message);
    } catch (e) {
      print('Error saving message: $e');
    }
  }

  /// Update conversation metadata (last message, timestamp, etc.)
  Future<void> _updateConversationMetadata(
    String conversationId,
    ConversationMessage lastMessage,
  ) async {
    await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .set({
      'userId': _auth.currentUser?.uid,
      'lastMessage': lastMessage.text,
      'lastMessageTimestamp': lastMessage.timestamp.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// Clear all messages in the current conversation
  Future<void> clearHistory() async {
    final conversationId = _getCurrentConversationId();
    if (conversationId == null) return;

    try {
      // Get all message documents
      final snapshot = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesSubcollection)
          .get();

      // Delete all messages in batches
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Update conversation metadata
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .set({
        'userId': _auth.currentUser?.uid,
        'clearedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      print('Conversation history cleared');
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  /// Delete old messages (keep only last N messages)
  Future<void> pruneOldMessages({int keepCount = 1000}) async {
    final conversationId = _getCurrentConversationId();
    if (conversationId == null) return;

    try {
      // Get all messages ordered by timestamp
      final snapshot = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesSubcollection)
          .orderBy('timestamp', descending: true)
          .get();

      // If we have more than keepCount messages, delete the old ones
      if (snapshot.docs.length > keepCount) {
        final docsToDelete = snapshot.docs.skip(keepCount);
        final batch = _firestore.batch();

        for (final doc in docsToDelete) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        print('Pruned ${docsToDelete.length} old messages');
      }
    } catch (e) {
      print('Error pruning old messages: $e');
    }
  }
}

/// Conversation Message Model
class ConversationMessage {
  final String id;
  final String senderId; // 'user' or 'homzy_ai'
  final String senderName;
  final String text;
  final DateTime timestamp;
  final List<String>? imageUrls;

  ConversationMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.imageUrls,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'imageUrls': imageUrls,
    };
  }

  factory ConversationMessage.fromFirestore(Map<String, dynamic> data) {
    return ConversationMessage(
      id: data['id'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      text: data['text'] ?? '',
      timestamp: DateTime.parse(data['timestamp']),
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : null,
    );
  }
}
