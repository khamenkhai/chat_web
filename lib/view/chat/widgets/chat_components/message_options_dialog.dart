import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

Future<void> showMessageOptionsDialog({
  required BuildContext context,
  required VoidCallback onEdit,
  required VoidCallback onReply,
  required VoidCallback onDelete,
  required bool isTextMessage,
}) {
  final Size size = MediaQuery.of(context).size;
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width < 600 ? 10 : 120,
        vertical: size.width < 600 ? 10 : 200,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                "Message Options",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 20),
            isTextMessage
                ? ListTile(
                    leading:
                        const Icon(IconlyBold.edit, color: Colors.blueAccent),
                    title: const Text("Edit Message"),
                    onTap: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                  )
                : Container(),
            ListTile(
              leading: const Icon(IconlyBold.send, color: Colors.green),
              title: const Text("Reply to Message"),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            ListTile(
              leading: const Icon(IconlyBold.delete, color: Colors.red),
              title: const Text("Delete Message"),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}
