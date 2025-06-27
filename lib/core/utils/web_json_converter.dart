// web_json_converter.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

class WebJsonConverter {
  static Map<String, dynamic> toMap(dynamic json,{bool isImageMessage = false}) {
    if (json == null) {
      debugPrint('🟡 JSON input is null → returning empty map');
      return {};
    }

    if(isImageMessage){
      debugPrint("🍉 Image message");
    }
    

    if (json is Map<String, dynamic>) {
      debugPrint('✅ JSON is already a Map<String, dynamic> → $json\n\n');
      return json;
    }

    if (kIsWeb) {
      debugPrint('🌐 Running on Web platform...');
      try {
        final converted = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
        debugPrint(
            '🔁 Successfully converted JS-interop object → returning converted map');
        return converted;
      } catch (e) {
        debugPrint('❌ Web JSON conversion error: $e');
        return {};
      }
    }

    try {
      final casted = Map<String, dynamic>.from(json);
      debugPrint('🔃 Successfully casted JSON → Map<String, dynamic>');
      return casted;
    } catch (e) {
      debugPrint('❗Error casting JSON to Map<String, dynamic>: $e');
      return {};
    }
  }

  static List<T> toList<T>(dynamic json, T Function(dynamic) converter) {
    if (json == null) return [];
    if (json is List) return json.map(converter).toList();
    return [];
  }
}
