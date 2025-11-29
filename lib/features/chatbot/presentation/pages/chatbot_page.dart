import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../data/chatbot_service.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final FocusNode _focusNode = FocusNode();
  final ChatbotService _chatbotService = ChatbotService();

  List<ChatMessage> _messages = [];
  List<ChatMessage> _filteredMessages = [];
  bool _isLoading = false;
  bool _showScrollButton = false;
  bool _isSearching = false;

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<ChatMessage> _selectedMessages = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _itemPositionsListener.itemPositions.addListener(_onScroll);
    _focusNode.addListener(_onFocusChange);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    // ItemScrollController and ItemPositionsListener do not need disposal
    super.dispose();
  }

  void _onScroll() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      // Check if index 0 (bottom) is visible
      final isBottomVisible = positions.any((p) => p.index == 0);
      if (_showScrollButton == isBottomVisible) {
        // Logic inverted: show button if bottom NOT visible
        setState(() {
          _showScrollButton = !isBottomVisible;
        });
      }
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Small delay to allow keyboard to show up
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMessages = List.from(_messages);
      } else {
        _filteredMessages = _messages.where((msg) {
          // Only search user messages as requested
          return msg.isUser && msg.text.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? messagesJson = prefs.getString('chat_history');
    if (messagesJson != null) {
      final List<dynamic> decoded = jsonDecode(messagesJson);
      setState(() {
        _messages = decoded.map((e) => ChatMessage.fromJson(e)).toList();
        // Reverse for the reversed ListView
        _messages = _messages.reversed.toList();
        _filteredMessages = List.from(_messages);
      });
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    // Save in normal order (oldest first)
    final messagesToSave = _messages.reversed.toList();
    final String encoded = jsonEncode(
      messagesToSave.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('chat_history', encoded);
  }

  void _scrollToBottom() {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: 0, // 0 is the bottom because of reverse: true
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _jumpToMessage(ChatMessage message) {
    // 1. Close search
    _toggleSearch();

    // 2. Find index in the full list
    final index = _messages.indexOf(message);
    if (index != -1) {
      // 3. Scroll to that index
      // We use a small delay to allow the list to rebuild with full messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_itemScrollController.isAttached) {
          _itemScrollController.scrollTo(
            index: index,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.5, // Center the message
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    // Add new message at the start (bottom) of the list
    final newMessage = ChatMessage(text: text, isUser: true);

    setState(() {
      _messages.insert(0, newMessage);
      _filteredMessages = List.from(_messages);
      _isLoading = true;
    });
    _saveMessages();
    _scrollToBottom();

    try {
      final response = await _chatbotService.sendMessage(text);
      if (mounted) {
        setState(() {
          _messages.insert(0, ChatMessage(text: response, isUser: false));
          _filteredMessages = List.from(_messages);
          _isLoading = false;
        });
        _saveMessages();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              text: "Sorry, I encountered an error. Please try again.",
              isUser: false,
            ),
          );
          _filteredMessages = List.from(_messages);
          _isLoading = false;
        });
        _saveMessages();
        _scrollToBottom();
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredMessages = List.from(_messages);
      } else {
        // Exit selection mode if active
        _isSelectionMode = false;
        _selectedMessages.clear();
      }
    });
  }

  // Selection Logic
  void _handleMessageTap(ChatMessage message) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedMessages.contains(message)) {
          _selectedMessages.remove(message);
          if (_selectedMessages.isEmpty) {
            _isSelectionMode = false;
          }
        } else {
          _selectedMessages.add(message);
        }
      });
    } else if (_isSearching) {
      _jumpToMessage(message);
    }
  }

  void _handleMessageLongPress(ChatMessage message) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedMessages.add(message);
      });
    }
  }

  void _deleteSelectedMessages() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Messages?'),
        content: Text('Delete ${_selectedMessages.length} selected messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.removeWhere((msg) => _selectedMessages.contains(msg));
                _filteredMessages = List.from(_messages);
                _selectedMessages.clear();
                _isSelectionMode = false;
              });
              _saveMessages();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearAllChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat?'),
        content: const Text(
          'This will delete all messages. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _filteredMessages.clear();
                _selectedMessages.clear();
                _isSelectionMode = false;
              });
              _saveMessages();
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5F7), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (_isSelectionMode) ...[
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isSelectionMode = false;
                            _selectedMessages.clear();
                          });
                        },
                        icon: const Icon(Icons.close, color: Colors.black),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedMessages.length} Selected',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _deleteSelectedMessages,
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ] else ...[
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isSearching
                            ? TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Search your messages...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                                style: const TextStyle(fontSize: 18),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RiseAi',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text(
                                    'Legal & Emotional Support',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (!_isSearching)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'search') {
                              _toggleSearch();
                            } else if (value == 'clear') {
                              _clearAllChat();
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(
                              value: 'search',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Search'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'clear',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete_sweep,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Clear Chat',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        IconButton(
                          onPressed: _toggleSearch,
                          icon: const Icon(Icons.close, color: Colors.black),
                        ),
                    ],
                  ],
                ),
              ),

              // Chat List
              Expanded(
                child: Stack(
                  children: [
                    _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Say "Hello" to start chatting!',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ScrollablePositionedList.builder(
                            itemScrollController: _itemScrollController,
                            itemPositionsListener: _itemPositionsListener,
                            reverse: true, // Keep latest at bottom
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount:
                                _filteredMessages.length + (_isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_isLoading && index == 0) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              // Adjust index if loading indicator is present
                              final msgIndex = _isLoading ? index - 1 : index;
                              final message = _filteredMessages[msgIndex];
                              final isSelected = _selectedMessages.contains(
                                message,
                              );

                              return GestureDetector(
                                onTap: () => _handleMessageTap(message),
                                onLongPress: () =>
                                    _handleMessageLongPress(message),
                                child: Container(
                                  color: isSelected
                                      ? Colors.pinkAccent.withOpacity(0.1)
                                      : Colors.transparent,
                                  child: _MessageBubble(message: message),
                                ),
                              );
                            },
                          ),
                    // Scroll to Bottom Button
                    if (_showScrollButton)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white,
                          child: const Icon(
                            Icons.arrow_downward,
                            color: Colors.pinkAccent,
                          ),
                          onPressed: _scrollToBottom,
                        ),
                      ),
                  ],
                ),
              ),

              // Input Area
              if (!_isSearching && !_isSelectionMode)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.pinkAccent,
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Copyright RiseAi powered by Gemini',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});

  Map<String, dynamic> toJson() => {'text': text, 'isUser': isUser};

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('lib/assets/home page logo.png'),
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.pinkAccent : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                boxShadow: [
                  if (!message.isUser)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: message.isUser
                  ? Text(
                      message.text,
                      style: const TextStyle(color: Colors.white),
                    )
                  : MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.black87),
                      ),
                    ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.pinkAccent,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}
