import 'package:big_frames/domain/models/s3_bucket.dart';
import 'package:big_frames/domain/models/s3_object.dart';

abstract class StorageRepository {
  Future<List<S3Bucket>> listBuckets();
  Future<void> createBucket(String bucketName);
  Future<void> deleteBucket(String bucketName);
  
  Future<List<S3Object>> listObjects(String bucketName, {String? prefix});
  Future<void> deleteObject(String bucketName, String objectKey);
  Future<void> createFolder(String bucketName, String folderPrefix);
}
