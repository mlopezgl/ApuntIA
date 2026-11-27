import 'package:flutter/material.dart';
import '../data/store.dart';
import '../domain/models.dart';
import '../services/generator.dart';
import '../services/ocr.dart';
import 'card_editor.dart';
import 'deck_page.dart';
import 'theme.dart';
import 'widgets.dart';

class CapturePage extends StatefulWidget {
  const CapturePage({
    super.key,
    required this.store,
    required this.generator,
    this.initialText,
  });
  final StudyStore store;
  final CardGenerator generator;
  final String? initialText;
  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final subject = TextEditingController();
  late final text = TextEditingController(text: widget.initialText);
  final scanner = NoteScanner();
  late final generator = widget.generator;
  bool busy = false, useAi = false, consent = false;
  String status = '';
  List<CardDraft>? drafts;
  @override
  void dispose() {
    title.dispose();
    subject.dispose();
    text.dispose();
    super.dispose();
  }

  Future<void> scan(bool camera) async {
    setState(() {
      busy = true;
      status = 'Leyendo el texto en tu teléfono…';
    });
    try {
      final result = await scanner.scan(camera: camera);
      if (result != null && mounted) {
        if (result.length > 12000) {
          throw const FormatException(
            'La foto contiene demasiado texto. Captura una sección de hasta 12,000 caracteres.',
          );
        }
        text.text = result;
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> generate() async {
    if (!form.currentState!.validate()) return;
    if (useAi && !consent) {
      showError(
        context,
        const FormatException(
          'Autoriza el envío del texto para generar con IA.',
        ),
      );
      return;
    }
    setState(() {
      busy = true;
      status = useAi ? 'Creando preguntas con IA…' : 'Preparando tus tarjetas…';
    });
    try {
      final result = useAi
          ? await generator.ai(text.text.trim(), subject.text.trim())
          : generator.local(text.text.trim());
      if (result.isEmpty) {
        throw const FormatException(
          'Agrega al menos una idea completa. Prueba con «Concepto: definición».',
        );
      }
      if (mounted) setState(() => drafts = result);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (drafts == null || drafts!.isEmpty || busy) return;
    if (widget.store.data.decks.length >= 200) {
      showError(
        context,
        const FormatException(
          'Has llegado a 200 mazos. Respalda y elimina los que ya no necesitas.',
        ),
      );
      return;
    }
    setState(() {
      busy = true;
      status = 'Guardando en tu dispositivo…';
    });
    final now = widget.store.clock();
    final deck = Deck(
      id: newId(),
      title: title.text.trim(),
      subject: subject.text.trim(),
      created: now,
      source: text.text.trim(),
      origin: useAi ? 'IA (Gemini)' : 'Plantillas locales',
      cards: drafts!.map((d) => d.toCard(now)).toList(),
    );
    try {
      await widget.store.addDeck(deck);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => DeckPage(store: widget.store, deckId: deck.id),
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
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(drafts == null ? 'Nueva captura' : 'Revisa tus tarjetas'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Tag(
                        '1 · Tus apuntes',
                        background: drafts == null
                            ? InkColors.lavender
                            : InkColors.line,
                      ),
                      Tag(
                        '2 · Tus tarjetas',
                        background: drafts != null
                            ? InkColors.lavender
                            : InkColors.line,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  if (drafts == null)
                    ...sourceForm(context)
                  else
                    ...preview(context),
                  if (busy) ...[
                    const SizedBox(height: 22),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(
                      status,
                      style: const TextStyle(color: InkColors.purple),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const InfoNote(
                    'La foto no se envía ni se añade al mazo. Solo guardamos el texto y las tarjetas en este dispositivo.',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> sourceForm(BuildContext context) => [
    Text(
      'De tus apuntes\na tu memoria.',
      style: Theme.of(context).textTheme.headlineLarge,
    ),
    const SizedBox(height: 12),
    const Text(
      'Toma una foto clara y revisa el texto antes de continuar.',
      style: TextStyle(color: InkColors.muted),
    ),
    const SizedBox(height: 24),
    Panel(
      color: const Color(0xFFF0EDFF),
      child: Column(
        children: [
          const Icon(
            Icons.document_scanner_outlined,
            size: 58,
            color: InkColors.purple,
          ),
          const SizedBox(height: 12),
          const Text(
            'Encuadra tus apuntes',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Buena luz, texto de frente y sin sombras.',
            textAlign: TextAlign.center,
            style: TextStyle(color: InkColors.muted),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: busy || !scanner.supported ? null : () => scan(true),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Tomar foto'),
              ),
              OutlinedButton.icon(
                onPressed: busy || !scanner.supported
                    ? null
                    : () => scan(false),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ],
          ),
          if (!scanner.supported) ...[
            const SizedBox(height: 14),
            const Text(
              'La cámara no está disponible en este dispositivo. Escribe o pega el texto de tus apuntes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: InkColors.muted),
            ),
          ],
        ],
      ),
    ),
    const SizedBox(height: 24),
    Form(
      key: form,
      child: Column(
        children: [
          TextFormField(
            controller: title,
            enabled: !busy,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre del mazo',
              hintText: 'Ej. Patrones de arquitectura',
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Ponle nombre a este tema.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: subject,
            enabled: !busy,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Materia',
              hintText: 'Ej. Ingeniería de software',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Escribe la materia.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: text,
            enabled: !busy,
            minLines: 7,
            maxLines: 16,
            maxLength: 12000,
            decoration: const InputDecoration(
              labelText: 'Texto de tus apuntes',
              alignLabelWithHint: true,
              hintText:
                  'Escribe, pega o captura una foto.\n\nModelo: representa los datos y las reglas del dominio.\nVista: muestra el estado al usuario.',
            ),
            validator: (v) => v == null || v.trim().length < 20
                ? 'Agrega al menos 20 caracteres de tus apuntes.'
                : null,
          ),
        ],
      ),
    ),
    const SizedBox(height: 18),
    Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: useAi,
            onChanged: busy || !generator.aiAvailable
                ? null
                : (v) => setState(() {
                    useAi = v;
                    consent = false;
                  }),
            title: const Text(
              'Generar con IA',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              generator.aiAvailable
                  ? 'Gemini crea preguntas sobre las ideas clave de tu texto.'
                  : 'Disponible en Android e iOS con conexión a internet.',
            ),
          ),
          if (useAi) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: consent,
              onChanged: busy
                  ? null
                  : (v) => setState(() => consent = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Autorizo enviar este texto y la materia a Gemini (Google) mediante Firebase. Mi foto no se enviará.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ] else
            const InfoNote(
              'Modo sin conexión: se crean borradores con plantillas a partir del texto. Revísalos y personalízalos; este modo no utiliza IA.',
              icon: Icons.wifi_off_outlined,
            ),
        ],
      ),
    ),
    const SizedBox(height: 22),
    SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: busy ? null : generate,
        icon: const Icon(Icons.auto_awesome_outlined),
        label: Text(
          useAi ? 'Crear tarjetas con IA' : 'Crear borradores sin conexión',
        ),
      ),
    ),
  ];

  List<Widget> preview(BuildContext context) => [
    Text(
      'Tú tienes\nla última palabra.',
      style: Theme.of(context).textTheme.headlineLarge,
    ),
    const SizedBox(height: 10),
    Text(
      '${drafts!.length} tarjetas · ${title.text}',
      style: const TextStyle(color: InkColors.muted),
    ),
    const SizedBox(height: 12),
    const InfoNote(
      'Comprueba que cada respuesta sea correcta y que la pregunta se entienda por sí sola. Puedes editar o quitar cualquier tarjeta.',
      icon: Icons.fact_check_outlined,
    ),
    const SizedBox(height: 22),
    ...drafts!.indexed.map(
      (entry) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Tag('Tarjeta ${entry.$1 + 1}'),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Editar borrador',
                    onPressed: busy
                        ? null
                        : () async {
                            final result = await editDraft(context, entry.$2);
                            if (result != null && mounted) {
                              setState(() => drafts![entry.$1] = result);
                            }
                          },
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Quitar borrador',
                    onPressed: busy
                        ? null
                        : () => setState(() => drafts!.removeAt(entry.$1)),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry.$2.question,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                entry.$2.answer,
                style: const TextStyle(color: InkColors.muted),
              ),
            ],
          ),
        ),
      ),
    ),
    if (drafts!.isEmpty)
      const Text('No quedan tarjetas. Vuelve al texto para crear nuevas.'),
    const SizedBox(height: 14),
    SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: busy || drafts!.isEmpty ? null : save,
        icon: const Icon(Icons.check_rounded),
        label: const Text('Guardar mi mazo'),
      ),
    ),
    const SizedBox(height: 10),
    TextButton(
      onPressed: busy
          ? null
          : () => setState(() {
              drafts = null;
              consent = false;
            }),
      child: const Text('Volver al texto'),
    ),
  ];
}
