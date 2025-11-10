import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cuaderno_provider.dart';
import '../../models/materia.dart';
import 'detalle_materia_screen.dart';

class MateriaSearchDelegate extends SearchDelegate<Materia?> {
  @override
  String get searchFieldLabel => 'Buscar materia';

  List<Materia> _filtrar(BuildContext context) {
    final provider = context.read<CuadernoProvider>();
    final q = query.trim().toLowerCase();
    final base = provider.materias;
    if (q.isEmpty) return base;
    return base
        .where(
          (m) =>
              m.nombre.toLowerCase().contains(q) ||
              m.descripcion.toLowerCase().contains(q) ||
              (m.codigoAcceso?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final resultados = _filtrar(context).take(5).toList();
    return ListView(
      children: resultados
          .map(
            (m) => ListTile(
              title: Text(
                m.grupo != null && m.grupo!.isNotEmpty
                    ? '${m.nombre} - Grupo ${m.grupo}'
                    : m.nombre,
              ),
              subtitle: Text(m.descripcion),
              onTap: () {
                query = m.nombre;
                showResults(context);
              },
            ),
          )
          .toList(),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final resultados = _filtrar(context);
    if (resultados.isEmpty) {
      return const Center(child: Text('Sin resultados'));
    }
    return ListView.builder(
      itemCount: resultados.length,
      itemBuilder: (ctx, i) {
        final m = resultados[i];
        return ListTile(
          title: Text(
            m.grupo != null && m.grupo!.isNotEmpty
                ? '${m.nombre} - Grupo ${m.grupo}'
                : m.nombre,
          ),
          subtitle: Text(m.descripcion),
          trailing: Text(m.codigoAcceso ?? ''),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DetalleMateriaScreen(materia: m),
              ),
            );
          },
        );
      },
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return null;
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }
}
