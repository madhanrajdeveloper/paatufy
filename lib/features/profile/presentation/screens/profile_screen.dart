import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paatufy/core/storage/hive_service.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/audio/presentation/controllers/player_controller.dart';
import 'package:paatufy/features/auth/presentation/controllers/auth_controller.dart';
import 'package:paatufy/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _formatListeningTime(int totalSeconds) {
    if (totalSeconds <= 0) return '0 mins';
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '$hours hr ${mins > 0 ? '$mins min' : ''}';
    return '$mins mins';
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref, UserModel targetUser, VoidCallback onDeleted) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: Text('Remove Account?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Text(
          'Are you sure you want to remove "${targetUser.name}" (${targetUser.email}) from this device? Its local storage and cached playlists will be cleared.',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(authControllerProvider.notifier).removeAccount(targetUser.id);
              onDeleted();
            },
            child: Text('Remove', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSwitchAccountModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final allUsers = HiveService.getAllUsers();
          final currentUser = ref.read(authControllerProvider).user;
          final audioHandler = ref.watch(audioHandlerProvider);
          final hasActiveMiniPlayer = audioHandler.mediaItem.value != null;
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          // Provide 90px clearance for the floating MiniPlayer when keyboard is closed
          final bottomPadding = bottomInset > 0
              ? bottomInset + 20
              : (hasActiveMiniPlayer ? 90.0 : 24.0);

          return AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: bottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Switch Account', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Select an account to load its isolated library, or tap the delete icon to remove it from this device.',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                if (allUsers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('No accounts registered.', style: GoogleFonts.poppins(color: AppTheme.textSecondary))),
                  )
                else
                  ...allUsers.map((user) {
                    final isCurrent = user.id == currentUser?.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF22C55E),
                        backgroundImage: user.photoUrl != null ? CachedNetworkImageProvider(user.photoUrl!) : null,
                        child: user.photoUrl == null
                            ? Text(user.name[0].toUpperCase(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black))
                            : null,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: GoogleFonts.poppins(fontSize: 9, color: const Color(0xFF22C55E), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            tooltip: 'Remove Account',
                            onPressed: () {
                              _confirmDeleteAccount(context, ref, user, () {
                                final remaining = HiveService.getAllUsers();
                                if (remaining.isEmpty) {
                                  Navigator.pop(ctx);
                                  context.go('/login');
                                } else {
                                  setModalState(() {});
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        if (!isCurrent) {
                          await ref.read(authControllerProvider.notifier).switchUser(user);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) context.go('/home');
                        }
                      },
                    );
                  }),
                const Divider(color: AppTheme.divider, height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: AppTheme.surface, shape: BoxShape.circle),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF22C55E)),
                  ),
                  title: Text('Add another account', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/signup');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user ?? HiveService.getUserMeta(HiveService.activeUserId);

    final likedCount = HiveService.getLikedSongs().length;
    final playlistCount = HiveService.getUserPlaylists().length;
    final savedAlbumCount = HiveService.getSavedAlbums().length;

    final history = HiveService.getActiveRecentlyPlayed();
    final totalListeningSecs = history.fold<int>(0, (sum, item) => sum + item.durationSeconds);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profile & Summary', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_account_rounded, color: Color(0xFF22C55E)),
            tooltip: 'Switch Account',
            onPressed: () => _showSwitchAccountModal(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // User Card Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFF22C55E),
                  backgroundImage: user?.photoUrl != null ? CachedNetworkImageProvider(user!.photoUrl!) : null,
                  child: user?.photoUrl == null
                      ? Text(
                          (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U',
                          style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? 'Paatufy Listener', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(user?.email ?? 'listener@paatufy.com', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF22C55E), width: 0.5),
                  ),
                  child: Text(
                    '${user?.authProvider.toUpperCase() ?? 'EMAIL'} VERIFIED',
                    style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF22C55E), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // User Stats Summary Shelf
          Text('Account Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _buildSummaryCard('Liked Songs', '$likedCount tracks', Icons.favorite_rounded, const Color(0xFFE91E63)),
              _buildSummaryCard('Playlists', '$playlistCount created', Icons.queue_music_rounded, const Color(0xFF22C55E)),
              _buildSummaryCard('Saved Albums', '$savedAlbumCount saved', Icons.album_rounded, const Color(0xFF3B82F6)),
              _buildSummaryCard('Estimated Time', _formatListeningTime(totalListeningSecs), Icons.schedule_rounded, const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 24),

          // Account Details & Storage Info
          Text('Storage & Identity Details', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildDetailRow('User ID', user?.id ?? 'guest'),
                const Divider(color: AppTheme.divider, height: 20),
                _buildDetailRow('Storage Scope', 'user_${user?.id ?? 'guest'}_*'),
                const Divider(color: AppTheme.divider, height: 20),
                _buildDetailRow(
                  'Member Since',
                  user != null ? DateTime.fromMillisecondsSinceEpoch(user.createdAt).toLocal().toString().split(' ')[0] : 'Today',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Log Out Action
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: Text('Log Out', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          Text(title, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}