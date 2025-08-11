// history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymsgg_app/theme/app_theme.dart';
import 'package:gymsgg_app/services/user_service.dart';

class HistoryScreen extends StatefulWidget {
  static const String routeName = '/history';

  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<WorkoutSession> _sessions = [];
  bool _isLoading = true;
  String _selectedFilter = 'Todas';

  final List<String> _filterOptions = [
    'Todas',
    'Esta semana',
    'Este mes',
    'Completadas',
    'Incompletas',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() => _isLoading = true);

      // Simular carga de historial desde Firebase
      // En una implementación real, cargarías desde Firestore
      await Future.delayed(const Duration(seconds: 1));

      // Datos de ejemplo
      final sessions = [
        WorkoutSession(
          id: '1',
          routineName: 'Pierna y Glúteos',
          date: DateTime.now().subtract(const Duration(days: 1)),
          duration: const Duration(minutes: 45),
          exercisesCompleted: 8,
          totalExercises: 10,
          caloriesBurned: 320,
          isCompleted: true,
        ),
        WorkoutSession(
          id: '2',
          routineName: 'Rutina de Brazo',
          date: DateTime.now().subtract(const Duration(days: 3)),
          duration: const Duration(minutes: 30),
          exercisesCompleted: 6,
          totalExercises: 8,
          caloriesBurned: 240,
          isCompleted: false,
        ),
        WorkoutSession(
          id: '3',
          routineName: 'Full Body',
          date: DateTime.now().subtract(const Duration(days: 7)),
          duration: const Duration(minutes: 60),
          exercisesCompleted: 12,
          totalExercises: 12,
          caloriesBurned: 450,
          isCompleted: true,
        ),
      ];

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al cargar historial: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<WorkoutSession> get _filteredSessions {
    List<WorkoutSession> filtered = _sessions;
    final now = DateTime.now();

    switch (_selectedFilter) {
      case 'Esta semana':
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered =
            filtered.where((session) => session.date.isAfter(weekAgo)).toList();
        break;
      case 'Este mes':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        filtered =
            filtered
                .where((session) => session.date.isAfter(monthAgo))
                .toList();
        break;
      case 'Completadas':
        filtered = filtered.where((session) => session.isCompleted).toList();
        break;
      case 'Incompletas':
        filtered = filtered.where((session) => !session.isCompleted).toList();
        break;
    }

    // Ordenar por fecha más reciente
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
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
              _buildStats(),
              _buildFilters(),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildHistoryList(),
              ),
            ],
          ),
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
              'Historial',
              style: TextStyle(
                color: AppTheme.iconColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _loadHistory,
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

  Widget _buildStats() {
    final completedSessions = _sessions.where((s) => s.isCompleted).length;
    final totalDuration = _sessions.fold<Duration>(
      Duration.zero,
      (total, session) => total + session.duration,
    );
    final totalCalories = _sessions.fold<int>(
      0,
      (total, session) => total + session.caloriesBurned,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.check_circle,
              value: '$completedSessions',
              label: 'Entrenamientos',
              color: Colors.green,
            ),
            _buildStatItem(
              icon: Icons.access_time,
              value: '${totalDuration.inMinutes}min',
              label: 'Tiempo total',
              color: AppTheme.accentColor,
            ),
            _buildStatItem(
              icon: Icons.local_fire_department,
              value: '$totalCalories',
              label: 'Calorías',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textColor.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
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
                  color: isSelected ? AppTheme.accentColor : AppTheme.textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    );
  }

  Widget _buildHistoryList() {
    final filteredSessions = _filteredSessions;

    if (filteredSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppTheme.textColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay entrenamientos',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tus entrenamientos aparecerán aquí',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredSessions.length,
      itemBuilder: (context, index) {
        final session = filteredSessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(WorkoutSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              session.isCompleted
                  ? Colors.green.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
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
                    color:
                        session.isCompleted
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    session.isCompleted
                        ? Icons.check_circle
                        : Icons.pause_circle,
                    color: session.isCompleted ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.routineName,
                        style: const TextStyle(
                          color: AppTheme.iconColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDateTime(session.date),
                        style: TextStyle(
                          color: AppTheme.textColor.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        session.isCompleted
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    session.isCompleted ? 'Completado' : 'Incompleto',
                    style: TextStyle(
                      color: session.isCompleted ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: session.exercisesCompleted / session.totalExercises,
                    backgroundColor: AppTheme.textColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(
                      session.isCompleted ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${session.exercisesCompleted}/${session.totalExercises}',
                  style: TextStyle(
                    color: AppTheme.textColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSessionStat(
                  Icons.access_time,
                  '${session.duration.inMinutes} min',
                ),
                _buildSessionStat(
                  Icons.local_fire_department,
                  '${session.caloriesBurned} cal',
                ),
                _buildSessionStat(
                  Icons.fitness_center,
                  '${session.exercisesCompleted} ejercicios',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.accentColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textColor.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Modelo para las sesiones de entrenamiento
class WorkoutSession {
  final String id;
  final String routineName;
  final DateTime date;
  final Duration duration;
  final int exercisesCompleted;
  final int totalExercises;
  final int caloriesBurned;
  final bool isCompleted;

  WorkoutSession({
    required this.id,
    required this.routineName,
    required this.date,
    required this.duration,
    required this.exercisesCompleted,
    required this.totalExercises,
    required this.caloriesBurned,
    required this.isCompleted,
  });
}
