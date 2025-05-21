import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static SharedPreferences? _sharedPreferences;

  /// Initialize SharedPreferences instance
  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  /// TO WRITE YOUR CUSTOM KEY HERE
  final String BEARER_TOKEN = "USER_TOKEN";
  final String THEME_KEY = "APP_THEME";
  final String LOCATION_KEY = "APP_LOCATION"; // Fixed the duplicate key

  /// Ensure SharedPreferences is initialized
  Future<void> _ensureInitialized() async {
    if (_sharedPreferences == null) {
      await init();
    }
  }

  // Save a string value
  Future<void> setString({required String value, required String key}) async {
    await _ensureInitialized();
    await _sharedPreferences!.setString(key, value);
  }

  // Get a string value
  Future<String> getString({required String key}) async {
    await _ensureInitialized();
    return _sharedPreferences!.getString(key) ?? "";
  }

  // Save a boolean value
  Future<void> setBool({required bool value, required String key}) async {
    await _ensureInitialized();
    await _sharedPreferences!.setBool(key, value);
  }

  // Get a boolean value
  Future<bool> getBool({required String key}) async {
    await _ensureInitialized();
    return _sharedPreferences!.getBool(key) ?? false;
  }

  // Save an integer value
  Future<void> setInt({required int value, required String key}) async {
    await _ensureInitialized();
    await _sharedPreferences!.setInt(key, value);
  }

  // Get an integer value
  Future<int> getInt({required String key}) async {
    await _ensureInitialized();
    return _sharedPreferences!.getInt(key) ?? 0;
  }

  // Save a double value
  Future<void> setDouble({required double value, required String key}) async {
    await _ensureInitialized();
    await _sharedPreferences!.setDouble(key, value);
  }

  // Get a double value
  Future<double> getDouble({required String key}) async {
    await _ensureInitialized();
    return _sharedPreferences!.getDouble(key) ?? 0.0;
  }

  // Save a list of strings
  Future<void> setStringList(
      {required List<String> value, required String key}) async {
    await _ensureInitialized();
    await _sharedPreferences!.setStringList(key, value);
  }

  // Get a list of strings
  Future<List<String>> getStringList({required String key}) async {
    await _ensureInitialized();
    return _sharedPreferences!.getStringList(key) ?? [];
  }

  // Clear data for a specific key
  Future<void> clearData({required String key}) async {
    await _ensureInitialized();
    await _sharedPreferences!.remove(key);
  }

  // Clear all data in SharedPreferences
  Future<void> clearAllData() async {
    await _ensureInitialized();
    await _sharedPreferences!.clear();
  }
}
