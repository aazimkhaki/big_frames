class S3Object {
  final String key;
  final int? size;
  final DateTime? lastModified;
  final String? eTag;
  final bool isPrefix; // true if this represents a folder/prefix
  final String? storageClass;

  const S3Object({
    required this.key,
    this.size,
    this.lastModified,
    this.eTag,
    this.isPrefix = false,
    this.storageClass,
  });

  String get name {
    if (isPrefix) {
      final parts = key.split('/');
      if (parts.length >= 2 && parts.last.isEmpty) {
        return '${parts[parts.length - 2]}/';
      }
      return key.split('/').last;
    }
    return key.split('/').last;
  }
}
