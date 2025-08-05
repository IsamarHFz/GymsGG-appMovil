// screens/edit_routine_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gymsgg_app/models/routine_model.dart';
import 'package:gymsgg_app/services/routine_service.dart';
import 'package:gymsgg_app/theme/app_theme.dart';

class EditRoutineScreen extends StatefulWidget {
  final Routine routine; // Cambio: ahora siempre requerido
  final bool isNewRoutine;

  const EditRoutineScreen({
    Key? key,
    required this.routine, // Cambio: siempre requerido
    required this.isNewRoutine,
  }) : super(key: key);

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _levelController;
  late TextEditingController _difficultyController;
  late TextEditingController _durationController;
  late TextEditingController _frequencyController;
  late TextEditingController _equipmentController;
  late TextEditingController _benefitsController;

  bool isSaving = false;
  bool _hasChanges = false; // Agregar seguimiento de cambios

  final List<String> _levelOptions = ['Principiante', 'Intermedio', 'Avanzado'];
  final List<String> _difficultyOptions = [
    'Fácil',
    'Moderado',
    'Difícil',
    'Extremo',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final routine = widget.routine;
    _nameController = TextEditingController(text: routine.name);
    _levelController = TextEditingController(text: routine.level);
    _difficultyController = TextEditingController(text: routine.difficulty);
    _durationController = TextEditingController(text: routine.duration);
    _frequencyController = TextEditingController(text: routine.frequency);
    _equipmentController = TextEditingController(text: routine.equipment);
    _benefitsController = TextEditingController(
      text: routine.benefits.join(', '),
    );

    // Agregar listeners para detectar cambios
    _nameController.addListener(_onTextChanged);
    _levelController.addListener(_onTextChanged);
    _difficultyController.addListener(_onTextChanged);
    _durationController.addListener(_onTextChanged);
    _frequencyController.addListener(_onTextChanged);
    _equipmentController.addListener(_onTextChanged);
    _benefitsController.addListener(_onTextChanged);
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
    _levelController.dispose();
    _difficultyController.dispose();
    _durationController.dispose();
    _frequencyController.dispose();
    _equipmentController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  Future<void> _saveRoutine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final now = DateTime.now();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showSnackBar('Usuario no autenticado.', isError: true);
      setState(() => isSaving = false);
      return;
    }

    // Crear la rutina actualizada
    final updatedRoutine = widget.routine.copyWith(
      name: _nameController.text.trim(),
      level: _levelController.text.trim(),
      difficulty: _difficultyController.text.trim(),
      duration: _durationController.text.trim(),
      frequency: _frequencyController.text.trim(),
      equipment: _equipmentController.text.trim(),
      benefits:
          _benefitsController.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
      updatedAt: now,
      userId: currentUser.uid,
    );

    try {
      // Solo guardar si no es nueva rutina y si realmente queremos persistir
      if (!widget.isNewRoutine) {
        await RoutineService().saveRoutine(updatedRoutine);
      }

      _showSnackBar('Rutina actualizada exitosamente.');

      // Regresar la rutina actualizada
      if (mounted) {
        Navigator.pop(context, updatedRoutine);
      }
    } catch (e) {
      _showSnackBar('Error al guardar: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.iconColor),
        ),
        backgroundColor: isError ? Colors.red : AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Método para manejar el botón de atrás
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
                    _saveRoutine(); // Guardar y salir
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

  Widget _buildCard({required Widget child}) {
    return Card(
      color: AppTheme.cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(20.0), child: child),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.iconColor),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textColor),
        hintStyle: TextStyle(color: AppTheme.textColor.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: AppTheme.accentColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.primaryColor,
      ),
    ),
  );

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> options,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        dropdownColor: AppTheme.cardColor,
        style: const TextStyle(color: AppTheme.iconColor),
        value: options.contains(controller.text) ? controller.text : null,
        onChanged: (value) {
          if (value != null) {
            controller.text = value;
            _onTextChanged(); // Detectar cambio
          }
        },
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textColor),
          prefixIcon: Icon(icon, color: AppTheme.accentColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.accentColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
          ),
          filled: true,
          fillColor: AppTheme.primaryColor,
        ),
        items:
            options
                .map(
                  (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _onBackPressed();
        return false; // Prevenir el pop automático
      },
      child: Container(
        decoration: AppTheme.foundColor,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              widget.isNewRoutine ? 'Crear Rutina' : 'Editar Rutina',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.iconColor,
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: AppTheme.iconColor,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: AppTheme.iconColor),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _onBackPressed,
            ),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.accentColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Información Básica',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTextFormField(
                          controller: _nameController,
                          label: 'Nombre de la rutina',
                          icon: Icons.fitness_center,
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Este campo es requerido'
                                      : null,
                        ),
                        _buildDropdownField(
                          controller: _levelController,
                          label: 'Nivel',
                          icon: Icons.trending_up,
                          options: _levelOptions,
                        ),
                        _buildDropdownField(
                          controller: _difficultyController,
                          label: 'Dificultad',
                          icon: Icons.whatshot,
                          options: _difficultyOptions,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.schedule, color: AppTheme.accentColor),
                            SizedBox(width: 8),
                            Text(
                              'Detalles de Entrenamiento',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTextFormField(
                          controller: _durationController,
                          label: 'Duración (ej: 45 min)',
                          icon: Icons.timer,
                        ),
                        _buildTextFormField(
                          controller: _frequencyController,
                          label: 'Frecuencia (ej: 3 veces por semana)',
                          icon: Icons.repeat,
                        ),
                        _buildTextFormField(
                          controller: _equipmentController,
                          label: 'Equipo necesario',
                          icon: Icons.build,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.favorite, color: AppTheme.accentColor),
                            SizedBox(width: 8),
                            Text(
                              'Beneficios',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Separa cada beneficio con una coma',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTextFormField(
                          controller: _benefitsController,
                          label: 'Beneficios (separados por coma)',
                          icon: Icons.star,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Mostrar botón solo si hay cambios
                  if (_hasChanges)
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [AppTheme.accentColor, Color(0xFFFFA500)],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveRoutine,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child:
                            isSaving
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.iconColor,
                                    ),
                                  ),
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.save,
                                      color: AppTheme.iconColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.isNewRoutine
                                          ? 'Crear Rutina'
                                          : 'Guardar Cambios',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.iconColor,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
