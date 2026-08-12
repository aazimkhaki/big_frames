import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:big_frames/application/providers/storage_provider.dart';
import 'package:big_frames/core/theme/app_theme.dart';
import 'package:big_frames/domain/models/s3_bucket.dart';
import 'package:big_frames/presentation/screens/file_browser_screen.dart';
import 'package:intl/intl.dart';

class BucketBrowserScreen extends ConsumerWidget {
  final String connectionId;
  final String connectionName;

  const BucketBrowserScreen({
    super.key,
    required this.connectionId,
    required this.connectionName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bucketsAsync = ref.watch(bucketsProvider(connectionId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              connectionName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textDark : AppTheme.textLight,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Buckets',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(bucketsProvider(connectionId)),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
        ),
      ),
      body: bucketsAsync.when(
        data: (buckets) {
          if (buckets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off_outlined,
                      size: 48,
                      color: isDark
                          ? AppTheme.subTextDark
                          : AppTheme.subTextLight),
                  const SizedBox(height: 16),
                  Text(
                    'No buckets found',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.textDark : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: buckets.length,
            itemBuilder: (context, index) {
              final bucket = buckets[index] as S3Bucket;
              return _BucketCard(
                bucket: bucket,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FileBrowserScreen(
                      connectionId: connectionId,
                      bucketName: bucket.name,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 40, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BucketCard extends StatefulWidget {
  final S3Bucket bucket;
  final VoidCallback onTap;
  const _BucketCard({required this.bucket, required this.onTap});

  @override
  State<_BucketCard> createState() => _BucketCardState();
}

class _BucketCardState extends State<_BucketCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.surface2Dark : AppTheme.surface2Light;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final dateStr = DateFormat('MMM d, yyyy').format(widget.bucket.creationDate);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? AppTheme.amber.withValues(alpha: 0.6) : border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppTheme.amber.withValues(alpha: 0.12),
                    blurRadius: 16,
                    spreadRadius: 0,
                  )
                ]
              : [],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon area
                AnimatedScale(
                  scale: _hovered ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: AppTheme.amber,
                      size: 26,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  widget.bucket.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textDark : AppTheme.textLight,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppTheme.subTextDark : AppTheme.subTextLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
