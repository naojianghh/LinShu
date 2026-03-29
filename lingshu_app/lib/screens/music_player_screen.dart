import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/five_tone_track.dart';

class MusicPlayerScreen extends StatefulWidget {
  final String title;
  final String toneType;
  final List<FiveToneTrack> tracks;
  final int initialIndex;
  final FiveToneTrack initialTrack;

  const MusicPlayerScreen({
    super.key,
    required this.title,
    required this.toneType,
    required this.tracks,
    required this.initialIndex,
    required this.initialTrack,
  });

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late final AudioPlayer _audioPlayer;
  late int _currentIndex;

  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<void>? _completeSub;

  FiveToneTrack get _currentTrack => widget.tracks[_currentIndex];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _currentIndex = widget.initialIndex;
    _bindPlayerStreams();
    unawaited(_loadAndPlay(_currentTrack));
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _completeSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _bindPlayerStreams() {
    _positionSub = _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() {
        _position = position;
      });
    });

    _durationSub = _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() {
        _duration = duration;
      });
    });

    _playerStateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      _playNext();
    });
  }

  Future<void> _loadAndPlay(FiveToneTrack track) async {
    setState(() {
      _isLoading = true;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setSource(AssetSource(track.path));
      await _audioPlayer.resume();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('播放失败: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }

  Future<void> _playNext() async {
    if (widget.tracks.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.tracks.length;
    });
    await _loadAndPlay(_currentTrack);
  }

  Future<void> _playPrevious() async {
    if (widget.tracks.isEmpty) return;
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + widget.tracks.length) % widget.tracks.length;
    });
    await _loadAndPlay(_currentTrack);
  }

  Future<void> _seekBySlider(double value) async {
    if (_duration.inMilliseconds <= 0) {
      return;
    }
    final targetMs = (_duration.inMilliseconds * value).round();
    await _audioPlayer.seek(Duration(milliseconds: targetMs));
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/meditation_player_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                const Spacer(flex: 1),
                Column(
                  children: [
                    Text(
                      _currentTrack.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Oxygen',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentTrack.artist,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontFamily: 'Oxygen',
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _buildProgressBar(ratio),
                      const SizedBox(height: 24),
                      _buildControls(),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                //_buildLyricCard(),
                const Spacer(flex: 2),
              ],
            ),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color.fromRGBO(0, 0, 0, 0.25),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.expand_more, size: 32, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              const Text(
                '中医五音疗愈',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontFamily: 'STKaiti',
                ),
              ),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'STKaiti',
                ),
              ),
            ],
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double ratio) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
          ),
          child: Slider(value: ratio, onChanged: _seekBySlider),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_position),
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            Text(
              _formatDuration(_duration),
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(
          Icons.queue_music,
          color: Colors.white.withValues(alpha: 0.8),
          size: 22,
        ),
        IconButton(
          onPressed: _playPrevious,
          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
        ),
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 32,
              color: const Color(0xFF8B7D6B),
            ),
          ),
        ),
        IconButton(
          onPressed: _playNext,
          icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
        ),
        Text(
          '${_currentIndex + 1}/${widget.tracks.length}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Widget _buildLyricCard() {
  //   final lyric = _currentTrack.lyric?.trim();
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 32),
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFFE8DCC8).withValues(alpha: 0.3),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Text(
  //       (lyric == null || lyric.isEmpty) ? '暂无歌词' : lyric,
  //       textAlign: TextAlign.center,
  //       style: const TextStyle(
  //         fontSize: 14,
  //         fontWeight: FontWeight.w500,
  //         color: Colors.white,
  //         height: 1.6,
  //         letterSpacing: 0.3,
  //       ),
  //     ),
  //   );
  // }
}
