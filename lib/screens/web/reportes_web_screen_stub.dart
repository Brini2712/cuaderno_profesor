import 'package:flutter/material.dart';

class ReportesWebScreen extends StatelessWidget {
  const ReportesWebScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Los reportes avanzados están disponibles solo en la versión Web.\n\n'
            'Abre la app en un navegador (Chrome/Edge/Firefox) para usar gráficos y exportaciones.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
