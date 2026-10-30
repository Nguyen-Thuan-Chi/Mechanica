import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/audio_service.dart';
import '../core/persistence.dart';
import '../core/cloud_service.dart';
import '../game/puzzles/guidance.dart';
import '../game/puzzles/onboarding.dart';
import '../game/puzzles/model.dart';
import '../game/puzzles/reducer.dart';

enum AppPage { home, chapters, levels, play, ending }

class GameController extends ChangeNotifier {
  GameController(
    this.levels,
    ProgressStore store,
    this.audio, {
    CloudService? cloud,
  }) : _playerStore = store,
       cloud = cloud ?? CloudService() {
    this.cloud.addListener(_cloudChanged);
  }
  final List<PuzzleDefinition> levels;
  final ProgressStore _playerStore;
  final CloudService cloud;
  ProgressStore? _accountStore;
  bool accountBusy = false;
  final Stopwatch playClock = Stopwatch();
  int _priorSeconds = 0;
  String _runId = '';
  bool _guidedReplay = false;
  bool assistanceBusy = false;
  bool _disposed = false;
  Guidance? assistance;
  void _cloudChanged() => notifyListeners();
  ProgressStore get playerStore => _accountStore ?? _playerStore;
  ProgressStore? _developmentStore;
  bool _developer = false, showHotspots = false;
  bool get isDeveloper => kDebugMode && _developer;
  ProgressStore get store => isDeveloper ? _developmentStore! : playerStore;
  bool get onboardingActive =>
      session != null &&
      Onboarding.active(store.tutorials, session!.definition.number);
  Guidance? get currentGuide => onboardingActive
      ? Onboarding.step(
          session!.definition,
          session!.state,
          store.tutorials,
          inventoryOpen: inventoryOpen,
          selected: heldItem != null,
          zoom: zoom,
        )
      : assistance;
  String? get guideTarget => currentGuide?.target;
  void beginOnboarding() {
    store.tutorials.add(Onboarding.intro);
    _save();
    notifyListeners();
  }

  void skipOnboarding() {
    session?.tutorialPractice = false;
    store.tutorials.add(Onboarding.skipped);
    _guidedReplay = false;
    _save();
    unawaited(cloud.checkpoint(store));
    notifyListeners();
  }

  void replayOnboarding() {
    if (session?.definition.number != 1) {
      start(0);
    }
    if (session!.state.won) reset();
    store.tutorials.removeAll([
      Onboarding.skipped,
      Onboarding.completed,
      Onboarding.intro,
    ]);
    _guidedReplay = true;
    session?.tutorialPractice = true;
    _save();
    notifyListeners();
  }

  Future<void> requestAssistance() async {
    if (session == null || assistanceBusy) return;
    assistanceBusy = true;
    running = false;
    notifyListeners();
    final owner = session!;
    final values = owner.state;
    final next = await GuidanceEngine.next(owner.definition, values);
    if (_disposed) return;
    if (session == owner && identical(owner.state, values)) assistance = next;
    assistanceBusy = false;
    notifyListeners();
  }

  void closeAssistance() {
    assistance = null;
    notifyListeners();
  }

  void developerTutorialCompleted() {
    if (!kDebugMode || !isDeveloper) return;
    store.tutorials.add('v3_completed');
    _save();
    notifyListeners();
  }

  Future<void> activateAccount({bool waitForSync = true}) async {
    _guidedReplay = false;
    if (cloud.user == null) return;
    await saveNow();
    if (isDeveloper) await setDeveloper(false);
    _accountStore = ProgressStore(
      _playerStore.preferences,
      uid: cloud.user!.uid,
    )..load();
    session = null;
    running = false;
    playClock.stop();
    page = AppPage.home;
    await audio.configure(store.settings);
    notifyListeners();
    if (waitForSync) {
      await cloud.sync(store);
    } else {
      unawaited(cloud.sync(store));
    }
  }

  Future<void> signOutAccount() async {
    if (accountBusy) return;
    accountBusy = true;
    notifyListeners();
    try {
      await saveNow();
      await cloud.signOut();
      _accountStore = null;
      _developer = false;
      session = null;
      running = false;
      playClock.stop();
      page = AppPage.home;
      await audio.configure(store.settings);
    } finally {
      accountBusy = false;
      notifyListeners();
    }
  }

  bool get guestHasProgress =>
      _playerStore.bestStars.isNotEmpty || _playerStore.resume != null;
  Future<void> importGuest() async {
    final target = _accountStore;
    if (target == null || isDeveloper) return;
    target.unlocked = target.unlocked > _playerStore.unlocked
        ? target.unlocked
        : _playerStore.unlocked;
    for (final e in _playerStore.bestStars.entries) {
      final better = e.value > (target.bestStars[e.key] ?? 0);
      if (better) target.bestStars[e.key] = e.value;
      final moves = _playerStore.bestMoves[e.key] ?? 100000;
      if (moves < (target.bestMoves[e.key] ?? 100000)) {
        target.bestMoves[e.key] = moves;
      }
      await cloud.record(
        target,
        e.key,
        e.value,
        moves,
        _playerStore.bestSeconds[e.key] ?? 86400,
        'import_${cloud.user!.uid}_${e.key}',
      );
    }
    target.resume ??= _playerStore.resume;
    target.tutorials.addAll(_playerStore.tutorials);
    await target.save();
    await cloud.checkpoint(target);
    notifyListeners();
  }

  bool isUnlocked(int number) => isDeveloper || number <= store.unlocked;
  Future<void> setDeveloper(bool enabled) async {
    if (!kDebugMode) return;
    await saveNow();
    assistance = null;
    playClock.stop();
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
    if (s.definition.number == 1) return null;
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
    if (page == AppPage.play) {
      playClock.stop();
      _save();
      unawaited(cloud.checkpoint(store));
    }
    unawaited(audio.effect('transition'));
    page = next;
    running = false;
    paused = false;
    notifyListeners();
  }

  void start(int index, {bool resume = false}) {
    final l = levels[index];
    if (!isUnlocked(l.number)) return;
    if (session != null) {
      _save();
      unawaited(cloud.checkpoint(store));
    }
    sceneSerial++;
    selectedItem = null;
    inventoryOpen = false;
    final restored = resume ? store.restore(l) : null;
    session = PuzzleSession(l, resume: restored);
    assistance = null;
    _runId = cloud.operationId();
    _priorSeconds = restored == null
        ? 0
        : store.resume?['elapsed_seconds'] as int? ?? 0;
    playClock
      ..reset()
      ..start();
    if (l.number == 1 && store.bestStars.containsKey(l.id) && !_guidedReplay) {
      store.tutorials.add(Onboarding.completed);
    }
    session!.tutorialPractice = onboardingActive;
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
    if (!result.accepted && session!.state.won) return;
    final refreshAssistance = assistance != null;
    assistance = null;
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
      playClock.stop();
      if (session!.definition.number == 1 && onboardingActive) {
        store.tutorials.add(Onboarding.completed);
        message = 'Bạn đã sửa thành công cỗ máy đầu tiên! Những căn phòng tiếp theo sẽ cần bạn tự tìm manh mối và vận dụng những gì đã học.';
      }
      final seconds = _priorSeconds + playClock.elapsed.inSeconds;
      final id = session!.definition.id;
      if (seconds < (store.bestSeconds[id] ?? 86400)) {
        store.bestSeconds[id] = seconds;
      }
      running = false;
      unawaited(
        store.complete(
          session!.definition,
          session!.stars,
          session!.state.moves,
        ),
      );
      unawaited(
        cloud.record(
          store,
          id,
          session!.stars,
          session!.state.moves,
          seconds,
          _runId,
        ),
      );
    } else {
      _save();
    }
    notifyListeners();
    if (refreshAssistance && !session!.state.won) {
      unawaited(requestAssistance());
    }
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
    if (assistance != null) unawaited(requestAssistance());
  }

  void reset() {
    session!.reset();
    assistance = null;
    _priorSeconds = 0;
    _runId = cloud.operationId();
    playClock
      ..reset()
      ..start();
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
    playClock.stop();
    paused = true;
    running = false;
    unawaited(audio.pause());
    _save();
    unawaited(cloud.checkpoint(store));
    notifyListeners();
  }

  void resume() {
    playClock.start();
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

  Future<void> saveNow() {
    store.elapsedSeconds = _priorSeconds + playClock.elapsed.inSeconds;
    return session == null || session!.state.won
        ? store.save()
        : store.saveSession(
            session!.definition,
            session!.state,
            session!.hintsUsed,
            session!.undoCount,
          );
  }

  void _save() {
    unawaited(saveNow());
  }

  void settingsChanged() {
    unawaited(audio.configure(store.settings));
    unawaited(store.save());
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    playClock.stop();
    cloud.removeListener(_cloudChanged);
    cloud.dispose();
    super.dispose();
  }
}
