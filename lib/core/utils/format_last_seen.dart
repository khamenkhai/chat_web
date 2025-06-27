 import 'package:easy_localization/easy_localization.dart';
 import 'package:timeago/timeago.dart' as timeago;

String formatLastSeen(int? lastSeen) {
    if (lastSeen == null) return "Last seen: unknown";

    try {
      final lastSeenDate = DateTime.fromMillisecondsSinceEpoch(lastSeen);
      final formattedTime =
          DateFormat.jm().format(lastSeenDate); // e.g., 5:20 PM
      final timeAgo = timeago.format(lastSeenDate); // e.g., 5 minutes ago
      return "Last seen $timeAgo at $formattedTime";
    } catch (e) {
      return "Last seen: invalid date";
    }
  }