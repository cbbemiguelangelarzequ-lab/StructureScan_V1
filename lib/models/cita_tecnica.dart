// lib/models/cita_tecnica.dart
// Modelo de datos para citas técnicas

import 'package:flutter/material.dart';

class CitaTecnica {
  final String? id;
  final String idSolicitud;
  final String idProfesional;
  final String idPropietario;
  final DateTime fechaProgramada;
  final TimeOfDay horaInicio;
  final TimeOfDay? horaFin;
  final double? costoEstimado;
  final String? direccion;
  final String? notasProfesional;
  final EstadoCita estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CitaTecnica({
    this.id,
    required this.idSolicitud,
    required this.idProfesional,
    required this.idPropietario,
    required this.fechaProgramada,
    required this.horaInicio,
    this.horaFin,
    this.costoEstimado,
    this.direccion,
    this.notasProfesional,
    this.estado = EstadoCita.pendienteConfirmacion,
    this.createdAt,
    this.updatedAt,
  });

  // Convertir desde JSON (Supabase)
  factory CitaTecnica.fromJson(Map<String, dynamic> json) {
    return CitaTecnica(
      id: json['id'] as String?,
      idSolicitud: json['id_solicitud'] as String,
      idProfesional: json['id_profesional'] as String,
      idPropietario: json['id_propietario'] as String,
      fechaProgramada: DateTime.parse(json['fecha_programada'] as String),
      horaInicio: _timeFromString(json['hora_inicio'] as String),
      horaFin: json['hora_fin'] != null
          ? _timeFromString(json['hora_fin'] as String)
          : null,
      costoEstimado: json['costo_estimado'] != null
          ? (json['costo_estimado'] as num).toDouble()
          : null,
      direccion: json['direccion'] as String?,
      notasProfesional: json['notas_profesional'] as String?,
      estado: EstadoCita.fromString(json['estado'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'id_solicitud': idSolicitud,
      'id_profesional': idProfesional,
      'id_propietario': idPropietario,
      'fecha_programada': fechaProgramada.toIso8601String(),
      'hora_inicio': _timeToString(horaInicio),
      if (horaFin != null) 'hora_fin': _timeToString(horaFin!),
      if (costoEstimado != null) 'costo_estimado': costoEstimado,
      if (direccion != null) 'direccion': direccion,
      if (notasProfesional != null) 'notas_profesional': notasProfesional,
      'estado': estado.value,
    };
  }

  // Helper para convertir TimeOfDay a String (formato HH:MM:SS)
  static String _timeToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  // Helper para convertir String a TimeOfDay
  static TimeOfDay _timeFromString(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // CopyWith para crear copias modificadas
  CitaTecnica copyWith({
    String? id,
    String? idSolicitud,
    String? idProfesional,
    String? idPropietario,
    DateTime? fechaProgramada,
    TimeOfDay? horaInicio,
    TimeOfDay? horaFin,
    double? costoEstimado,
    String? direccion,
    String? notasProfesional,
    EstadoCita? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CitaTecnica(
      id: id ?? this.id,
      idSolicitud: idSolicitud ?? this.idSolicitud,
      idProfesional: idProfesional ?? this.idProfesional,
      idPropietario: idPropietario ?? this.idPropietario,
      fechaProgramada: fechaProgramada ?? this.fechaProgramada,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      costoEstimado: costoEstimado ?? this.costoEstimado,
      direccion: direccion ?? this.direccion,
      notasProfesional: notasProfesional ?? this.notasProfesional,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CitaTecnica{id: $id, fecha: $fechaProgramada, estado: ${estado.displayName}}';
  }
}

// Enum para Estado de Cita
enum EstadoCita {
  pendienteConfirmacion(
      'pendiente_confirmacion', 'Pendiente Confirmación', '⏳'),
  confirmada('confirmada', 'Confirmada', '✅'),
  cancelada('cancelada', 'Cancelada', '❌'),
  completada('completada', 'Completada', '🎯');

  final String value;
  final String displayName;
  final String emoji;

  const EstadoCita(this.value, this.displayName, this.emoji);

  static EstadoCita fromString(String value) {
    return EstadoCita.values.firstWhere((e) => e.value == value);
  }
}
