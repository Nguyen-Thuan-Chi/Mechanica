import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/puzzles/model.dart';

class GameSettings {
  GameSettings({
    this.music = .45,
    this.sfx = .7,
    this.reducedMotion = false,
    this.muted = false,
    this.musicEnabled = true,
  });
  double music, sfx;
  bool reducedMotion, muted, musicEnabled;
  Json toJson() => {
    'music': music,
    'sfx': sfx,
    'reduced_motion': reducedMotion,
    'muted': muted,
    'music_enabled': musicEnabled,
  };
  static GameSettings fromJson(Json j) => GameSettings(
    music: (j['music'] as num? ?? .45).toDouble().clamp(0, 1),
    sfx: (j['sfx'] as num? ?? .7).toDouble().clamp(0, 1),
    reducedMotion: j['reduced_motion'] as bool? ?? false,
    muted: j['muted'] as bool? ?? false,
    musicEnabled: j['music_enabled'] as bool? ?? true,
  );
}

class ProgressStore {
  ProgressStore(this.preferences, {this.development = false});
  final bool development;
  final SharedPreferences preferences;
  static const key = 'mechanica_save_v1', backupKey = 'mechanica_save_backup';
  String get storageKey => development ? 'mechanica_development_v2' : key;
  String get storageBackupKey =>
      development ? 'mechanica_development_backup' : backupKey;
  int _loadedVersion = 2;
  int unlocked = 1;
  final Map<String, int> bestStars = {}, bestMoves = {}, hintUsage = {};
  final Set<String> tutorials = {};
  GameSettings settings = GameSettings();
  Json? resume;
  String? warning;
  Future<void> _pending = Future.value();

  void load() {
    for (final candidate in [
      preferences.getString(storageKey),
      preferences.getString(storageBackupKey),
    ]) {
      if (candidate == null) continue;
      try {
        final j = object(jsonDecode(candidate));
        if (j['save_version'] != 1 && j['save_version'] != 2) {
          throw const FormatException('Unsupported save version');
        }
        // Parse everything before committing so a damaged primary cannot
        // contaminate a valid backup with partially restored values.
        final nextUnlocked = (j['unlocked'] as int).clamp(1, 12);
        final stars = Map<String, int>.from(j['best_stars'] as Map? ?? {});
        final moves = Map<String, int>.from(j['best_moves'] as Map? ?? {});
        final hints = Map<String, int>.from(j['hint_usage'] as Map? ?? {});
        final seen = array(j['tutorials']).cast<String>().toList();
        final nextSettings = GameSettings.fromJson(object(j['settings']));
        final nextResume = j['resume'] == null ? null : object(j['resume']);
        if (stars.values.any((v) => v < 1 || v > 3) ||
            moves.values.any((v) => v < 0) ||
            hints.values.any((v) => v < 0 || v > 3)) {
          throw const FormatException('Invalid progress counters');
        }
        unlocked = nextUnlocked;
        bestStars
          ..clear()
          ..addAll(stars);
        bestMoves
          ..clear()
          ..addAll(moves);
        hintUsage
          ..clear()
          ..addAll(hints);
        tutorials
          ..clear()
          ..addAll(seen);
        settings = nextSettings;
        resume = nextResume;
        _loadedVersion = j['save_version']! as int;
        return;
      } catch (_) {
        warning = 'Bản lưu gần nhất bị lỗi. Đã thử phục hồi bản dự phòng.';
      }
    }
  }

  Json snapshot() => {
    'save_version': _loadedVersion,
    'unlocked': unlocked,
    'best_stars': bestStars,
    'best_moves': bestMoves,
    'hint_usage': hintUsage,
    'tutorials': tutorials.toList(),
    'settings': settings.toJson(),
    'resume': resume,
  };
  Future<void> save() {
    final encoded = jsonEncode(snapshot());
    _pending = _pending.catchError((Object _) {}).then((_) async {
      final previous = preferences.getString(storageKey);
      if (previous != null) {
        await preferences.setString(storageBackupKey, previous);
      }
      final ok = await preferences.setString(storageKey, encoded);
      if (!ok) {
        warning = 'Không lưu được tiến trình trên thiết bị.';
      }
    });
    return _pending;
  }

  Future<void> saveSession(
    PuzzleDefinition level,
    PuzzleState state,
    int hints,
    int undo,
  ) {
    _loadedVersion = 2;
    resume = state.won
        ? null
        : {
            'level': level.id,
            'state': state.toJson(),
            'hints': hints,
            'undo': undo,
          };
    hintUsage[level.id] = hints;
    return save();
  }

  PuzzleState? restore(PuzzleDefinition level) {
    if (resume?['level'] != level.id) return null;
    try {
      final j = object(resume!['state']);
      final values = Map<String, int>.from(j['values']! as Map);
      if (_loadedVersion == 1) {
        // Keep the old machine configuration; new room content starts fresh.
        for (final e in level.initial.entries) {
          values.putIfAbsent(e.key, () => e.value);
        }
      }
      if (!level.initial.keys.every(values.containsKey) ||
          values.values.any((v) => v.abs() > 100000)) {
        throw const FormatException();
      }
      // Ignore unknown future/corrupt fields, but retain all canonical fields.
      final clean = {for (final k in level.initial.keys) k: values[k]!};
      for (final item in level.room?.items ?? <RoomItem>[]) {
        if (clean[item.field]! > 2) {
          throw const FormatException('Invalid inventory status');
        }
      }
      if (clean.entries.any((e) => e.value < 0 && e.key != 'direction')) {
        throw const FormatException('Negative resource in resume');
      }
      for (final control in level.controls) {
        if (control.field != null &&
            control.options.isNotEmpty &&
            clean[control.field!]! >= control.options.length) {
          throw const FormatException('Invalid control position in resume');
        }
      }
      if (level.massFields.isNotEmpty &&
          level.massFields.fold(0, (int sum, k) => sum + clean[k]!) !=
              level.massFields.fold(
                0,
                (int sum, k) => sum + level.initial[k]!,
              )) {
        throw const FormatException('Invalid fluid mass in resume');
      }
      return PuzzleState(
        values: clean,
        moves: (j['moves'] as int).clamp(0, 100000),
        errors: (j['errors'] as int).clamp(0, 100000),
        ticks: (j['ticks'] as int).clamp(0, 100000),
      );
    } catch (_) {
      warning = 'Máy đang chơi không thể phục hồi; màn sẽ bắt đầu lại.';
      resume = null;
      return null;
    }
  }

  Future<void> complete(PuzzleDefinition l, int stars, int moves) {
    unlocked = (l.number + 1).clamp(unlocked, 12);
    if (stars > (bestStars[l.id] ?? 0)) bestStars[l.id] = stars;
    if (moves < (bestMoves[l.id] ?? 1 << 30)) bestMoves[l.id] = moves;
    resume = null;
    return save();
  }

  Future<void> resetProgress() async {
    unlocked = 1;
    bestStars.clear();
    bestMoves.clear();
    hintUsage.clear();
    tutorials.clear();
    resume = null;
    _loadedVersion = 2;
    await _pending.catchError((Object _) {});
    await preferences.remove(storageBackupKey);
    await preferences.remove(storageKey);
    await save();
  }
}
