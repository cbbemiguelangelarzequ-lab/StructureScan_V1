// lib/screens/professional/editar_perfil_profesional_screen.dart
// Pantalla para que el profesional edite su información profesional

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constants.dart';
import '../../services/database_service.dart';
import '../../services/image_processing_service.dart';

class EditarPerfilProfesionalScreen extends StatefulWidget {
  const EditarPerfilProfesionalScreen({super.key});

  @override
  State<EditarPerfilProfesionalScreen> createState() =>
      _EditarPerfilProfesionalScreenState();
}

class _EditarPerfilProfesionalScreenState
    extends State<EditarPerfilProfesionalScreen> {
  final DatabaseService _db = DatabaseService();
  final ImageProcessingService _imageService = ImageProcessingService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nombreController = TextEditingController();
  final _phoneController = TextEditingController();
  final _especializacionController = TextEditingController();
  final _universidadController = TextEditingController();
  final _tituloController = TextEditingController();
  final _cipController = TextEditingController();
  final _experienciaController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _tarifaDesdeController = TextEditingController();
  final _tarifaHastaController = TextEditingController();

  List<String> _certificaciones = [];
  final _certificacionController = TextEditingController();

  String? _fotoPerfilUrl;
  bool _cargando = true;
  bool _guardando = false;
  bool _subiendoFoto = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _phoneController.dispose();
    _especializacionController.dispose();
    _universidadController.dispose();
    _tituloController.dispose();
    _cipController.dispose();
    _experienciaController.dispose();
    _descripcionController.dispose();
    _tarifaDesdeController.dispose();
    _tarifaHastaController.dispose();
    _certificacionController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final perfil = await _db.getPerfil(userId);

      if (perfil != null) {
        setState(() {
          _nombreController.text = perfil['full_name'] ?? '';
          _phoneController.text = perfil['phone'] ?? '';
          _especializacionController.text = perfil['especializacion'] ?? '';
          _universidadController.text = perfil['universidad'] ?? '';
          _tituloController.text = perfil['titulo_academico'] ?? '';
          _cipController.text = perfil['cip_numero'] ?? '';
          _experienciaController.text =
              (perfil['years_experiencia'] ?? 0).toString();
          _descripcionController.text = perfil['descripcion_profesional'] ?? '';
          _tarifaDesdeController.text =
              (perfil['tarifa_desde'] ?? '').toString();
          _tarifaHastaController.text =
              (perfil['tarifa_hasta'] ?? '').toString();
          _fotoPerfilUrl = perfil['foto_perfil_url'];

          if (perfil['certificaciones'] != null) {
            _certificaciones =
                List<String>.from(perfil['certificaciones'] as List);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfil: $e')),
        );
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await _db.actualizarPerfil(userId, {
        'full_name': _nombreController.text.trim(),
        'phone': _phoneController.text.trim(),
        'especializacion': _especializacionController.text.trim(),
        'universidad': _universidadController.text.trim(),
        'titulo_academico': _tituloController.text.trim(),
        'cip_numero': _cipController.text.trim(),
        'years_experiencia': int.tryParse(_experienciaController.text) ?? 0,
        'descripcion_profesional': _descripcionController.text.trim(),
        'tarifa_desde': double.tryParse(_tarifaDesdeController.text),
        'tarifa_hasta': double.tryParse(_tarifaHastaController.text),
        'certificaciones': _certificaciones,
        if (_fotoPerfilUrl != null) 'foto_perfil_url': _fotoPerfilUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil actualizado exitosamente'),
            backgroundColor: kVerdeExito,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: kRojoAdvertencia,
          ),
        );
      }
    } finally {
      setState(() => _guardando = false);
    }
  }

  Future<void> _cambiarFotoPerfil() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _subiendoFoto = true);

      final userId = Supabase.instance.client.auth.currentUser!.id;

      final fotoUrl = await _imageService.subirFotoPerfil(
        imagen: File(image.path),
        userId: userId,
      );

      setState(() {
        _fotoPerfilUrl = fotoUrl;
        _subiendoFoto = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto cargada (guarda para aplicar cambios)'),
            backgroundColor: kVerdeExito,
          ),
        );
      }
    } catch (e) {
      setState(() => _subiendoFoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar foto: $e'),
            backgroundColor: kRojoAdvertencia,
          ),
        );
      }
    }
  }

  void _agregarCertificacion() {
    if (_certificacionController.text.trim().isNotEmpty) {
      setState(() {
        _certificaciones.add(_certificacionController.text.trim());
        _certificacionController.clear();
      });
    }
  }

  void _eliminarCertificacion(int index) {
    setState(() {
      _certificaciones.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil Profesional'),
        backgroundColor: kAzulPrincipalOscuro,
        actions: [
          if (!_cargando)
            IconButton(
              icon: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(kBlanco),
                      ),
                    )
                  : const Icon(Icons.save),
              onPressed: _guardando ? null : _guardarPerfil,
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Foto de Perfil
                    _buildSeccionTitulo('Foto de Perfil'),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: kGrisClaro,
                            backgroundImage: _fotoPerfilUrl != null
                                ? NetworkImage(_fotoPerfilUrl!)
                                : null,
                            child: _fotoPerfilUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: kGrisMedio,
                                  )
                                : null,
                          ),
                          if (_subiendoFoto)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(kBlanco),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _subiendoFoto ? null : _cambiarFotoPerfil,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kAzulPrincipalOscuro,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kBlanco, width: 3),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: kBlanco,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Información Básica
                    _buildSeccionTitulo('Información Básica'),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre Completo *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (WhatsApp) *',
                        hintText: 'Ej: +59170000000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _especializacionController,
                      decoration: const InputDecoration(
                        labelText: 'Especialización',
                        hintText: 'Ej: Ingeniero Estructural',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Formación Académica
                    _buildSeccionTitulo('Formación Académica'),
                    TextFormField(
                      controller: _universidadController,
                      decoration: const InputDecoration(
                        labelText: 'Universidad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título Académico',
                        hintText: 'Ej: Ingeniero Civil',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cipController,
                      decoration: const InputDecoration(
                        labelText: 'Número CIP',
                        hintText: 'Colegio de Ingenieros del Perú',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _experienciaController,
                      decoration: const InputDecoration(
                        labelText: 'Años de Experiencia',
                        border: OutlineInputBorder(),
                        suffixText: 'años',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final num = int.tryParse(value);
                          if (num == null || num < 0) {
                            return 'Ingrese un número válido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Descripción Profesional
                    _buildSeccionTitulo('Sobre Mí'),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción Profesional',
                        hintText:
                            'Cuéntanos sobre tu experiencia y especialidades...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      maxLength: 500,
                    ),
                    const SizedBox(height: 24),

                    // Tarifas
                    _buildSeccionTitulo('Tarifas Estimadas'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tarifaDesdeController,
                            decoration: const InputDecoration(
                              labelText: 'Desde',
                              border: OutlineInputBorder(),
                              prefixText: 'Bs/. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final num = double.tryParse(value);
                                if (num == null || num < 0) {
                                  return 'Número inválido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _tarifaHastaController,
                            decoration: const InputDecoration(
                              labelText: 'Hasta',
                              border: OutlineInputBorder(),
                              prefixText: 'Bs/. ',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final num = double.tryParse(value);
                                if (num == null || num < 0) {
                                  return 'Número inválido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Certificaciones
                    _buildSeccionTitulo('Certificaciones'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _certificacionController,
                            decoration: const InputDecoration(
                              labelText: 'Nueva Certificación',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _agregarCertificacion(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, size: 32),
                          color: kVerdeExito,
                          onPressed: _agregarCertificacion,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_certificaciones.isNotEmpty)
                      ..._certificaciones.asMap().entries.map((entry) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.verified,
                                color: kVerdeExito),
                            title: Text(entry.value),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: kRojoAdvertencia),
                              onPressed: () =>
                                  _eliminarCertificacion(entry.key),
                            ),
                          ),
                        );
                      }).toList(),
                    const SizedBox(height: 32),

                    // Botón Guardar
                    ElevatedButton(
                      onPressed: _guardando ? null : _guardarPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kVerdeExito,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _guardando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(kBlanco),
                              ),
                            )
                          : const Text(
                              'Guardar Cambios',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kBlanco,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kAzulPrincipalOscuro,
        ),
      ),
    );
  }
}
