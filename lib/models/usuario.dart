enum TipoUsuario { profesor, alumno }

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final TipoUsuario tipo;
  final String? fotoUrl;
  final DateTime fechaCreacion;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.tipo,
    this.fotoUrl,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'tipo': tipo.toString().split('.').last,
      'fotoUrl': fotoUrl,
      'fechaCreacion': fechaCreacion.millisecondsSinceEpoch,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      tipo: TipoUsuario.values.firstWhere(
        (e) => e.toString().split('.').last == map['tipo'],
        orElse: () => TipoUsuario.alumno,
      ),
      fotoUrl: map['fotoUrl'],
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(map['fechaCreacion'] ?? 0),
    );
  }

  Usuario copyWith({
    String? id,
    String? nombre,
    String? email,
    TipoUsuario? tipo,
    String? fotoUrl,
    DateTime? fechaCreacion,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      tipo: tipo ?? this.tipo,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}