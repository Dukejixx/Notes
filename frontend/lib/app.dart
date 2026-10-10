import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/notes/notes_controller.dart';
import 'features/notes/notes_screen.dart';
import 'features/stats/stats_controller.dart';
import 'features/stats/stats_screen.dart';
import 'services/notes_api.dart';

class NotesApp extends StatelessWidget {
  const NotesApp({super.key, required this.api});

  final NotesApi api;

  @override
  Widget build(BuildContext context) {
    const seed = Colors.indigo;
    return MaterialApp(
      title: 'Notas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeShell(api: api),
    );
  }
}

/// Navegación principal: barra inferior en pantallas estrechas y barra
/// lateral en pantallas anchas. Mantiene el estado de cada sección.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.api});

  final NotesApi api;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _railMinWidth = 720.0;

  late final NotesController _notesController = NotesController(widget.api);
  late final StatsController _statsController = StatsController(widget.api);
  int _selectedIndex = 0;

  @override
  void dispose() {
    _notesController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = IndexedStack(
      index: _selectedIndex,
      children: [
        NotesScreen(controller: _notesController),
        StatsScreen(controller: _statsController),
      ],
    );

    if (MediaQuery.sizeOf(context).width >= _railMinWidth) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.sticky_note_2_outlined),
                  selectedIcon: Icon(Icons.sticky_note_2),
                  label: Text('Notas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: Text('Estadísticas'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages),
          ],
        ),
      );
    }

    return Scaffold(
      body: pages,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2),
            label: 'Notas',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Estadísticas',
          ),
        ],
      ),
    );
  }

  void _select(int index) => setState(() => _selectedIndex = index);
}
