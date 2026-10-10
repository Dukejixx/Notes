import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../../models/note.dart';
import '../../services/notes_api.dart';

/// Estado del listado de notas con paginación incremental.
class NotesController extends ChangeNotifier {
  NotesController(this._api, {this.pageSize = 20});

  final NotesApi _api;
  final int pageSize;

  final List<Note> _notes = [];
  List<Note> get notes => List.unmodifiable(_notes);

  int _total = 0;
  int get total => _total;

  int _lastPage = 0;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _isLoading = false;

  /// Carga de la primera página (o recarga completa).
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _error;

  /// Error al cargar la primera página.
  String? get error => _error;

  String? _loadMoreError;

  /// Error al cargar páginas posteriores (el listado ya cargado se conserva).
  String? get loadMoreError => _loadMoreError;

  bool _disposed = false;

  /// Carga (o recarga) desde la primera página.
  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _notify();
    try {
      final page = await _api.fetchNotes(page: 1, limit: pageSize);
      _notes
        ..clear()
        ..addAll(page.items);
      _applyPage(page);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Carga la página siguiente si existe y no hay otra carga en curso.
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _lastPage == 0) return;
    _isLoadingMore = true;
    _loadMoreError = null;
    _notify();
    try {
      final page = await _api.fetchNotes(page: _lastPage + 1, limit: pageSize);
      // Evita duplicados si se insertaron notas entre una página y otra.
      final knownIds = _notes.map((note) => note.id).toSet();
      _notes.addAll(page.items.where((note) => !knownIds.contains(note.id)));
      _applyPage(page);
    } on ApiException catch (e) {
      _loadMoreError = e.message;
    } finally {
      _isLoadingMore = false;
      _notify();
    }
  }

  void _applyPage(NotePage page) {
    _total = page.total;
    _lastPage = page.page;
    _hasMore = page.hasMore;
    _loadMoreError = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
