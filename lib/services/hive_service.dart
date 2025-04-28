import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_profile.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();

  factory HiveService() {
    return _instance;
  }

  HiveService._internal();

  Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      // Register adapters for all custom types
      Hive.registerAdapter(UserProfileAdapter());
      Hive.registerAdapter(WorkExperienceAdapter());
      Hive.registerAdapter(EducationAdapter());
      Hive.registerAdapter(ContactInfoAdapter());
      // Register adapters here if needed
    } catch (e) {
      print('Error initializing Hive: $e');
      rethrow;
    }
  }

  Future<Box<T>> openBox<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      print('Error opening Hive box: $e');
      rethrow;
    }
  }
}
