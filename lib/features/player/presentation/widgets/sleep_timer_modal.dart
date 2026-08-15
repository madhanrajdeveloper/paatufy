import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';

class SleepTimerModal extends ConsumerWidget {
  const SleepTimerModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => const SleepTimerModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.read(audioHandlerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Stop audio in', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildOption(context, '5 minutes', () => handler.setSleepTimer(const Duration(minutes: 5))),
            _buildOption(context, '15 minutes', () => handler.setSleepTimer(const Duration(minutes: 15))),
            _buildOption(context, '30 minutes', () => handler.setSleepTimer(const Duration(minutes: 30))),
            _buildOption(context, '45 minutes', () => handler.setSleepTimer(const Duration(minutes: 45))),
            _buildOption(context, '1 hour', () => handler.setSleepTimer(const Duration(hours: 1))),
            _buildOption(context, 'End of current track', () => handler.setSleepTimerEndAtTrack()),
            const Divider(color: AppTheme.divider),
            _buildOption(context, 'Turn off timer', () => handler.setSleepTimer(null), isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
    );
  }
}