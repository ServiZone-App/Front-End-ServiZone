/// Contenedor genérico y tipado para todas las respuestas de la API.
///
/// Garantías:
/// - [data] solo existe cuando [success] == true
/// - [message] siempre está presente (nunca null)
/// - [statusCode] refleja el código HTTP real recibido del servidor
class ApiResult<T> {
  final bool success;
  final T? data;
  final String message;
  final int statusCode;

  const ApiResult._({
    required this.success,
    this.data,
    required this.message,
    required this.statusCode,
  });

  factory ApiResult.success({
    required T data,
    String message = '',
    int statusCode = 200,
  }) =>
      ApiResult._(
        success: true,
        data: data,
        message: message,
        statusCode: statusCode,
      );

  factory ApiResult.failure({
    required String message,
    int statusCode = 0,
  }) =>
      ApiResult._(
        success: false,
        data: null,
        message: message,
        statusCode: statusCode,
      );

  /// Transforma el dato interno si el resultado fue exitoso.
  // ignore: unused_element
  ApiResult<R> map<R>(R Function(T data) transform) {
    if (success && data != null) {
      return ApiResult.success(
        data: transform(data as T),
        message: message,
        statusCode: statusCode,
      );
    }
    return ApiResult.failure(message: message, statusCode: statusCode);
  }

  @override
  String toString() => success
      ? 'ApiResult.success(statusCode: $statusCode, data: $data)'
      : 'ApiResult.failure(statusCode: $statusCode, message: $message)';
}
