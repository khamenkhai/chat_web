import 'package:flutter/material.dart';

void showMaterialSnackBar(BuildContext context, String message) {
  final snackBar = _MaterialSnackBar(message: message);

  // Show the snackbar using the ScaffoldMessenger
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: snackBar,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: const EdgeInsets.only(bottom: 25),
      // behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

class _MaterialSnackBar extends StatelessWidget {
  final String message;

  const _MaterialSnackBar({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(25), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset:const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message,
          style:const TextStyle(
            color: Colors.white, // White text
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

