import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:paatufy/core/theme/app_theme.dart';
import 'package:paatufy/models/user_playlist.dart';

class PlaylistCollageCover extends StatelessWidget {
  final UserPlaylist playlist;
  final double width;
  final double height;
  final double borderRadius;

  const PlaylistCollageCover({
    super.key,
    required this.playlist,
    this.width = 56,
    this.height = 56,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Prioritize explicit artwork URL if available (e.g., Spotify import)
    if (playlist.artworkUrl != null && playlist.artworkUrl!.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: playlist.artworkUrl!,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _buildFallback(),
        ),
      );
    }

    // 2. Extract distinct non-empty artwork URLs from playlist tracks
    final artUrls = playlist.songs
        .map((s) => s.artworkUrl)
        .where((url) => url != null && url.trim().isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    // 3. 4 or more unique covers -> 2x2 Grid Collage
    if (artUrls.length >= 4) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: artUrls[0],
                        fit: BoxFit.cover,
                        height: double.infinity,
                        errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceElevated),
                      ),
                    ),
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: artUrls[1],
                        fit: BoxFit.cover,
                        height: double.infinity,
                        errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceElevated),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: artUrls[2],
                        fit: BoxFit.cover,
                        height: double.infinity,
                        errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceElevated),
                      ),
                    ),
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: artUrls[3],
                        fit: BoxFit.cover,
                        height: double.infinity,
                        errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceElevated),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. 1 to 3 unique covers -> Display single full cover of the first track
    if (artUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: artUrls.first,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _buildFallback(),
        ),
      );
    }

    // 5. Empty playlist fallback
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.queue_music_rounded,
          color: Colors.white,
          size: width * 0.45,
        ),
      ),
    );
  }
}