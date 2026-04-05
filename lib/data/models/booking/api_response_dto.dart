/// Wrapper que mapea la estructura `{ success, data, message }` que devuelve
/// el backend de bookings. Se usa internamente en [BookingApiService] para
/// extraer los datos antes de convertirlos a [ApiResult].
class ApiResponseDto {
  final bool success;
  final dynamic data;
  final String message;

  const ApiResponseDto({
    required this.success,
    required this.data,
    required this.message,
  });

  factory ApiResponseDto.fromJson(Map<String, dynamic> json) {
    return ApiResponseDto(
      success: json['success'] as bool? ?? false,
      data: json['data'] ?? json['Data'],
      message: (json['message'] ?? json['Message'] ?? '').toString(),
    );
  }
}
