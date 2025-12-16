import 'package:flutter/material.dart';

/// Message input field with send button
class MessageInputField extends StatefulWidget {
  final Function(String) onSend;
  final bool isSending;

  const MessageInputField({
    super.key,
    required this.onSend,
    this.isSending = false,
  });

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isSending) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          IconButton(
            onPressed: () {
              // TODO: Implement media picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Medya paylaşımı yakında eklenecek'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(
              Icons.add_circle_outline,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),

          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Mesaj yaz...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: widget.isSending
                ? Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : IconButton(
                    onPressed: _hasText ? _sendMessage : null,
                    style: IconButton.styleFrom(
                      backgroundColor: _hasText
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: Icon(
                      Icons.send_rounded,
                      color: _hasText
                          ? Colors.white
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      size: 24,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
