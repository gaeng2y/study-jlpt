import '../../core/models/profile_settings.dart';

abstract class ProfileRepository {
  Future<int> currentStreak();
  Future<int> freezeLeft();
  Future<ProfileSettings> getSettings();
  Future<void> saveSettings(ProfileSettings settings);
}
