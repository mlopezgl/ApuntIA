import 'package:flutter/material.dart';
import '../services/cloud_sync.dart';
import 'login_page.dart';
import 'theme.dart';
import 'widgets.dart';

/// Estado de la cuenta y de la copia en la nube, dentro de Ajustes.
class AccountPanel extends StatefulWidget {
  const AccountPanel({super.key, required this.cloud});
  final CloudSync? cloud;
  @override
  State<AccountPanel> createState() => _AccountPanelState();
}

class _AccountPanelState extends State<AccountPanel> {
  bool busy = false;

  Future<void> _signOut(CloudSync cloud) async {
    setState(() => busy = true);
    try {
      await cloud.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión cerrada. Tus mazos siguen en este teléfono.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloud = widget.cloud;
    if (cloud == null) {
      return const Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle('Tu cuenta'),
            InfoNote(
              'La cuenta y la copia en la nube no están disponibles en este momento.',
              icon: Icons.cloud_off_outlined,
            ),
          ],
        ),
      );
    }
    return ListenableBuilder(
      listenable: cloud,
      builder: (context, _) {
        final user = cloud.user;
        final last = cloud.lastSync;
        return Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Tu cuenta y la nube'),
              if (user == null) ...[
                const Text(
                  'Inicia sesión con Google, Apple, Facebook o tu correo para respaldar tus mazos y usarlos en otro teléfono.',
                  style: TextStyle(color: InkColors.muted),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          LoginPage(cloud: cloud, popOnSuccess: true),
                    ),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Iniciar sesión'),
                ),
              ] else ...[
                Tag(
                  user.email ?? user.displayName ?? 'Cuenta conectada',
                  icon: Icons.verified_user_outlined,
                ),
                const SizedBox(height: 12),
                Text(
                  cloud.lastError ??
                      (last == null
                          ? 'Sincronizando…'
                          : 'Copia en la nube actualizada a las ${TimeOfDay.fromDateTime(last).format(context)}.'),
                  style: TextStyle(
                    color: cloud.lastError == null
                        ? InkColors.muted
                        : Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: busy || cloud.syncing ? null : cloud.syncNow,
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Sincronizar ahora'),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => _signOut(cloud),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ],
              if (busy || cloud.syncing) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        );
      },
    );
  }
}
