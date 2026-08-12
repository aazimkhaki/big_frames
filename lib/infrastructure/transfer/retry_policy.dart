import 'dart:math';

class RetryPolicy {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffFactor;

  RetryPolicy({
    this.maxRetries = 5,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffFactor = 2.0,
  });

  Future<T> execute<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (_isPermanentError(e)) {
          rethrow;
        }
        
        // Exponential backoff capped at 60 seconds
        final maxDelay = const Duration(seconds: 60);
        var delay = initialDelay * pow(backoffFactor, attempts - 1);
        if (delay > maxDelay) delay = maxDelay;
        
        await Future.delayed(delay);
      }
    }
  }

  bool _isPermanentError(dynamic error) {
    final str = error.toString().toLowerCase();
    // Skip retries for AccessDenied, Authentication, NoSuchBucket, etc.
    if (str.contains('access denied') || 
        str.contains('authentication') ||
        str.contains('signaturedoesnotmatch') ||
        str.contains('nosuchbucket')) {
      return true;
    }
    return false;
  }
}
