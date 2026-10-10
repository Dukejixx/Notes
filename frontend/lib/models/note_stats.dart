import 'api_date.dart';

/// Respuesta de `GET /api/v1/notes/stats`.
class NoteStats {
  const NoteStats({
    required this.totalNotes,
    required this.byCategory,
    required this.activity,
    required this.mostUsedCategory,
  });

  factory NoteStats.fromJson(Map<String, dynamic> json) => NoteStats(
    totalNotes: json['total_notes'] as int,
    byCategory: (json['by_category'] as List<dynamic>)
        .map((item) => CategoryStat.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    activity: (json['activity'] as List<dynamic>)
        .map((item) => DailyActivity.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    mostUsedCategory: json['most_used_category'] as String?,
  );

  final int totalNotes;
  final List<CategoryStat> byCategory;
  final List<DailyActivity> activity;
  final String? mostUsedCategory;

  bool get isEmpty => totalNotes == 0;
}

class CategoryStat {
  const CategoryStat({
    required this.category,
    required this.count,
    required this.percentage,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) => CategoryStat(
    category: json['category'] as String,
    count: json['count'] as int,
    percentage: (json['percentage'] as num).toDouble(),
  );

  final String category;
  final int count;
  final double percentage;
}

class DailyActivity {
  const DailyActivity({required this.date, required this.count});

  factory DailyActivity.fromJson(Map<String, dynamic> json) => DailyActivity(
    date: parseApiDate(json['date'] as String),
    count: json['count'] as int,
  );

  /// Día UTC al que corresponde el conteo.
  final DateTime date;
  final int count;
}
