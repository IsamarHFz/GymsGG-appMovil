import 'package:flutter/material.dart';
import 'package:gymsgg_app/theme/app_theme.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.foundColor,
      child: Text(
        "Bienvenido al Sistema de Comercialización SCS",
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 40.0, color: AppTheme.textColor),
      ),
    );
  }
}
