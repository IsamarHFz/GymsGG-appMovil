import 'package:flutter/material.dart';
import 'package:gymsgg_app/models/routine_model.dart';
import 'package:gymsgg_app/theme/app_theme.dart';

class EditExerciseScreen extends StatefulWidget {
  final Exercise exercise;
  final bool isNewExercise;

  const EditExerciseScreen({
    super.key,
    required this.exercise,
    this.isNewExercise = false,
  });

  @override
  State<EditExerciseScreen> createState() => _EditExerciseScreenState();
}

class _EditExerciseScreenState extends State<EditExerciseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _targetController;
  late TextEditingController _setsController;
  late TextEditingController _restController;

  late Exercise _editedExercise;
  bool _hasChanges = false;

  // Lista de iconos disponibles para ejercicios
  final Map<String, IconData> _availableIcons = {
    'fitness_center': Icons.fitness_center,
    'directions_run': Icons.directions_run,
    'accessibility_new': Icons.accessibility_new,
    'straighten': Icons.straighten,
    'sports_gymnastics': Icons.sports_gymnastics,
    'sports_martial_arts': Icons.sports_martial_arts,
    'pool': Icons.pool,
    'sports_handball': Icons.sports_handball,
    'sports_kabaddi': Icons.sports_kabaddi,
    'self_improvement': Icons.self_improvement,
  };

  // Opciones de dificultad disponibles
  final List<String> _difficultyOptions = ['Fácil', 'Medio', 'Difícil'];

  @override
  void initState() {
    super.initState();
    _editedExercise = widget.exercise;
    _validateAndFixInitialValues();
    _initializeControllers();
  }

  void _validateAndFixInitialValues() {
    // Asegurar que el icono esté en la lista disponible
    if (!_availableIcons.containsKey(_editedExercise.iconName)) {
      _editedExercise = _editedExercise.copyWith(iconName: 'fitness_center');
    }

    // Asegurar que la dificultad esté en la lista
    if (!_difficultyOptions.contains(_editedExercise.difficulty)) {
      _editedExercise = _editedExercise.copyWith(
        difficulty: _difficultyOptions[1],
      ); // Medio por defecto
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: _editedExercise.name);
    _targetController = TextEditingController(text: _editedExercise.target);
    _setsController = TextEditingController(text: _editedExercise.sets);
    _restController = TextEditingController(text: _editedExercise.rest);

    // Escuchar cambios
    _nameController.addListener(_onTextChanged);
    _targetController.addListener(_onTextChanged);
    _setsController.addListener(_onTextChanged);
    _restController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _setsController.dispose();
    _restController.dispose();
    super.dispose();
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
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBasicInfoSection(),
                          const SizedBox(height: 20),
                          _buildParametersSection(),
                          const SizedBox(height: 20),
                          _buildIconSelectionSection(),
                          const SizedBox(height: 20),
                          _buildDifficultySection(),
                          const SizedBox(height: 80), // Espacio para el botón
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton:
            _hasChanges
                ? FloatingActionButton.extended(
                  onPressed: _saveExercise,
                  backgroundColor: AppTheme.accentColor,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Guardar',
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _onBackPressed(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppTheme.iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isNewExercise ? 'Nuevo Ejercicio' : 'Editar Ejercicio',
                  style: const TextStyle(
                    color: AppTheme.iconColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!widget.isNewExercise)
                  Text(
                    'Modificando: ${widget.exercise.name}',
                    style: TextStyle(
                      color: AppTheme.textColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Información básica',
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Nombre del ejercicio',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es obligatorio';
              }
              if (value.trim().length < 3) {
                return 'El nombre debe tener al menos 3 caracteres';
              }
              if (value.trim().length > 50) {
                return 'El nombre no puede exceder 50 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _targetController,
            label: 'Grupo muscular objetivo',
            hintText: 'ej: Pecho, hombros',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El grupo muscular es obligatorio';
              }
              if (value.trim().length < 3) {
                return 'Debe tener al menos 3 caracteres';
              }
              if (value.trim().length > 30) {
                return 'No puede exceder 30 caracteres';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildParametersSection() {
    return _buildSection(
      title: 'Parámetros de entrenamiento',
      child: Column(
        children: [
          _buildTextField(
            controller: _setsController,
            label: 'Series y repeticiones',
            hintText: 'ej: 3 series x 10-12 reps',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Las series son obligatorias';
              }
              if (value.trim().length < 3) {
                return 'Debe ser más descriptivo';
              }
              if (value.trim().length > 50) {
                return 'No puede exceder 50 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _restController,
            label: 'Tiempo de descanso',
            hintText: 'ej: 60-90 seg',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El tiempo de descanso es obligatorio';
              }
              if (value.trim().length > 20) {
                return 'No puede exceder 20 caracteres';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconSelectionSection() {
    return _buildSection(
      title: 'Icono del ejercicio',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _availableIcons[_editedExercise.iconName] ??
                    Icons.fitness_center,
                color: AppTheme.accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Icono seleccionado: ${_getIconDisplayName(_editedExercise.iconName)}',
                style: TextStyle(
                  color: AppTheme.textColor.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Selecciona un icono:',
            style: TextStyle(color: AppTheme.textColor, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                _availableIcons.entries.map((entry) {
                  final isSelected = _editedExercise.iconName == entry.key;
                  return GestureDetector(
                    onTap: () => _selectIcon(entry.key),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppTheme.accentColor.withOpacity(0.3)
                                : AppTheme.cardColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppTheme.accentColor
                                  : AppTheme.accentColor.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        entry.value,
                        color:
                            isSelected
                                ? AppTheme.accentColor
                                : AppTheme.textColor,
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection() {
    return _buildSection(
      title: 'Dificultad',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getDifficultyColor(_editedExercise.difficulty),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Dificultad seleccionada: ${_editedExercise.difficulty}',
                style: TextStyle(
                  color: AppTheme.textColor.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Selecciona la dificultad:',
            style: TextStyle(color: AppTheme.textColor, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children:
                _difficultyOptions.map((difficulty) {
                  final isSelected = _editedExercise.difficulty == difficulty;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDifficulty(difficulty),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? _getDifficultyColor(
                                    difficulty,
                                  ).withOpacity(0.2)
                                  : AppTheme.cardColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isSelected
                                    ? _getDifficultyColor(difficulty)
                                    : AppTheme.accentColor.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          difficulty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? _getDifficultyColor(difficulty)
                                    : AppTheme.textColor,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: AppTheme.cardColor.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        labelStyle: TextStyle(color: AppTheme.textColor.withOpacity(0.8)),
        hintStyle: TextStyle(color: AppTheme.textColor.withOpacity(0.5)),
      ),
      style: const TextStyle(color: AppTheme.iconColor),
      validator: validator,
    );
  }

  String _getIconDisplayName(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return 'Pesas';
      case 'directions_run':
        return 'Correr';
      case 'accessibility_new':
        return 'Estiramiento';
      case 'straighten':
        return 'Flexibilidad';
      case 'sports_gymnastics':
        return 'Gimnasia';
      case 'sports_martial_arts':
        return 'Artes marciales';
      case 'pool':
        return 'Natación';
      case 'sports_handball':
        return 'Deportes';
      case 'sports_kabaddi':
        return 'Fuerza';
      case 'self_improvement':
        return 'Meditación';
      default:
        return 'Ejercicio';
    }
  }

  void _selectIcon(String iconName) {
    setState(() {
      _editedExercise = _editedExercise.copyWith(iconName: iconName);
      _hasChanges = true;
    });
  }

  void _selectDifficulty(String difficulty) {
    setState(() {
      _editedExercise = _editedExercise.copyWith(difficulty: difficulty);
      _hasChanges = true;
    });
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'fácil':
        return Colors.green;
      case 'medio':
        return Colors.orange;
      case 'difícil':
        return Colors.red;
      default:
        return AppTheme.accentColor;
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onBackPressed() {
    if (_hasChanges) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: const Text(
                'Cambios sin guardar',
                style: TextStyle(color: AppTheme.iconColor),
              ),
              content: const Text(
                '¿Quieres guardar los cambios antes de salir?',
                style: TextStyle(color: AppTheme.textColor),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Cerrar diálogo
                    Navigator.pop(context); // Salir sin guardar
                  },
                  child: const Text('Salir sin guardar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Cerrar diálogo
                    _saveExercise(); // Guardar y salir
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _saveExercise() {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Por favor corrige los errores en el formulario');
      return;
    }

    // Actualizar el ejercicio con los valores de los controladores
    final updatedExercise = _editedExercise.copyWith(
      name: _nameController.text.trim(),
      target: _targetController.text.trim(),
      sets: _setsController.text.trim(),
      rest: _restController.text.trim(),
    );

    _showSuccessSnackBar(
      'Ejercicio ${widget.isNewExercise ? 'creado' : 'actualizado'} exitosamente',
    );

    Navigator.pop(context, updatedExercise);
  }
}
