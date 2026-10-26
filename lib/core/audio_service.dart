import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'persistence.dart';

/// Four reusable SFX voices. Reusing a voice stops its old sound; taps never
/// allocate an unbounded collection of native players.
class AudioService {
  AudioService({this.enabled = true});
  final bool enabled;
  final List<AudioPlayer> _voices = [];
  int _voice = 0, _chapter = -1;
  bool ready = false, _paused = false;
  String? error;
  GameSettings settings = GameSettings();
  Future<void> _musicQueue = Future.value();
  Future<void>? _initializing;
  bool _disposed = false;
  double _fadeGain = 1;
  int musicStarts = 0;
  int get currentChapter => _chapter;
  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    if (!enabled) return;
    try {
      await FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.loadAll([
        for (final s in [
          'click',
          'switch',
          'metal',
          'gear',
          'steam',
          'valve',
          'water',
          'beam',
          'door',
          'win',
          'fail',
          'inventory',
          'pickup',
          'clue',
          'latch',
          'transition',
          'motor_start',
          'motor_stop',
          'jam',
        ])
          'sfx/$s.wav',
      ]);
      for (var i = 0; i < 4; i++) {
        final voice = AudioPlayer()..audioCache = FlameAudio.audioCache;
        await voice.setAudioContext(
          AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
              .build(),
        );
        _voices.add(voice);
      }
      ready = true;
    } catch (e) {
      error = '$e';
      debugPrint('Audio preload: $e');
    }
  }

  Future<void> chapter(int chapter) {
    if (!ready || _disposed) return Future.value();
    if (_chapter == chapter) return _musicQueue;
    final hadMusic = _chapter >= 0;
    _chapter = chapter;
    _musicQueue = _musicQueue.catchError((Object _) {}).then((_) async {
      try {
        if (_disposed || _chapter != chapter) return;
        if (hadMusic) await _fade(0);
        if (_disposed || _chapter != chapter) return;
        await FlameAudio.bgm.play('music/ch${chapter + 1}.wav', volume: 0);
        musicStarts++;
        if (_paused) await FlameAudio.bgm.pause();
        await _fade(1);
      } catch (e) {
        error = '$e';
        debugPrint('Music: $e');
      }
    });
    return _musicQueue;
  }

  double get _volume =>
      settings.muted || !settings.musicEnabled ? 0 : settings.music * _fadeGain;
  Future<void> _fade(double target) async {
    final from = _fadeGain;
    for (var i = 1; i <= 12; i++) {
      if (_disposed) return;
      _fadeGain = from + (target - from) * i / 12;
      await FlameAudio.bgm.audioPlayer.setVolume(_volume);
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
  }

  Future<void> effect(String name) async {
    if (!ready || _disposed || settings.muted || settings.sfx == 0 || _paused) {
      return;
    }
    final player = _voices[_voice++ % _voices.length];
    try {
      await player.stop();
      await player.play(AssetSource('sfx/$name.wav'), volume: settings.sfx);
    } catch (e) {
      error = '$e';
    }
  }

  Future<void> configure(GameSettings next) async {
    settings = next;
    if (ready) {
      await FlameAudio.bgm.audioPlayer.setVolume(_volume);
    }
  }

  Future<void> pause() async {
    _paused = true;
    if (!ready) return;
    await FlameAudio.bgm.pause();
    for (final v in _voices) {
      await v.stop();
    }
  }

  Future<void> resume() async {
    _paused = false;
    if (ready && _chapter >= 0) await FlameAudio.bgm.resume();
  }

  Future<void> dispose() async {
    if (!enabled) return;
    _disposed = true;
    await _initializing;
    await _musicQueue;
    for (final v in _voices) {
      await v.dispose();
    }
    await FlameAudio.bgm.dispose();
  }
}
