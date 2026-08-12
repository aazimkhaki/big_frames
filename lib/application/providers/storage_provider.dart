import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:big_frames/domain/repositories/storage_repository.dart';
import 'package:big_frames/infrastructure/persistence/connection_storage.dart';
import 'package:big_frames/infrastructure/s3/s3_storage_provider.dart';

final storageRepositoryProvider = FutureProvider.family<StorageRepository, String>((ref, connectionId) async {
  final connectionRepo = await ref.watch(connectionRepositoryProvider.future);
  final connection = await connectionRepo.getConnection(connectionId);
  
  if (connection == null) {
    throw Exception('Connection not found: $connectionId');
  }
  
  return S3StorageProvider(connection);
});

final bucketsProvider = FutureProvider.family<List, String>((ref, connectionId) async {
  final storageRepo = await ref.watch(storageRepositoryProvider(connectionId).future);
  return storageRepo.listBuckets();
});
