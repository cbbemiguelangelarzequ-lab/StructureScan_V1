// lib/services/database_service.dart
// Servicio centralizado para operaciones CRUD con Supabase

import 'package:supabase_flutter/supabase_flutter.dart';
class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ===== EDIFICACIONES =====
  
  Future<List<Map<String, dynamic>>> getEdificacionesPorUsuario(
      String idUsuario) async {
    final response = await _supabase
        .from('edificaciones')
        .select()
        .eq('id_usuario', idUsuario)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getEdificacion(String id) async {
    final response =
        await _supabase.from('edificaciones').select().eq('id', id).single();
    return response;
  }

  Future<Map<String, dynamic>> crearEdificacion(
      Map<String, dynamic> datos) async {
    final response =
        await _supabase.from('edificaciones').insert(datos).select().single();
    return response;
  }

  Future<void> actualizarEdificacion(
      String id, Map<String, dynamic> datos) async {
    await _supabase.from('edificaciones').update(datos).eq('id', id);
  }

  // ===== SÍNTOMAS =====

  Future<List<Map<String, dynamic>>> getSintomasPorEdificacion(
      String idEdificacion) async {
    final response = await _supabase
        .from('sintomas_inspeccion')
        .select()
        .eq('id_edificacion', idEdificacion)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> crearSintoma(Map<String, dynamic> datos) async {
    final response = await _supabase
        .from('sintomas_inspeccion')
        .insert(datos)
        .select()
        .single();
    return response;
  }

  // ===== ANAMNESIS =====

  Future<Map<String, dynamic>?> getAnamnesisporEdificacion(
      String idEdificacion) async {
    final response = await _supabase
        .from('anamnesis')
        .select()
        .eq('id_edificacion', idEdificacion)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>> crearAnamnesis(
      Map<String, dynamic> datos) async {
    final response =
        await _supabase.from('anamnesis').insert(datos).select().single();
    return response;
  }

  Future<void> actualizarAnamnesis(
      String id, Map<String, dynamic> datos) async {
    await _supabase.from('anamnesis').update(datos).eq('id', id);
  }

  // ===== SOLICITUDES DE REVISIÓN =====

  Future<List<Map<String, dynamic>>> getSolicitudesPorPropietario(
      String idPropietario) async {
    final response = await _supabase
        .from('solicitudes_revision')
        .select()
        .eq('id_propietario', idPropietario)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getSolicitudesPendientes() async {
    final response = await _supabase
        .from('solicitudes_revision')
        .select()
        .eq('estado', 'pendiente')
        .order('nivel_riesgo', ascending: true) // ALTO primero
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> crearSolicitudRevision(
      Map<String, dynamic> datos) async {
    final response = await _supabase
        .from('solicitudes_revision')
        .insert(datos)
        .select()
        .single();
    return response;
  }

  Future<void> actualizarSolicitudRevision(
      String id, Map<String, dynamic> datos) async {
    await _supabase.from('solicitudes_revision').update(datos).eq('id', id);
  }

  // ===== HALLAZGOS PROFESIONALES =====

  Future<List<Map<String, dynamic>>> getHallazgosPorSolicitud(
      String idSolicitud) async {
    final response = await _supabase
        .from('hallazgos_profesionales')
        .select()
        .eq('id_solicitud', idSolicitud)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> crearHallazgo(
      Map<String, dynamic> datos) async {
    final response = await _supabase
        .from('hallazgos_profesionales')
        .insert(datos)
        .select()
        .single();
    return response;
  }

  // ===== INFORMES TÉCNICOS =====

  Future<Map<String, dynamic>> crearInformeTecnico(
      Map<String, dynamic> datos) async {
    final response = await _supabase
        .from('informes_tecnicos')
        .insert(datos)
        .select()
        .single();
    return response;
  }

  Future<Map<String, dynamic>?> getInformePorSolicitud(
      String idSolicitud) async {
    final response = await _supabase
        .from('informes_tecnicos')
        .select()
        .eq('id_solicitud', idSolicitud)
        .maybeSingle();
    return response;
  }

  Future<void> actualizarInformeTecnico(
      String id, Map<String, dynamic> datos) async {
    await _supabase.from('informes_tecnicos').update(datos).eq('id', id);
  }

  // ===== MÉTODOS AUXILIARES =====

  /// Obtiene síntomas por ID de edificación (alias para mejor claridad)
  Future<List<Map<String, dynamic>>> getSintomasByEdificacionId(
      String edificacionId) async {
    return getSintomasPorEdificacion(edificacionId);
  }

  /// Obtiene hallazgos por ID de solicitud (alias para mejor claridad)
  Future<List<Map<String, dynamic>>> getHallazgosBySolicitudId(
      String solicitudId) async {
    return getHallazgosPorSolicitud(solicitudId);
  }

  /// Actualiza solo el estado de una solicitud
  Future<void> updateSolicitudEstado(String id, String nuevoEstado) async {
    await _supabase
        .from('solicitudes_revision')
        .update({'estado': nuevoEstado}).eq('id', id);
  }

  /// Guarda informe técnico (alias para mejor claridad)
  Future<Map<String, dynamic>> saveInformeTecnico(
      Map<String, dynamic> datos) async {
    return crearInformeTecnico(datos);
  }

  // ===== CONSULTAS RELACIONALES =====

  /// Obtiene una edificación con todos sus síntomas y anamnesis
  Future<Map<String, dynamic>> getEdificacionCompleta(String id) async {
    final edificacion = await getEdificacion(id);
    final sintomas = await getSintomasPorEdificacion(id);
    final anamnesis = await getAnamnesisporEdificacion(id);

    return {
      'edificacion': edificacion,
      'sintomas': sintomas,
      'anamnesis': anamnesis,
    };
  }

  /// Obtiene una solicitud con la edificación relacionada
  Future<Map<String, dynamic>> getSolicitudConEdificacion(
      String idSolicitud) async {
    final solicitud = await _supabase
        .from('solicitudes_revision')
        .select('*, edificaciones(*)')
        .eq('id', idSolicitud)
        .single();
    return solicitud;
  }

  // ===== PERFILES (USUARIOS) =====

  Future<Map<String, dynamic>?> getPerfil(String idUsuario) async {
    final response = await _supabase
        .from('perfiles')
        .select()
        .eq('id_usuario', idUsuario)
        .maybeSingle();
    return response;
  }

  Future<void> actualizarPerfil(
      String idUsuario, Map<String, dynamic> datos) async {
    await _supabase.from('perfiles').update(datos).eq('id_usuario', idUsuario);
  }
}
