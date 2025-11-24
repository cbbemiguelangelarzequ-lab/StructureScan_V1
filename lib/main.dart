import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Core Screens
import 'package:structurescan_app/screens/splash_screen.dart';
import 'package:structurescan_app/screens/onboarding_screen.dart';
import 'package:structurescan_app/screens/auth_screen.dart';
import 'package:structurescan_app/screens/dashboard_propietario.dart';
import 'package:structurescan_app/screens/dashboard_profesional.dart';
import 'package:structurescan_app/screens/profile_screen.dart';
import 'package:structurescan_app/screens/help_screen.dart';
import 'package:structurescan_app/screens/analisis_camara_screen.dart';
import 'package:structurescan_app/constants.dart';

// Owner Flow Screens
import 'package:structurescan_app/screens/owner/perfil_vulnerabilidad_screen.dart';
import 'package:structurescan_app/screens/owner/seleccion_sintoma_screen.dart';
import 'package:structurescan_app/screens/owner/inspeccion_grieta_screen.dart';
import 'package:structurescan_app/screens/owner/inspeccion_humedad_screen.dart';
import 'package:structurescan_app/screens/owner/inspeccion_deformacion_screen.dart';
import 'package:structurescan_app/screens/owner/anamnesis_screen.dart';
import 'package:structurescan_app/screens/owner/solicitud_revision_screen.dart';

// Professional Flow Screens
import 'package:structurescan_app/screens/professional/bandeja_solicitudes_screen.dart';
import 'package:structurescan_app/screens/professional/revision_preliminar_screen.dart';
import 'package:structurescan_app/screens/professional/inspeccion_tecnica_screen.dart';
import 'package:structurescan_app/screens/professional/generacion_informe_screen.dart';

// Función principal asíncrona para inicializar Supabase
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno (.env contiene claves de Roboflow y Google AI)
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

// Instancia global de Supabase
final SupabaseClient supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StructureScan App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kAzulPrincipalOscuro,
        hintColor: kAzulSecundarioClaro,
        scaffoldBackgroundColor: kGrisClaro,
        appBarTheme: const AppBarTheme(
          backgroundColor: kAzulPrincipalOscuro,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        // Core Flow
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/auth': (context) => const AuthScreen(),
        '/dashboard_propietario': (context) => const DashboardPropietario(),
        '/dashboard_profesional': (context) => const DashboardProfesional(),
        '/profile': (context) => const ProfileScreen(),
        '/help': (context) => const HelpScreen(),

        // Owner Flow - Phase A: Vulnerability Profile
        '/perfil_vulnerabilidad': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          return PerfilVulnerabilidadScreen(edificacionId: args);
        },

        // Owner Flow - Phase B: Symptom Selection & Inspection
        '/seleccion_sintoma': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return SeleccionSintomaScreen(edificacionId: args);
        },
        '/inspeccion_grieta': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return InspeccionGrietaScreen(edificacionId: args);
        },
        '/inspeccion_humedad': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return InspeccionHumedadScreen(edificacionId: args);
        },
        '/inspeccion_deformacion': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return InspeccionDeformacionScreen(edificacionId: args);
        },

        // Owner Flow - Phase C: Anamnesis
        '/anamnesis': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return AnamnesisScreen(edificacionId: args);
        },

        // Owner Flow - Final: Solicitud Revision
        '/solicitud_revision': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return SolicitudRevisionScreen(edificacionId: args);
        },

        // Shared AI Camera (used by symptom inspections and professionals)
        '/analisis_camara': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return AnalisisCamaraScreen(edificacionId: args);
        },

        // Professional Flow - Phase A: Reception & Triage
        '/bandeja_solicitudes': (context) => const BandejaSolicitudesScreen(),
        '/revision_preliminar': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return RevisionPreliminarScreen(solicitudId: args);
        },

        // Professional Flow - Phase B: On-site Inspection
        '/inspeccion_tecnica': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return InspeccionTecnicaScreen(solicitudId: args);
        },

        // Professional Flow - Phase C: Report Generation
        '/generacion_informe': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return GeneracionInformeScreen(solicitudId: args);
        },
      },
    );
  }
}