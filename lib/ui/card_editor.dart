import 'package:flutter/material.dart';
import '../services/generator.dart';

Future<CardDraft?> editDraft(BuildContext context, CardDraft draft) =>
    showDialog<CardDraft>(
      context: context,
      builder: (_) => _CardEditor(draft: draft),
    );

class _CardEditor extends StatefulWidget {
  const _CardEditor({required this.draft});
  final CardDraft draft;
  @override
  State<_CardEditor> createState() => _CardEditorState();
}

class _CardEditorState extends State<_CardEditor> {
  final form = GlobalKey<FormState>();
  late final question = TextEditingController(text: widget.draft.question);
  late final answer = TextEditingController(text: widget.draft.answer);
  @override
  void dispose() {
    question.dispose();
    answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar tarjeta'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: question,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'Pregunta'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Escribe una pregunta.'
                    : null,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: answer,
                minLines: 3,
                maxLines: 7,
                maxLength: 2000,
                decoration: const InputDecoration(labelText: 'Respuesta'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Escribe una respuesta.'
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(
              context,
              CardDraft(question.text.trim(), answer.text.trim()),
            );
          }
        },
        child: const Text('Guardar cambios'),
      ),
    ],
  );
}
