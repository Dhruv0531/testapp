import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String category;
  final bool isCompleted;
  final double progress;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    this.isCompleted = false,
    this.progress = 0.0,
  });

  /// **Convert Task to a Map for Firestore**
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'duedate': Timestamp.fromDate(date), // Convert DateTime to Firestore Timestamp
      'category': category,
      'completed': isCompleted,
      'progress': progress,
    };
  }

  /// **CopyWith Method for Immutability**
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? category,
    bool? isCompleted,
    double? progress,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
    );
  }

  /// **Create a Task Object from Firestore Document**
  factory Task.fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? '',
      date: (data['duedate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: data['category'] ?? 'Other',
      isCompleted: data['completed'] ?? false,
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
