import 'package:flutter/material.dart';
import 'package:structurescan_app/constants.dart';
import 'package:structurescan_app/widgets/modern_alert_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:structurescan_app/services/localization_service.dart';

class SeguridadScreen extends StatefulWidget {
  const SeguridadScreen({super.key});

  @override
  State<SeguridadScreen> createState() => _SeguridadScreenState();
}

class _SeguridadScreenState extends State<SeguridadScreen> {
  bool _twoFactorEnabled = false;
  bool _biometricEnabled = true;

  Future<void> _cambiarContrasena() async {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(LocalizationService().translate('change_password')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: LocalizationService().translate('new_password'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: LocalizationService().translate('confirm_password'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService().translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.isEmpty ||
                  passwordController.text != confirmController.text) {
                ModernAlertDialog.showToast(
                  context,
                  message: LocalizationService().translate('password_mismatch'),
                  type: AlertType.error,
                );
                return;
              }

              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: passwordController.text),
                );
                if (mounted) {
                  Navigator.pop(context);
                  ModernAlertDialog.showToast(
                    context,
                    message: LocalizationService().translate('password_updated'),
                    type: AlertType.success,
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ModernAlertDialog.showToast(
                    context,
                    message: '${LocalizationService().translate('error_updating')}: $e',
                    type: AlertType.error,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kAzulPrincipalOscuro,
              foregroundColor: kBlanco,
            ),
            child: Text(LocalizationService().translate('update')),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCuenta() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService().translate('delete_account')),
        content: Text(
            LocalizationService().translate('delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocalizationService().translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kRojoAdvertencia),
            child: Text(LocalizationService().translate('delete_account_action'),
                style: TextStyle(color: kBlanco)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      // Aquí iría la lógica real de eliminación (requiere función backend o edge function)
      if (mounted) {
        ModernAlertDialog.showToast(
          context,
          message: LocalizationService().translate('delete_request_sent'),
          type: AlertType.info,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('security')),
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader(LocalizationService().translate('account_security')),
            _buildActionTile(
              title: LocalizationService().translate('change_password'),
              subtitle: LocalizationService().translate('change_password_subtitle'),
              icon: Icons.lock_reset,
              onTap: _cambiarContrasena,
            ),
            _buildSwitchTile(
              title: LocalizationService().translate('two_factor'),
              subtitle: LocalizationService().translate('two_factor_subtitle'),
              value: _twoFactorEnabled,
              onChanged: (val) => setState(() => _twoFactorEnabled = val),
              icon: Icons.security,
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader(LocalizationService().translate('biometric_access')),
            _buildSwitchTile(
              title: LocalizationService().translate('biometric'),
              subtitle: LocalizationService().translate('biometric_subtitle'),
              value: _biometricEnabled,
              onChanged: (val) => setState(() => _biometricEnabled = val),
              icon: Icons.fingerprint,
            ),

            const SizedBox(height: 24),
            _buildSectionHeader(LocalizationService().translate('danger_zone')),
            Container(
              decoration: BoxDecoration(
                color: kBlanco,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kRojoAdvertencia.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: kRojoAdvertencia.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kRojoAdvertencia.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_forever, color: kRojoAdvertencia),
                ),
                title: Text(
                  LocalizationService().translate('delete_account'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kRojoAdvertencia,
                  ),
                ),
                subtitle: Text(LocalizationService().translate('delete_account_subtitle')),
                onTap: _eliminarCuenta,
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

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kAzulPrincipalOscuro.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: kAzulPrincipalOscuro),
        ),
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: kGrisMedio),
        onTap: onTap,
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
