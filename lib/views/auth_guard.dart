import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_view.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isLoading) {
          // Muestra un indicador mientras se verifica el estado de autenticación
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (authService.isLoggedIn) {
          // Si está autenticado, muestra el contenido de la página
          return child;
        } else {
          // Si no está autenticado, redirige al login
          return const LoginView();
        }
      },
    );
  }
}
