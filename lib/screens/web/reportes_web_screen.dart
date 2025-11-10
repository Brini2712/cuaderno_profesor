import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:convert';
import '../../providers/cuaderno_provider.dart';
import '../../models/reporte_estadisticas.dart';

class ReportesWebScreen extends StatefulWidget {
  const ReportesWebScreen({super.key});

  @override
  State<ReportesWebScreen> createState() => _ReportesWebScreenState();
}

class _ReportesWebScreenState extends State<ReportesWebScreen> {
  String? _materiaSeleccionada;
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 7));
  DateTime _fechaFin = DateTime.now();
  RangoPreset _rangoPreset = RangoPreset.semana;
  ReporteEstadisticas? _reporte;
  int? _evaluacionSeleccionada; // null = todas, 1/2/3 = específica

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CuadernoProvider>();
      if (provider.materias.isNotEmpty) {
        setState(() {
          _materiaSeleccionada = provider.materias.first.id;
        });
        _generarReporte();
      }
    });
  }

  void _cambiarRangoPreset(RangoPreset preset) {
    setState(() {
      _rangoPreset = preset;
      final now = DateTime.now();
      switch (preset) {
        case RangoPreset.semana:
          _fechaInicio = now.subtract(const Duration(days: 7));
          _fechaFin = now;
          break;
        case RangoPreset.mes:
          _fechaInicio = DateTime(now.year, now.month, 1);
          _fechaFin = DateTime(now.year, now.month + 1, 0);
          break;
        case RangoPreset.custom:
          // No cambiar, el usuario elegirá
          break;
      }
    });
    _generarReporte();
  }

  void _generarReporte() {
    if (_materiaSeleccionada == null) return;
    final provider = context.read<CuadernoProvider>();
    setState(() {
      _reporte = provider.generarReporte(
        materiaId: _materiaSeleccionada!,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
    });
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
        _rangoPreset = RangoPreset.custom;
      });
      _generarReporte();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CuadernoProvider>();
    final materias = provider.materias;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Estadísticas'),
        elevation: 0,
        actions: [
          if (_reporte != null) ...[
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Exportar CSV',
              onPressed: () => _exportarCSV(_reporte!),
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Exportar PDF',
              onPressed: () => _exportarPDF(_reporte!),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: materias.isEmpty
          ? const Center(child: Text('No hay materias disponibles'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Controles de filtro
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filtros',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _materiaSeleccionada,
                                  decoration: const InputDecoration(
                                    labelText: 'Materia',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: materias
                                      .map(
                                        (m) => DropdownMenuItem(
                                          value: m.id,
                                          child: Text(
                                            m.grupo != null &&
                                                    m.grupo!.isNotEmpty
                                                ? '${m.nombre} - Grupo ${m.grupo}'
                                                : m.nombre,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _materiaSeleccionada = val;
                                    });
                                    _generarReporte();
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: SegmentedButton<RangoPreset>(
                                  segments: const [
                                    ButtonSegment(
                                      value: RangoPreset.semana,
                                      label: Text('Semana'),
                                    ),
                                    ButtonSegment(
                                      value: RangoPreset.mes,
                                      label: Text('Mes'),
                                    ),
                                    ButtonSegment(
                                      value: RangoPreset.custom,
                                      label: Text('Personalizado'),
                                    ),
                                  ],
                                  selected: {_rangoPreset},
                                  onSelectionChanged: (Set<RangoPreset> sel) {
                                    if (sel.isNotEmpty) {
                                      _cambiarRangoPreset(sel.first);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<int?>(
                                  initialValue: _evaluacionSeleccionada,
                                  decoration: const InputDecoration(
                                    labelText: 'Evaluación',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text('Todas'),
                                    ),
                                    DropdownMenuItem(
                                      value: 1,
                                      child: Text('1era Evaluación'),
                                    ),
                                    DropdownMenuItem(
                                      value: 2,
                                      child: Text('2da Evaluación'),
                                    ),
                                    DropdownMenuItem(
                                      value: 3,
                                      child: Text('3era Evaluación'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() {
                                      _evaluacionSeleccionada = val;
                                    });
                                    _generarReporte();
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_rangoPreset == RangoPreset.custom) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _seleccionarFecha(context, true),
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(
                                      'Inicio: ${DateFormat('dd/MM/yyyy').format(_fechaInicio)}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _seleccionarFecha(context, false),
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(
                                      'Fin: ${DateFormat('dd/MM/yyyy').format(_fechaFin)}',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Resumen general
                  if (_reporte != null) ...[
                    _buildResumenGeneral(_reporte!),
                    const SizedBox(height: 24),
                    _buildGraficos(_reporte!),
                    const SizedBox(height: 24),
                    _buildTablaAlumnos(_reporte!),
                  ] else
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
    );
  }

  Widget _buildResumenGeneral(ReporteEstadisticas reporte) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen General - ${reporte.materiaNombre}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildKPI(
                    'Asistencia Promedio',
                    '${reporte.promedioAsistenciaGrupo.toStringAsFixed(1)}%',
                    Icons.person_outline,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPI(
                    'Evidencias Promedio',
                    '${reporte.promedioEvidenciasGrupo.toStringAsFixed(1)}%',
                    Icons.assignment,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPI(
                    'Alumnos en Riesgo',
                    '${reporte.alumnosEnRiesgo}',
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPI(
                    'Alumnos Exentos',
                    '${reporte.alumnosExentos}',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPI(
                    'Requieren Ordinaria',
                    '${reporte.alumnosConOrdinaria}',
                    Icons.school,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPI(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaAlumnos(ReporteEstadisticas reporte) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalle por Alumno',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Alumno',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Calificación\nFinal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Asistencia',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Evidencias',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Evaluaciones\nReprobadas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Estado',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: reporte.estadisticasAlumnos.map((alumno) {
                  return DataRow(
                    cells: [
                      DataCell(Text(alumno.alumnoNombre)),
                      DataCell(
                        Text(
                          alumno.calificacionFinal != null
                              ? alumno.calificacionFinal!.toStringAsFixed(1)
                              : 'N/A',
                          style: TextStyle(
                            color: alumno.calificacionFinal != null
                                ? (alumno.calificacionFinal! >= 6
                                      ? Colors.green
                                      : Colors.red)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${alumno.porcentajeAsistencia.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: alumno.porcentajeAsistencia < 80
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${alumno.porcentajeEvidencias.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: alumno.porcentajeEvidencias < 50
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${alumno.evaluacionesReprobadas}/3',
                          style: TextStyle(
                            color: alumno.evaluacionesReprobadas >= 2
                                ? Colors.purple
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                      DataCell(
                        Chip(
                          label: Text(
                            alumno.estadoGeneral,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: _colorEstado(alumno.estadoGeneral),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Exento':
        return Colors.amber[100]!;
      case 'Riesgo':
        return Colors.orange[100]!;
      case 'Ordinaria':
        return Colors.purple[100]!;
      default:
        return Colors.green[100]!;
    }
  }

  Widget _buildGraficos(ReporteEstadisticas reporte) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribución de Estados',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: reporte.alumnosExentos.toDouble(),
                            title: 'Exentos\n${reporte.alumnosExentos}',
                            color: Colors.amber,
                            radius: 100,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: reporte.alumnosEnRiesgo.toDouble(),
                            title: 'Riesgo\n${reporte.alumnosEnRiesgo}',
                            color: Colors.orange,
                            radius: 100,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: reporte.alumnosConOrdinaria.toDouble(),
                            title: 'Ordinaria\n${reporte.alumnosConOrdinaria}',
                            color: Colors.purple,
                            radius: 100,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value:
                                (reporte.estadisticasAlumnos.length -
                                        reporte.alumnosExentos -
                                        reporte.alumnosEnRiesgo -
                                        reporte.alumnosConOrdinaria)
                                    .toDouble(),
                            title:
                                'Regular\n${reporte.estadisticasAlumnos.length - reporte.alumnosExentos - reporte.alumnosEnRiesgo - reporte.alumnosConOrdinaria}',
                            color: Colors.green,
                            radius: 100,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Promedios del Grupo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text('Asistencia');
                                  case 1:
                                    return const Text('Evidencias');
                                  default:
                                    return const Text('');
                                }
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}%');
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: reporte.promedioAsistenciaGrupo,
                                color: Colors.blue,
                                width: 50,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: reporte.promedioEvidenciasGrupo,
                                color: Colors.green,
                                width: 50,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportarPDF(ReporteEstadisticas reporte) async {
    final pdf = pw.Document();

    final baseColor = PdfColors.indigo;
    // PdfColor no soporta withOpacity directamente; crear un color claro manual.
    final lightFill = PdfColor.fromInt(0xF0F3F9FF); // tono muy claro azulado

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Reporte de Estadísticas',
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: baseColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.now()),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(height: 1.2, color: baseColor),
              pw.SizedBox(height: 6),
              pw.Text(
                'Materia: ${reporte.materiaNombre}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.Text(
                'Periodo: ${DateFormat('dd/MM/yyyy').format(reporte.fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(reporte.fechaFin)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              if (_evaluacionSeleccionada != null)
                pw.Text(
                  'Evaluación: $_evaluacionSeleccionada',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        build: (pw.Context context) {
          return [
            // Resumen en tarjetas
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _kpiBox(
                  'Asistencia Promedio',
                  '${reporte.promedioAsistenciaGrupo.toStringAsFixed(1)}%',
                  baseColor,
                  lightFill,
                ),
                _kpiBox(
                  'Evidencias Promedio',
                  '${reporte.promedioEvidenciasGrupo.toStringAsFixed(1)}%',
                  baseColor,
                  lightFill,
                ),
                _kpiBox(
                  'En Riesgo',
                  '${reporte.alumnosEnRiesgo}',
                  baseColor,
                  lightFill,
                ),
                _kpiBox(
                  'Exentos',
                  '${reporte.alumnosExentos}',
                  baseColor,
                  lightFill,
                ),
                _kpiBox(
                  'Ordinaria',
                  '${reporte.alumnosConOrdinaria}',
                  baseColor,
                  lightFill,
                ),
                _kpiBox(
                  'Calificación Promedio',
                  reporte.promedioCalificacionGrupo.toStringAsFixed(1),
                  baseColor,
                  lightFill,
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            pw.Text(
              'Detalle por Alumno',
              style: pw.TextStyle(
                fontSize: 14,
                color: baseColor,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              headers: const [
                'Alumno',
                'Cal. Final',
                'Asistencia',
                'Evidencias',
                'Eval. Rep.',
                'Estado',
              ],
              data: [
                for (final alumno in reporte.estadisticasAlumnos)
                  [
                    alumno.alumnoNombre,
                    alumno.calificacionFinal != null
                        ? alumno.calificacionFinal!.toStringAsFixed(1)
                        : 'N/A',
                    '${alumno.porcentajeAsistencia.toStringAsFixed(1)}%',
                    '${alumno.porcentajeEvidencias.toStringAsFixed(1)}%',
                    '${alumno.evaluacionesReprobadas}/3',
                    alumno.estadoGeneral,
                  ],
              ],
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: pw.BoxDecoration(color: baseColor),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              oddRowDecoration: pw.BoxDecoration(color: lightFill),
              border: null,
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1.2),
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _kpiBox(String title, String value, PdfColor color, PdfColor fill) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: fill,
        borderRadius: pw.BorderRadius.circular(8),
        // Simular opacidad reduciendo intensidad mezclando con blanco
        border: pw.Border.all(color: PdfColor.fromInt(0xD5D9E6FF), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _exportarCSV(ReporteEstadisticas reporte) {
    final List<List<dynamic>> rows = [];

    // Metadatos al inicio (compatibles con Excel/Sheets)
    rows.add(['Reporte de Estadísticas']);
    rows.add(['Materia', reporte.materiaNombre]);
    rows.add([
      'Periodo',
      '${DateFormat('dd/MM/yyyy').format(reporte.fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(reporte.fechaFin)}',
    ]);
    if (_evaluacionSeleccionada != null) {
      rows.add(['Evaluación', _evaluacionSeleccionada]);
    }
    rows.add([]); // línea en blanco

    // Encabezados de la tabla
    rows.add([
      'Alumno',
      'Calificación Final',
      'Asistencia (%)',
      'Evidencias (%)',
      'Evaluaciones Reprobadas',
      'Estado',
    ]);

    // Datos
    for (final alumno in reporte.estadisticasAlumnos) {
      rows.add([
        alumno.alumnoNombre,
        alumno.calificacionFinal != null
            ? alumno.calificacionFinal!.toStringAsFixed(1)
            : 'N/A',
        alumno.porcentajeAsistencia.toStringAsFixed(1),
        alumno.porcentajeEvidencias.toStringAsFixed(1),
        '${alumno.evaluacionesReprobadas}/3',
        alumno.estadoGeneral,
      ]);
    }

    // Usar ; como separador y BOM UTF-8 para compatibilidad con Excel (acentos)
    final converter = const ListToCsvConverter(
      fieldDelimiter: ';',
      textDelimiter: '"',
      eol: '\r\n',
    );
    final String csv = converter.convert(rows);
    final bytes = utf8.encode('\uFEFF$csv'); // BOM + CSV
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'reporte_${reporte.materiaNombre}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
      )
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV exportado exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

enum RangoPreset { semana, mes, custom }
