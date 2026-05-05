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
        await _supabase.from('edificaciones').select().eq('id', id).maybeSingle();
    if (response == null) {
      throw Exception('Edificación no encontrada');
    }
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
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    
    final response = await _supabase
        .from('solicitudes_revision')
        .select()
        // Mostrar solicitudes SIN asignar O asignadas a este profesional
        .or('id_profesional.is.null,id_profesional.eq.$userId')
        // Estados activos (usando .or() en lugar de .in_() para compatibilidad)
        .or('estado.eq.pendiente,estado.eq.en_revision,estado.eq.programada')
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

  Future<Map<String, dynamic>?> getInformePorId(String idInforme) async {
    final response = await _supabase
        .from('informes_tecnicos')
        .select()
        .eq('id', idInforme)
        .maybeSingle();
    return response;
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

  Future<void> actualizarPreferenciasNotificaciones(
      String idUsuario, Map<String, dynamic> preferencias) async {
    await _supabase.from('perfiles').update({
      'preferencias_notificaciones': preferencias
    }).eq('id_usuario', idUsuario);
  }

  // ===== VALORACIONES PROFESIONALES =====

  /// Obtiene todas las valoraciones de un profesional
  Future<List<Map<String, dynamic>>> getValoracionesPorProfesional(
      String idProfesional) async {
    final response = await _supabase
        .from('valoraciones_profesionales')
        .select('*')
        .eq('id_profesional', idProfesional)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Obtiene el promedio de valoraciones de un profesional
  Future<double> getPromedioValoraciones(String idProfesional) async {
    final response = await _supabase
        .rpc('get_promedio_valoraciones', params: {'profesional_id': idProfesional});
    return (response as num?)?.toDouble() ?? 0.0;
  }

  /// Crea una nueva valoración
  Future<Map<String, dynamic>> crearValoracion({
    required String idProfesional,
    required String idPropietario,
    required String idSolicitud,
    required int calificacion,
    String? comentario,
  }) async {
    final response = await _supabase
        .from('valoraciones_profesionales')
        .insert({
          'id_profesional': idProfesional,
          'id_propietario': idPropietario,
          'id_solicitud': idSolicitud,
          'calificacion': calificacion,
          if (comentario != null) 'comentario': comentario,
        })
        .select()
        .single();
    return response;
  }

  /// Verifica si ya existe una valoración para una solicitud
  Future<bool> existeValoracion(String idSolicitud) async {
    final response = await _supabase
        .from('valoraciones_profesionales')
        .select('id')
        .eq('id_solicitud', idSolicitud)
        .maybeSingle();
    return response != null;
  }

  /// Obtiene valoración por solicitud
  Future<Map<String, dynamic>?> getValoracionPorSolicitud(
      String idSolicitud) async {
    final response = await _supabase
        .from('valoraciones_profesionales')
        .select()
        .eq('id_solicitud', idSolicitud)
        .maybeSingle();
    return response;
  }

  // ===== PROFESIONALES DISPONIBLES =====

  /// Obtiene lista de profesionales disponibles con sus datos
  Future<List<Map<String, dynamic>>> getProfesionalesDisponibles() async {
    final response = await _supabase
        .from('perfiles')
        .select()
        .eq('rol', 'profesional')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Obtiene perfil completo de un profesional con estadísticas
  Future<Map<String, dynamic>> getPerfilProfesionalCompleto(
      String idProfesional) async {
    final perfil = await getPerfil(idProfesional);
    if (perfil == null) throw Exception('Profesional no encontrado');

    final promedio = await getPromedioValoraciones(idProfesional);
    final trabajosCompletados = await _supabase
        .rpc('get_trabajos_completados', params: {'profesional_id': idProfesional});
    final valoraciones = await getValoracionesPorProfesional(idProfesional);

    return {
      ...perfil,
      'valoracion_promedio': promedio,
      'trabajos_completados': trabajosCompletados ?? 0,
      'total_valoraciones': valoraciones.length,
      'ultimas_valoraciones': valoraciones.take(5).toList(),
    };
  }

  // ===== CITAS TÉCNICAS =====

  /// Crea una nueva cita técnica
  Future<Map<String, dynamic>> crearCita(Map<String, dynamic> datos) async {
    final response = await _supabase
        .from('citas_tecnicas')
        .insert(datos)
        .select()
        .single();
    return response;
  }

  /// Obtiene cita por ID de solicitud
  Future<Map<String, dynamic>?> getCitaPorSolicitud(
      String idSolicitud) async {
    final response = await _supabase
        .from('citas_tecnicas')
        .select()
        .eq('id_solicitud', idSolicitud)
        .maybeSingle();
    return response;
  }

  /// Actualiza el estado de una cita
  Future<void> actualizarEstadoCita(String id, String nuevoEstado) async {
    await _supabase
        .from('citas_tecnicas')
        .update({'estado': nuevoEstado}).eq('id', id);
  }

  /// Obtiene citas de un profesional
  Future<List<Map<String, dynamic>>> getCitasPorProfesional(
      String idProfesional) async {
    final response = await _supabase
        .from('citas_tecnicas')
        .select('*, solicitudes_revision(*, edificaciones(nombre_edificacion))')
        .eq('id_profesional', idProfesional)
        .order('fecha_programada', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Obtiene citas de un propietario
  Future<List<Map<String, dynamic>>> getCitasPorPropietario(
      String idPropietario) async {
    final response = await _supabase
        .from('citas_tecnicas')
        .select('*')
        .eq('id_propietario', idPropietario)
        .order('fecha_programada', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Actualiza una cita técnica
  Future<void> actualizarCita(String idCita, Map<String, dynamic> datos) async {
    await _supabase
        .from('citas_tecnicas')
        .update(datos)
        .eq('id', idCita);
  }

  Future<Map<String, dynamic>> getCitaPorId(String idCita) async {
    final response = await _supabase
        .from('citas_tecnicas')
        .select()
        .eq('id', idCita)
        .single();
    return response;
  }

  // ===== INFORMES =====

  /// Obtiene todos los informes generados por un profesional
  Future<List<Map<String, dynamic>>> getInformesPorProfesional(
      String idProfesional) async {
    final response = await _supabase
        .from('informes_tecnicos')
        .select('*, solicitudes_revision(*, edificaciones(nombre_edificacion))')
        .eq('id_profesional', idProfesional)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Actualiza solo la URL del PDF de un informe
  Future<void> actualizarPdfUrl(String idInforme, String pdfUrl) async {
    await _supabase
        .from('informes_tecnicos')
        .update({'pdf_url': pdfUrl}).eq('id', idInforme);
  }

  /// Marca un informe como compartido en una red social
  Future<void> marcarInformeCompartido(
      String idInforme, String redSocial) async {
    final informe = await _supabase
        .from('informes_tecnicos')
        .select('compartido_en')
        .eq('id', idInforme)
        .single();

    List<String> compartidoEn =
        List<String>.from(informe['compartido_en'] ?? []);
    if (!compartidoEn.contains(redSocial)) {
      compartidoEn.add(redSocial);
    }

    await _supabase
        .from('informes_tecnicos')
        .update({'compartido_en': compartidoEn}).eq('id', idInforme);
  }

  // ===== ESTADÍSTICAS =====

  /// Obtiene estadísticas del mes para un profesional
  Future<Map<String, dynamic>> getEstadisticasMes(
      String idProfesional) async {
    final response = await _supabase.rpc('get_estadisticas_mes',
        params: {'profesional_id': idProfesional});

    if (response is List && response.isNotEmpty) {
      return response[0] as Map<String, dynamic>;
    }

    return {
      'solicitudes_nuevas': 0,
      'en_proceso': 0,
      'completadas': 0,
      'valoracion_promedio': 0.0,
    };
  }

  /// Obtiene solicitudes asignadas a un profesional (para bandeja)
  Future<List<Map<String, dynamic>>> getSolicitudesPorProfesional(
      String idProfesional) async {
    final response = await _supabase
        .from('solicitudes_revision')
        .select('*, edificaciones(*), perfiles!id_propietario(full_name, phone)')
        .eq('id_profesional', idProfesional)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}

