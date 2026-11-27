import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/store.dart';
import 'services/app_services.dart';
import 'services/ocr.dart';
import 'ui/capture_page.dart';
import 'ui/home_page.dart';
import 'ui/library_page.dart';
import 'ui/login_page.dart';
import 'ui/progress_page.dart';
import 'ui/settings_page.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class ApuntiaApp extends StatelessWidget {
  ApuntiaApp({super.key, required this.store, AppServices? services})
    : services = services ?? AppServices.offline();
  final StudyStore store;
  final AppServices services;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ApuntIA',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    locale: const Locale('es', 'MX'),
    supportedLocales: const [Locale('es', 'MX')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: _Bootstrap(store: store, services: services),
  );
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap({required this.store, required this.services});
  final StudyStore store;
  final AppServices services;
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  Object? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      if (!widget.store.loaded) await widget.store.load();
      if (mounted) setState(() => error = null);
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: EmptyMessage(
                  title: 'No pudimos abrir tus apuntes',
                  message:
                      'Tus datos no se han reemplazado. Intenta abrirlos de nuevo. Si el problema continúa, conserva los datos de la app para recuperarlos.',
                  action: FilledButton(
                    onPressed: load,
                    child: const Text('Reintentar'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (!widget.store.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cloud = widget.services.cloud;
    if (cloud == null) {
      return AppShell(store: widget.store, services: widget.services);
    }
    // Pantalla de acceso al abrir la app, salvo que haya sesión o que la
    // persona haya elegido "Continuar sin cuenta".
    return ListenableBuilder(
      listenable: cloud,
      builder: (context, _) => cloud.signedIn || cloud.loginSkipped
          ? AppShell(store: widget.store, services: widget.services)
          : LoginPage(cloud: cloud, onSkip: cloud.skipLogin),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store, required this.services});
  final StudyStore store;
  final AppServices services;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int selected = 0;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => recover());
  }

  Future<void> recover() async {
    try {
      final text = await NoteScanner().recover();
      if (text != null && mounted) capture(initialText: text);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void capture({String? initialText}) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => CapturePage(
        store: widget.store,
        generator: widget.services.generator,
        initialText: initialText,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final wide = MediaQuery.sizeOf(context).width >= 1000;
      final pages = [
        HomePage(
          store: widget.store,
          onCapture: () => capture(),
          onLibrary: () => setState(() => selected = 1),
        ),
        LibraryPage(store: widget.store, onCapture: () => capture()),
        ProgressPage(store: widget.store),
      ];
      final content = SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(wide ? 40 : 22, 20, wide ? 40 : 22, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: pages[selected],
          ),
        ),
      );
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 82,
          titleSpacing: wide ? 36 : 22,
          title: const Brand(),
          actions: [
            if (MediaQuery.sizeOf(context).width >= 500)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Tag(
                  'Tu espacio de estudio',
                  icon: Icons.school_outlined,
                ),
              ),
            IconButton(
              tooltip: 'Ajustes y respaldos',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => SettingsPage(
                    store: widget.store,
                    services: widget.services,
                  ),
                ),
              ),
              icon: const Icon(Icons.tune_rounded),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SafeArea(
          top: false,
          child: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selected,
                      onDestinationSelected: (v) =>
                          setState(() => selected = v),
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: InkColors.paper,
                      indicatorColor: InkColors.lavender,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.grid_view_rounded),
                          label: Text('Inicio'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.style_outlined),
                          label: Text('Mis apuntes'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.bar_chart_rounded),
                          label: Text('Progreso'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (v) => setState(() => selected = v),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: 'Inicio',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.style_outlined),
                    selectedIcon: Icon(Icons.style),
                    label: 'Mis apuntes',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart_rounded),
                    label: 'Progreso',
                  ),
                ],
              ),
      );
    },
  );
}
