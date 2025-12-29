import 'dart:convert';

enum RepeatType { once, daily, weekly }

class Reminder {
  final String id;
  final String title;
  final String message;
  final DateTime dateTime;
  final bool isActive;
  final RepeatType repeatType;

  Reminder({
    required this.id,
    required this.title,
    required this.message,
    required this.dateTime,
    this.isActive = true,
    this.repeatType = RepeatType.once,
  });

  // Copy with
  Reminder copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? dateTime,
    bool? isActive,
    RepeatType? repeatType,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      dateTime: dateTime ?? this.dateTime,
      isActive: isActive ?? this.isActive,
      repeatType: repeatType ?? this.repeatType,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'dateTime': dateTime.toIso8601String(),
      'isActive': isActive,
      'repeatType': repeatType.index,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      dateTime: DateTime.parse(json['dateTime']),
      isActive: json['isActive'] ?? true,
      repeatType: RepeatType.values[json['repeatType'] ?? 0],
    );
  }

  // Generate unique ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
