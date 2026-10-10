import 'package:flutter/material.dart';

import '../../models/note.dart';
import '../../shared/formatters.dart';
import 'widgets/category_chip.dart';

/// Detalle de una nota. Usa los datos ya recibidos en el listado: la API no
/// tiene un endpoint de consulta individual.
class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wasEdited = note.updatedAt.isAfter(note.createdAt);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la nota')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryChip(category: note.category),
                const SizedBox(height: 16),
                SelectableText(
                  note.title,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Creada el ${formatDateTime(note.createdAt)}'
                  '${wasEdited ? ' · Editada el ${formatDateTime(note.updatedAt)}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const Divider(height: 32),
                SelectableText(note.content, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
