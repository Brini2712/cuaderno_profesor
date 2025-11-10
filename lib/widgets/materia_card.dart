import 'package:flutter/material.dart';
import '../models/materia.dart';

class MateriaCard extends StatelessWidget {
  final Materia materia;
  final VoidCallback onTap;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;
  final VoidCallback? onCopiarCodigo;

  const MateriaCard({
    super.key,
    required this.materia,
    required this.onTap,
    this.onEditar,
    this.onEliminar,
    this.onCopiarCodigo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(materia.color.replaceAll('#', '0xFF')),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      materia.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (materia.grupo != null &&
                        materia.grupo!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.class_, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Grupo ${materia.grupo}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      materia.descripcion,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${materia.alumnosIds.length} estudiantes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          materia.codigoAcceso ?? 'Sin código',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'editar' && onEditar != null) onEditar!();
                  if (v == 'eliminar' && onEliminar != null) onEliminar!();
                  if (v == 'copiar' && onCopiarCodigo != null) {
                    onCopiarCodigo!();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Text('Eliminar'),
                  ),
                  const PopupMenuItem(
                    value: 'copiar',
                    child: Text('Copiar código'),
                  ),
                ],
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
