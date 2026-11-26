# Validación de ApuntIA

Entorno de revisión: Flutter 3.47.7, Dart 3.13.5, Node.js y herramientas Swift de Xcode con SDK de simulador iOS.

| Comprobación | Resultado |
|---|---|
| Resolución de dependencias Dart | Correcta; archivo `pubspec.lock` incluido |
| Análisis estático de Dart | Sin errores, advertencias ni observaciones |
| Compilación Flutter para web | Correcta, modo release con recursos web locales |
| Tipos de los canales nativos iOS | `swiftc -typecheck` correcto para `AppDelegate.swift` y `SceneDelegate.swift` contra Flutter y el SDK de simulador |
| Comprobaciones ejecutables de dominio | Correctas: intervalos Fácil/Difícil, vencimientos, pausa por reporte, racha, JSON y plantillas locales |
| Pruebas del servidor | 3 correctas; validación de entrada, autorización, consentimiento, errores, cuotas y respuesta mediante el manejador HTTP en memoria |
| Pruebas Flutter de widgets y persistencia | Incluidas; el ejecutor quedó bloqueado antes de cargarlas porque esta sesión prohíbe abrir puertos locales |
| APK/IPA | No generados; falta compilar y probar la integración completa en el entorno de desarrollo del dispositivo |
| Cámara/OCR en teléfono físico | Pendiente de validación en Android y iOS |
| Generación real con OpenAI | Pendiente de configurar servidor, credenciales y endpoint HTTPS; no se hicieron llamadas de pago |

La comprobación de tipos Swift no equivale a una compilación completa de iOS ni a una prueba de cámara. La compilación web valida la interfaz y la ruta web; la cámara/OCR móvil utiliza su implementación nativa independiente.

## Pruebas manuales pendientes

1. Permitir y rechazar cámara/galería; cancelar la selección sin generar tarjetas.
2. Extraer una foto nítida de apuntes en español; repetir con una imagen sin texto y con el teléfono sin conexión.
3. Crear un mazo, cerrar completamente la app y comprobar que se conserva al volver a abrir.
4. Editar una tarjeta, reportarla y verificar que vuelve al repaso después de corregirla.
5. Marcar Fácil y Difícil y comprobar las fechas, la racha y el gráfico.
6. Copiar y restaurar un respaldo válido; comprobar que un JSON inválido no sustituye datos.
7. En Android, comprobar recuperación si el sistema termina la actividad mientras la cámara está abierta.
8. Con IA configurada, comprobar permiso explícito, código incorrecto, falta de internet y revisión de tarjetas antes de guardarlas.
9. Ejecutar `flutter test` en un entorno que permita los puertos locales del ejecutor de Flutter.
