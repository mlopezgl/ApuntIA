import 'package:flutter/material.dart';
import 'app.dart';
import 'data/store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ApuntiaApp(store: StudyStore(DeviceStorage())));
}
