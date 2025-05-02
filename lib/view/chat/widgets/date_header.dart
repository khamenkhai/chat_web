import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DateHeader extends StatelessWidget {
  final DateTime date;

  const DateHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    String text;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);

    final difference = today.difference(messageDay).inDays;

    if (difference == 0) {
      text = 'Today';
    } else if (difference == 1) {
      text = 'Yesterday';
    } else {
      text = DateFormat('MMMM dd, yyyy').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
