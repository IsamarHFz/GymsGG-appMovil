import 'package:flutter/material.dart';
import 'package:gymsgg_app/theme/app_theme.dart';

class FitnessLevelScreen extends StatefulWidget {
  const FitnessLevelScreen({super.key});

  @override
  State<FitnessLevelScreen> createState() => _FitnessLevelScreenState();
}

class _FitnessLevelScreenState extends State<FitnessLevelScreen> {
  String selectedLevel = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.foundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
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
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppTheme.iconColor,
                size: 24,
              ),
            ),
          ],
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
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }

  Widget _buildLevelCard({
    required String title,
    required String description,
    required IconData icon,
    required String level,
  }) {
    bool isSelected = selectedLevel == level;

    return GestureDetector(
      onTap: () {
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
                  : null,
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
                    style: TextStyle(
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
        gradient: const LinearGradient(
          colors: [AppTheme.accentColor, Color(0xFFFFA500)],
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          debugPrint('Nivel seleccionado: $selectedLevel');
          // Aquí navegarías a la siguiente pantalla
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
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
}
