# ApuntIA — De la foto a la memoria

Aplicación Flutter basada en la referencia visual proporcionada: azul oscuro, morado, lavanda y naranja. Incluye una interfaz adaptable, captura de apuntes, lectura de texto en el dispositivo, mazos editables, repaso espaciado y estadísticas reales.

## Abrir y ejecutar

Requisitos: Flutter **3.47.7** / Dart **3.13.5** (entorno utilizado para revisar el proyecto), Android SDK y JDK 17 para Android; macOS y Xcode para iOS. La app requiere Android 7/API 24 o posterior e iOS 15 o posterior. Las dependencias resueltas se conservan en `pubspec.lock`.

Abre **la carpeta completa `apuntia`** en VS Code, no únicamente `main.dart`. En su terminal:

```bash
flutter pub get
flutter devices
flutter run
```

Para probar el flujo con texto en navegador:

```bash
flutter run -d chrome --web-port=8080
```

Para un teléfono Android conectado con depuración USB:

```bash
flutter devices
flutter run -d ID_DEL_DISPOSITIVO
```

En iOS, selecciona un equipo de firma en `ios/Runner.xcworkspace` si Xcode lo solicita. Prueba la cámara en un dispositivo físico; el simulador no dispone de cámara real. No ejecutes `flutter create .` sobre esta carpeta: reemplazar la configuración nativa puede perder los canales de OCR y almacenamiento.

## Funcionalidades

1. **Inicio:** tarjetas pendientes, racha, repasos de hoy y mazos recientes. Se incluye un mazo identificado como **Ejemplo**, con ocho tarjetas sobre arquitectura de software. Las estadísticas empiezan en cero.
2. **Nueva captura:** foto o galería en Android/iOS, con texto reconocido editable. También puedes escribir o pegar apuntes. Nombra el mazo e indica la materia.
3. **Crear tarjetas:** sin conexión se generan borradores mediante plantillas; con un servidor configurado puedes elegir generación con IA. Puedes editar o quitar borradores antes de guardar.
4. **Mis apuntes:** buscar por tema/materia, filtrar pendientes, consultar el texto original, editar tarjetas, marcar errores y eliminar mazos con confirmación. Una tarjeta reportada queda pausada localmente hasta que la edites. No se envían reportes a terceros.
5. **Repaso:** pensar la respuesta, revelarla y marcar **Fácil** o **Difícil**. Cada valoración se guarda antes de avanzar. El temporizador de diez minutos es una guía; puedes terminar antes o continuar. Se pausa cuando la app pasa a segundo plano.
6. **Progreso:** racha, gráfico de los últimos siete días, total de repasos y porcentaje marcado como Fácil. Este porcentaje representa valoraciones, no una medición del aprendizaje.
7. **Ajustes:** copiar un respaldo JSON y restaurarlo con validación y confirmación antes de reemplazar los datos.

## Sin conexión y privacidad

- Android usa **Google ML Kit Text Recognition**, con el modelo latino incluido en la aplicación. iOS usa **Apple Vision**. La captura no usa un servicio de OCR remoto.
- La imagen permanece en el dispositivo y no se incorpora al mazo. El selector de imágenes puede dejar una copia temporal en la caché local hasta que el sistema la limpie.
- Los apuntes, tarjetas y eventos se guardan localmente: archivo JSON con escritura atómica en Android/iOS y `localStorage` en web. No hay sincronización entre dispositivos.
- El respaldo automático del archivo de apuntes se desactiva en Android y se excluye de la copia del sistema en iOS. **Haz tus propios respaldos** desde Ajustes. Desinstalar, borrar datos o limpiar el almacenamiento del navegador puede eliminar tus mazos.
- Solo se envían **texto y materia** si activas IA, escribes el código de acceso y marcas la autorización en esa captura. No se envían fotos, nombres de mazos ni historial.
- El servidor solicita `store: false` a OpenAI. Esto no sustituye las políticas de retención aplicables a la cuenta de API.
- Las claves de OpenAI se configuran únicamente en el servidor. No están en Flutter ni en el repositorio. El código de acceso al servidor se introduce en tiempo de ejecución y no se persiste.
- La lectura de escritura a mano, fórmulas, tablas o pizarrones lejanos puede ser imperfecta. Revisa siempre el texto extraído y las respuestas generadas.

## Activar la IA opcional

La app funciona sin cuentas ni configuración de IA. Para habilitarla se incluye un servidor en `server/`, con Node.js 22 o posterior y **sin dependencias npm**.

```bash
cd server
cp .env.example .env
```

Edita `.env` y establece:

| Variable | Uso |
|---|---|
| `OPENAI_API_KEY` | Clave privada de tu proyecto de API. Nunca ponerla en Flutter. |
| `OPENAI_MODEL` | Modelo compatible con Responses y Structured Outputs; valor inicial `gpt-4.1-mini`. |
| `APUNTIA_ACCESS_TOKEN` | Secreto aleatorio de al menos 24 caracteres, que escribirás en la app al usar IA. |
| `HOST` | `127.0.0.1` por defecto; escucha solo localmente. |
| `PORT` | `8787` por defecto. |
| `ALLOWED_ORIGINS` | Orígenes web autorizados separados por comas, con puerto si corresponde. |

Puedes generar el código de acceso con:

```bash
node -e "process.stdout.write(require('node:crypto').randomBytes(32).toString('hex'))"
```

Después de editar `.env`:

```bash
npm start
```

Expón el servidor mediante un proxy HTTPS privado o un entorno de despliegue propio. No se ha desplegado ningún servidor ni contratado servicio de pago. La API puede generar cargos según el uso de tu cuenta.

Ejecuta Flutter desde la raíz usando la dirección HTTPS completa de `/cards`:

```bash
flutter run --dart-define=AI_ENDPOINT=https://TU_SERVIDOR/cards
```

El cliente solo habilita IA para endpoints HTTPS. Un teléfono no puede acceder a tu computadora usando `localhost`. Al usar el navegador, configura su origen exacto en `ALLOWED_ORIGINS`.

Contrato HTTP:

```http
POST /cards
Content-Type: application/json
Authorization: Bearer CODIGO_DE_ACCESO
```

```json
{
  "text": "Modelo: representa los datos y las reglas del dominio.",
  "subject": "Ingeniería de software",
  "consent": true
}
```

La respuesta tiene el formato `{"cards":[{"question":"...","answer":"..."}]}`. El servidor rechaza campos adicionales (incluidas fotografías), limita el texto a 12,000 caracteres, limita las solicitudes y valida las respuestas. Los errores no exponen claves ni apuntes. No registra cuerpos de solicitudes.

Este acceso compartido está pensado para un **MVP y pruebas privadas**. Antes de un lanzamiento público, incorpora autenticación individual, cuotas duraderas por usuario, presupuesto de API, gestión de acceso, política de privacidad y condiciones de uso. El limitador actual está en memoria y usa la IP del socket; detrás de un proxy todas las solicitudes pueden compartir la misma cuota.

## Programación del repaso

| Respuesta | Próxima revisión |
|---|---|
| Primera Fácil | Un día después |
| Siguientes Fácil | 3, 7, 14, 30 y 60 días; máximo 60 |
| Difícil | Dentro de 10 minutos; reinicia la progresión |

Es una estrategia sencilla; no es una implementación de SM-2 ni FSRS. La app muestra fechas y rachas según la zona horaria del dispositivo. La racha se conserva si repasaste ayer y todavía no has repasado hoy. No incluye notificaciones del sistema: las tarjetas pendientes aparecen al abrir la app.

## Organización del código

| Ruta | Responsabilidad |
|---|---|
| `lib/main.dart` | Inicio |
| `lib/app.dart` | Carga, navegación y recuperación de capturas interrumpidas en Android |
| `lib/domain/models.dart` | Mazos, tarjetas, historial y reglas de repaso |
| `lib/data/store.dart` | Estado, operaciones serializadas, respaldo y restauración |
| `lib/data/storage_*.dart` | Persistencia por plataforma |
| `lib/services/ocr*.dart` | Cámara/galería y puente hacia OCR nativo |
| `lib/services/generator.dart` | Plantillas locales y cliente de IA |
| `lib/ui/` | Pantallas, componentes y tema |
| `android/app/src/main/kotlin/.../MainActivity.kt` | OCR de ML Kit y archivo atómico |
| `ios/Runner/AppDelegate.swift` | OCR con Vision y archivo atómico |
| `server/` | API opcional que protege la clave de OpenAI |
| `test/` | Pruebas de dominio, persistencia y widgets |
| `tool/domain_check.dart` | Comprobaciones de lógica sin abrir puertos |

## Validación

```bash
flutter analyze
flutter test
dart run tool/domain_check.dart
cd server
node --test
```

Para compilar desde la raíz:

```bash
flutter build web --no-web-resources-cdn
flutter build apk --debug
flutter build ios --no-codesign
```

La primera compilación puede descargar dependencias de Flutter, Gradle o Xcode. Android tiene firma de desarrollo; publicar en Google Play necesita una clave de firma propia. iOS requiere los perfiles correspondientes para instalar o publicar.

Consulta `VALIDACION.md` para distinguir las comprobaciones ejecutadas de las que necesitan un teléfono, simulador o un entorno sin las restricciones de esta sesión.

## Fuentes técnicas

- [Flutter](https://docs.flutter.dev/)
- [image_picker](https://pub.dev/packages/image_picker)
- [ML Kit en Android](https://developers.google.com/ml-kit/vision/text-recognition/v2/android)
- [Apple Vision: reconocer texto](https://developer.apple.com/documentation/vision/recognizing-text-in-images)
- [OpenAI: Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs)

Proyecto creado para el caso ApuntIA de «De la idea a la app».
