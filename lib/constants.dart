// lib/constants.dart
import 'package:flutter/material.dart';
// Importa el paquete de Supabase si vas a usar SupabaseClient aquí.
// Si solo usas Supabase.instance.client, no es estrictamente necesario,
// pero es buena práctica si la constante `supabase` estuviera aquí.
// import 'package:supabase_flutter/supabase_flutter.dart';


// --- COLORES ---
const Color kAzulPrincipalOscuro = Color(0xFF2C3E50); // Azul Principal Oscuro
const Color kAzulSecundarioClaro = Color(0xFF3498DB); // Azul Secundario Claro
const Color kNaranjaAcento = Color(0xFFF39C12); // Naranja Acento

const Color kVerdeExito = Color(0xFF2ECC71); // Verde Éxito/Confirmación
const Color kRojoAdvertencia = Color(0xFFE74C3C); // Rojo Advertencia/Peligro

const Color kBlanco = Color(0xFFFFFFFF); // Blanco
const Color kGrisClaro = Color(0xFFECF0F1); // Gris Claro (Fondo)
const Color kGrisMedio = Color(0xFF7F8C8D); // Gris Medio (Texto/Íconos Secundarios)
const Color kGrisOscuro = Color(0xFF34495E); // Gris Oscuro (Texto/Íconos Principal en claro)


// --- ESTILOS DE TEXTO ---
// Fuentes: Si no tienes las fuentes Montserrat y Roboto, se usarán las predeterminadas.
// Asegúrate de añadir la sección 'fonts' en pubspec.yaml si las usas.

// Títulos/Encabezados (simulando Montserrat Bold/Semibold)
const TextStyle kTituloPrincipalStyle = TextStyle(
  fontFamily: 'Montserrat', // Si importas la fuente
  fontSize: 28.0,
  fontWeight: FontWeight.bold,
  color: kBlanco, // Por defecto para App Bars
);

const TextStyle kTituloPantallaStyle = TextStyle(
  fontFamily: 'Montserrat',
  fontSize: 24.0,
  fontWeight: FontWeight.bold,
  color: kAzulPrincipalOscuro,
);

const TextStyle kSaludoDashboardStyle = TextStyle(
  fontFamily: 'Montserrat',
  fontSize: 22.0,
  fontWeight: FontWeight.w600, // Semibold
  color: kAzulPrincipalOscuro,
);

// Cuerpo de texto (simulando Roboto Regular/Medium)
const TextStyle kBodyTextStyle = TextStyle(
  fontFamily: 'Roboto', // Si importas la fuente
  fontSize: 16.0,
  color: kGrisOscuro,
);

const TextStyle kButtonTextStyle = TextStyle(
  fontFamily: 'Roboto',
  fontSize: 16.0,
  fontWeight: FontWeight.bold,
  color: kBlanco,
);

const TextStyle kLinkTextStyle = TextStyle(
  fontFamily: 'Roboto',
  fontSize: 14.0,
  color: kAzulSecundarioClaro,
  fontWeight: FontWeight.w500, // Medium
);

const TextStyle kMiniaturaTextStyle = TextStyle(
  fontFamily: 'Roboto',
  fontSize: 12.0,
  color: kGrisMedio,
);


// --- CONSTANTES DE SUPABASE ---
// **IMPORTANTE: REEMPLAZA CON TU URL Y ANON KEY REALES DE SUPABASE**
// Puedes encontrar estos en tu panel de Supabase > Project Settings > API
const String supabaseUrl = 'https://evovehnvsfdhlklypxai.supabase.co'; // Tu URL de Supabase
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2b3ZlaG52c2ZkaGxrbHlweGFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2MTM3MDUsImV4cCI6MjA3OTE4OTcwNX0.202Z68JXtOfXX6daYqxUOGCKlzA48_Px9aBjoQwOQz4'; // Tu Anon Key de Supabase

// Si quieres una instancia global de SupabaseClient aquí, descomenta y usa esta línea.
// Asegúrate de que `package:supabase_flutter/supabase_flutter.dart` esté importado arriba.
// final SupabaseClient supabase = Supabase.instance.client;