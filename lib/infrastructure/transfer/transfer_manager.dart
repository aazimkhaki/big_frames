import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:big_frames/application/providers/storage_provider.dart';
import 'package:big_frames/domain/models/transfer_task.dart';
import 'package:big_frames/infrastructure/persistence/database_provider.dart';
import 'package:big_frames/infrastructure/persistence/transfer_storage.dart';
import 'package:big_frames/infrastructure/s3/s3_storage_provider.dart';
import 'package:big_frames/infrastructure/transfer/download_worker.dart';
import 'package:big_frames/infrastructure/transfer/retry_policy.dart';
import 'package:big_frames/infrastructure/transfer/upload_worker.dart';

final transferStorageProvider = FutureProvider<TransferStorage>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return TransferStorage(db);
});

final transferManagerProvider = StateNotifierProvider<TransferManager, List<TransferTask>>((ref) {
  return TransferManager(ref);
});

class TransferManager extends StateNotifier<List<TransferTask>> {
  final Ref _ref;
  final RetryPolicy _retryPolicy = RetryPolicy();
  
  // Track active workers to allow cancellation
  final Map<String, dynamic> _activeWorkers = {};

  TransferManager(this._ref) : super([]) {
    _loadPersistedTransfers();
  }

  Future<void> _loadPersistedTransfers() async {
    try {
      final storage = await _ref.read(transferStorageProvider.future);
      final tasks = storage.getAllTransfers();
      state = tasks;
      
      // Auto-resume incomplete tasks on startup
      for (final task in tasks) {
        if (task.status == TransferStatus.inProgress || task.status == TransferStatus.pending) {
          if (task.type == TransferType.upload) {
            _startUpload(task);
          } else {
            _startDownload(task);
          }
        }
      }
    } catch (e) {
      // Handle db load error
    }
  }

  Future<void> addUpload(String connectionId, String bucketName, String objectKey, String localFilePath) async {
    final file = File(localFilePath);
    if (!await file.exists()) return;
    
    final size = await file.length();
    final task = TransferTask(
      connectionId: connectionId,
      bucketName: bucketName,
      objectKey: objectKey,
      localFilePath: localFilePath,
      type: TransferType.upload,
      totalBytes: size,
    );
    
    _addTask(task);
    _startUpload(task);
  }

  Future<void> addDownload(String connectionId, String bucketName, String objectKey, String localFilePath, int size) async {
    final task = TransferTask(
      connectionId: connectionId,
      bucketName: bucketName,
      objectKey: objectKey,
      localFilePath: localFilePath,
      type: TransferType.download,
      totalBytes: size,
    );
    
    _addTask(task);
    _startDownload(task);
  }

  void _addTask(TransferTask task) {
    state = [task, ...state];
    _ref.read(transferStorageProvider.future).then((storage) => storage.saveTransfer(task));
  }

  Future<void> _startUpload(TransferTask task) async {
    try {
      final s3Provider = await _ref.read(storageRepositoryProvider(task.connectionId).future) as S3StorageProvider;
      
      final worker = UploadWorker(
        task: task,
        s3Provider: s3Provider,
        retryPolicy: _retryPolicy,
      );
      
      _activeWorkers[task.id] = worker;
      
      worker.progressStream.listen((updatedTask) {
        _updateTaskState(updatedTask);
      });
      
      await worker.start();
    } catch (e) {
      _updateTaskState(task.copyWith(status: TransferStatus.failed, errorMessage: e.toString()));
    } finally {
      _activeWorkers.remove(task.id);
    }
  }

  Future<void> _startDownload(TransferTask task) async {
    try {
      final s3Provider = await _ref.read(storageRepositoryProvider(task.connectionId).future) as S3StorageProvider;
      
      final worker = DownloadWorker(
        task: task,
        s3Provider: s3Provider,
        retryPolicy: _retryPolicy,
      );
      
      _activeWorkers[task.id] = worker;
      
      worker.progressStream.listen((updatedTask) {
        _updateTaskState(updatedTask);
      });
      
      await worker.start();
    } catch (e) {
      _updateTaskState(task.copyWith(status: TransferStatus.failed, errorMessage: e.toString()));
    } finally {
      _activeWorkers.remove(task.id);
    }
  }

  void cancelTask(String id) {
    if (_activeWorkers.containsKey(id)) {
      _activeWorkers[id]!.cancel();
    } else {
      // If it's not active, just mark it cancelled in state/db
      final task = state.firstWhere((t) => t.id == id);
      _updateTaskState(task.copyWith(status: TransferStatus.cancelled));
    }
  }

  void pauseTask(String id) {
    // Mark task as paused in state; a full implementation would
    // signal the active UploadWorker to pause mid-chunk.
    final taskIndex = state.indexWhere((t) => t.id == id);
    if (taskIndex == -1) return;
    final task = state[taskIndex];
    if (task.status == TransferStatus.inProgress) {
      _activeWorkers[id]?.cancel();
      _updateTaskState(task.copyWith(status: TransferStatus.paused));
    }
  }

  void _updateTaskState(TransferTask updatedTask) {
    state = state.map((t) => t.id == updatedTask.id ? updatedTask : t).toList();
    // Throttle db writes in a real app, for now we persist immediately or on key state changes
    _ref.read(transferStorageProvider.future).then((storage) => storage.saveTransfer(updatedTask));
  }
}
