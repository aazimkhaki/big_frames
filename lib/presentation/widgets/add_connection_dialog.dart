import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:big_frames/core/region_detector.dart';
import 'package:big_frames/core/theme/app_theme.dart';
import 'package:big_frames/domain/models/connection.dart';
import 'package:big_frames/infrastructure/persistence/connection_storage.dart';
import 'package:big_frames/presentation/screens/connections_screen.dart';
import 'package:big_frames/presentation/screens/bucket_browser_screen.dart';

// Provider presets — region is set automatically but not shown to user
class _Preset {
  final String label;
  final String endpoint;
  final String region;
  final IconData icon;
  final Color color;
  const _Preset(this.label, this.endpoint, this.region, this.icon, this.color);
}

const _presets = [
  _Preset('AWS S3',        'https://s3.amazonaws.com',                          'us-east-1', Icons.cloud,          Color(0xFFFF9900)),
  _Preset('Wasabi',        'https://s3.wasabisys.com',                          'us-east-1', Icons.bolt_rounded,   Color(0xFF00C853)),
  _Preset('Cloudflare R2', 'https://account.r2.cloudflarestorage.com',          'auto',      Icons.shield_rounded, Color(0xFFFF6633)),
  _Preset('MinIO',         'http://localhost:9000',                              'us-east-1', Icons.storage_rounded,AppTheme.accent),
];

class AddConnectionDialog extends ConsumerStatefulWidget {
  const AddConnectionDialog({super.key});

  @override
  ConsumerState<AddConnectionDialog> createState() =>
      _AddConnectionDialogState();
}

class _AddConnectionDialogState extends ConsumerState<AddConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController(text: 'My Storage');
  final _accessKeyCtrl = TextEditingController();
  final _secretKeyCtrl = TextEditingController();
  final _endpointCtrl  = TextEditingController(text: 'https://s3.wasabisys.com');

  // Region is auto-managed; not shown in UI
  String _region = 'us-east-1';

  bool _isSaving = false;
  bool _obscureSecret = true;
  int? _selectedPreset;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _accessKeyCtrl.dispose();
    _secretKeyCtrl.dispose();
    _endpointCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(int index) {
    final p = _presets[index];
    setState(() {
      _selectedPreset = index;
      _region = p.region;
    });
    _endpointCtrl.text = p.endpoint;
    _nameCtrl.text = '${p.label} Connection';
  }

  Future<void> _saveConnection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = await ref.read(connectionRepositoryProvider.future);
      // If user didn't pick a preset, auto-detect region from the endpoint.
      final region = _selectedPreset != null
          ? _region
          : RegionDetector.fromEndpoint(_endpointCtrl.text.trim());
      final connection = S3Connection(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        accessKey: _accessKeyCtrl.text.trim(),
        secretKey: _secretKeyCtrl.text.trim(),
        region: region,
        endpoint: _endpointCtrl.text.trim(),
      );
      await repo.saveConnection(connection, connection.secretKey);
      ref.invalidate(connectionsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BucketBrowserScreen(
              connectionId: connection.id,
              connectionName: connection.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: border),
      ),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Title ─────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accent, Color(0xFF4F8EF7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_link_rounded,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'New Connection',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.textDark : AppTheme.textLight,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(28, 28),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Provider presets ──────────────────────────────────
                Text('PROVIDER',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark
                            ? AppTheme.subTextDark
                            : AppTheme.subTextLight)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_presets.length, (i) {
                    final p = _presets[i];
                    return _PresetChip(
                      label: p.label,
                      icon: p.icon,
                      color: p.color,
                      selected: _selectedPreset == i,
                      onTap: () => _applyPreset(i),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // ── Fields ────────────────────────────────────────────
                _label('Connection Name', isDark),
                const SizedBox(height: 6),
                _field(
                    controller: _nameCtrl,
                    hint: 'My Wasabi Storage',
                    icon: Icons.label_outline_rounded),
                const SizedBox(height: 14),

                _label('Access Key ID', isDark),
                const SizedBox(height: 6),
                _field(
                    controller: _accessKeyCtrl,
                    hint: 'AKIAIOSFODNN7EXAMPLE',
                    icon: Icons.key_rounded),
                const SizedBox(height: 14),

                _label('Secret Access Key', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _secretKeyCtrl,
                  obscureText: _obscureSecret,
                  decoration: InputDecoration(
                    hintText: '••••••••••••••••••••••••',
                    prefixIcon:
                        const Icon(Icons.lock_outline_rounded, size: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSecret
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 16,
                      ),
                      onPressed: () =>
                          setState(() => _obscureSecret = !_obscureSecret),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                _label('Endpoint URL', isDark),
                const SizedBox(height: 6),
                _field(
                    controller: _endpointCtrl,
                    hint: 'https://s3.wasabisys.com',
                    icon: Icons.link_rounded),
                const SizedBox(height: 24),

                // ── Actions ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSaving ? null : _saveConnection,
                      child: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Connect'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, bool isDark) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.textDark : AppTheme.textLight,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 16),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      );
}

// ── Preset Chip ───────────────────────────────────────────────────────────────
class _PresetChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PresetChip> createState() => _PresetChipState();
}

class _PresetChipState extends State<_PresetChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? widget.color.withValues(alpha: 0.12)
                : (_hovered
                    ? widget.color.withValues(alpha: 0.06)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.selected
                  ? widget.color
                  : (_hovered
                      ? widget.color.withValues(alpha: 0.4)
                      : border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: widget.color),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.selected
                      ? widget.color
                      : (isDark
                          ? AppTheme.textDark
                          : AppTheme.textLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
