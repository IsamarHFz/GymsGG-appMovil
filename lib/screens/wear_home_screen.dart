import 'package:flutter/material.dart';

class WearHomeScreen extends StatelessWidget {
  const WearHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, color: Colors.amber, size: 32),
              const SizedBox(height: 8),
              const Text(
                'GymsGG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _buildWearButton(
                context,
                icon: Icons.play_arrow,
                label: 'Iniciar',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _buildWearButton(
                context,
                icon: Icons.history,
                label: 'Historial',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              _buildWearButton(
                context,
                icon: Icons.settings,
                label: 'Config',
                onTap: () {},
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
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.withOpacity(0.2),
          foregroundColor: Colors.amber,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.amber, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
