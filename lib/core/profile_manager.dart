import 'package:shared_preferences/shared_preferences.dart';

class ProfileManager {
  static final ProfileManager _instance = ProfileManager._internal();
  factory ProfileManager() => _instance;
  ProfileManager._internal();

  static const String _imagePathKey = 'profile_image_path';
  String? _imagePath;

  String? get imagePath => _imagePath;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _imagePath = prefs.getString(_imagePathKey);
  }

  Future<void> saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imagePathKey, path);
    _imagePath = path;
  }
}
