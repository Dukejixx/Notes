import 'package:flutter/material.dart';

import '../../shared/widgets/status_views.dart';
import 'note_detail_screen.dart';
import 'notes_controller.dart';
import 'widgets/note_card.dart';

/// Listado de notas con desplazamiento infinito y "deslizar para recargar".
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.controller});

  final NotesController controller;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const _loadMoreThreshold = 300.0;
  final _scrollController = ScrollController();

  NotesController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (_controller.notes.isEmpty && !_controller.isLoading) {
      _controller.refresh();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Notas'),
              if (_controller.total > 0)
                Text(
                  '${_controller.total} en total',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: _controller.refresh,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading && _controller.notes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _controller.error;
    if (error != null && _controller.notes.isEmpty) {
      return ErrorView(message: error, onRetry: _controller.refresh);
    }
    if (_controller.notes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            EmptyView(
              title: 'Todavía no hay notas',
              message:
                  'Cuando se añadan notas en la base de datos aparecerán aquí.',
            ),
          ],
        ),
      );
    }

    final notes = _controller.notes;
    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: notes.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == notes.length) return _buildListFooter();
          final note = notes[index];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: NoteCard(
                note: note,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NoteDetailScreen(note: note),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListFooter() {
    final loadMoreError = _controller.loadMoreError;
    Widget child;
    if (_controller.isLoadingMore) {
      child = const CircularProgressIndicator();
    } else if (loadMoreError != null) {
      child = Column(
        children: [
          Text(loadMoreError, textAlign: TextAlign.center),
          TextButton(
            onPressed: _controller.loadMore,
            child: const Text('Reintentar'),
          ),
        ],
      );
    } else if (_controller.hasMore) {
      // Si la lista no llena la pantalla no hay desplazamiento: botón manual.
      child = OutlinedButton(
        onPressed: _controller.loadMore,
        child: const Text('Cargar más'),
      );
    } else {
      child = Text(
        'No hay más notas',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: child),
    );
  }
}
