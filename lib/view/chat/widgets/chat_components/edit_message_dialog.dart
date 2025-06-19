import 'package:flutter/material.dart';

Future<void> showEditMessageDialog({
  required BuildContext context,
  required String initialMessage,
  required Function(String) onSave,
}) async {
  final TextEditingController controller = TextEditingController(text: initialMessage);

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Edit Message"),
      content: TextField(
        controller: controller,
        maxLines: null,
        decoration: InputDecoration(
          hintText: "Edit your message...",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final newMessage = controller.text.trim();
            if (newMessage.isNotEmpty) {
              onSave(newMessage);
              Navigator.of(context).pop();
            }
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}
