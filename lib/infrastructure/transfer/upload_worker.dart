import 'dart:async';
import 'package:big_frames/domain/models/transfer_task.dart';
import 'package:big_frames/infrastructure/s3/s3_storage_provider.dart';
import 'package:big_frames/infrastructure/s3/s3_multipart_upload.dart';
import 'package:big_frames/infrastructure/transfer/retry_policy.dart';
import 'package:big_frames/infrastructure/transfer/transfer_progress.dart';

class UploadWorker {
  final TransferTask task;
  final S3StorageProvider s3Provider;
  final RetryPolicy retryPolicy;
  
  final _progressController = StreamController<TransferTask>.broadcast();
  Stream<TransferTask> get progressStream => _progressController.stream;
  
  bool _isCancelled = false;

  UploadWorker({
    required this.task,
    required this.s3Provider,
    required this.retryPolicy,
  });

  Future<void> start() async {
    final progressTracker = TransferProgress();
    var currentTask = task.copyWith(status: TransferStatus.inProgress);
    _progressController.add(currentTask);
    
    try {
      await retryPolicy.execute(() async {
        if (_isCancelled) throw Exception('Cancelled');
        
        final uploader = S3MultipartUpload(
          minio: s3Provider.minio,
          bucketName: task.bucketName,
          objectKey: task.objectKey,
          localFilePath: task.localFilePath,
        );
        
        await uploader.execute(
          onProgress: (transferred, total) {
            if (_isCancelled) throw Exception('Cancelled');
            
            final speed = progressTracker.getSmoothedSpeed(transferred);
            final eta = progressTracker.calculateETA(task.totalBytes, speed);
            
            currentTask = currentTask.copyWith(
              transferredBytes: transferred,
              currentSpeedBytesPerSec: speed,
              eta: eta,
            );
            _progressController.add(currentTask);
          }
        );
      });
      
      currentTask = currentTask.copyWith(
        transferredBytes: task.totalBytes,
        status: TransferStatus.completed,
        currentSpeedBytesPerSec: 0,
        eta: null,
      );
      _progressController.add(currentTask);
      
    } catch (e) {
      if (_isCancelled) {
        currentTask = currentTask.copyWith(status: TransferStatus.cancelled);
      } else {
        currentTask = currentTask.copyWith(
          status: TransferStatus.failed,
          errorMessage: e.toString(),
        );
      }
      _progressController.add(currentTask);
    } finally {
      _progressController.close();
    }
  }

  void cancel() {
    _isCancelled = true;
  }
}
