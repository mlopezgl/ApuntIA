import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_config.dart';
import '../services/cloud_sync.dart';
import 'email_auth_form.dart';
import 'theme.dart';
import 'widgets.dart';

/// Pantalla de acceso: Google, Apple (iCloud), Facebook o correo.
/// Con [onSkip] muestra "Continuar sin cuenta" (la app funciona sin conexión).
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.cloud,
    this.onSkip,
    this.popOnSuccess = false,
  });
  final CloudSync cloud;
  final VoidCallback? onSkip;
  final bool popOnSuccess;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool busy = false, showEmail = false;

  void _done() {
    if (widget.popOnSuccess && mounted) Navigator.of(context).pop();
  }

  Future<void> _provider(Future<bool> Function() signIn) async {
    setState(() => busy = true);
    try {
      if (await signIn()) _done();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloud = widget.cloud;
    final apple = _ProviderButton(
      label: 'Continuar con Apple',
      icon: const Icon(Icons.apple, size: 24),
      background: Colors.black,
      foreground: Colors.white,
      soon: !AuthConfig.appleEnabled,
      onPressed: busy ? null : () => _provider(cloud.signInWithApple),
    );
    final google = _ProviderButton(
      label: 'Continuar con Google',
      icon: const _LetterMark('G'),
      background: Colors.white,
      foreground: InkColors.navy,
      onPressed: busy ? null : () => _provider(cloud.signInWithGoogle),
    );
    final facebook = _ProviderButton(
      label: 'Continuar con Facebook',
      icon: const Icon(Icons.facebook, size: 24),
      background: const Color(0xFF1877F2),
      foreground: Colors.white,
      soon: !AuthConfig.facebookEnabled,
      onPressed: busy ? null : () => _provider(cloud.signInWithFacebook),
    );
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    return Scaffold(
      backgroundColor: InkColors.navy,
      appBar: widget.popOnSuccess
          ? AppBar(
              backgroundColor: InkColors.navy,
              foregroundColor: Colors.white,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Logo(),
                  const SizedBox(height: 28),
                  const Text(
                    'Tus apuntes,\nlistos para repasar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      letterSpacing: -.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Inicia sesión para guardar tus mazos en la nube y usarlos en cualquier teléfono.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFC2C0DA), height: 1.45),
                  ),
                  const SizedBox(height: 32),
                  // Apple pide mostrar su botón al menos igual de visible en iOS.
                  if (ios) ...[apple, google] else ...[google, apple],
                  facebook,
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => setState(() => showEmail = !showEmail),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF4A4C72)),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: const Text('Continuar con correo'),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    child: showEmail
                        ? Container(
                            margin: const EdgeInsets.only(top: 14),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: InkColors.paper,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: EmailAuthForm(
                              cloud: cloud,
                              onSignedIn: _done,
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  if (busy) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(color: InkColors.orange),
                  ],
                  if (widget.onSkip != null) ...[
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: busy ? null : widget.onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: InkColors.orange,
                      ),
                      child: const Text('Continuar sin cuenta'),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Text(
                    'Sin cuenta, tus mazos se guardan solo en este teléfono.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF8E8CAE), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.soon = false,
  });
  final String label;
  final Widget icon;
  final Color background, foreground;
  final VoidCallback? onPressed;
  final bool soon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: FilledButton(
      onPressed: soon ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: .35),
        disabledForegroundColor: foreground.withValues(alpha: .6),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Center(child: icon)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          SizedBox(
            width: 38,
            child: soon
                ? const Text(
                    'Pronto',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 11),
                  )
                : null,
          ),
        ],
      ),
    ),
  );
}

class _LetterMark extends StatelessWidget {
  const _LetterMark(this.letter);
  final String letter;
  @override
  Widget build(BuildContext context) => Text(
    letter,
    style: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w900,
      color: InkColors.purple,
    ),
  );
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset('assets/branding/icon.png', width: 88, height: 88),
      ),
      const SizedBox(height: 16),
      const Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Apunt'),
            TextSpan(
              text: 'IA',
              style: TextStyle(color: InkColors.orange),
            ),
          ],
        ),
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
    ],
  );
}
