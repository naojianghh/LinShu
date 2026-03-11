class FiveToneTrack {
  final String id;
  final String tone;
  final String title;
  final String artist;
  final String audioUrl;
  final String? coverUrl;
  final String? lyric;

  const FiveToneTrack({
    required this.id,
    required this.tone,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.coverUrl,
    this.lyric,
  });

  factory FiveToneTrack.fromJson(Map<String, dynamic> json) {
    return FiveToneTrack(
      id: (json['id'] ?? '').toString(),
      tone: (json['tone'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      artist: (json['artist'] ?? '未知艺术家').toString(),
      audioUrl: (json['audio_url'] ?? json['audioUrl'] ?? '').toString(),
      coverUrl: (json['cover_url'] ?? json['coverUrl'])?.toString(),
      lyric: json['lyric']?.toString(),
    );
  }
}
