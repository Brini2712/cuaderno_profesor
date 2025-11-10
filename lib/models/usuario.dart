enum TipoUsuario { profesor, alumno }

class Usuario {
  final String id;
  final String nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String email;
  final TipoUsuario tipo;
  final String? fotoUrl;
  final DateTime fechaCreacion;

  Usuario({
    required this.id,
    required this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
    required this.email,
    required this.tipo,
    this.fotoUrl,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apellidoPaterno': apellidoPaterno,
      'apellidoMaterno': apellidoMaterno,
      'email': email,
      'tipo': tipo.toString().split('.').last,
      'fotoUrl': fotoUrl,
      'fechaCreacion': fechaCreacion.millisecondsSinceEpoch,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    String nombre = map['nombre'] ?? '';
    String? apPat = map['apellidoPaterno'];
    String? apMat = map['apellidoMaterno'];
    // Fallback: si no vienen apellidos, intentar parsearlos desde nombre
    if ((apPat == null || apPat.isEmpty) && (apMat == null || apMat.isEmpty)) {
      final parts = (nombre.trim())
          .split(RegExp(r"\s+"))
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length >= 3) {
        apPat = parts[parts.length - 2];
        apMat = parts[parts.length - 1];
        nombre = parts.sublist(0, parts.length - 2).join(' ');
      } else if (parts.length == 2) {
        apPat = parts[1];
        nombre = parts[0];
      }
    }
    return Usuario(
      id: map['id'] ?? '',
      nombre: nombre,
      apellidoPaterno: apPat,
      apellidoMaterno: apMat,
      email: map['email'] ?? '',
      tipo: TipoUsuario.values.firstWhere(
        (e) => e.toString().split('.').last == map['tipo'],
        orElse: () => TipoUsuario.alumno,
      ),
      fotoUrl: map['fotoUrl'],
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(
        map['fechaCreacion'] ?? 0,
      ),
    );
  }

  Usuario copyWith({
    String? id,
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? email,
    TipoUsuario? tipo,
    String? fotoUrl,
    DateTime? fechaCreacion,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      email: email ?? this.email,
      tipo: tipo ?? this.tipo,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  // Nombre completo con apellidos (para mostrar en listas)
  String get nombreCompleto {
    final apPat = apellidoPaterno?.trim() ?? '';
    final apMat = apellidoMaterno?.trim() ?? '';
    final nom = nombre.trim();
    return [apPat, apMat, nom].where((p) => p.isNotEmpty).join(' ').trim();
  }
}
