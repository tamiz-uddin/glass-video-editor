import 'package:flutter/material.dart';
import 'package:glass_video_editor/core/theme/app_theme.dart';
import 'package:glass_video_editor/core/widgets/glass_panel.dart';

class EditorTool {
  const EditorTool(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class GlassToolbar extends StatelessWidget {
  const GlassToolbar({super.key, required this.tools});

  final List<EditorTool> tools;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      blur: 28,
      opacity: 0.10,
      radius: AppRadius.panel,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: tools
            .map(
              (tool) => _ToolButton(tool: tool),
            )
            .toList(),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.tool});

  final EditorTool tool;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.button),
      onTap: tool.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tool.icon, color: AppColors.textPrimary, size: 22),
            const SizedBox(height: 4),
            Text(
              tool.label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
