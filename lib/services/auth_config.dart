/// Proveedores de inicio de sesión de ApuntIA.
///
/// Google y correo funcionan ya. Apple y Facebook están programados pero
/// apagados hasta completar su configuración externa (pasos en LEEME.md).
abstract final class AuthConfig {
  /// Requiere Apple Developer Program (de pago) y la capacidad
  /// "Sign in with Apple" en Xcode (Runner → Signing & Capabilities).
  static const appleEnabled = false;

  /// Requiere una app en Meta for Developers, el proveedor Facebook activo en
  /// Firebase y el paquete `flutter_facebook_auth`.
  static const facebookEnabled = false;
}
