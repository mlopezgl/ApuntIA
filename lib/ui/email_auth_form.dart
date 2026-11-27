import 'package:flutter/material.dart';
import '../services/cloud_sync.dart';
import 'widgets.dart';

/// Formulario de correo y contraseña: iniciar sesión, crear cuenta y
/// restablecer la contraseña.
class EmailAuthForm extends StatefulWidget {
  const EmailAuthForm({super.key, required this.cloud, this.onSignedIn});
  final CloudSync cloud;
  final VoidCallback? onSignedIn;
  @override
  State<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends State<EmailAuthForm> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false, creating = false, hidden = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => busy = true);
    try {
      await action();
      if (!mounted) return;
      password.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _submit() {
    if (!form.currentState!.validate()) return;
    final cloud = widget.cloud;
    _run(() async {
      creating
          ? await cloud.register(email.text, password.text)
          : await cloud.signIn(email.text, password.text);
      widget.onSignedIn?.call();
    }, creating ? 'Cuenta creada.' : 'Sesión iniciada.');
  }

  void _reset() {
    final value = email.text.trim();
    if (!value.contains('@')) {
      showError(
        context,
        const FormatException('Escribe tu correo para enviarte el enlace.'),
      );
      return;
    }
    _run(
      () => widget.cloud.resetPassword(value),
      'Te enviamos un correo para restablecer la contraseña.',
    );
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: email,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Correo'),
            validator: (v) =>
                v == null || !RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim())
                ? 'Escribe un correo válido.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: password,
            enabled: !busy,
            obscureText: hidden,
            autofillHints: [
              creating ? AutofillHints.newPassword : AutofillHints.password,
            ],
            decoration: InputDecoration(
              labelText: 'Contraseña',
              helperText: creating ? 'Mínimo 6 caracteres.' : null,
              suffixIcon: IconButton(
                tooltip: hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
                onPressed: () => setState(() => hidden = !hidden),
                icon: Icon(
                  hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (v) => v == null || v.length < 6
                ? 'La contraseña debe tener al menos 6 caracteres.'
                : null,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: Text(creating ? 'Crear cuenta' : 'Iniciar sesión'),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() => creating = !creating),
                child: Text(creating ? 'Ya tengo cuenta' : 'Crear una cuenta'),
              ),
              if (!creating)
                TextButton(
                  onPressed: busy ? null : _reset,
                  child: const Text('Olvidé mi contraseña'),
                ),
            ],
          ),
          if (busy) const LinearProgressIndicator(),
        ],
      ),
    ),
  );
}
