import '../puzzles/model.dart';

class OpticalResult {
  const OpticalResult(this.beams, this.sensors, this.overloaded);
  final List<BeamSegment> beams;
  final Map<String, int> sensors;
  final bool overloaded;
}

/// Grid rays: east, south, west, north. Mirror 0 = /, mirror 1 = \.
/// Every ray tracks cell, heading, colour and intensity. Visited states and
/// a global 512-segment bound terminate closed paths and splitter cycles.
class OpticalSystem {
  static OpticalResult trace(Json layout, Map<String, int> state) {
    final nodes = array(layout['nodes']).map(object).toList();
    final sensors = <String, int>{};
    for (final n in nodes) {
      if (n['type'] == 'sensor') sensors[n['field']! as String] = 0;
    }
    final beams = <BeamSegment>[];
    final queue = <({int x, int y, int d, int color, int power})>[];
    for (final e in array(layout['emitters']).map(object)) {
      if (evaluate(e['enabled'] ?? 1, state) != 0) {
        queue.add((
          x: e['x']! as int,
          y: e['y']! as int,
          d: e['direction']! as int,
          color: e['color']! as int,
          power: e['power'] as int? ?? 1,
        ));
      }
    }
    const dx = [1, 0, -1, 0], dy = [0, 1, 0, -1];
    final visited = <String>{};
    var overloaded = false;
    while (queue.isNotEmpty && beams.length < 512) {
      var r = queue.removeLast();
      while (beams.length < 512) {
        if (!visited.add('${r.x},${r.y},${r.d},${r.color},${r.power}')) break;
        final nx = r.x + dx[r.d], ny = r.y + dy[r.d];
        if (nx < 0 ||
            ny < 0 ||
            nx > (layout['width']! as int) ||
            ny > (layout['height']! as int)) {
          break;
        }
        beams.add(BeamSegment(r.x, r.y, nx, ny, r.color, r.power));
        Json? node;
        for (final n in nodes) {
          if (n['x'] == nx &&
              n['y'] == ny &&
              evaluate(n['enabled'] ?? 1, state) != 0) {
            node = n;
            break;
          }
        }
        var direction = r.d, color = r.color, power = r.power;
        var stop = false;
        if (node != null) {
          final n = node;
          switch (n['type']) {
            case 'mirror':
              final orientation = state[n['field']]! % 2;
              direction = (orientation == 0
                  ? [3, 2, 1, 0]
                  : [1, 0, 3, 2])[direction];
            case 'shutter':
              stop = state[n['field']] == 0;
            case 'filter':
              final masks = array(n['masks']).cast<int>();
              color &= masks[state[n['field']]! % masks.length];
              stop = color == 0;
            case 'splitter':
              power = 1;
              for (final d in array(n['directions']).cast<int>()) {
                queue.add((x: nx, y: ny, d: d, color: color, power: power));
              }
              stop = true;
            case 'attenuator':
              power = 1;
            case 'fragile':
              if (power > (n['max_power'] as int? ?? 1)) overloaded = true;
              stop = true;
            case 'sensor':
              if (direction == n['direction'] &&
                  color == n['color'] &&
                  power <= (n['max_power'] as int? ?? 2)) {
                sensors[n['field']! as String] = 1;
              }
              stop = !(n['through'] as bool? ?? false);
            case 'wall':
              stop = true;
          }
        }
        if (stop) break;
        r = (x: nx, y: ny, d: direction, color: color, power: power);
      }
    }
    return OpticalResult(beams, sensors, overloaded);
  }
}
