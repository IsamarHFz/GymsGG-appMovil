import 'package:flutter/material.dart';
import 'package:gymsgg_app/theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();

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
                _buildForm(),
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
            const Expanded(
              child: Text(
                'Recuperar contraseña',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.iconColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        const Text(
          'Ingresa tu número de celular o\nemail',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
          ),
          child: TextField(
            controller: emailController,
            style: const TextStyle(color: AppTheme.iconColor, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Email o número de teléfono',
              hintStyle: TextStyle(color: AppTheme.textColor.withOpacity(0.7)),
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: AppTheme.accentColor,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Se enviará un enlace para\nactualizar la contraseña',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),
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
            onPressed: () {
              debugPrint('Recuperar contraseña para: ${emailController.text}');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Enlace de recuperación enviado'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Buscar cuenta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
