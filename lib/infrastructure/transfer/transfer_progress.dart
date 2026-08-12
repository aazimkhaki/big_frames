/// Tracks transfer speed using a sliding time window (last 3 seconds),
/// giving accurate real-time speed from the very first chunk.
class TransferProgress {
  static const _windowMs = 3000; // 3-second sliding window

  // Circular buffer of (timestamp, bytes) samples
  final _samples = <_Sample>[];

  int _totalTransferred = 0;

  void record(int currentTransferred) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _samples.add(_Sample(now, currentTransferred));
    _totalTransferred = currentTransferred;

    // Evict samples older than the window
    _samples.removeWhere((s) => now - s.timestampMs > _windowMs);
  }

  /// Returns bytes/sec averaged over the sliding window.
  double get currentSpeed {
    if (_samples.length < 2) return 0;
    final oldest = _samples.first;
    final newest = _samples.last;
    final elapsedMs = newest.timestampMs - oldest.timestampMs;
    if (elapsedMs <= 0) return 0;
    final bytesDiff = newest.bytes - oldest.bytes;
    return (bytesDiff / elapsedMs) * 1000;
  }

  Duration? calculateETA(int totalBytes, double speed) {
    if (speed <= 0 || totalBytes <= 0) return null;
    final remaining = totalBytes - _totalTransferred;
    if (remaining <= 0) return Duration.zero;
    return Duration(seconds: (remaining / speed).ceil());
  }

  // Legacy API used by workers
  double getSmoothedSpeed(int currentTransferred) {
    record(currentTransferred);
    return currentSpeed;
  }
}

class _Sample {
  final int timestampMs;
  final int bytes;
  const _Sample(this.timestampMs, this.bytes);
}
