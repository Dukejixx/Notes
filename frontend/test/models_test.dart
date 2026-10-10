import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/api_date.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/models/note_stats.dart';

import 'fakes.dart';

void main() {
  group('Fechas', () {
    test('interpreta las fechas sin zona como UTC', () {
      final parsed = parseUtcDateTime('2026-10-01T10:30:00');

      expect(parsed.toUtc(), DateTime.utc(2026, 10, 1, 10, 30));
      expect(parsed.isUtc, isFalse, reason: 'se muestra en hora local');
    });

    test('respeta una zona horaria explícita', () {
      expect(
        parseUtcDateTime('2026-10-01T10:30:00Z').toUtc(),
        DateTime.utc(2026, 10, 1, 10, 30),
      );
    });

    test('formatea las fechas como YYYY-MM-DD', () {
      expect(formatApiDate(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    });
  });

  group('NotePage', () {
    NotePage page({
      required int page,
      required int limit,
      required int total,
    }) => NotePage.fromJson({
      'items': [noteJson(1)],
      'total': total,
      'page': page,
      'limit': limit,
    });

    test('lee las notas y sus campos', () {
      final note = page(page: 1, limit: 10, total: 1).items.single;

      expect(note.id, 1);
      expect(note.title, 'Nota 1');
      expect(note.category, 'Estudio');
      expect(note.createdAt.toUtc(), DateTime.utc(2026, 10, 1, 10, 30));
    });

    test('calcula si quedan más páginas', () {
      expect(page(page: 1, limit: 10, total: 25).hasMore, isTrue);
      expect(page(page: 3, limit: 10, total: 25).hasMore, isFalse);
      expect(page(page: 1, limit: 10, total: 10).hasMore, isFalse);
    });
  });

  group('NoteStats', () {
    test('lee todas las métricas', () {
      final stats = NoteStats.fromJson(statsJson);

      expect(stats.totalNotes, 3);
      expect(stats.byCategory.first.percentage, 66.67);
      expect(stats.activity.map((day) => day.count), [2, 0, 1]);
      expect(stats.activity.first.date, DateTime(2026, 10, 1));
      expect(stats.mostUsedCategory, 'Estudio');
    });

    test('acepta la respuesta vacía', () {
      final stats = NoteStats.fromJson({
        'total_notes': 0,
        'by_category': <Object>[],
        'activity': <Object>[],
        'most_used_category': null,
      });

      expect(stats.isEmpty, isTrue);
      expect(stats.mostUsedCategory, isNull);
    });
  });
}
