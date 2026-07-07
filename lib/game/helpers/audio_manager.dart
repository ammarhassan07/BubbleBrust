import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _isPlaying = false;

  // Continuous background piano track
  Future<void> playBGM() async {
    if (_isPlaying) return;
    _isPlaying = true;
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource('audio/piano.mp3'));
  }

  void stopBGM() {
    _bgmPlayer.stop();
    _isPlaying = false;
  }

  // FIXED: Fire-and-forget player method for overlapping instantaneous sound effects
  // FIXED FOR AUDIO PLAYERS 6.X: Correct asynchronous instantiation and stream listening
  void playPopSFX() {
    final AudioPlayer player = AudioPlayer();

    // 1. Listen for completion first, then dispose the player channel automatically
    player.onPlayerComplete.listen((_) {
      player.dispose();
    });

    // 2. Fire the asset sound track stream cleanly
    player.play(AssetSource('audio/pop.mp3'));
  }}