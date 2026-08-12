import 'package:uuid/uuid.dart';

enum TransferType { upload, download }
enum TransferStatus { pending, inProgress, paused, completed, failed, cancelled }

class TransferTask {
  final String id;
  final String connectionId;
  final String bucketName;
  final String objectKey;
  final String localFilePath;
  final TransferType type;
  
  final int totalBytes;
  final int transferredBytes;
  final TransferStatus status;
  final String? errorMessage;
  
  // Stats
  final double currentSpeedBytesPerSec; // Bytes per second
  final Duration? eta;

  TransferTask({
    String? id,
    required this.connectionId,
    required this.bucketName,
    required this.objectKey,
    required this.localFilePath,
    required this.type,
    required this.totalBytes,
    this.transferredBytes = 0,
    this.status = TransferStatus.pending,
    this.errorMessage,
    this.currentSpeedBytesPerSec = 0,
    this.eta,
  }) : id = id ?? const Uuid().v4();

  double get progress => totalBytes == 0 ? 0 : transferredBytes / totalBytes;

  TransferTask copyWith({
    int? transferredBytes,
    TransferStatus? status,
    String? errorMessage,
    double? currentSpeedBytesPerSec,
    Duration? eta,
  }) {
    return TransferTask(
      id: id,
      connectionId: connectionId,
      bucketName: bucketName,
      objectKey: objectKey,
      localFilePath: localFilePath,
      type: type,
      totalBytes: totalBytes,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      currentSpeedBytesPerSec: currentSpeedBytesPerSec ?? this.currentSpeedBytesPerSec,
      eta: eta ?? this.eta,
    );
  }
}
