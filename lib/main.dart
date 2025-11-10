import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'providers/cuaderno_provider.dart';
import 'models/usuario.dart';
import 'providers/notificaciones_provider.dart';
import 'screens/login_screen.dart';
import 'screens/profesor_home_screen.dart';
import 'screens/alumno_home_screen.dart';
import 'screens/notificaciones_screen.dart';
// Import condicional para evitar 'dart:html' en plataformas móviles/desktop
import 'screens/web/reportes_web_screen_stub.dart'
    if (dart.library.html) 'screens/web/reportes_web_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CuadernoProfesorApp());
}

class CuadernoProfesorApp extends StatelessWidget {
  const CuadernoProfesorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CuadernoProvider()),
        ChangeNotifierProvider(create: (_) => NotificacionesProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Evitamos reconstruir el router en cada notifyListeners
          final provider = context.read<CuadernoProvider>();
          final router = GoRouter(
            // NO establecemos initialLocation para que respete la URL del navegador
            refreshListenable: provider,
            redirect: (context, state) {
              // Mientras se carga el usuario inicial, no redirigimos
              if (provider.cargandoUsuarioInicial) return null;

              final usuario = provider.usuario;
              final currentLocation = state.matchedLocation;

              // Si no hay usuario autenticado, redirigir a login (excepto si ya está en login)
              if (usuario == null) {
                return currentLocation == '/login' ? null : '/login';
              }

              // Si hay usuario autenticado Y está en login o raíz, redirigir a su home
              if (currentLocation == '/login' || currentLocation == '/') {
                return usuario.tipo == TipoUsuario.profesor
                    ? '/profesor/inicio'
                    : '/alumno';
              }

              // Para cualquier otra ruta, respetar la ubicación actual
              return null;
            },
            routes: [
              GoRoute(
                path: '/login',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(
                path: '/profesor',
                redirect: (context, state) => '/profesor/inicio',
              ),
              GoRoute(
                path: '/profesor/:tab',
                builder: (context, state) {
                  final tab = state.pathParameters['tab'] ?? 'inicio';
                  return ProfesorHomeScreen(initialTab: tab);
                },
              ),
              GoRoute(
                path: '/alumno',
                builder: (context, state) => const AlumnoHomeScreen(),
              ),
              GoRoute(
                path: '/notificaciones',
                builder: (context, state) => const NotificacionesScreen(),
              ),
              GoRoute(
                path: '/reportes',
                builder: (context, state) => const ReportesWebScreen(),
              ),
            ],
          );

          return MaterialApp.router(
            title: 'Cuaderno Profesor',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF1976D2),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1976D2),
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1976D2),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              cardTheme: const CardThemeData(elevation: 2),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              useMaterial3: true,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
