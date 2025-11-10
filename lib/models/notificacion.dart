import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Notificacion {
  final String id;
  final String usuarioId;
  final String titulo;
  final String mensaje;
  final String tipo; // 'evidencia', 'calificacion', 'asistencia', 'general'
  final DateTime fecha;
  final bool leida;
  final String? materiaId;
  final String? evidenciaId;

  Notificacion({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.fecha,
    this.leida = false,
    this.materiaId,
    this.evidenciaId,
  });

  factory Notificacion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Notificacion(
      id: doc.id,
      usuarioId: data['usuarioId'] ?? '',
      titulo: data['titulo'] ?? '',
      mensaje: data['mensaje'] ?? '',
      tipo: data['tipo'] ?? 'general',
      fecha: (data['fecha'] as Timestamp).toDate(),
      leida: data['leida'] ?? false,
      materiaId: data['materiaId'],
      evidenciaId: data['evidenciaId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'usuarioId': usuarioId,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'fecha': Timestamp.fromDate(fecha),
      'leida': leida,
      if (materiaId != null) 'materiaId': materiaId,
      if (evidenciaId != null) 'evidenciaId': evidenciaId,
    };
  }

  Notificacion copyWith({
    String? id,
    String? usuarioId,
    String? titulo,
    String? mensaje,
    String? tipo,
    DateTime? fecha,
    bool? leida,
    String? materiaId,
    String? evidenciaId,
  }) {
    return Notificacion(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      leida: leida ?? this.leida,
      materiaId: materiaId ?? this.materiaId,
      evidenciaId: evidenciaId ?? this.evidenciaId,
    );
  }

  IconData get icono {
    switch (tipo) {
      case 'evidencia':
        return Icons.assignment;
      case 'calificacion':
        return Icons.grade;
      case 'asistencia':
        return Icons.event_available;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (tipo) {
      case 'evidencia':
        return Colors.blue;
      case 'calificacion':
        return Colors.orange;
      case 'asistencia':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
