import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final VoidCallback onAttachmentPressed;

  const MessageInput({
    super.key,
    required this.onSend,
    required this.onAttachmentPressed,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: widget.onAttachmentPressed,
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (text) {
                setState(() {});
              },
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: _textController.text.trim().isEmpty
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: _textController.text.trim().isEmpty
                ? null
                : () {
                    widget.onSend(_textController.text);
                    _textController.clear();
                    setState(() {});
                  },
          ),
        ],
      ),
    );
  }
}
