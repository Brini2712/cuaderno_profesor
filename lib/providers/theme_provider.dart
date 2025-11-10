import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _modoOscuro = false;
  bool _isLoading = true;

  bool get modoOscuro => _modoOscuro;
  bool get isLoading => _isLoading;

  /// Ajusta el color para que se vea bien en modo oscuro
  /// Reduce mucho la saturación para colores más grises y sutiles
  Color ajustarColorParaDarkMode(Color color) {
    if (!_modoOscuro) return color;

    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(
          (hsl.saturation * 0.3).clamp(0.0, 1.0),
        ) // Muy desaturado (más gris)
        .withLightness(0.5) // Luminosidad media (gris medio)
        .toColor();
  }

  ThemeProvider() {
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _modoOscuro = prefs.getBool('modoOscuro') ?? false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error al cargar preferencias de tema: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleModoOscuro() async {
    _modoOscuro = !_modoOscuro;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('modoOscuro', _modoOscuro);
      debugPrint('✅ Modo oscuro guardado: $_modoOscuro');
    } catch (e) {
      debugPrint('❌ Error al guardar preferencia de tema: $e');
    }
  }

  // Tema claro (actual)
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );

  // Tema oscuro
  // Tema oscuro (estilo Google Classroom)
  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6B7A8F), // Azul gris apagado
      secondary: Color(0xFF6B7A8F),
      surface: Color(0xFF1E1E1E), // Fondo de tarjetas (más oscuro)
      background: Color(0xFF0D0D0D), // Fondo principal (negro profundo)
      onPrimary: Color(0xFFE0E0E0),
      onSecondary: Color(0xFFE0E0E0),
      onSurface: Color(0xFFB0B0B0), // Texto principal (gris medio)
      onBackground: Color(0xFFB0B0B0), // Texto sobre fondo
    ),
    scaffoldBackgroundColor: const Color(0xFF0D0D0D), // Fondo muy oscuro
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A), // Gris muy oscuro
      foregroundColor: Color(0xFFB0B0B0), // Texto gris medio
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF808080)),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E), // Tarjetas oscuras
      elevation: 1,
      surfaceTintColor: Colors.transparent,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFF141414), // Sidebar muy oscuro
      selectedIconTheme: IconThemeData(color: Color(0xFF6B7A8F)),
      unselectedIconTheme: IconThemeData(color: Color(0xFF505050)),
      selectedLabelTextStyle: TextStyle(color: Color(0xFF6B7A8F)),
      unselectedLabelTextStyle: TextStyle(color: Color(0xFF505050)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      selectedItemColor: Color(0xFF6B7A8F),
      unselectedItemColor: Color(0xFF505050),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E), // Inputs oscuros
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6B7A8F), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF808080)),
      hintStyle: const TextStyle(color: Color(0xFF606060)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6B7A8F),
        foregroundColor: const Color(0xFFE0E0E0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFB0B0B0)),
      bodyMedium: TextStyle(color: Color(0xFFB0B0B0)),
      bodySmall: TextStyle(color: Color(0xFF808080)),
      titleLarge: TextStyle(color: Color(0xFFB0B0B0)),
      titleMedium: TextStyle(color: Color(0xFFB0B0B0)),
      titleSmall: TextStyle(color: Color(0xFFB0B0B0)),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF808080)),
    dividerColor: const Color(0xFF2A2A2A),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      surfaceTintColor: Colors.transparent,
    ),
  );
}
