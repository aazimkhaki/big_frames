import 'dart:io';
import 'dart:typed_data';
import 'package:minio/minio.dart';

class S3MultipartUpload {
  final Minio minio;
  final String bucketName;
  final String objectKey;
  final String localFilePath;
  final int chunkSize;

  S3MultipartUpload({
    required this.minio,
    required this.bucketName,
    required this.objectKey,
    required this.localFilePath,
    this.chunkSize = 64 * 1024 * 1024, // Default 64MB chunks
  });

  /// Uploads the local file to S3 using minio's putObject, which handles
  /// multipart automatically for large files. Progress is reported via
  /// [onProgress] with (bytesTransferred, totalBytes).
  Future<void> execute({
    String? existingUploadId,
    Function(int transferred, int total)? onProgress,
  }) async {
    final file = File(localFilePath);
    final fileSize = await file.length();

    int transferred = 0;

    // Wrap the file's byte stream to intercept chunk counts for progress.
    final rawStream = file.openRead().map((chunk) {
      final bytes = Uint8List.fromList(chunk);
      transferred += bytes.length;
      onProgress?.call(transferred, fileSize);
      return bytes;
    });

    await minio.putObject(
      bucketName,
      objectKey,
      rawStream,
      size: fileSize,
      chunkSize: chunkSize,
    );

    // Ensure 100% is reported on completion.
    onProgress?.call(fileSize, fileSize);
  }
}
