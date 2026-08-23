class LyricLine {
  final Duration timestamp;
  final String text;
  final bool isInstrumental;
  final Duration duration;

  LyricLine({
    required this.timestamp,
    required this.text,
    this.isInstrumental = false,
    this.duration = const Duration(seconds: 4),
  });

  /// Parses synchronized `.lrc` lyrics and inserts Spotify-style instrumental gaps
  static List<LyricLine> parseLrc(String lrcContent) {
    final List<LyricLine> rawLines = [];
    final regExp = RegExp(r'\[(\d{2}):(\d{2})[.:](\d{2,3})\](.*)');

    for (final rawLine in lrcContent.split('\n')) {
      final trimmed = rawLine.trim();
      final match = regExp.firstMatch(trimmed);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisStr = match.group(3)!.padRight(3, '0').substring(0, 3);
        final milliseconds = int.parse(millisStr);
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          rawLines.add(
            LyricLine(
              timestamp: Duration(
                minutes: minutes,
                seconds: seconds,
                milliseconds: milliseconds,
              ),
              text: text,
            ),
          );
        }
      }
    }
    rawLines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (rawLines.isEmpty) return [];

    final List<LyricLine> enrichedLines = [];

    // 1. Check for Intro Instrumental Break before first vocal line
    if (rawLines.first.timestamp.inSeconds >= 5) {
      enrichedLines.add(
        LyricLine(
          timestamp: Duration.zero,
          text: '•••',
          isInstrumental: true,
          duration: rawLines.first.timestamp,
        ),
      );
    }

    // 2. Iterate lines and insert interludes for vocal gaps >= 6 seconds
    for (int i = 0; i < rawLines.length; i++) {
      enrichedLines.add(rawLines[i]);

      if (i < rawLines.length - 1) {
        final currentTimestamp = rawLines[i].timestamp;
        final nextTimestamp = rawLines[i + 1].timestamp;
        final gapDuration = nextTimestamp - currentTimestamp;

        if (gapDuration.inSeconds >= 6) {
          enrichedLines.add(
            LyricLine(
              timestamp: currentTimestamp + const Duration(seconds: 2),
              text: '•••',
              isInstrumental: true,
              duration: gapDuration - const Duration(seconds: 2),
            ),
          );
        }
      }
    }

    return enrichedLines;
  }
}