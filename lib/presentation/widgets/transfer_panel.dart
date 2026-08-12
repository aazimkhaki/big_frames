import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:big_frames/core/theme/app_theme.dart';
import 'package:big_frames/domain/models/transfer_task.dart';
import 'package:big_frames/infrastructure/transfer/transfer_manager.dart';

class TransferPanel extends ConsumerWidget {
  const TransferPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(transferManagerProvider);
    final activeTasks =
        tasks.where((t) => t.status != TransferStatus.completed).toList();
    final recentlyDone = tasks
        .where((t) => t.status == TransferStatus.completed)
        .take(3)
        .toList();
    final shown = [...activeTasks, ...recentlyDone];

    if (shown.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final bg = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 280,
      decoration: BoxDecoration(
        color: bg,
        border: Border(left: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                const Icon(Icons.swap_vert_rounded,
                    size: 14, color: AppTheme.accent),
                const SizedBox(width: 8),
                Text(
                  'Transfers',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.textDark : AppTheme.textLight,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${shown.length}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),

          // Transfer list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: shown.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                return _TransferItem(task: shown[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferItem extends ConsumerWidget {
  final TransferTask task;
  const _TransferItem({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.surface2Dark : AppTheme.surface2Light;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final subText = isDark ? AppTheme.subTextDark : AppTheme.subTextLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;

    final inProgressLabel = task.type == TransferType.upload ? 'Uploading' : 'Downloading';
    final (statusColor, statusLabel) = switch (task.status) {
      TransferStatus.pending    => (subText, 'Queued'),
      TransferStatus.inProgress => (AppTheme.accent, inProgressLabel),
      TransferStatus.paused     => (const Color(0xFFFFB74D), 'Paused'),
      TransferStatus.completed  => (const Color(0xFF4ADE80), 'Done'),
      TransferStatus.failed     => (Theme.of(context).colorScheme.error, 'Failed'),
      TransferStatus.cancelled  => (subText, 'Cancelled'),
    };

    final fileName = task.objectKey.split('/').last;
    final progress = task.status == TransferStatus.completed
        ? 1.0
        : task.progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                task.type == TransferType.upload
                    ? Icons.upload_rounded
                    : Icons.download_rounded,
                size: 13,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w600),
              ),
              if (task.status == TransferStatus.inProgress) ...[
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.pause_rounded,
                  tooltip: 'Pause',
                  onTap: () => ref
                      .read(transferManagerProvider.notifier)
                      .pauseTask(task.id),
                ),
                const SizedBox(width: 2),
                _ActionBtn(
                  icon: Icons.close_rounded,
                  tooltip: 'Cancel',
                  onTap: () => ref
                      .read(transferManagerProvider.notifier)
                      .cancelTask(task.id),
                ),
              ],
            ],
          ),
          if (task.status == TransferStatus.inProgress ||
              task.status == TransferStatus.paused ||
              task.status == TransferStatus.completed) ...[
            const SizedBox(height: 8),
            // Gradient progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  Container(
                    height: 3,
                    color: isDark
                        ? AppTheme.borderDark
                        : AppTheme.borderLight,
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: task.status == TransferStatus.completed
                              ? [
                                  const Color(0xFF4ADE80),
                                  const Color(0xFF22D3EE)
                                ]
                              : [
                                  AppTheme.accent,
                                  const Color(0xFF4F8EF7),
                                ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 10, color: subText),
                ),
                const Spacer(),
                if (task.status == TransferStatus.inProgress)
                  _SpeedChip(
                    speed: task.currentSpeedBytesPerSec,
                    eta: task.eta,
                  ),
              ],
            ),
          ],
          if (task.status == TransferStatus.failed &&
              task.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                task.errorMessage!,
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  String _formatSpeed(int bps) {
    if (bps < 1024) return '$bps B/s';
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}

class _SpeedChip extends StatelessWidget {
  final double speed;
  final Duration? eta;
  const _SpeedChip({required this.speed, this.eta});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final speedStr = _formatSpeed(speed.toInt());
    final etaStr = eta != null ? ' · ${_formatEta(eta!)}' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$speedStr$etaStr',
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatSpeed(int bps) {
    if (bps < 1024) return '$bps B/s';
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatEta(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            icon,
            size: 12,
            color: isDark ? AppTheme.subTextDark : AppTheme.subTextLight,
          ),
        ),
      ),
    );
  }
}
