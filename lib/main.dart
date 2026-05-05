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
import 'package:structurescan_app/screens/forgot_password_screen.dart';
import 'package:structurescan_app/screens/analisis_camara_screen.dart';
import 'package:structurescan_app/constants.dart';

// Owner Flow Screens
import 'package:structurescan_app/screens/owner/perfil_vulnerabilidad_screen.dart';
import 'package:structurescan_app/screens/owner/seleccion_sintoma_screen.dart';
import 'package:structurescan_app/screens/owner/inspeccion_grieta_screen.dart';
import 'package:structurescan_app/screens/owner/inspeccion_humedad_screen.dart';
import 'package:structurescan_app/screens/owner/inspeccion_deformacion_screen.dart';
import 'package:structurescan_app/screens/owner/inspeccion_desprendimiento_screen.dart';
import 'package:structurescan_app/screens/owner/anamnesis_screen.dart';
import 'package:structurescan_app/screens/owner/solicitud_revision_screen.dart';
import 'package:structurescan_app/screens/owner/seleccion_profesional_screen.dart';
import 'package:structurescan_app/screens/owner/perfil_profesional_screen.dart';
import 'package:structurescan_app/screens/owner/valorar_profesional_screen.dart';
import 'package:structurescan_app/screens/owner/confirmar_cita_screen.dart';
import 'package:structurescan_app/screens/owner/mis_solicitudes_propietario_screen.dart';
import 'package:structurescan_app/screens/owner/detalle_solicitud_propietario_screen.dart';

// Professional Flow Screens
import 'package:structurescan_app/screens/professional/bandeja_solicitudes_screen.dart';
import 'package:structurescan_app/screens/professional/revision_preliminar_screen.dart';
import 'package:structurescan_app/screens/professional/inspeccion_tecnica_screen.dart';
import 'package:structurescan_app/screens/professional/generacion_informe_screen.dart';
import 'package:structurescan_app/screens/professional/agendar_cita_screen.dart';
import 'package:structurescan_app/screens/professional/mis_informes_screen.dart';
import 'package:structurescan_app/screens/professional/detalle_informe_screen.dart';
import 'package:structurescan_app/screens/professional/editar_perfil_profesional_screen.dart';

// Common Screens
import 'package:structurescan_app/screens/common/perfil_usuario_screen.dart';
import 'package:structurescan_app/screens/settings/notificaciones_screen.dart';
import 'package:structurescan_app/screens/settings/notificaciones_screen.dart';
import 'package:structurescan_app/screens/settings/seguridad_screen.dart';
import 'package:structurescan_app/services/localization_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
    return AnimatedBuilder(
      animation: LocalizationService(),
      builder: (context, child) {
        return MaterialApp(
          title: 'StructureScan App',
          debugShowCheckedModeBanner: false,
          locale: LocalizationService().currentLocale,
          supportedLocales: const [
            Locale('es'),
            Locale('en'),
            Locale('pt'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
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
            '/forgot_password': (context) => const ForgotPasswordScreen(),
    
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
            '/inspeccion_desprendimiento': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as String;
              return InspeccionDesprendimientoScreen(edificacionId: args);
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
    
            // Owner Flow - Professional Selection & Rating
            '/seleccion_profesional': (context) => const SeleccionProfesionalScreen(),
            '/perfil_profesional': (context) {
              final idProfesional = ModalRoute.of(context)?.settings.arguments as String;
              return PerfilProfesionalScreen(idProfesional: idProfesional);
            },
            '/valorar_profesional': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
              return ValorarProfesionalScreen(
                idSolicitud: args['idSolicitud'],
                idProfesional: args['idProfesional'],
                nombreProfesional: args['nombreProfesional'],
              );
            },
    
            // Owner Flow - Mis Solicitudes
            '/mis_solicitudes_propietario': (context) => const MisSolicitudesPropietarioScreen(),
            '/detalle_solicitud_propietario': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as String;
              return DetalleSolicitudPropietarioScreen(solicitudId: args);
            },
    
            // Professional Flow - Appointment Scheduling
            '/agendar_cita': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
              return AgendarCitaScreen(
                idSolicitud: args['idSolicitud'],
                idPropietario: args['idPropietario'],
                nombreEdificacion: args['nombreEdificacion'],
                direccionEdificacion: args['direccionEdificacion'], // Auto-fill
              );
            },
            '/confirmar_cita': (context) {
              final idCita = ModalRoute.of(context)?.settings.arguments as String;
              return ConfirmarCitaScreen(idCita: idCita);
            },
    
            // Professional Flow - Reports
            '/mis_informes': (context) => const MisInformesScreen(),
            '/detalle_informe': (context) {
              final idInforme = ModalRoute.of(context)?.settings.arguments as String;
              return DetalleInformeScreen(idInforme: idInforme);
            },
    
            // Profile Screens
            '/perfil_usuario': (context) => const PerfilUsuarioScreen(),
            '/editar_perfil_profesional': (context) => const EditarPerfilProfesionalScreen(),
            
            // Settings
            '/settings/notificaciones': (context) => const NotificacionesScreen(),
            '/settings/seguridad': (context) => const SeguridadScreen(),
          },
        );
      },
    );
  }
}
