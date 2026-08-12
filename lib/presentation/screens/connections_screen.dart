import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:big_frames/core/theme/app_theme.dart';
import 'package:big_frames/domain/models/connection.dart';
import 'package:big_frames/infrastructure/persistence/connection_storage.dart';
import 'package:big_frames/presentation/widgets/add_connection_dialog.dart';
import 'package:big_frames/presentation/screens/bucket_browser_screen.dart';

final connectionsProvider = FutureProvider<List<S3Connection>>((ref) async {
  final repo = await ref.watch(connectionRepositoryProvider.future);
  return repo.getConnections();
});

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Logo + title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.accent, Color(0xFF4F8EF7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.cloud_done_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Big Frames',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.textDark : AppTheme.textLight,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your S3-compatible storage connections',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.subTextDark : AppTheme.subTextLight,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _AddConnectionButton(ref: ref),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: connectionsAsync.when(
              data: (connections) {
                if (connections.isEmpty) {
                  return _EmptyState(onAdd: () => _showAddDialog(context));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: connections.length + 1, // +1 for "add" card
                  itemBuilder: (context, index) {
                    if (index == connections.length) {
                      return _AddConnectionCard(
                          onTap: () => _showAddDialog(context));
                    }
                    final conn = connections[index];
                    return _ConnectionCard(
                      connection: conn,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BucketBrowserScreen(
                            connectionId: conn.id,
                            connectionName: conn.name,
                          ),
                        ),
                      ),
                      onDelete: () async {
                        final confirm = await _confirmDelete(context, conn.name);
                        if (confirm == true) {
                          final repo = await ref
                              .read(connectionRepositoryProvider.future);
                          await repo.deleteConnection(conn.id);
                          ref.invalidate(connectionsProvider);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AddConnectionDialog(),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Remove "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddConnectionButton extends StatelessWidget {
  final WidgetRef ref;
  const _AddConnectionButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.add, size: 16),
      label: const Text('New Connection'),
      onPressed: () => showDialog(
        context: context,
        builder: (_) => const AddConnectionDialog(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.cloud_off_rounded,
                size: 40, color: AppTheme.accent),
          ),
          const SizedBox(height: 20),
          Text(
            'No connections yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textDark : AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first S3-compatible storage connection\nto start browsing and uploading files.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? AppTheme.subTextDark : AppTheme.subTextLight,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Connection'),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatefulWidget {
  final S3Connection connection;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _ConnectionCard(
      {required this.connection,
      required this.onTap,
      required this.onDelete});

  @override
  State<_ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<_ConnectionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.surface2Dark : AppTheme.surface2Light;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? AppTheme.accent : border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.15),
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
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accent, Color(0xFF4F8EF7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.cloud_queue_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: InkWell(
                        onTap: widget.onDelete,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(Icons.delete_outline_rounded,
                              size: 16,
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.connection.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textDark : AppTheme.textLight,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.connection.region,
                  style: TextStyle(
                    fontSize: 12,
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

class _AddConnectionCard extends StatefulWidget {
  final VoidCallback onTap;
  const _AddConnectionCard({required this.onTap});

  @override
  State<_AddConnectionCard> createState() => _AddConnectionCardState();
}

class _AddConnectionCardState extends State<_AddConnectionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered
              ? AppTheme.accent.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? AppTheme.accent : border,
            style: BorderStyle.solid,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 28,
                color: _hovered
                    ? AppTheme.accent
                    : (isDark ? AppTheme.subTextDark : AppTheme.subTextLight),
              ),
              const SizedBox(height: 8),
              Text(
                'Add Connection',
                style: TextStyle(
                  fontSize: 13,
                  color: _hovered
                      ? AppTheme.accent
                      : (isDark
                          ? AppTheme.subTextDark
                          : AppTheme.subTextLight),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
