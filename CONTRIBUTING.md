# Cómo contribuir a ApuntIA

¡Gracias por querer mejorar ApuntIA! Esta guía explica el proceso en pocos pasos.

## 1. Antes de empezar

- Busca en los [issues](../../issues) si alguien ya reportó el problema o propuso la idea.
- Si no existe, abre uno nuevo con la plantilla correspondiente (*error* o *mejora*).
- Para cambios grandes, comenta primero en el issue tu propuesta antes de programar.

## 2. Prepara tu entorno

1. Haz un *fork* del repositorio y clónalo.
2. Sigue los [primeros pasos del README](README.md#primeros-pasos) (copiar plantillas y `flutter run`).
3. Crea una rama descriptiva:
   ```bash
   git checkout -b mejora/modo-oscuro
   ```
   Prefijos sugeridos: `mejora/`, `correccion/`, `docs/`, `pruebas/`.

## 3. Mientras programas

- Formatea el código: `dart format lib test`.
- Mantén el análisis limpio: `flutter analyze` sin observaciones.
- Agrega o actualiza pruebas en `test/` cuando cambies lógica.
- Los textos de la interfaz van en **español**, claros y breves.
- La lógica de estudio va en `lib/domain/` y no debe depender de Flutter ni de Firebase.

## 4. Nunca subas datos privados

No incluyas en tu *commit* archivos con datos de tu proyecto de Firebase o Apple:
`lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`,
`ios/Flutter/Secrets.xcconfig`, `firebase.json`, `.firebaserc` ni `config/*.json`.
Ya están en `.gitignore`; si cambias algo de configuración, actualiza la plantilla `*.example.*` correspondiente usando `AQUI_COLOCA_...`.

## 5. Envía tu Pull Request

1. Verifica antes de enviar:
   ```bash
   flutter analyze && flutter test && dart run tool/domain_check.dart
   ```
2. Escribe mensajes de *commit* en español y en imperativo, por ejemplo: `Agrega modo oscuro en Ajustes`.
3. Abre el Pull Request hacia `main`, llena la plantilla y enlaza el issue (`Cierra #12`).
4. La integración continua ejecutará el análisis y las pruebas automáticamente.

## Código de conducta

Trata a todas las personas con respeto. Las críticas son al código, nunca a quien lo escribe. Preguntas de principiantes son bienvenidas.
