/// Extracts an S3 region from a known endpoint URL pattern.
/// Falls back to 'us-east-1' for unrecognised endpoints.
class RegionDetector {
  static const _fallback = 'us-east-1';

  static String fromEndpoint(String endpoint) {
    final uri = Uri.tryParse(endpoint);
    if (uri == null) return _fallback;
    final host = uri.host.toLowerCase();

    // Cloudflare R2 — uses 'auto' as region
    if (host.contains('r2.cloudflarestorage.com')) return 'auto';

    // AWS S3 — s3.<region>.amazonaws.com  or  s3-<region>.amazonaws.com
    final awsMatch = RegExp(
            r's3[.\-]([a-z]{2}-[a-z]+-\d+)\.amazonaws\.com')
        .firstMatch(host);
    if (awsMatch != null) return awsMatch.group(1)!;

    // Wasabi — s3.<region>.wasabisys.com
    final wasabiMatch =
        RegExp(r's3\.([a-z]{2}-[a-z]+-\d+)\.wasabisys\.com')
            .firstMatch(host);
    if (wasabiMatch != null) return wasabiMatch.group(1)!;

    // Backblaze B2 — s3.<region>.backblazeb2.com
    final b2Match =
        RegExp(r's3\.([a-z]{3}\d{3})\.backblazeb2\.com').firstMatch(host);
    if (b2Match != null) return b2Match.group(1)!;

    // DigitalOcean Spaces — <region>.digitaloceanspaces.com
    final doMatch =
        RegExp(r'^([a-z]{3}\d+)\.digitaloceanspaces\.com').firstMatch(host);
    if (doMatch != null) return doMatch.group(1)!;

    return _fallback;
  }
}
