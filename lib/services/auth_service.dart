import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pan_de_vida_web/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get error => _error;

  // Credenciales de usuarios de prueba (en producción, deberían estar en una base de datos)
  final Map<String, Map<String, String>> _users = {
    'admin': {'password': 'admin123', 'role': 'admin'},
    'empleado': {'password': 'empleado123', 'role': 'employee'},
  };

  // Constructor que intenta cargar la sesión almacenada
  AuthService() {
    _loadUserFromStorage();
  }

  // Cargar usuario desde almacenamiento local si existe
  Future<void> _loadUserFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson != null) {
        final userData = json.decode(userJson);
        _currentUser = User.fromJson(userData);
      }
    } catch (e) {
      _error = 'Error al cargar la sesión';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Guardar usuario en almacenamiento local
  Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(user.toJson()));
    } catch (e) {
      print('Error al guardar la sesión: $e');
    }
  }

  // Método para hacer login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulamos un delay para imitar una petición a servidor
      await Future.delayed(const Duration(seconds: 1));

      // Verificar si el usuario existe y la contraseña es correcta
      if (_users.containsKey(username) &&
          _users[username]?['password'] == password) {
        _currentUser = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          username: username,
          role: _users[username]?['role'] ?? 'user',
        );

        await _saveUserToStorage(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Usuario o contraseña incorrectos';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error al iniciar sesión';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Método para cerrar sesión
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      _currentUser = null;
    } catch (e) {
      _error = 'Error al cerrar sesión';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
