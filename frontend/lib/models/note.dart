import 'api_date.dart';

/// Nota tal como la devuelve `GET /api/v1/notes`.
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as int,
    title: json['title'] as String,
    content: json['content'] as String,
    category: json['category'] as String,
    createdAt: parseUtcDateTime(json['created_at'] as String),
    updatedAt: parseUtcDateTime(json['updated_at'] as String),
  );

  final int id;
  final String title;
  final String content;
  final String category;

  /// Fecha de creación en hora local.
  final DateTime createdAt;

  /// Fecha de la última modificación en hora local.
  final DateTime updatedAt;
}

/// Página de notas con los datos de paginación.
class NotePage {
  const NotePage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory NotePage.fromJson(Map<String, dynamic> json) => NotePage(
    items: (json['items'] as List<dynamic>)
        .map((item) => Note.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    total: json['total'] as int,
    page: json['page'] as int,
    limit: json['limit'] as int,
  );

  final List<Note> items;
  final int total;
  final int page;
  final int limit;

  /// Indica si existen más notas después de esta página.
  bool get hasMore => page * limit < total;
}
