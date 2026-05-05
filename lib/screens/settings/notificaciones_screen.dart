import 'package:flutter/material.dart';
import 'package:structurescan_app/constants.dart';
import 'package:structurescan_app/widgets/modern_alert_dialog.dart';
import 'package:structurescan_app/services/localization_service.dart';
import 'package:structurescan_app/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String? _userId = Supabase.instance.client.auth.currentUser?.id;

  bool _isLoading = true;
  bool _isSaving = false;

  // Estado local para simular preferencias
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _newRequestsEnabled = true; // Solo para profesionales
  bool _statusUpdatesEnabled = true; // Solo para propietarios
  bool _marketingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final perfil = await _dbService.getPerfil(_userId!);
      if (perfil != null && perfil['preferencias_notificaciones'] != null) {
        final prefs = perfil['preferencias_notificaciones'] as Map<String, dynamic>;
        setState(() {
          _pushEnabled = prefs['push'] ?? true;
          _emailEnabled = prefs['email'] ?? true;
          _newRequestsEnabled = prefs['new_requests'] ?? true;
          _statusUpdatesEnabled = prefs['status_updates'] ?? true;
          _marketingEnabled = prefs['marketing'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Error loading preferences: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_userId == null) return;
    setState(() => _isSaving = true);
    try {
      final prefs = {
        'push': _pushEnabled,
        'email': _emailEnabled,
        'new_requests': _newRequestsEnabled,
        'status_updates': _statusUpdatesEnabled,
        'marketing': _marketingEnabled,
      };
      await _dbService.actualizarPreferenciasNotificaciones(_userId!, prefs);
      
      if (mounted) {
        ModernAlertDialog.showToast(
          context,
          message: LocalizationService().translate('preferences_saved'),
          type: AlertType.success,
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ModernAlertDialog.showToast(
          context,
          message: 'Error al actualizar preferencias',
          type: AlertType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('notifications')),
        backgroundColor: kAzulPrincipalOscuro,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kAzulPrincipalOscuro.withOpacity(0.05),
              kBlanco,
            ],
          ),
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: kAzulPrincipalOscuro))
          : ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader(LocalizationService().translate('general_preferences')),
            _buildSwitchTile(
              title: LocalizationService().translate('notifications_push'),
              subtitle: LocalizationService().translate('notifications_push_subtitle'),
              value: _pushEnabled,
              onChanged: (val) => setState(() => _pushEnabled = val),
              icon: Icons.notifications_active_rounded,
            ),
            _buildSwitchTile(
              title: LocalizationService().translate('notifications_email'),
              subtitle: LocalizationService().translate('notifications_email_subtitle'),
              value: _emailEnabled,
              onChanged: (val) => setState(() => _emailEnabled = val),
              icon: Icons.email_rounded,
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader(LocalizationService().translate('activity')),
            _buildSwitchTile(
              title: LocalizationService().translate('notifications_new_requests'),
              subtitle: LocalizationService().translate('notifications_new_requests_subtitle'),
              value: _newRequestsEnabled,
              onChanged: (val) => setState(() => _newRequestsEnabled = val),
              icon: Icons.assignment_add,
            ),
            _buildSwitchTile(
              title: LocalizationService().translate('notifications_status_updates'),
              subtitle: LocalizationService().translate('notifications_status_updates_subtitle'),
              value: _statusUpdatesEnabled,
              onChanged: (val) => setState(() => _statusUpdatesEnabled = val),
              icon: Icons.update,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(LocalizationService().translate('others')),
            _buildSwitchTile(
              title: LocalizationService().translate('notifications_marketing'),
              subtitle: LocalizationService().translate('notifications_marketing_subtitle'),
              value: _marketingEnabled,
              onChanged: (val) => setState(() => _marketingEnabled = val),
              icon: Icons.campaign_rounded,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _isSaving ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAzulPrincipalOscuro,
                  foregroundColor: kBlanco,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kBlanco,
                        ),
                      )
                    : Text(
                        LocalizationService().translate('save_changes'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kAzulPrincipalOscuro,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kBlanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: kAzulSecundarioClaro,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: kGrisOscuro,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: kGrisMedio.withOpacity(0.8),
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kAzulPrincipalOscuro.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: kAzulPrincipalOscuro),
        ),
      ),
    );
  }
}
