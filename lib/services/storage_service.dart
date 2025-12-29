import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';

class StorageService {
  static const String _remindersKey = 'reminders';
  
  // Get all reminders
  static Future<List<Reminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? remindersJson = prefs.getString(_remindersKey);
    
    if (remindersJson == null || remindersJson.isEmpty) {
      return [];
    }
    
    final List<dynamic> decoded = jsonDecode(remindersJson);
    return decoded.map((json) => Reminder.fromJson(json)).toList();
  }
  
  // Save all reminders
  static Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_remindersKey, encoded);
  }
  
  // Add a reminder
  static Future<void> addReminder(Reminder reminder) async {
    final reminders = await getReminders();
    reminders.add(reminder);
    await saveReminders(reminders);
  }
  
  // Update a reminder
  static Future<void> updateReminder(Reminder reminder) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      reminders[index] = reminder;
      await saveReminders(reminders);
    }
  }
  
  // Delete a reminder
  static Future<void> deleteReminder(String id) async {
    final reminders = await getReminders();
    reminders.removeWhere((r) => r.id == id);
    await saveReminders(reminders);
  }
  
  // Toggle reminder active state
  static Future<void> toggleReminder(String id) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      reminders[index] = reminders[index].copyWith(
        isActive: !reminders[index].isActive,
      );
      await saveReminders(reminders);
    }
  }
}
