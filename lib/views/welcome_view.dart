import 'package:flutter/material.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Texto de bienvenida con estilo
            Text(
              'Bienvenido',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Sistema de Gestión de Ventas y Libros',
              style: TextStyle(fontSize: 20, color: Colors.blue[600]),
            ),
            // Logo con efecto de elevación
            // Container(
            //   padding: const EdgeInsets.all(20),
            //   // decoration: BoxDecoration(
            //   //   color: Colors.white,
            //   //   shape: BoxShape.circle,
            //   //   boxShadow: [
            //   //     BoxShadow(
            //   //       color: Colors.black.withOpacity(0.1),
            //   //       spreadRadius: 3,
            //   //       blurRadius: 5,
            //   //       offset: const Offset(0, 2),
            //   //     ),
            //   //   ],
            //   // ),
            //   child: Image.asset('pandevida_logo.png'),
            // ),
          ],
        ),
      ),
    );
  }
}
