import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:chat_application/fyrechat/fyrechat.dart' as fc;
import 'package:timeago/timeago.dart' as timeago;

String formatTime(String timestamp) {
  // Parse the timestamp into DateTime
  DateTime dateTime = DateTime.parse(timestamp);

  // Format the time into 12-hour format with AM/PM
  return DateFormat('h:mm a').format(dateTime);
}

String formatDate(String timestamp) {
  // Parse the timestamp into DateTime
  DateTime dateTime = DateTime.parse(timestamp);

  // Format the date into M/d/yyyy format
  return DateFormat('M/d/yyyy').format(dateTime);
}

String formatTimeAgo(String dateString) {
  try {
    // Correct format for "07 Jan 2025 20:38:06 PM"
    DateTime dateTime = DateFormat("dd MMM yyyy hh:mm:ss a").parse(dateString);

    // Return the relative time ago
    return timeago.format(dateTime);
  } catch (e) {
    return "";
  }
}

Color getStatusColor(String orderStatus) {
  switch (orderStatus.toLowerCase()) {
    case 'new':
      return Colors.blue; // New order
    case 'waiting':
      return Colors.orange; // Waiting for confirmation
    case 'pending':
      return Colors.amber; // Pending user confirmation
    case 'processing':
      return Colors.amber; // Pending user confirmation
    case 'confirmed':
      return Colors.green; // Order confirmed
    case 'rejected':
      return Colors.red; // Canceled by girl
    case 'user canceled':
      return Colors.redAccent; // Canceled by user
    case 'both canceled':
      return Colors.red.shade300; // Both canceled
    case 'completed':
      return Colors.teal; // Order completed
    default:
      return Colors.grey; // Unknown status
  }
}

String extractDate(DateTime dateTime) {
  // Define the format pattern for date only: "dd MMM yyyy"
  DateFormat dateFormat = DateFormat("dd MMM yyyy");
  return dateFormat.format(dateTime);
}

String extractTime(DateTime? dateTime) {
  // Define the format pattern for time only: "hh:mm a"
  try {
    DateFormat timeFormat = DateFormat("hh:mm a");
    return timeFormat.format(dateTime!);
  } catch (e) {
    return "";
  }
}

String getUserName(fc.User user) =>
    '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();

// Function to hash an email using SHA-256
String hashEmail(String email) {
  var bytes = utf8.encode(email);
  var digest = sha256.convert(bytes);
  return base64UrlEncode(digest.bytes).substring(0, 16); // Shorten to 16 chars
}

String getTimeAgo(int timestamp) {
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
  return timeago.format(dateTime);
}

String getFirebaseUserId(int laravelUserId) {
  // Convert numeric ID to a Firebase-friendly format
  return 'user_${laravelUserId.toString().padLeft(10, '0')}';
  // Example: user_0000000123
}
