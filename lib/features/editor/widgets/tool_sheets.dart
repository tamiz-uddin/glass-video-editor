import 'package:flutter/material.dart';
import 'package:glass_video_editor/core/theme/app_theme.dart';
import 'package:glass_video_editor/core/widgets/glass_panel.dart';

const transitionOptions = <String, String>{
  'none': 'None',
  'fade': 'Fade',
  'slideLeft': 'Slide L',
  'slideRight': 'Slide R',
  'zoom': 'Zoom',
};

const filterOptions = <String, String>{
  'none': 'None',
  'warm': 'Warm',
  'cool': 'Cool',
  'bw': 'B&W',
  'vivid': 'Vivid',
  'vintage': 'Vintage',
};

Future<void> showToolSheet({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 80,
      ),
      child: GlassPanel(
        blur: 30,
        opacity: 0.14,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    ),
  );
}

class OptionSheet extends StatelessWidget {
  const OptionSheet({
    super.key,
    required this.options,
    required this.current,
    required this.onSelected,
  });

  final Map<String, String> options;
  final String current;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((e) {
        final selected = e.key == current;
        return ChoiceChip(
          label: Text(e.value),
          selected: selected,
          onSelected: (_) => onSelected(e.key),
          selectedColor: AppColors.accentViolet,
          labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary),
        );
      }).toList(),
    );
  }
}

class SpeedSheet extends StatefulWidget {
  const SpeedSheet({super.key, required this.initial, required this.onChanged});

  final double initial;
  final ValueChanged<double> onChanged;

  @override
  State<SpeedSheet> createState() => _SpeedSheetState();
}

class _SpeedSheetState extends State<SpeedSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('${_value.toStringAsFixed(2)}x',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
        Slider(
          value: _value.clamp(0.1, 10),
          min: 0.1,
          max: 10,
          divisions: 99,
          activeColor: AppColors.accentViolet,
          onChanged: (v) {
            setState(() => _value = v);
            widget.onChanged(v);
          },
        ),
      ],
    );
  }
}

class VolumeSheet extends StatefulWidget {
  const VolumeSheet({super.key, required this.initial, required this.onChanged});

  final double initial;
  final ValueChanged<double> onChanged;

  @override
  State<VolumeSheet> createState() => _VolumeSheetState();
}

class _VolumeSheetState extends State<VolumeSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _value,
      min: 0,
      max: 1,
      activeColor: AppColors.accentCyan,
      onChanged: (v) {
        setState(() => _value = v);
        widget.onChanged(v);
      },
    );
  }
}

class TextSheet extends StatefulWidget {
  const TextSheet({super.key, required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<TextSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Type caption...',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.check_circle, color: AppColors.accentCyan, size: 32),
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onSubmit(_controller.text.trim());
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}

class ExportSettingsSheet extends StatelessWidget {
  const ExportSettingsSheet({
    super.key,
    required this.width,
    required this.height,
    required this.fps,
    required this.onResolution,
    required this.onFps,
    required this.onExport,
    required this.exporting,
  });

  final int width;
  final int height;
  final int fps;
  final void Function(int width, int height) onResolution;
  final ValueChanged<int> onFps;
  final VoidCallback onExport;
  final bool exporting;

  static const resolutions = <String, List<int>>{
    '720p': [720, 1280],
    '1080p': [1080, 1920],
    '4K': [2160, 3840],
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: resolutions.entries.map((e) {
            final selected = e.value[0] == width && e.value[1] == height;
            return ChoiceChip(
              label: Text(e.key),
              selected: selected,
              onSelected: (_) => onResolution(e.value[0], e.value[1]),
              selectedColor: AppColors.accentViolet,
              labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [24, 30, 60].map((f) {
            final selected = f == fps;
            return ChoiceChip(
              label: Text('$f fps'),
              selected: selected,
              onSelected: (_) => onFps(f),
              selectedColor: AppColors.accentCyan,
              labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: exporting ? null : onExport,
            icon: exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.file_upload_outlined),
            label: Text(exporting ? 'Exporting...' : 'Export video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
          ),
        ),
      ],
    );
  }
}
