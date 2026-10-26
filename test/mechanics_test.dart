import 'package:flutter_test/flutter_test.dart';
import 'package:mechanica/game/mechanics/gears.dart';
import 'package:mechanica/game/mechanics/optics.dart';

void main() {
  test('Gear edges enforce ratios, reversal and disconnected paths', () {
    final graph = <String, Object?>{
      'source': 'a',
      'nodes': [
        {'id': 'a', 'teeth': 24},
        {'id': 'b', 'teeth': 12},
        {'id': 'c', 'teeth': r'$installed'},
      ],
      'edges': [
        {'a': 'a', 'b': 'b', 'type': 'mesh'},
        {'a': 'b', 'b': 'c', 'type': 'mesh'},
      ],
    };
    final connected = GearNetwork.solve(graph, {'installed': 12});
    expect(connected.motion['b']!.direction, -1);
    expect(connected.motion['c']!.direction, 1);
    expect(connected.motion['c']!.numerator, 2);
    final disconnected = GearNetwork.solve(graph, {'installed': 0});
    expect(disconnected.motion.containsKey('c'), false);
  });
  test('An odd mesh loop jams instead of inventing inconsistent motion', () {
    final graph = <String, Object?>{
      'source': 'a',
      'nodes': [
        for (final id in ['a', 'b', 'c']) {'id': id, 'teeth': 12},
      ],
      'edges': [
        {'a': 'a', 'b': 'b', 'type': 'mesh'},
        {'a': 'b', 'b': 'c', 'type': 'mesh'},
        {'a': 'c', 'b': 'a', 'type': 'mesh'},
      ],
    };
    expect(GearNetwork.solve(graph, {}).jammed, true);
  });
  test('Sensors reject wrong approach direction and wrong color', () {
    final graph = <String, Object?>{
      'width': 5,
      'height': 3,
      'emitters': [
        {'x': 0, 'y': 1, 'direction': 0, 'color': 1},
      ],
      'nodes': [
        {
          'type': 'sensor',
          'x': 4,
          'y': 1,
          'direction': 3,
          'color': 1,
          'field': 'sensor',
        },
      ],
    };
    expect(OpticalSystem.trace(graph, {}).sensors['sensor'], 0);
    graph['nodes'] = [
      {
        'type': 'sensor',
        'x': 4,
        'y': 1,
        'direction': 0,
        'color': 2,
        'field': 'sensor',
      },
    ];
    expect(OpticalSystem.trace(graph, {}).sensors['sensor'], 0);
    graph['nodes'] = [
      {
        'type': 'sensor',
        'x': 4,
        'y': 1,
        'direction': 0,
        'color': 1,
        'field': 'sensor',
      },
    ];
    expect(OpticalSystem.trace(graph, {}).sensors['sensor'], 1);
  });
}
