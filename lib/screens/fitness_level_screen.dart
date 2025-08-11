import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymsgg_app/screens/routine_selection_screen.dart'; // ← CAMBIO: Navegar a selección de rutina
import 'package:gymsgg_app/services/firebase_service.dart';
import 'package:gymsgg_app/theme/app_theme.dart';

class FitnessLevelScreen extends StatefulWidget {
  const FitnessLevelScreen({super.key});

  @override
  State<FitnessLevelScreen> createState() => _FitnessLevelScreenState();
}

class _FitnessLevelScreenState extends State<FitnessLevelScreen> {
  String selectedLevel = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(decoration: AppTheme.foundColor),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 60),
                  _buildLevelOptions(),
                  const SizedBox(height: 40),
                  if (selectedLevel.isNotEmpty) _buildContinueButton(),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppTheme.iconColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '¿Cuál es tu nivel de\nentrenamiento?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.iconColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelOptions() {
    return Column(
      children: [
        _buildLevelCard(
          title: 'Principiante',
          description: 'Estoy comenzando o\ntengo poca experiencia.',
          icon: Icons.directions_walk,
          level: 'beginner',
        ),
        const SizedBox(height: 20),
        _buildLevelCard(
          title: 'Intermedio',
          description: 'Entreno regularmente y\nconozco ejercicios básicos.',
          icon: Icons.directions_run,
          level: 'intermediate',
        ),
        const SizedBox(height: 20),
        _buildLevelCard(
          title: 'Avanzado',
          description: 'Tengo mucha experiencia\ny entreno constantemente.',
          icon: Icons.fitness_center,
          level: 'advanced',
        ),
      ],
    );
  }

  Widget _buildLevelCard({
    required String title,
    required String description,
    required IconData icon,
    required String level,
  }) {
    final bool isSelected = selectedLevel == level;

    return GestureDetector(
      onTap:
          _isLoading
              ? null
              : () {
                setState(() {
                  selectedLevel = level;
                });
              },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppTheme.accentColor.withOpacity(0.1)
                  : AppTheme.cardColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? AppTheme.accentColor
                    : AppTheme.accentColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppTheme.accentColor.withOpacity(0.2)
                        : AppTheme.cardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.accentColor : AppTheme.textColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          isSelected
                              ? AppTheme.accentColor
                              : AppTheme.iconColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors:
              _isLoading
                  ? [
                    AppTheme.accentColor.withOpacity(0.5),
                    const Color(0xFFFFA500).withOpacity(0.5),
                  ]
                  : [AppTheme.accentColor, const Color(0xFFFFA500)],
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 2.5,
                  ),
                )
                : const Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
      ),
    );
  }

  // ✅ MÉTODO CORREGIDO: Solo guardar nivel y continuar al siguiente paso
  Future<void> _handleContinue() async {
    if (kDebugMode) {
      debugPrint('Nivel seleccionado: $selectedLevel');
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ Solo guardar el nivel de fitness (NO marcar como completado aún)
      final userData = {
        'fitnessLevel': selectedLevel, // 'beginner', 'intermediate', 'advanced'
        'onboardingStep': 'routine_selection', // Paso actual del onboarding
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final success = await FirebaseService.updateCurrentUserProfile(userData);

      if (mounted) {
        if (success) {
          // ✅ Ir a selección de rutina (NO a ProfileScreen)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => RoutineSelectionScreen(
                    selectedLevel: selectedLevel,
                    fitnessLevel:
                        selectedLevel, // Pasar como parámetro requerido
                  ),
            ),
          );
        } else {
          _showErrorMessage('Error al guardar la configuración');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
