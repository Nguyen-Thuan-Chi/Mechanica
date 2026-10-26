import '../puzzles/model.dart';

class GearMotion {
  const GearMotion(this.numerator, this.denominator, this.direction);
  final int numerator, denominator, direction;
  GearMotion mesh(int fromTeeth, int toTeeth) {
    final n = numerator * fromTeeth, d = denominator * toTeeth, g = n.gcd(d);
    return GearMotion(n ~/ g, d ~/ g, -direction);
  }

  bool same(GearMotion other) =>
      numerator * other.denominator == other.numerator * denominator &&
      direction == other.direction;
}

class GearNetworkResult {
  const GearNetworkResult(this.motion, this.jammed);
  final Map<String, GearMotion> motion;
  final bool jammed;
}

/// Propagation through actual shaft/mesh edges. Missing gears disconnect a path;
/// each mesh reverses direction and applies an exact rational tooth ratio.
class GearNetwork {
  static GearNetworkResult solve(Json graph, Map<String, int> state) {
    final teeth = <String, int>{};
    for (final n in array(graph['nodes']).map(object)) {
      teeth[n['id']! as String] = evaluate(n['teeth'], state);
    }
    final source = graph['source']! as String;
    if ((teeth[source] ?? 0) <= 0) return const GearNetworkResult({}, false);
    final motion = <String, GearMotion>{
      source: GearMotion(1, 1, evaluate(graph['direction'] ?? 1, state)),
    };
    final queue = <String>[source];
    final edges = array(graph['edges']).map(object).toList();
    var jammed = false;
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final e in edges) {
        final a = e['a']! as String, b = e['b']! as String;
        if (a != current && b != current) continue;
        final next = a == current ? b : a;
        if ((teeth[next] ?? 0) <= 0 ||
            (e['engaged'] != null && evaluate(e['engaged'], state) == 0)) {
          continue;
        }
        final candidate = e['type'] == 'mesh'
            ? motion[current]!.mesh(teeth[current]!, teeth[next]!)
            : motion[current]!;
        if (motion.containsKey(next)) {
          if (!motion[next]!.same(candidate)) jammed = true;
        } else {
          motion[next] = candidate;
          queue.add(next);
        }
      }
    }
    return GearNetworkResult(Map.unmodifiable(motion), jammed);
  }
}
