// routines_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsgg_app/theme/app_theme.dart';
import 'package:gymsgg_app/models/routine_model.dart';
import 'package:gymsgg_app/services/user_service.dart';

class RoutinesListScreen extends StatefulWidget {
  static const String routeName = '/routines-list';

  const RoutinesListScreen({super.key});

  @override
  State<RoutinesListScreen> createState() => _RoutinesListScreenState();
}

class _RoutinesListScreenState extends State<RoutinesListScreen> {
  List<Routine> _routines = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Todas';

  final List<String> _filterOptions = [
    'Todas',
    'Principiante',
    'Intermedio',
    'Avanzado',
  ];

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    try {
      setState(() => _isLoading = true);

      final routines = await UserService.getUserRoutines();

      if (mounted) {
        setState(() {
          _routines = routines;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar rutinas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Routine> get _filteredRoutines {
    List<Routine> filtered = _routines;

    // Filtrar por nivel
    if (_selectedFilter != 'Todas') {
      filtered =
          filtered
              .where(
                (routine) =>
                    routine.level.toLowerCase() ==
                    _selectedFilter.toLowerCase(),
              )
              .toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (routine) =>
                    routine.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    routine.level.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    routine.difficulty.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    return filtered;
  }

  Future<void> _deleteRoutine(Routine routine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: const Text(
              'Eliminar Rutina',
              style: TextStyle(color: AppTheme.iconColor),
            ),
            content: Text(
              '¿Estás seguro de que quieres eliminar "${routine.name}"?',
              style: const TextStyle(color: AppTheme.textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('routines')
            .doc(routine.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Rutina eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadRoutines(); // Recargar la lista
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.foundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchAndFilter(),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildRoutinesList(),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createNewRoutine,
          backgroundColor: AppTheme.accentColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppTheme.iconColor,
              size: 24,
            ),
          ),
          const Expanded(
            child: Text(
              'Mis Rutinas',
              style: TextStyle(
                color: AppTheme.iconColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _loadRoutines,
            icon: const Icon(
              Icons.refresh,
              color: AppTheme.accentColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Barra de búsqueda
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: AppTheme.iconColor),
              decoration: const InputDecoration(
                hintText: 'Buscar rutinas...',
                hintStyle: TextStyle(color: AppTheme.textColor),
                prefixIcon: Icon(Icons.search, color: AppTheme.accentColor),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Filtros
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                    backgroundColor: Colors.transparent,
                    selectedColor: AppTheme.accentColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.accentColor,
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? AppTheme.accentColor
                              : AppTheme.textColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color:
                          isSelected
                              ? AppTheme.accentColor
                              : AppTheme.textColor.withOpacity(0.3),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRoutinesList() {
    final filteredRoutines = _filteredRoutines;

    if (filteredRoutines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _routines.isEmpty ? Icons.fitness_center : Icons.search_off,
              size: 64,
              color: AppTheme.textColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _routines.isEmpty
                  ? 'No tienes rutinas creadas'
                  : 'No se encontraron rutinas',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _routines.isEmpty
                  ? 'Crea tu primera rutina presionando el botón +'
                  : 'Intenta con otros términos de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredRoutines.length,
      itemBuilder: (context, index) {
        final routine = filteredRoutines[index];
        return _buildRoutineCard(routine);
      },
    );
  }

  Widget _buildRoutineCard(Routine routine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToRoutineDetails(routine),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: AppTheme.accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routine.name,
                            style: const TextStyle(
                              color: AppTheme.iconColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${routine.level} • ${routine.difficulty}',
                            style: TextStyle(
                              color: AppTheme.textColor.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppTheme.textColor,
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteRoutine(routine);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(Icons.access_time, routine.duration),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.repeat,
                      '${routine.exercises.length} ejercicios',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Creado: ${_formatDate(routine.createdAt)}',
                  style: TextStyle(
                    color: AppTheme.textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.accentColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToRoutineDetails(Routine routine) {
    Navigator.pushNamed(
      context,
      '/routine-details',
      arguments: {
        'routineId': routine.id,
        'routineName': routine.name,
        'level': routine.level,
        'difficulty': routine.difficulty,
        'fitnessLevel': routine.level,
      },
    );
  }

  void _createNewRoutine() {
    Navigator.pushNamed(
      context,
      '/routine-details',
      arguments: {
        'routineId': '',
        'routineName': 'Nueva Rutina',
        'level': 'beginner',
        'difficulty': 'medium',
        'fitnessLevel': 'beginner',
      },
    );
  }
}
