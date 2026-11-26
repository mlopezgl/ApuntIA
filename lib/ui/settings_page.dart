import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/store.dart';
import '../services/generator.dart';
import 'theme.dart';
import 'widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});
  final StudyStore store;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool busy = false;
  Future<void> backup() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.store.exportJson()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Respaldo copiado. Pégalo en un archivo de texto y guárdalo con extensión .json.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> restore() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar respaldo'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 10,
            maxLength: 5000000,
            decoration: const InputDecoration(
              labelText: 'Pega el JSON de tu respaldo',
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    // The route animates out before its TextField is disposed.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
    if (raw == null || !mounted) return;
    final yes = await confirm(
      context,
      title: '¿Reemplazar los datos actuales?',
      message:
          'El respaldo sustituirá todos tus mazos y tu historial en este dispositivo. Copia primero un respaldo de tus datos actuales.',
      action: 'Restaurar',
    );
    if (!yes || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.store.importJson(raw);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Respaldo restaurado.')));
      }
    } catch (e) {
      if (mounted) {
        showError(
          context,
          const FormatException(
            'No se pudo restaurar. Comprueba que el JSON sea un respaldo válido de ApuntIA. Tus datos actuales se conservan.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Ajustes y privacidad')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus apuntes.\nTus decisiones.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 26),
                const Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle('Privacidad, desde el inicio'),
                      InfoNote(
                        'El reconocimiento de texto se realiza en el dispositivo. ApuntIA no envía tu foto.',
                      ),
                      SizedBox(height: 18),
                      InfoNote(
                        'Solo al activar la IA y autorizarlo, enviamos el texto y la materia al servidor configurado y a OpenAI para crear las tarjetas.',
                        icon: Icons.cloud_outlined,
                      ),
                      SizedBox(height: 18),
                      InfoNote(
                        'Los mazos y el progreso se guardan localmente. Al desinstalar la app o borrar los datos del navegador puedes perderlos. Haz respaldos periódicos.',
                        icon: Icons.save_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Una copia de tus ideas'),
                      const Text(
                        'Copia un respaldo JSON para guardarlo donde prefieras. El portapapeles contendrá tus apuntes; evita usarlo en dispositivos compartidos.',
                        style: TextStyle(color: InkColors.muted),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: busy ? null : backup,
                            icon: const Icon(Icons.copy_all_outlined),
                            label: const Text('Copiar respaldo'),
                          ),
                          OutlinedButton.icon(
                            onPressed: busy ? null : restore,
                            icon: const Icon(Icons.restore_rounded),
                            label: const Text('Restaurar JSON'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Generación con IA'),
                      Tag(
                        CardGenerator.aiAvailable
                            ? 'Servicio configurado'
                            : 'Modo sin conexión',
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'El modo local usa plantillas, sin IA. La IA es opcional; las tarjetas generadas siempre requieren revisión. El repaso funciona sin internet.',
                        style: TextStyle(color: InkColors.muted),
                      ),
                    ],
                  ),
                ),
                if (busy) ...[
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(),
                ],
                const SizedBox(height: 30),
                const Text(
                  'ApuntIA · 1.0.0\nDe la idea a la app.',
                  style: TextStyle(color: InkColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
