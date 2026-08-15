import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/features/search/presentation/screens/entity_detail_screen.dart';
import 'package:paatufy/features/search/presentation/screens/search_screen.dart';
import 'package:paatufy/models/app_notification.dart';

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final provider = ref.watch(jioSaavnProviderInstance);

  final results = await Future.wait([
    provider.searchAll('Latest Tamil Singles 2026'),
    provider.searchAll('New English Releases 2026'),
  ]);

  final List<AppNotification> notifications = [];

  // Tamil releases
  for (var album in results[0].albums.take(3)) {
    notifications.add(
      AppNotification(
        id: 'notif_${album.id}',
        title: 'New Release from ${album.artist}',
        message: 'New single "${album.title}" is out now.',
        timeAgo: '2h ago',
        imageUrl: album.artworkUrl,
        type: NotificationType.release,
        targetId: album.id,
        targetTitle: album.title,
      ),
    );
  }

  // English releases
  for (var album in results[1].albums.take(3)) {
    notifications.add(
      AppNotification(
        id: 'notif_${album.id}',
        title: 'Fresh Drop • ${album.artist}',
        message: 'Album "${album.title}" added to trending.',
        timeAgo: '5h ago',
        imageUrl: album.artworkUrl,
        type: NotificationType.release,
        targetId: album.id,
        targetTitle: album.title,
      ),
    );
  }

  // Mix update
  notifications.add(
    AppNotification(
      id: 'notif_mix_refresh',
      title: 'Daily Mix Refreshed',
      message: 'Your personal mix and top picks have been updated for today.',
      timeAgo: '1d ago',
      type: NotificationType.playlist,
    ),
  );

  return notifications;
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("What's New", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          TextButton(
            onPressed: () {
              final list = notificationsAsync.value;
              if (list != null) {
                setState(() {
                  for (var item in list) {
                    item.isRead = true;
                  }
                });
              }
            },
            child: const Text('Mark all read', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Music'),
                const SizedBox(width: 8),
                _buildFilterChip('Playlists'),
              ],
            ),
          ),
          Expanded(
            child: notificationsAsync.when(
              data: (items) {
                final filtered = items.where((item) {
                  if (_selectedFilter == 'Music') return item.type == NotificationType.release;
                  if (_selectedFilter == 'Playlists') return item.type == NotificationType.playlist;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No new updates right now', style: TextStyle(color: AppTheme.textSecondary)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(color: AppTheme.divider, height: 20),
                  itemBuilder: (context, index) {
                    final notif = filtered[index];

                    return GestureDetector(
                      onTap: () {
                        setState(() => notif.isRead = true);
                        if (notif.targetId != null && notif.type == NotificationType.release) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EntityDetailScreen(
                                id: notif.targetId!,
                                title: notif.targetTitle ?? 'Album',
                                artworkUrl: notif.imageUrl,
                                type: DetailType.album,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: notif.imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: notif.imageUrl!,
                                      width: 54,
                                      height: 54,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 54,
                                      height: 54,
                                      color: AppTheme.surfaceElevated,
                                      child: const Icon(Icons.notifications_active_rounded, color: AppTheme.primary),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif.title,
                                          style: TextStyle(
                                            fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                                            fontSize: 14,
                                            color: AppTheme.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!notif.isRead)
                                        Container(
                                          width: 7,
                                          height: 7,
                                          margin: const EdgeInsets.only(left: 6),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.message,
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notif.timeAgo,
                                    style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (err, _) => Center(
                child: Text('Error loading feed: $err', style: const TextStyle(color: AppTheme.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = label),
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.surfaceElevated,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}