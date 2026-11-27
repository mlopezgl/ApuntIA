import 'package:flutter/material.dart';
import 'app.dart';
import 'data/store.dart';
import 'services/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = StudyStore(DeviceStorage());
  final services = await AppServices.initialize(store);
  runApp(ApuntiaApp(store: store, services: services));
}
