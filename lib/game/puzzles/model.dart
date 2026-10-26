import 'dart:convert';

typedef Json = Map<String, Object?>;

Json object(Object? value) => Map<String, Object?>.from(value! as Map);
List<Object?> array(Object? value) => List<Object?>.from(value as List? ?? []);

/// Small deterministic integer expression language used by level data.
/// No Flutter, wall clock, random generator or executable strings.
int evaluate(Object? expression, Map<String, int> state) {
  if (expression is num) return expression.toInt();
  if (expression is bool) return expression ? 1 : 0;
  if (expression is String) {
    if (!expression.startsWith(r'$')) {
      throw FormatException('Expected field: $expression');
    }
    final key = expression.substring(1);
    if (!state.containsKey(key)) {
      throw FormatException('Unknown state field: $key');
    }
    return state[key]!;
  }
  final terms = array(expression);
  if (terms.isEmpty) throw const FormatException('Empty expression');
  final op = terms.first as String;
  final v = terms.skip(1).map((e) => evaluate(e, state)).toList();
  switch (op) {
    case '+':
      return v.reduce((a, b) => a + b);
    case '-':
      return v[0] - v[1];
    case '*':
      return v.reduce((a, b) => a * b);
    case '~/':
      return v[0] ~/ v[1];
    case '%':
      return v[0] % v[1];
    case '&':
      return v[0] & v[1];
    case '==':
      return v[0] == v[1] ? 1 : 0;
    case '!=':
      return v[0] != v[1] ? 1 : 0;
    case '>=':
      return v[0] >= v[1] ? 1 : 0;
    case '<=':
      return v[0] <= v[1] ? 1 : 0;
    case '>':
      return v[0] > v[1] ? 1 : 0;
    case '<':
      return v[0] < v[1] ? 1 : 0;
    case 'all':
      return v.every((x) => x != 0) ? 1 : 0;
    case 'any':
      return v.any((x) => x != 0) ? 1 : 0;
    case 'min':
      return v.reduce((a, b) => a < b ? a : b);
    case 'max':
      return v.reduce((a, b) => a > b ? a : b);
    case 'if':
      return v[0] != 0 ? v[1] : v[2];
    default:
      throw FormatException('Unknown expression operator $op');
  }
}

class PuzzleAction {
  const PuzzleAction(this.id);
  final String id;
  static const inspect = PuzzleAction('ACT_INSPECT');
  static const tick = PuzzleAction('ACT_STEP');
}

class ControlDefinition {
  ControlDefinition.fromJson(Json j)
    : id = j['id']! as String,
      label = j['label']! as String,
      kind = j['kind']! as String,
      field = j['field'] as String?,
      x = (j['x']! as num).toDouble(),
      y = (j['y']! as num).toDouble(),
      guard = j['guard'] ?? 1,
      reason = j['reason'] as String? ?? 'Cơ cấu chưa sẵn sàng.',
      effects = array(j['effects']).map(object).toList(),
      options = array(j['options']).cast<String>(),
      sound = j['sound'] as String? ?? 'switch',
      help = j['help'] as String? ?? '',
      feedback = j['feedback'] as String? ?? '',
      group = j['group'] as int? ?? 0;
  final String id, label, kind, reason, sound, help, feedback;
  bool get isRoomAction => kind.startsWith('room_');
  final String? field;
  final double x, y;
  final int group;
  final Object guard;
  final List<Json> effects;
  final List<String> options;
  String valueLabel(PuzzleState s) {
    if (kind == 'button' || kind.startsWith('room_') && options.isEmpty) {
      return '';
    }
    if (field == 'powered' && options.isEmpty) {
      return s['powered'] == 1 ? 'Đang chạy' : 'Đã dừng';
    }
    if (options.isEmpty && (field == 'locked' || field == 'latch')) {
      return s[field!] == 1 ? 'Đã giữ' : 'Chưa giữ';
    }
    if (options.isEmpty && field == 'door') {
      return s['door'] == 1 ? 'Đã mở' : 'Đang khóa';
    }
    final v = field == null ? 0 : s[field!];
    return options.isEmpty
        ? (field == null ? '' : '$v')
        : options[v % options.length];
  }
}

class Objective {
  const Objective(this.label, this.condition);
  final String label;
  final Object condition;
  bool met(PuzzleState state) => evaluate(condition, state.values) != 0;
}

class PuzzleDefinition {
  PuzzleDefinition.fromJson(Json j)
    : id = j['id']! as String,
      number = j['number']! as int,
      chapter = j['chapter']! as int,
      title = j['title']! as String,
      goal = j['goal']! as String,
      note = j['note']! as String,
      story = j['story']! as String,
      tutorial = j['tutorial'] as String? ?? '',
      completion = j['completion'] as String? ?? 'Cánh cửa đã mở.',
      room = j['room'] == null
          ? null
          : RoomDefinition.fromJson(object(j['room'])),
      rule = j['introduced_rule']! as String,
      hints = array(j['hints']).cast<String>(),
      initial = Map<String, int>.from(j['initial']! as Map),
      controls = array(j['controls'])
          .map((e) => ControlDefinition.fromJson(object(e)))
          .toList(),
      objectives = array(j['objectives']).map((e) {
        final o = object(e);
        return Objective(o['label']! as String, o['condition']!);
      }).toList(),
      derived = object(j['derived'] ?? <String, Object?>{}),
      constraints = array(j['constraints']).map(object).toList(),
      optics = j['optics'] == null ? null : object(j['optics']),
      mechanical = j['mechanical'] == null ? null : object(j['mechanical']),
      gauges = array(j['gauges']).map(object).toList(),
      solution = array(j['solution']).cast<String>(),
      wrongTrace = array(j['wrong_trace']).cast<String>(),
      targetMoves = j['target_moves']! as int,
      massFields = array(j['mass_fields']).cast<String>(),
      inferences = array(j['required_inferences']).cast<String>();
  final String id, title, goal, note, story, rule, tutorial, completion;
  final RoomDefinition? room;
  final int number, chapter, targetMoves;
  final List<String> hints, solution, wrongTrace, massFields, inferences;
  final Map<String, int> initial;
  final List<ControlDefinition> controls;
  final List<Objective> objectives;
  final Json derived;
  final List<Json> constraints, gauges;
  final Json? optics;
  final Json? mechanical;
  String get biome => ['brass', 'water', 'prism', 'core'][chapter];
  String get background => 'assets/images/chapters/$biome/room.png';
  ControlDefinition? control(String id) {
    for (final c in controls) {
      if (c.id == id) return c;
    }
    return null;
  }

  static List<PuzzleDefinition> decode(String source) {
    final root = object(jsonDecode(source));
    final levels = array(root['levels'])
        .map((e) => PuzzleDefinition.fromJson(object(e)))
        .toList();
    if (levels.length != 12) {
      throw const FormatException('Expected twelve levels');
    }
    final ids = <String>{};
    for (var i = 0; i < levels.length; i++) {
      final l = levels[i];
      if (!ids.add(l.id) ||
          l.number != i + 1 ||
          l.chapter != i ~/ 3 ||
          l.hints.length != 3 ||
          l.solution.isEmpty ||
          l.wrongTrace.isEmpty ||
          l.objectives.isEmpty) {
        throw FormatException('Invalid level contract ${l.id}');
      }
      final actions = l.controls.map((c) => c.id).toSet();
      if (actions.length != l.controls.length) {
        throw FormatException('Duplicate action ${l.id}');
      }
      for (final a in [...l.solution, ...l.wrongTrace]) {
        if (a != 'ACT_INSPECT' && !actions.contains(a)) {
          throw FormatException('Missing action $a');
        }
      }
      for (final c in l.controls) {
        if (c.x < 0 ||
            c.x > 1 ||
            c.y < 0 ||
            c.y > 1 ||
            (c.field != null && !l.initial.containsKey(c.field))) {
          throw FormatException('Invalid device ${c.id}');
        }
        evaluate(c.guard, l.initial);
      }
      for (final o in l.objectives) {
        evaluate(o.condition, l.initial);
      }
      final room = l.room;
      if (room != null) {
        if (room.hotspots.map((h) => h.id).toSet().length !=
                room.hotspots.length ||
            room.items.map((i) => i.id).toSet().length != room.items.length ||
            !room.items.any((i) => i.id == room.repairItem)) {
          throw FormatException('Invalid room ${l.id}');
        }
        for (final h in room.hotspots) {
          if (h.rect.length != 4 ||
              h.rect[0] < 0 ||
              h.rect[1] < 0 ||
              h.rect[0] + h.rect[2] > 1280 ||
              h.rect[1] + h.rect[3] > 720 ||
              (h.action.isNotEmpty &&
                  h.action != 'ACT_INSPECT' &&
                  !actions.contains(h.action))) {
            throw FormatException('Invalid hotspot ${h.id}');
          }
        }
        for (final item in room.items) {
          if (!l.initial.containsKey(item.field)) {
            throw FormatException('Missing item field ${item.id}');
          }
        }
      }
    }
    return List.unmodifiable(levels);
  }
}

class RoomItem {
  RoomItem.fromJson(Json j)
    : id = j['id']! as String,
      field = j['field']! as String,
      name = j['name']! as String,
      image = j['image']! as String,
      description = j['description']! as String;
  final String id, field, name, image, description;
  String get asset => roomAsset(image);
}

String roomAsset(String image) => switch (image) {
  'gear' => 'assets/images/chapters/brass/prop0.png',
  'crystal' => 'assets/images/chapters/prism/prop1.png',
  _ => 'assets/images/exploration/$image.png',
};

class RoomHotspot {
  RoomHotspot.fromJson(Json j)
    : id = j['id']! as String,
      kind = j['kind']! as String,
      title = j['title']! as String,
      text = j['text']! as String,
      image = j['image']! as String,
      action = j['action'] as String? ?? '',
      rect = array(j['rect']).map((v) => (v as num).toDouble()).toList();
  final String id, kind, title, text, image, action;
  final List<double> rect;
  bool contains(double x, double y) =>
      x >= rect[0] &&
      x <= rect[0] + rect[2] &&
      y >= rect[1] &&
      y <= rect[1] + rect[3];
}

class RoomDefinition {
  RoomDefinition.fromJson(Json j)
    : items = array(j['items'])
          .map((e) => RoomItem.fromJson(object(e)))
          .toList(),
      hotspots = array(j['hotspots'])
          .map((e) => RoomHotspot.fromJson(object(e)))
          .toList(),
      solution = array(j['solution']).cast<String>(),
      combine = j['combine'] as bool,
      locked = j['locked'] as bool,
      repairItem = j['repairItem']! as String,
      repairTitle = j['repairTitle']! as String;
  final List<RoomItem> items;
  final List<RoomHotspot> hotspots;
  final List<String> solution;
  final bool combine, locked;
  final String repairItem, repairTitle;
}

class BeamSegment {
  const BeamSegment(this.x1, this.y1, this.x2, this.y2, this.color, this.power);
  final int x1, y1, x2, y2, color, power;
}

class GameEvent {
  const GameEvent(
    this.kind,
    this.message, {
    this.target = '',
    this.sound = 'click',
  });
  final String kind, message, target, sound;
}

class PuzzleState {
  PuzzleState({
    required Map<String, int> values,
    this.moves = 0,
    this.errors = 0,
    this.ticks = 0,
    this.won = false,
    List<BeamSegment> beams = const [],
  }) : values = Map.unmodifiable(values),
       beams = List.unmodifiable(beams);
  final Map<String, int> values;
  final int moves, errors, ticks;
  final bool won;
  final List<BeamSegment> beams;
  int operator [](String key) => values[key] ?? 0;
  PuzzleState copy({
    Map<String, int>? values,
    int? moves,
    int? errors,
    int? ticks,
    bool? won,
    List<BeamSegment>? beams,
  }) => PuzzleState(
    values: values ?? this.values,
    moves: moves ?? this.moves,
    errors: errors ?? this.errors,
    ticks: ticks ?? this.ticks,
    won: won ?? this.won,
    beams: beams ?? this.beams,
  );
  Json toJson() => {
    'values': values,
    'moves': moves,
    'errors': errors,
    'ticks': ticks,
  };
}

class ValidationResult {
  const ValidationResult(this.state, this.events, {this.accepted = true});
  final PuzzleState state;
  final List<GameEvent> events;
  final bool accepted;
}

class UndoSnapshot {
  const UndoSnapshot(this.state);
  final PuzzleState state;
}
