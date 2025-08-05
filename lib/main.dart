import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

// Importaciones de Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymsGG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const ResponsiveHomeWrapper(),
    );
  }
}

class ResponsiveHomeWrapper extends StatelessWidget {
  const ResponsiveHomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Detectar tipo de pantalla por dimensiones
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Pantalla de smartwatch (circular o cuadrada pequeña)
        if (width < 300 && height < 400) {
          return const WearHomeScreen();
        }
        // // Tablet
        // else if (width > 600) {
        //   return const TabletHomeScreen();
        // }
        // Teléfono móvil
        else {
          return const HomeScreen();
        }
      },
    );
  }
}

// Pantalla para Wear OS / Smartwatch
class WearHomeScreen extends StatelessWidget {
  const WearHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isRound = size.width == size.height; // Detectar pantalla redonda

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration:
            isRound ? const BoxDecoration(shape: BoxShape.circle) : null,
        child: Padding(
          padding: EdgeInsets.all(isRound ? 16.0 : 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                color: Colors.amber,
                size: size.width * 0.15, // Tamaño proporcional
              ),
              SizedBox(height: size.height * 0.02),
              Text(
                'GymsGG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.08,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: size.height * 0.06),

              // Botones adaptados para pantalla pequeña
              _buildWearButton(
                context,
                icon: Icons.play_arrow,
                label: 'Iniciar',
                size: size,
              ),
              SizedBox(height: size.height * 0.02),
              _buildWearButton(
                context,
                icon: Icons.history,
                label: 'Historial',
                size: size,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWearButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Size size,
  }) {
    return SizedBox(
      width: size.width * 0.8,
      height: size.height * 0.12,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.withOpacity(0.2),
          foregroundColor: Colors.amber,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size.width * 0.1),
            side: const BorderSide(color: Colors.amber, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: size.width * 0.06),
            SizedBox(width: size.width * 0.02),
            Text(label, style: TextStyle(fontSize: size.width * 0.05)),
          ],
        ),
      ),
    );
  }
}
