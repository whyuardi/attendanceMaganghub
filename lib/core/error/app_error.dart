sealed class AppError {
  final String message;
  const AppError(this.message);

  @override
  String toString() => message;
}

class NetworkError extends AppError {
  const NetworkError([
    super.message = 'Tidak ada koneksi. Absen belum tercatat. Coba lagi',
  ]);
}

class UnauthorizedError extends AppError {
  const UnauthorizedError([
    super.message = 'Sesi telah berakhir. Silakan masuk kembali',
  ]);
}

class ValidationError extends AppError {
  const ValidationError(super.message);
}

class UnknownError extends AppError {
  const UnknownError([
    super.message = 'Terjadi kesalahan sistem. Silakan coba lagi',
  ]);
}
