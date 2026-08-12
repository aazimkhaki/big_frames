import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:big_frames/application/providers/storage_provider.dart';
import 'package:big_frames/core/theme/app_theme.dart';
import 'package:big_frames/domain/models/s3_object.dart';
import 'package:big_frames/domain/models/transfer_task.dart';
import 'package:big_frames/infrastructure/s3/s3_storage_provider.dart';
import 'package:big_frames/infrastructure/transfer/transfer_manager.dart';
import 'package:big_frames/presentation/widgets/transfer_panel.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final currentPrefixProvider =
    StateProvider.family<String, String>((ref, bucketName) => '');

typedef ObjectsArgs = ({String connectionId, String bucketName});

final objectsProvider =
    FutureProvider.family<List<S3Object>, ObjectsArgs>((ref, args) async {
  final prefix = ref.watch(currentPrefixProvider(args.bucketName));
  final storageRepo =
      await ref.watch(storageRepositoryProvider(args.connectionId).future);
  return storageRepo.listObjects(args.bucketName,
      prefix: prefix.isEmpty ? null : prefix);
});

// ── File type helpers ────────────────────────────────────────────────────────

IconData _iconForExtension(String name) {
  final ext = p.extension(name).toLowerCase();
  const images = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.tiff'};
  const videos = {'.mp4', '.mov', '.avi', '.mkv', '.mxf', '.r3d', '.braw'};
  const audio  = {'.mp3', '.wav', '.aac', '.flac', '.m4a'};
  const docs   = {'.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'};
  const code   = {'.dart', '.py', '.js', '.ts', '.json', '.yaml', '.xml'};
  const zips   = {'.zip', '.tar', '.gz', '.rar', '.7z'};
  if (images.contains(ext)) return Icons.image_rounded;
  if (videos.contains(ext)) return Icons.videocam_rounded;
  if (audio.contains(ext))  return Icons.audiotrack_rounded;
  if (docs.contains(ext))   return Icons.description_rounded;
  if (code.contains(ext))   return Icons.code_rounded;
  if (zips.contains(ext))   return Icons.folder_zip_rounded;
  return Icons.insert_drive_file_rounded;
}

Color _colorForExtension(String name) {
  final ext = p.extension(name).toLowerCase();
  const images = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.tiff'};
  const videos = {'.mp4', '.mov', '.avi', '.mkv', '.mxf', '.r3d', '.braw'};
  const audio  = {'.mp3', '.wav', '.aac', '.flac', '.m4a'};
  if (images.contains(ext)) return const Color(0xFF22D3EE);
  if (videos.contains(ext)) return const Color(0xFFA78BFA);
  if (audio.contains(ext))  return const Color(0xFFF472B6);
  return const Color(0xFF6B7280);
}

// ── Screen ───────────────────────────────────────────────────────────────────

class FileBrowserScreen extends ConsumerStatefulWidget {
  final String connectionId;
  final String bucketName;
  const FileBrowserScreen({
    super.key,
    required this.connectionId,
    required this.bucketName,
  });

  @override
  ConsumerState<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends ConsumerState<FileBrowserScreen> {
  bool _isDraggingOver = false;

  void _handleDroppedFiles(List<XFile> files, String prefix) {
    final manager = ref.read(transferManagerProvider.notifier);
    for (final xfile in files) {
      final localPath = xfile.path;
      final fileName = p.basename(localPath);
      final objectKey = prefix.isEmpty ? fileName : '$prefix$fileName';
      manager.addUpload(
          widget.connectionId, widget.bucketName, objectKey, localPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefix = ref.watch(currentPrefixProvider(widget.bucketName));
    final objectsArgs =
        (connectionId: widget.connectionId, bucketName: widget.bucketName);
    final objectsAsync = ref.watch(objectsProvider(objectsArgs));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-refresh when an upload for this bucket completes
    ref.listen<List<TransferTask>>(transferManagerProvider, (prev, next) {
      if (prev == null) return;
      final prevStatuses = {for (final t in prev) t.id: t.status};
      for (final task in next) {
        if (task.bucketName == widget.bucketName &&
            task.type == TransferType.upload &&
            task.status == TransferStatus.completed &&
            prevStatuses[task.id] != TransferStatus.completed) {
          ref.invalidate(objectsProvider(objectsArgs));
          break;
        }
      }
    });

    return Scaffold(
      body: Column(
        children: [
          // ── Top bar ────────────────────────────────────────────────
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              border: Border(
                bottom: BorderSide(
                    color: isDark
                        ? AppTheme.borderDark
                        : AppTheme.borderLight),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back to Buckets',
                ),
                Expanded(
                  child: _BreadcrumbBar(
                    bucketName: widget.bucketName,
                    prefix: prefix,
                    onSegmentTap: (newPrefix) => ref
                        .read(currentPrefixProvider(widget.bucketName)
                            .notifier)
                        .state = newPrefix,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  tooltip: 'Refresh',
                  onPressed: () =>
                      ref.invalidate(objectsProvider(objectsArgs)),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          // ── Main area ──────────────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                // Sidebar
                Material(
                  color: isDark
                      ? AppTheme.surfaceDark
                      : AppTheme.surfaceLight,
                  child: SizedBox(
                    width: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 12, 12, 4),
                          child: Text(
                            'NAVIGATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? AppTheme.subTextDark
                                  : AppTheme.subTextLight,
                            ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.storage_rounded,
                              size: 16),
                          title: Text(
                            widget.bucketName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(
                    width: 1,
                    color: isDark
                        ? AppTheme.borderDark
                        : AppTheme.borderLight),

                // File list + drop target
                Expanded(
                  child: DropTarget(
                    onDragEntered: (_) =>
                        setState(() => _isDraggingOver = true),
                    onDragExited: (_) =>
                        setState(() => _isDraggingOver = false),
                    onDragDone: (details) {
                      setState(() => _isDraggingOver = false);
                      _handleDroppedFiles(details.files, prefix);
                    },
                    child: Stack(
                      children: [
                        objectsAsync.when(
                          data: (objects) {
                            if (objects.isEmpty) {
                              return _EmptyFolder(
                                  prefix: prefix,
                                  bucketName: widget.bucketName);
                            }
                            return _FileContent(
                              objects: objects,
                              bucketName: widget.bucketName,
                              connectionId: widget.connectionId,
                              onFolderTap: (key) => ref
                                  .read(currentPrefixProvider(
                                          widget.bucketName)
                                      .notifier)
                                  .state = key,
                            );
                          },
                          loading: () => const Center(
                              child: CircularProgressIndicator()),
                          error: (err, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(err.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                      fontSize: 13)),
                            ),
                          ),
                        ),
                        // Drop overlay
                        if (_isDraggingOver)
                          Positioned.fill(
                            child: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.accent
                                    .withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppTheme.accent, width: 2),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 56,
                                      color: AppTheme.accent),
                                  const SizedBox(height: 14),
                                  const Text('Drop to upload',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.accent)),
                                  const SizedBox(height: 6),
                                  Text(
                                    's3://${widget.bucketName}/$prefix',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.accent),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Transfer panel
                const TransferPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── File Content (folders as tiles, files as list) ───────────────────────────

class _FileContent extends ConsumerWidget {
  final List<S3Object> objects;
  final String bucketName;
  final String connectionId;
  final void Function(String) onFolderTap;

  const _FileContent({
    required this.objects,
    required this.bucketName,
    required this.connectionId,
    required this.onFolderTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = objects.where((o) => o.isPrefix).toList();
    final files   = objects.where((o) => !o.isPrefix).toList();
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final subText = isDark ? AppTheme.subTextDark : AppTheme.subTextLight;

    return ListView(
      children: [
        // ── Folder tiles section ──────────────────────────────────
        if (folders.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('FOLDERS',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: subText)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: folders
                  .map((folder) => _FolderTile(
                        folder: folder,
                        bucketName: bucketName,
                        connectionId: connectionId,
                        onTap: () => onFolderTap(folder.key),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),
        ],

        // ── File list section ─────────────────────────────────────
        if (files.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text('FILES',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: subText)),
          ),
          // Column header
          Container(
            margin: const EdgeInsets.only(top: 8),
            color: isDark ? AppTheme.surface2Dark : AppTheme.surface2Light,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 28),
                Expanded(
                  flex: 4,
                  child: Text('NAME',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: subText)),
                ),
                SizedBox(
                  width: 90,
                  child: Text('SIZE',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: subText)),
                ),
                SizedBox(
                  width: 140,
                  child: Text('MODIFIED',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: subText)),
                ),
                const SizedBox(width: 64),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight),
          ...files.map((file) => _FileRow(
                object: file,
                bucketName: bucketName,
                connectionId: connectionId,
                onFolderTap: onFolderTap,
              )),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Folder Tile ───────────────────────────────────────────────────────────────

class _FolderTile extends ConsumerStatefulWidget {
  final S3Object folder;
  final String bucketName;
  final String connectionId;
  final VoidCallback onTap;

  const _FolderTile({
    required this.folder,
    required this.bucketName,
    required this.connectionId,
    required this.onTap,
  });

  @override
  ConsumerState<_FolderTile> createState() => _FolderTileState();
}

class _FolderTileState extends ConsumerState<_FolderTile> {
  bool _hovered = false;

  Future<void> _downloadFolder(BuildContext context) async {
    final destDir = await getDirectoryPath(
      confirmButtonText: 'Download Here',
    );
    if (destDir == null) return;

    final s3Provider = await ref.read(
        storageRepositoryProvider(widget.connectionId).future) as S3StorageProvider;

    final allFiles = await s3Provider.listAllFilesRecursively(
        widget.bucketName, widget.folder.key);

    final manager = ref.read(transferManagerProvider.notifier);
    final folderName = widget.folder.name.replaceAll('/', '');

    for (final file in allFiles) {
      // Preserve relative structure inside the destination folder
      final relPath = file.key.substring(widget.folder.key.length);
      final localPath = '$destDir/$folderName/$relPath';
      manager.addDownload(
        widget.connectionId,
        widget.bucketName,
        file.key,
        localPath,
        file.size ?? 0,
      );
    }
  }

  void _showContextMenu(BuildContext context, TapUpDetails details) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuBg = isDark ? AppTheme.surface2Dark : AppTheme.surfaceLight;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final relPos = RelativeRect.fromRect(
      Rect.fromLTWH(
          details.globalPosition.dx, details.globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    showMenu<void>(
      context: context,
      position: relPos,
      color: menuBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: border),
      ),
      elevation: 8,
      items: <PopupMenuEntry<void>>[
        PopupMenuItem(
          height: 36,
          onTap: () => widget.onTap(),
          child: _MenuRow(
              icon: Icons.folder_open_rounded,
              label: 'Open',
              color: AppTheme.amber,
              textColor: textColor),
        ),
        PopupMenuItem(
          height: 36,
          onTap: () => _downloadFolder(context),
          child: _MenuRow(
              icon: Icons.download_rounded,
              label: 'Download Folder',
              color: AppTheme.accent,
              textColor: textColor),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          height: 36,
          onTap: () {},
          child: _MenuRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: Theme.of(context).colorScheme.error,
              textColor: Theme.of(context).colorScheme.error),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.surface2Dark : AppTheme.surface2Light;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapUp: (details) => _showContextMenu(context, details),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 140,
          height: 100,
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.amber.withValues(alpha: 0.08)
                : bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? AppTheme.amber.withValues(alpha: 0.5)
                  : border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppTheme.amber.withValues(alpha: 0.1),
                      blurRadius: 12,
                    )
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedScale(
                  scale: _hovered ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  child: const Icon(Icons.folder_rounded,
                      color: AppTheme.amber, size: 28),
                ),
                const Spacer(),
                Text(
                  widget.folder.name.replaceAll('/', ''),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.textDark : AppTheme.textLight,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── File Row ─────────────────────────────────────────────────────────────────

class _FileRow extends ConsumerStatefulWidget {
  final S3Object object;
  final String bucketName;
  final String connectionId;
  final void Function(String) onFolderTap;

  const _FileRow({
    required this.object,
    required this.bucketName,
    required this.connectionId,
    required this.onFolderTap,
  });

  @override
  ConsumerState<_FileRow> createState() => _FileRowState();
}

class _FileRowState extends ConsumerState<_FileRow> {
  bool _hovered = false;

  Future<void> _triggerDownload(BuildContext context) async {
    final obj = widget.object;
    final saveLocation = await getSaveLocation(suggestedName: p.basename(obj.key));
    if (saveLocation == null) return;
    ref.read(transferManagerProvider.notifier).addDownload(
          widget.connectionId,
          widget.bucketName,
          obj.key,
          saveLocation.path,
          obj.size ?? 0,
        );
  }

  Future<void> _streamFile(BuildContext context) async {
    final obj = widget.object;
    if (obj.isPrefix) return;

    try {
      final s3Provider = await ref.read(storageRepositoryProvider(widget.connectionId).future) as S3StorageProvider;
      final urlStr = await s3Provider.getPresignedUrl(widget.bucketName, obj.key);
      final uri = Uri.tryParse(urlStr);
      if (uri != null) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate streaming link: $e')),
        );
      }
    }
  }

  void _showContextMenu(BuildContext context, TapUpDetails details) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuBg = isDark ? AppTheme.surface2Dark : AppTheme.surfaceLight;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final relPos = RelativeRect.fromRect(
      Rect.fromLTWH(
          details.globalPosition.dx, details.globalPosition.dy, 0, 0),
      Offset.zero & overlay.size,
    );

    showMenu<void>(
      context: context,
      position: relPos,
      color: menuBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: border),
      ),
      elevation: 8,
      items: <PopupMenuEntry<void>>[
        PopupMenuItem(
          height: 36,
          onTap: () => _triggerDownload(context),
          child: _MenuRow(
              icon: Icons.download_rounded,
              label: 'Download',
              color: AppTheme.accent,
              textColor: textColor),
        ),
        PopupMenuItem(
          height: 36,
          onTap: () {},
          child: _MenuRow(
              icon: Icons.copy_rounded,
              label: 'Copy Key',
              color: isDark ? AppTheme.subTextDark : AppTheme.subTextLight,
              textColor: textColor),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          height: 36,
          onTap: () {},
          child: _MenuRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: Theme.of(context).colorScheme.error,
              textColor: Theme.of(context).colorScheme.error),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final obj = widget.object;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    final subText   = isDark ? AppTheme.subTextDark : AppTheme.subTextLight;
    final hoverBg   = isDark ? AppTheme.surface2Dark : AppTheme.surface2Light;
    final border    = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    final icon      = _iconForExtension(obj.name);
    final iconColor = _colorForExtension(obj.name);
    final sizeStr   = _formatSize(obj.size ?? 0);
    final dateStr   = obj.lastModified != null
        ? DateFormat('MMM d, yyyy').format(obj.lastModified!)
        : '—';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onDoubleTap: obj.isPrefix ? null : () => _streamFile(context),
        onSecondaryTapUp: (details) => _showContextMenu(context, details),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          color: _hovered ? hoverBg : Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: SizedBox(
                  height: 38,
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: iconColor),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: Text(obj.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13, color: textColor)),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(sizeStr,
                            style: TextStyle(
                                fontSize: 12, color: subText)),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text(dateStr,
                            style: TextStyle(
                                fontSize: 12, color: subText)),
                      ),
                      SizedBox(
                        width: 64,
                        child: AnimatedOpacity(
                          opacity: _hovered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 120),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _RowIconButton(
                                icon: Icons.download_rounded,
                                tooltip: 'Download',
                                onTap: () => _triggerDownload(context),
                              ),
                              _RowIconButton(
                                icon: Icons.delete_outline_rounded,
                                tooltip: 'Delete',
                                onTap: () {},
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                  height: 1,
                  color: border.withValues(alpha: 0.5),
                  indent: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _RowIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  const _RowIconButton(
      {required this.icon,
      required this.tooltip,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 14,
              color: color ??
                  (isDark ? AppTheme.subTextDark : AppTheme.subTextLight)),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  const _MenuRow(
      {required this.icon,
      required this.label,
      required this.color,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(fontSize: 13, color: textColor)),
      ],
    );
  }
}

// ── Breadcrumb Bar ────────────────────────────────────────────────────────────

class _BreadcrumbBar extends StatelessWidget {
  final String bucketName;
  final String prefix;
  final void Function(String) onSegmentTap;

  const _BreadcrumbBar(
      {required this.bucketName,
      required this.prefix,
      required this.onSegmentTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.subTextDark : AppTheme.subTextLight;
    final activeColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    final segments = prefix.isEmpty
        ? <String>[]
        : prefix.split('/').where((s) => s.isNotEmpty).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onSegmentTap(''),
            child: Text(bucketName,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: segments.isEmpty
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color:
                        segments.isEmpty ? activeColor : textColor)),
          ),
          for (int i = 0; i < segments.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.chevron_right_rounded,
                  size: 14, color: textColor),
            ),
            GestureDetector(
              onTap: () {
                final newPrefix =
                    '${segments.sublist(0, i + 1).join('/')}/';
                onSegmentTap(newPrefix);
              },
              child: Text(segments[i],
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == segments.length - 1
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: i == segments.length - 1
                          ? activeColor
                          : textColor)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Empty Folder ──────────────────────────────────────────────────────────────

class _EmptyFolder extends StatelessWidget {
  final String prefix;
  final String bucketName;
  const _EmptyFolder({required this.prefix, required this.bucketName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.cloud_upload_outlined,
                size: 36, color: AppTheme.accent),
          ),
          const SizedBox(height: 20),
          Text('This folder is empty',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textDark : AppTheme.textLight)),
          const SizedBox(height: 8),
          Text('Drag & drop files here to upload',
              style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.subTextDark
                      : AppTheme.subTextLight)),
        ],
      ),
    );
  }
}
