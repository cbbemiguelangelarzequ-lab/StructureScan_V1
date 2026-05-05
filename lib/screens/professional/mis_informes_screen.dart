// lib/screens/professional/mis_informes_screen.dart
// Pantalla que muestra todos los informes generados por el profesional

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/database_service.dart';
import '../../constants.dart';

class MisInformesScreen extends StatefulWidget {
  const MisInformesScreen({super.key});

  @override
  State<MisInformesScreen> createState() => _MisInformesScreenState();
}

class _MisInformesScreenState extends State<MisInformesScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _informes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarInformes();
  }

  Future<void> _cargarInformes() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final informes = await _db.getInformesPorProfesional(userId);

      setState(() {
        _informes = informes;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Informes'),
        backgroundColor: kAzulPrincipalOscuro,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _informes.isEmpty
              ? _buildEmpty()
              : _buildLista(),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 64, color: kGrisMedio),
          SizedBox(height: 16),
          Text(
            'No has generado informes técnicos aún',
            style: TextStyle(fontSize: 16, color: kGrisMedio),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _informes.length,
      itemBuilder: (context, index) {
        final informe = _informes[index];
        return _buildInformeCard(informe);
      },
    );
  }

  Widget _buildInformeCard(Map<String, dynamic> informe) {
    final String edificacion = informe['solicitudes_revision']?['edificaciones']
            ?['nombre_edificacion'] ??
        'Sin nombre';
    final DateTime? fecha = informe['created_at'] != null
        ? DateTime.parse(informe['created_at'])
        : null;
    final bool esHabitable = informe['es_habitable'] ?? true;
    final bool tienePdf = informe['pdf_url'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _verDetalle(informe['id']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    esHabitable ? Icons.check_circle : Icons.warning,
                    color: esHabitable ? kVerdeExito : kRojoAdvertencia,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      edificacion,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (tienePdf)
                    const Icon(Icons.picture_as_pdf, color: kRojoAdvertencia),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                esHabitable ? 'Habitable' : 'No Habitable - Requiere Intervención',
                style: TextStyle(
                  fontSize: 12,
                  color: esHabitable ? kVerdeExito : kRojoAdvertencia,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (fecha != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${fecha.day}/${fecha.month}/${fecha.year}',
                  style: const TextStyle(fontSize: 12, color: kGrisMedio),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _verDetalle(String idInforme) {
    Navigator.pushNamed(
      context,
      '/detalle_informe',
      arguments: idInforme,
    );
  }
}
