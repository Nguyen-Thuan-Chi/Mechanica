import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/audio_service.dart';
import '../core/persistence.dart';
import '../game/puzzles/model.dart';
import '../game/puzzles/reducer.dart';

enum AppPage { home, chapters, levels, play, ending }

class GameController extends ChangeNotifier {
  GameController(this.levels, ProgressStore store, this.audio)
    : _playerStore = store;
  final List<PuzzleDefinition> levels;
  final ProgressStore _playerStore;
  ProgressStore? _developmentStore;
  bool _developer = false, showHotspots = false;
  bool get isDeveloper => kDebugMode && _developer;
  ProgressStore get store => isDeveloper ? _developmentStore! : _playerStore;
  bool isUnlocked(int number) => isDeveloper || number <= store.unlocked;
  Future<void> setDeveloper(bool enabled) async {
    if (!kDebugMode) return;
    await saveNow();
    if (enabled) {
      _developmentStore ??= ProgressStore(
        _playerStore.preferences,
        development: true,
      )..load();
    }
    _developer = enabled;
    session = null;
    selectedItem = null;
    inventoryOpen = false;
    showHotspots = false;
    page = AppPage.home;
    paused = false;
    running = false;
    await audio.configure(store.settings);
    notifyListeners();
  }

  void developerJump(int index) {
    if (!kDebugMode || !isDeveloper) return;
    start(index);
  }

  void developerHotspots() {
    if (!kDebugMode || !isDeveloper) return;
    showHotspots = !showHotspots;
    notifyListeners();
  }

  Future<void> developerResetSave() async {
    if (!kDebugMode || !isDeveloper) return;
    await store.resetProgress();
    session = null;
    navigate(AppPage.home);
  }

  final AudioService audio;
  AppPage page = AppPage.home;
  int selectedChapter = 0;
  int machineFocus = -1;
  PuzzleSession? session;
  bool zoom = false, paused = false, running = false, showResult = false;
  String message = '';
  int revision = 0;
  List<GameEvent> latestEvents = [];
  String? selectedItem;
  bool inventoryOpen = false;
  int sceneSerial = 0;
  List<RoomItem> get inventory =>
      session?.definition.room?.items
          .where((i) => session!.state[i.field] > 0)
          .toList() ??
      [];
  RoomItem? get heldItem {
    for (final item in inventory) {
      if (item.id == selectedItem && session!.state[item.field] == 1) {
        return item;
      }
    }
    return null;
  }

  void toggleInventory() {
    inventoryOpen = !inventoryOpen;
    running = false;
    unawaited(audio.effect('inventory'));
    notifyListeners();
  }

  void selectItem(String id) {
    if (paused) return;
    for (final item in inventory) {
      if (item.id == id && session!.state[item.field] == 1) selectedItem = id;
    }
    notifyListeners();
  }

  void combineItems(String otherId) {
    final room = session?.definition.room;
    if (room == null || heldItem == null || otherId == selectedItem) return;
    final pair = room.items.take(2).map((i) => i.id).toSet();
    if (room.combine && pair.contains(selectedItem) && pair.contains(otherId)) {
      act(const PuzzleAction('ACT_COMBINE'));
      selectedItem = room.repairItem;
    } else {
      message = 'Hai món này không có chỗ khớp với nhau.';
      unawaited(audio.effect('fail'));
    }
    notifyListeners();
  }

  void useSelectedItem(String hotspotId) {
    if (paused || session == null) return;
    if (hotspotId != 'repair' ||
        heldItem?.id != session!.definition.room?.repairItem) {
      message =
          'Món này không vừa chỗ đó. Hãy nhìn kỹ đầu nối và chỗ còn thiếu.';
      unawaited(audio.effect('fail'));
      notifyListeners();
      return;
    }
    act(const PuzzleAction('ACT_REPAIR'));
    if (session!.state['repairReady'] == 1) {
      selectedItem = null;
      inventoryOpen = false;
    }
    notifyListeners();
  }

  String? get tutorial {
    final s = session;
    if (s == null) return null;
    final tag = s.state['repairReady'] == 0
        ? 'room'
        : 'machine_${s.definition.number}';
    if (store.tutorials.contains('tutorial_$tag')) return null;
    return s.state['repairReady'] == 0
        ? 'Chạm đồ vật để quan sát. Mở Túi đồ để chọn đồ vừa tìm được, rồi chạm nơi cần sửa.'
        : s.definition.tutorial;
  }

  void dismissTutorial() {
    if (session == null) return;
    store.tutorials.add(
      'tutorial_${session!.state['repairReady'] == 0 ? 'room' : 'machine_${session!.definition.number}'}',
    );
    _save();
    notifyListeners();
  }

  void navigate(AppPage next) {
    unawaited(audio.effect('transition'));
    page = next;
    running = false;
    paused = false;
    notifyListeners();
  }

  void start(int index, {bool resume = false}) {
    final l = levels[index];
    if (!isUnlocked(l.number)) return;
    sceneSerial++;
    selectedItem = null;
    inventoryOpen = false;
    final restored = resume ? store.restore(l) : null;
    session = PuzzleSession(l, resume: restored);
    if (restored != null) {
      session!.hintsUsed = store.resume?['hints'] as int? ?? 0;
      session!.undoCount = store.resume?['undo'] as int? ?? 0;
    }
    zoom = false;
    machineFocus = -1;
    paused = false;
    running = false;
    showResult = false;
    message = l.goal;
    latestEvents = [];
    revision++;
    page = AppPage.play;
    selectedChapter = l.chapter;
    unawaited(audio.chapter(l.chapter));
    _save();
    notifyListeners();
  }

  void continueGame() {
    final id = store.resume?['level'];
    final index = levels.indexWhere((l) => l.id == id);
    start(index < 0 ? store.unlocked - 1 : index, resume: index >= 0);
  }

  void act(PuzzleAction action) {
    if (session == null || paused || showResult) return;
    final result = session!.act(action);
    latestEvents = result.events;
    revision++;
    if (result.events.isNotEmpty) {
      message = result.events.last.message;
      for (final sound in result.events.map((e) => e.sound).toSet().take(3)) {
        unawaited(audio.effect(sound));
      }
    }
    if (!result.accepted || result.events.any((e) => e.kind == 'failure')) {
      running = false;
    }
    if (session!.state.won) {
      running = false;
      unawaited(
        store.complete(
          session!.definition,
          session!.stars,
          session!.state.moves,
        ),
      );
    } else {
      _save();
    }
    notifyListeners();
  }

  void inspect() {
    act(PuzzleAction.inspect);
    message = 'Bạn đã đọc lời nhắn của người thợ. Hãy nhìn quanh phòng để tìm dấu vết và bộ phận còn thiếu.';
    store.tutorials.add(session!.definition.id);
    _save();
  }

  void setZoom(bool value) {
    zoom = value;
    inventoryOpen = false;
    if (!value) machineFocus = -1;
    running = false;
    notifyListeners();
  }

  void cycleFocus() {
    machineFocus = machineFocus == 2 ? -1 : machineFocus + 1;
    running = false;
    notifyListeners();
  }

  void undo() {
    if (session == null || paused) return;
    running = false;
    session!.undo();
    latestEvents = [
      const GameEvent('undo', 'Đã hoàn tác cơ cấu.', sound: 'metal'),
    ];
    message = 'Đã hoàn tác cơ cấu.';
    revision++;
    _save();
    notifyListeners();
  }

  void reset() {
    session!.reset();
    selectedItem = null;
    inventoryOpen = false;
    running = false;
    showResult = false;
    zoom = false;
    machineFocus = -1;
    latestEvents = [];
    message = session!.definition.goal;
    revision++;
    _save();
    notifyListeners();
  }

  String hint() {
    running = false;
    final h = session!.hint();
    _save();
    notifyListeners();
    return h;
  }

  void toggleRun() {
    if (session?.definition.control('ACT_STEP') == null ||
        paused ||
        session!.state.won) {
      return;
    }
    running = !running;
    notifyListeners();
  }

  void pause() {
    paused = true;
    running = false;
    unawaited(audio.pause());
    _save();
    notifyListeners();
  }

  void resume() {
    paused = false;
    unawaited(audio.resume());
    notifyListeners();
  }

  void resultReady() {
    if (session?.state.won == true) {
      showResult = true;
      unawaited(audio.effect('door'));
      notifyListeners();
    }
  }

  Future<void> saveNow() => session == null || session!.state.won
      ? store.save()
      : store.saveSession(
          session!.definition,
          session!.state,
          session!.hintsUsed,
          session!.undoCount,
        );
  void _save() {
    unawaited(saveNow());
  }

  void settingsChanged() {
    unawaited(audio.configure(store.settings));
    unawaited(store.save());
    notifyListeners();
  }
}
