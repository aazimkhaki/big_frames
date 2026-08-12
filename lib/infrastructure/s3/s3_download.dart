import 'dart:io';
import 'package:minio/minio.dart';

class S3Download {
  final Minio minio;
  final String bucketName;
  final String objectKey;
  final String destinationPath;

  S3Download({
    required this.minio,
    required this.bucketName,
    required this.objectKey,
    required this.destinationPath,
  });

  Future<void> execute({
    int resumeOffset = 0,
    Function(int transferred)? onProgress,
  }) async {
    final tempPath = '$destinationPath.part';
    final tempFile = File(tempPath);
    
    // Ensure parent directory exists to prevent PathNotFoundException
    if (!await tempFile.parent.exists()) {
      await tempFile.parent.create(recursive: true);
    }
    
    final IOSink sink = tempFile.openWrite(mode: resumeOffset > 0 ? FileMode.append : FileMode.write);
    
    try {
      // In a real scenario supporting resume, we would pass range headers if minio supports it
      // For now, we simulate the standard streaming download
      final stream = await minio.getObject(bucketName, objectKey);
      
      int transferred = resumeOffset;
      
      await for (final chunk in stream) {
        sink.add(chunk);
        transferred += chunk.length;
        if (onProgress != null) {
          onProgress(transferred);
        }
      }
      
      await sink.flush();
      await sink.close();
      
      // Rename to final file only on success
      await tempFile.rename(destinationPath);
      
    } catch (e) {
      await sink.close();
      rethrow;
    }
  }
}
