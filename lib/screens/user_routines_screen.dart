// screens/user_routines_screen.dart
import 'package:flutter/material.dart';
import 'package:gymsgg_app/models/routine_model.dart';
import 'package:gymsgg_app/screens/routine_details_screen.dart';
import 'package:gymsgg_app/services/user_service.dart';
import 'package:gymsgg_app/theme/app_theme.dart';

class UserRoutinesScreen extends StatefulWidget {
  static const String routeName = '/user-routines';

  const UserRoutinesScreen({super.key});

  @override
  State<UserRoutinesScreen> createState() => _UserRoutinesScreenState();
}

class _UserRoutinesScreenState extends State<UserRoutinesScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.foundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Mis Rutinas',
            style: TextStyle(
              color: AppTheme.iconColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: StreamBuilder<List<Routine>>(
          stream: UserService.getUserRoutinesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar rutinas',
                      style: TextStyle(
                        color: AppTheme.textColor.withOpacity(0.8),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        color: AppTheme.textColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            // ✅ VERIFICACIÓN DE AUTENTICACIÓN
            if (!UserService.isLoggedIn) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off,
                      size: 64,
                      color: AppTheme.textColor.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Inicia sesión para ver tus rutinas',
                      style: TextStyle(
                        color: AppTheme.textColor.withOpacity(0.8),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text('Iniciar Sesión'),
                    ),
                  ],
                ),
              );
            }

            final routines = snapshot.data ?? [];

            if (routines.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 64,
                      color: AppTheme.accentColor.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes rutinas guardadas',
                      style: TextStyle(
                        color: AppTheme.textColor.withOpacity(0.8),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crea tu primera rutina para comenzar',
                      style: TextStyle(
                        color: AppTheme.textColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navegar a crear nueva rutina
                        Navigator.pushNamed(context, '/create-routine');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Crear Rutina'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                return _buildRoutineCard(routine);
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/create-routine');
          },
          backgroundColor: AppTheme.accentColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // ✅ CARD mejorada basada en tu código original
  Widget _buildRoutineCard(Routine routine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.cardColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => RoutineDetailsScreen(
                    routineId: routine.id,
                    routineName: routine.name,
                    level: routine.level,
                    difficulty: routine.difficulty,
                    fitnessLevel: routine.level,
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: AppTheme.accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
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
                        const SizedBox(height: 4),
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
                      color: AppTheme.iconColor,
                    ),
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Editar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editRoutine(routine);
                      } else if (value == 'delete') {
                        _deleteRoutine(routine);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.access_time,
                    routine.duration ?? "45 min",
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.fitness_center,
                    '${routine.totalExercises ?? routine.exercises?.length ?? 0} ejercicios',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Actualizada: ${_formatDate(routine.updatedAt)}',
                style: TextStyle(
                  color: AppTheme.textColor.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
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
            style: TextStyle(
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
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _editRoutine(Routine routine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => RoutineDetailsScreen(
              routineId: routine.id,
              routineName: routine.name,
              level: routine.level,
              difficulty: routine.difficulty,
              fitnessLevel: routine.level,
            ),
      ),
    );
  }

  void _deleteRoutine(Routine routine) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            title: const Text(
              'Eliminar rutina',
              style: TextStyle(color: AppTheme.iconColor),
            ),
            content: Text(
              '¿Estás seguro de que quieres eliminar "${routine.name}"?',
              style: const TextStyle(color: AppTheme.textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  bool success = await UserService.deleteUserRoutine(
                    routine.id,
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Rutina eliminada correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Error al eliminar rutina'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
