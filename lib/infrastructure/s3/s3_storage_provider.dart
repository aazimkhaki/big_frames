import 'dart:async';

import 'package:minio/minio.dart';
import 'package:big_frames/domain/models/connection.dart';
import 'package:big_frames/domain/models/s3_bucket.dart';
import 'package:big_frames/domain/models/s3_object.dart';
import 'package:big_frames/domain/repositories/storage_repository.dart';
import 'package:big_frames/infrastructure/s3/s3_error_mapper.dart';

class S3StorageProvider implements StorageRepository {
  final Minio minio;
  final S3Connection connection;

  S3StorageProvider(this.connection)
      : minio = Minio(
          endPoint: connection.endpoint.replaceFirst(RegExp(r'^https?:\/\/'), ''),
          accessKey: connection.accessKey,
          secretKey: connection.secretKey,
          region: connection.region,
          useSSL: connection.endpoint.startsWith('https'),
          pathStyle: true,
        );

  @override
  Future<List<S3Bucket>> listBuckets() async {
    try {
      final buckets = await minio.listBuckets();
      return buckets
          .map((b) => S3Bucket(
                name: b.name,
                creationDate: b.creationDate ?? DateTime.now(),
              ))
          .toList();
    } catch (e) {
      throw Exception(S3ErrorMapper.mapError(e));
    }
  }

  @override
  Future<void> createBucket(String bucketName) async {
    try {
      await minio.makeBucket(bucketName);
    } catch (e) {
      throw Exception(S3ErrorMapper.mapError(e));
    }
  }

  @override
  Future<void> deleteBucket(String bucketName) async {
    try {
      await minio.removeBucket(bucketName);
    } catch (e) {
      throw Exception(S3ErrorMapper.mapError(e));
    }
  }

  @override
  Future<List<S3Object>> listObjects(String bucketName, {String? prefix}) async {
    try {
      print('listObjects called for bucket: $bucketName, prefix: $prefix');
      final stream = minio.listObjectsV2(bucketName, prefix: prefix ?? '', recursive: false);
      final List<S3Object> objects = [];
      print('Waiting for stream chunks...');

      // Use a Completer + explicit subscription to avoid the stream hanging
      // indefinitely (known issue with minio dart package where the stream
      // may not emit a 'done' event after all objects have been delivered).
      final completer = Completer<void>();
      late final StreamSubscription subscription;
      subscription = stream.listen(
        (chunk) {
          for (final p in chunk.prefixes) {
            objects.add(S3Object(key: p, isPrefix: true));
          }
          for (final obj in chunk.objects) {
            if (obj.key != prefix) { // Exclude the folder object itself
              objects.add(S3Object(
                key: obj.key ?? '',
                size: obj.size,
                lastModified: obj.lastModified,
                eTag: obj.eTag,
                isPrefix: false,
              ));
            }
          }
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        onError: (Object e, StackTrace st) {
          if (!completer.isCompleted) completer.completeError(e, st);
        },
        cancelOnError: true,
      );

      // Wait for stream to finish, with a safety timeout of 30 seconds.
      await completer.future
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              subscription.cancel();
              print('listObjects timed out after 30s, returning ${objects.length} collected so far');
            },
          );

      await subscription.cancel();

      objects.sort((a, b) {
        if (a.isPrefix && !b.isPrefix) return -1;
        if (!a.isPrefix && b.isPrefix) return 1;
        return a.key.compareTo(b.key);
      });

      print('Returning ${objects.length} objects');
      return objects;
    } catch (e) {
      print('Error in listObjects: $e');
      throw Exception(S3ErrorMapper.mapError(e));
    }
  }

  @override
  Future<void> deleteObject(String bucketName, String objectKey) async {
    try {
      await minio.removeObject(bucketName, objectKey);
    } catch (e) {
      throw Exception(S3ErrorMapper.mapError(e));
    }
  }

  @override
  Future<void> createFolder(String bucketName, String folderPrefix) async {
    try {
      final key = folderPrefix.endsWith('/') ? folderPrefix : '$folderPrefix/';
      await minio.putObject(bucketName, key, const Stream.empty());
    } catch (e) {
      throw Exception(S3ErrorMapper.mapError(e));
    }
  }
  
  // Advanced features requested:

  Future<void> renameObject(String bucketName, String oldKey, String newKey) async {
    try {
      // S3 has no rename. We must copy then delete.
      await minio.copyObject(bucketName, newKey, '/$bucketName/$oldKey');
      await minio.removeObject(bucketName, oldKey);
    } catch (e) {
      throw Exception(S3ErrorMapper.mapError(e));
    }
  }

  /// Generates a presigned URL for streaming/downloading directly in the browser/player.
  Future<String> getPresignedUrl(String bucketName, String objectKey, {int expiryInSeconds = 3600}) async {
    try {
      return await minio.presignedGetObject(bucketName, objectKey, expires: expiryInSeconds);
    } catch (e) {
      throw Exception(S3ErrorMapper.mapError(e));
    }
  }

  /// Lists ALL files (non-prefix objects) recursively under [prefix].
  /// Used for folder downloads — returns flat list of every leaf file key.
  Future<List<S3Object>> listAllFilesRecursively(
      String bucketName, String prefix) async {
    try {
      final stream =
          minio.listObjectsV2(bucketName, prefix: prefix, recursive: true);
      final List<S3Object> objects = [];
      final completer = Completer<void>();
      late final StreamSubscription sub;
      sub = stream.listen(
        (chunk) {
          for (final obj in chunk.objects) {
            if (obj.key != null && !obj.key!.endsWith('/')) {
              objects.add(S3Object(
                key: obj.key!,
                size: obj.size,
                lastModified: obj.lastModified,
                eTag: obj.eTag,
                isPrefix: false,
              ));
            }
          }
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        onError: (Object e, StackTrace st) {
          if (!completer.isCompleted) completer.completeError(e, st);
        },
        cancelOnError: true,
      );
      await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => sub.cancel(),
      );
      await sub.cancel();
      return objects;
    } catch (e) {
      throw Exception(S3ErrorMapper.mapError(e));
    }
  }
}
