import 'package:flutter/material.dart';
import 'package:gymsgg_app/screens/history_screen.dart';
import 'package:gymsgg_app/screens/routine_details_screen.dart';
import 'package:gymsgg_app/services/firebase_service.dart';
import 'package:gymsgg_app/services/user_service.dart';
import 'package:gymsgg_app/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/menu';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  Map<String, int> _userStats = {'routines': 0, 'exercises': 0};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!FirebaseService.isUserLoggedIn()) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      // Usar FirebaseService en lugar de UserService
      final userProfile = await FirebaseService.getUserProfile();

      // Para las estadísticas, puedes crear un método similar o usar valores por defecto
      final userStats = {'routines': 0, 'exercises': 0}; // Placeholder

      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _userStats = userStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando datos del usuario: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Y reemplazar el método _performLogout:
  Future<void> _performLogout() async {
    try {
      final result = await FirebaseService.signOut();
      //
      if (mounted) {
        if (result['success']) {
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al cerrar sesión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: AppTheme.foundColor,
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: AppTheme.foundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildWelcomeCard(),
                  const SizedBox(height: 32),
                  _buildQuickStats(),
                  const SizedBox(height: 32),
                  _buildNavigationMenu(),
                  const SizedBox(height: 32),
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final userName = _userProfile?['name'] ?? 'Usuario';

    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(Icons.person, color: AppTheme.accentColor, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $userName! 👋',
                style: const TextStyle(
                  color: AppTheme.iconColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Bienvenido a tu gimnasio virtual',
                style: TextStyle(
                  color: AppTheme.textColor.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => _showLogoutDialog(),
            icon: const Icon(Icons.logout, color: Colors.red, size: 20),
            tooltip: 'Cerrar sesión',
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentColor, Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💪 Es hora de entrenar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu cuerpo te lo agradecerá después',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              Icons.fitness_center,
              '${_userStats['routines'] ?? 0}',
              'Rutinas',
              AppTheme.accentColor,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              Icons.list,
              '${_userStats['exercises'] ?? 0}',
              'Ejercicios',
              Colors.orange,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStatItem(
              Icons.local_fire_department,
              '7',
              'Días activo',
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppTheme.accentColor.withOpacity(0.2),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.iconColor,
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
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildNavigationMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menú Principal',
          style: TextStyle(
            color: AppTheme.accentColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMenuButton(
                icon: Icons.fitness_center,
                title: 'Mis Rutinas',
                subtitle: 'Ver y crear rutinas',
                color: AppTheme.accentColor,
                onPressed: _navigateToRoutines,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuButton(
                icon: Icons.history,
                title: 'Historial',
                subtitle: 'Tu progreso',
                color: Colors.blue,
                onPressed: _navigateToHistory,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: 120,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.cardColor.withOpacity(0.2),
          foregroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withOpacity(0.3), width: 1),
          ),
          padding: const EdgeInsets.all(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.iconColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textColor.withOpacity(0.8),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            color: AppTheme.accentColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // ✅ BOTÓN PRINCIPAL CORREGIDO - Sin ElevatedButton anidado
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [AppTheme.accentColor, Color(0xFFFFA500)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              // ✅ CORRECTO: Usar Navigator.push para navegar
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => RoutineDetailsScreen(
                        routineName: 'Nueva Rutina',
                        level: 'beginner',
                        difficulty: 'easy',
                        fitnessLevel: 'beginner',
                        routine: null,
                      ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Crear Nueva Rutina',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ), // ✅ Container cerrado correctamente
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _syncData(),
            icon: const Icon(Icons.sync, color: AppTheme.accentColor, size: 20),
            label: const Text(
              'Sincronizar Datos',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.accentColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: AppTheme.iconColor),
            ),
            content: const Text(
              '¿Estás seguro de que quieres cerrar sesión?',
              style: TextStyle(color: AppTheme.textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _performLogout();
                },
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  // ✅ MÉTODOS DE NAVEGACIÓN CORREGIDOS
  void _navigateToRoutines() {
    print('🔍 Intentando navegar a RoutineDetailsScreen');

    Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => RoutineDetailsScreen(
                  routineName: 'Mis Rutinas',
                  level: 'beginner',
                  difficulty: 'easy',
                  fitnessLevel: 'beginner',
                  routine: null,
                ),
          ),
        )
        .then((value) {
          print('✅ Regresó de RoutineDetailsScreen');
        })
        .catchError((error) {
          print('❌ Error navegando a rutinas: $error');
          _showComingSoon('Mis Rutinas');
        });
  }

  void _navigateToHistory() {
    print('🔍 Intentando navegar a HistoryScreen');

    Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HistoryScreen()),
        )
        .then((value) {
          print('✅ Regresó de HistoryScreen');
        })
        .catchError((error) {
          print('❌ Error navegando al historial: $error');
          _showComingSoon('Historial');
        });
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
    _showComingSoon('Mi Perfil');
  }

  void _createNewRoutine() {
    Navigator.pushNamed(context, '/create-routine');
    _showComingSoon('Crear Rutina');
  }

  Future<void> _syncData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            ),
          ),
    );

    try {
      await UserService.forceSyncWithServer();
      await _loadUserData();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('✅ Datos sincronizados correctamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al sincronizar datos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.accentColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  feature,
                  style: const TextStyle(color: AppTheme.iconColor),
                ),
              ],
            ),
            content: Text(
              'Esta función estará disponible próximamente.\n\n¡Estamos trabajando para traértela pronto! 🚀',
              style: const TextStyle(color: AppTheme.textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
    );
  }
}
