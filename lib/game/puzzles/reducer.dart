import '../mechanics/optics.dart';
import '../mechanics/gears.dart';
import 'model.dart';
import 'guidance.dart';

class PuzzleReducer {
  const PuzzleReducer(this.definition);
  final PuzzleDefinition definition;

  PuzzleState initial() => refresh(PuzzleState(values: definition.initial));

  PuzzleState refresh(PuzzleState s) {
    final v = Map<String, int>.of(s.values);
    if (definition.mechanical != null) {
      final graph = definition.mechanical!;
      final result = GearNetwork.solve(graph, v);
      final output = result.motion[graph['output']];
      v['ratio'] = output == null ? 0 : output.numerator ~/ output.denominator;
      v['ratioNumerator'] = output?.numerator ?? 0;
      v['ratioDenominator'] = output?.denominator ?? 1;
      v['direction'] = output?.direction ?? 0;
      v['networkJam'] = result.jammed ? 1 : 0;
    }
    for (final e in definition.derived.entries) {
      v[e.key] = evaluate(e.value, v);
    }
    var beams = <BeamSegment>[];
    if (definition.optics != null) {
      final result = OpticalSystem.trace(definition.optics!, v);
      v.addAll(result.sensors);
      v['optical_fault'] = result.overloaded ? 1 : 0;
      beams = result.beams;
    }
    final candidate = s.copy(values: v, beams: beams, won: false);
    return candidate.copy(
      won:
          candidate['inspected'] == 1 &&
          definition.objectives.every((o) => o.met(candidate)),
    );
  }

  ValidationResult apply(PuzzleState before, PuzzleAction action) {
    if (before.won) return ValidationResult(before, const [], accepted: false);
    if (action.id == 'ACT_INSPECT') {
      if (before['inspected'] == 1) {
        return ValidationResult(before, const [], accepted: false);
      }
      return ValidationResult(
        refresh(before.copy(values: {...before.values, 'inspected': 1})),
        [GameEvent('discover', definition.note, sound: 'click')],
      );
    }
    final control = definition.control(action.id);
    if (control == null) return _reject(before, 'Thao tác không tồn tại.');
    if (before['inspected'] == 0 && !control.isRoomAction) {
      return _reject(
        before,
        'Hãy đọc trang ghi chép bên trái căn phòng trước khi vận hành.',
      );
    }
    if (!control.isRoomAction &&
        definition.room != null &&
        before['repairReady'] == 0) {
      return _reject(
        before,
        'Máy còn một chỗ hỏng. Hãy quay lại phòng, tìm bộ phận thay thế và lắp vào đúng ổ.',
      );
    }
    if (evaluate(control.guard, before.values) == 0) {
      return _reject(before, control.reason);
    }
    final values = Map<String, int>.of(before.values);
    final events = <GameEvent>[];
    try {
      _effects(control.effects, values, events);
    } on StateError catch (e) {
      return _reject(before, e.message);
    }
    var next = refresh(
      before.copy(
        values: values,
        moves: before.moves + 1,
        ticks: before.ticks + (action.id == 'ACT_STEP' ? 1 : 0),
      ),
    );
    for (final constraint in definition.constraints) {
      if (evaluate(constraint['when'], next.values) != 0) {
        final recovered = Map<String, int>.of(next.values);
        _effects(
          array(constraint['effects']).map(object).toList(),
          recovered,
          events,
        );
        events.add(
          GameEvent(
            'failure',
            constraint['message']! as String,
            sound: recovered['jam'] == 1 ? 'jam' : 'fail',
          ),
        );
        next = refresh(next.copy(values: recovered, errors: next.errors + 1));
      }
    }
    // Transfers must conserve declared mass, including explicit drain reservoirs.
    if (definition.massFields.isNotEmpty) {
      final total = definition.massFields.fold(
        0,
        (int sum, k) => sum + next[k],
      );
      final original = definition.massFields.fold(
        0,
        (int sum, k) => sum + definition.initial[k]!,
      );
      if (total != original || definition.massFields.any((k) => next[k] < 0)) {
        throw StateError('Fluid invariant violated in ${definition.id}');
      }
    }
    if (events.isEmpty) {
      events.add(
        GameEvent(
          control.kind,
          control.feedback.isEmpty
              ? '${control.label} · ${control.valueLabel(next)}'
              : control.feedback,
          target: control.id,
          sound: control.sound,
        ),
      );
    }
    if (next.won) {
      events.add(GameEvent('victory', definition.completion, sound: 'win'));
    }
    if (before['powered'] != next['powered']) {
      events.insert(
        0,
        GameEvent(
          next['powered'] == 1 ? 'motor_start' : 'motor_stop',
          next['powered'] == 1
              ? 'Bộ máy bắt đầu chuyển động.'
              : 'Bộ máy đã dừng lại.',
          sound: next['powered'] == 1 ? 'motor_start' : 'motor_stop',
        ),
      );
    }
    return ValidationResult(next, events);
  }

  ValidationResult _reject(PuzzleState s, String reason) => ValidationResult(
    s.copy(errors: s.errors + 1),
    [GameEvent('rejected', reason, sound: 'fail')],
    accepted: false,
  );

  void _effects(
    List<Json> effects,
    Map<String, int> v,
    List<GameEvent> events,
  ) {
    for (final effect in effects) {
      if (effect.containsKey('set')) {
        // Simultaneous assignment inside a set; successive effects are sequential.
        final writes = <String, int>{};
        for (final e in object(effect['set']).entries) {
          writes[e.key] = evaluate(e.value, v);
        }
        v.addAll(writes);
      } else if (effect.containsKey('if')) {
        final branch = evaluate(effect['if'], v) != 0
            ? effect['then']
            : effect['else'];
        _effects(array(branch).map(object).toList(), v, events);
      } else if (effect.containsKey('transfer')) {
        final t = object(effect['transfer']);
        final from = t['from']! as String, to = t['to']! as String;
        final amount = evaluate(t['amount'] ?? 1, v);
        final cap = evaluate(t['capacity'], v);
        if (amount <= 0 || v[from]! < amount) {
          throw StateError('Nguồn không đủ nước cho một nhịp bơm.');
        }
        if (v[to]! + amount > cap) {
          throw StateError('Bể nhận đã đầy. Đổi tuyến hoặc rút nước.');
        }
        final dirty = t['dirty_from'] as String?;
        final dirtyTo = t['dirty_to'] as String?;
        var polluted = dirty != null && v[dirty] != 0;
        if (polluted && t['filter'] != null && v[t['filter']] != 0) {
          final charge = t['charge']! as String;
          if (v[charge]! < amount) {
            throw StateError(
              'Màng lọc đã cạn. Hoàn tác để giữ lại tài nguyên.',
            );
          }
          v[charge] = v[charge]! - amount;
          polluted = false;
        }
        v[from] = v[from]! - amount;
        v[to] = v[to]! + amount;
        if (dirtyTo != null && polluted) v[dirtyTo] = 1;
        v['flow'] = 1;
        events.add(
          GameEvent(
            'flow',
            'Đã chuyển $amount đơn vị nước.',
            target: to,
            sound: 'water',
          ),
        );
      } else if (effect.containsKey('message')) {
        events.add(
          GameEvent(
            effect['kind'] as String? ?? 'mechanism',
            effect['message']! as String,
            sound: effect['sound'] as String? ?? 'switch',
          ),
        );
      } else {
        throw const FormatException('Unknown effect');
      }
    }
  }
}

class PuzzleSession {
  PuzzleSession(this.definition, {PuzzleState? resume})
    : reducer = PuzzleReducer(definition) {
    state = resume == null ? reducer.initial() : reducer.refresh(resume);
  }
  final PuzzleDefinition definition;
  final PuzzleReducer reducer;
  late PuzzleState state;
  final List<UndoSnapshot> history = [];
  final List<GameEvent> eventLog = [];
  int hintsUsed = 0, undoCount = 0;
  bool tutorialPractice = false;
  ValidationResult act(PuzzleAction action) {
    final result = reducer.apply(state, action);
    if (result.accepted && action.id != 'ACT_INSPECT') {
      history.add(UndoSnapshot(state));
      if (history.length > 100) history.removeAt(0);
    }
    state = result.state;
    eventLog.addAll(result.events);
    if (eventLog.length > 80) eventLog.removeRange(0, eventLog.length - 80);
    return result;
  }

  void undo() {
    if (history.isEmpty || state.won) return;
    final previous = history.removeLast().state;
    state = reducer.refresh(
      previous.copy(errors: state.errors, moves: state.moves),
    );
    undoCount++;
  }

  void reset() {
    state = reducer.initial();
    history.clear();
    eventLog.clear();
    hintsUsed = 0;
    undoCount = 0;
  }

  String hint() {
    final tier = hintsUsed.clamp(0, 2);
    hintsUsed = (hintsUsed + 1).clamp(0, 3);
    if (state['inspected'] == 0) {
      return 'Chạm trang giấy bên trái căn phòng để đọc lời nhắn người thợ để lại.';
    }
    final room = definition.room;
    if (room != null && state['repairReady'] == 0) {
      if (state['clueFound'] == 0) {
        return 'Tờ giấy ở phía bên phải căn phòng còn chưa được xem. Hãy đến đó; người thợ đã để lại những dấu cần thiết.';
      }
      if (state['itemA'] == 0) {
        if (room.locked &&
            evaluate(definition.control('ACT_SEARCH')!.guard, state.values) ==
                0) {
          return tier == 0
              ? 'Nhìn lại dấu vẽ ở góc giấy và mặt khóa ngăn kéo.'
              : 'Xoay mặt khóa ngăn kéo đến hình được nhắc ở cuối manh mối, rồi thử kéo ngăn.';
        }
        return 'Mở ngăn dụng cụ bên trái và lấy bộ phận còn nằm bên trong.';
      }
      if (room.combine && state['itemB'] == 0) {
        return 'Hộp kính nhỏ dưới máy còn giữ một phần nữa. Chạm hộp để nhặt nó.';
      }
      if (room.combine && state['itemC'] == 0) {
        return 'Mở Túi đồ, chọn một bộ phận rồi chọn bộ phận còn lại. Hai đầu khớp nhau có thể ghép thành một món.';
      }
      return 'Chọn ${room.items.last.name.toLowerCase()} trong Túi đồ, rồi chạm ${room.repairTitle.toLowerCase()} ở bên phải phòng để lắp.';
    }
    if (tier < 2) return definition.hints[tier];
    final help = GuidanceEngine.solve(
      definition,
      state,
      maxStates: 400,
      milliseconds: 12,
    );
    return '${help.instruction} ${help.reason}';
  }

  int get stars => tutorialPractice && definition.number == 1
      ? 3
      : hintsUsed == 0 &&
            state.errors == 0 &&
            undoCount == 0 &&
            state.moves <= definition.targetMoves
      ? 3
      : hintsUsed <= 2 && state.moves <= definition.targetMoves * 2
      ? 2
      : 1;
}
