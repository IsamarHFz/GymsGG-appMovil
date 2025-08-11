// login_screen.dart - Corregido para flujo completo de onboarding
import 'package:flutter/material.dart';
import 'package:gymsgg_app/screens/fitness_level_screen.dart';
import 'package:gymsgg_app/screens/profile_screen.dart';
import 'package:gymsgg_app/screens/routine_selection_screen.dart';
import 'package:gymsgg_app/screens/routine_details_screen.dart';
import 'package:gymsgg_app/screens/sign_up_screen.dart';
import 'package:gymsgg_app/theme/app_theme.dart';
import 'package:gymsgg_app/services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.foundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildLoginForm(),
                  const SizedBox(height: 20),
                  _buildSignUpLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Iniciar Sesión',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.iconColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Bienvenido de vuelta',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textColor.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildInputField(
          controller: emailController,
          hintText: 'Email o Usuario',
          icon: Icons.person_outline,
          validator: _validateEmailOrUsername,
        ),
        const SizedBox(height: 20),
        _buildInputField(
          controller: passwordController,
          hintText: 'Contraseña',
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: _obscurePassword,
          onToggleVisibility: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          validator: _validatePassword,
        ),
        const SizedBox(height: 40),
        _buildLoginButton(),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        enabled: !_isLoading,
        style: const TextStyle(color: AppTheme.iconColor, fontSize: 16),
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppTheme.textColor.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: AppTheme.accentColor),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textColor,
                    ),
                    onPressed: _isLoading ? null : onToggleVisibility,
                  )
                  : null,
          border: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient:
            _isLoading
                ? LinearGradient(
                  colors: [
                    AppTheme.accentColor.withOpacity(0.5),
                    const Color(0xFFFFA500).withOpacity(0.5),
                  ],
                )
                : const LinearGradient(
                  colors: [AppTheme.accentColor, Color(0xFFFFA500)],
                ),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
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
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta? ',
          style: TextStyle(
            color: AppTheme.textColor.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap:
              _isLoading
                  ? null
                  : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
          child: Text(
            'Regístrate',
            style: TextStyle(
              color:
                  _isLoading
                      ? AppTheme.accentColor.withOpacity(0.5)
                      : AppTheme.accentColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Validaciones
  String? _validateEmailOrUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email o usuario es requerido';
    }

    if (value.contains('@')) {
      if (!_isValidEmail(value)) {
        return 'Formato de email inválido';
      }
    } else {
      if (!_isValidUsername(value)) {
        return 'Usuario inválido (min. 3 caracteres, solo letras, números y _)';
      }
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidUsername(String username) {
    return username.length >= 3 &&
        RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
  }

  // ✅ MÉTODO MEJORADO - Navegación inteligente según el estado del perfil
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await FirebaseService.signInUserWithProfile(
        emailOrUsername: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        _showSuccessMessage(result['message']);

        // Breve delay para mostrar el mensaje
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          // ✅ LÓGICA MEJORADA: Navegación según el estado detallado del perfil
          final hasCompleteProfile = result['hasCompleteProfile'] ?? false;
          final onboardingStep = result['onboardingStep'] ?? 'fitness_level';
          final fitnessLevel = result['fitnessLevel'];
          final selectedRoutineId = result['selectedRoutineId'];

          print('🎯 Estado del login:');
          print('   - hasCompleteProfile: $hasCompleteProfile');
          print('   - onboardingStep: $onboardingStep');
          print('   - fitnessLevel: $fitnessLevel');
          print('   - selectedRoutineId: $selectedRoutineId');

          if (hasCompleteProfile) {
            // ✅ Usuario con perfil completo → ProfileScreen
            print('✅ Usuario con perfil completo → ProfileScreen');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
              (route) => false,
            );
          } else {
            // ✅ Usuario incompleto → Determinar siguiente paso
            switch (onboardingStep) {
              case 'fitness_level':
                print('⚠️ Usuario nuevo → FitnessLevelScreen');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FitnessLevelScreen(),
                  ),
                  (route) => false,
                );
                break;

              case 'routine_selection':
                print(
                  '⚠️ Usuario con nivel pero sin rutina → RoutineSelectionScreen',
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => RoutineSelectionScreen(
                          selectedLevel: fitnessLevel ?? 'beginner',
                          fitnessLevel: fitnessLevel ?? 'beginner',
                        ),
                  ),
                  (route) => false,
                );
                break;

              case 'completed':
              default:
                // Si por alguna razón llega aquí, ir al perfil
                print('⚠️ Estado indefinido → ProfileScreen');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                  (route) => false,
                );
                break;
            }
          }
        }
      } else {
        _showErrorMessage(result['message']);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error inesperado: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
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
