class TransferCheckpoint {
  final String transferId;
  final String? multipartUploadId;
  final List<int> completedPartNumbers;
  
  TransferCheckpoint({
    required this.transferId,
    this.multipartUploadId,
    this.completedPartNumbers = const [],
  });
  
  // This would typically have json serialization logic to store in SQLite
}
