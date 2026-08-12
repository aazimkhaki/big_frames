import 'package:minio/minio.dart';

class S3ErrorMapper {
  static String mapError(dynamic error) {
    if (error is MinioError) {
      if (error.message?.contains('SignatureDoesNotMatch') == true) {
        return 'Authentication failed. Please check your Access Key and Secret Key.';
      }
      if (error.message?.contains('NoSuchBucket') == true) {
        return 'The specified bucket does not exist.';
      }
      if (error.message?.contains('AccessDenied') == true) {
        return 'Access denied. You do not have permission to perform this action.';
      }
      if (error.message?.contains('NoSuchKey') == true) {
        return 'The specified file or folder was not found.';
      }
      return 'Storage Error: ${error.message ?? 'Unknown Minio error'}';
    }
    
    // Add mapping for network errors (SocketException etc) here
    final errorStr = error.toString();
    if (errorStr.contains('SocketException') || errorStr.contains('Failed host lookup')) {
      return 'Network error. Please check your internet connection and endpoint.';
    }
    
    return 'An unexpected error occurred: $errorStr';
  }
}
