import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/inventory_view.dart';
import 'views/sales_view.dart';
import 'views/auth_guard.dart';
import 'services/auth_service.dart';
import 'views/login_view.dart';
import 'components/app/main_scaffold.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pan de Vida',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/':
            (context) =>
                const AuthGuard(child: MainScaffold(child: InventoryView())),
        '/home':
            (context) =>
                const AuthGuard(child: MainScaffold(child: InventoryView())),
        '/sales':
            (context) =>
                const AuthGuard(child: MainScaffold(child: SalesView())),
        '/login': (context) => const LoginView(),
      },
    );
  }
}
