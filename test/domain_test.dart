import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mechanica/game/puzzles/model.dart';
import 'package:mechanica/game/puzzles/reducer.dart';
import 'package:mechanica/game/mechanics/optics.dart';

void main() {
  final levels = PuzzleDefinition.decode(
    File('assets/data/levels.json').readAsStringSync(),
  );
  group('Canonical level contracts', () {
    test('12 levels, 4 chapters, 3 hints each', () {
      expect(levels.length, 12);
      for (final l in levels) {
        expect(l.hints.length, 3);
        expect(l.inferences.length, greaterThanOrEqualTo(3));
      }
    });
    for (final level in levels) {
      test('${level.id} full reference solution and deterministic replay', () {
        final a = PuzzleSession(level), b = PuzzleSession(level);
        expect(a.state.won, false);
        for (final id in level.solution) {
          final result = a.act(PuzzleAction(id));
          b.act(PuzzleAction(id));
          expect(
            result.accepted,
            true,
            reason:
                '${level.id}: $id ${result.events.map((e) => e.message)} ${a.state.values}',
          );
          expect(a.state.values, b.state.values);
          expect(
            a.state.errors,
            0,
            reason: '${level.id}: $id ${result.events.map((e) => e.message)}',
          );
        }
        expect(a.state.won, true, reason: '${level.id}: ${a.state.values}');
        final end = jsonEncode(a.state.toJson());
        a.act(
          level.controls.isEmpty
              ? PuzzleAction.tick
              : PuzzleAction(level.controls.first.id),
        );
        expect(
          jsonEncode(a.state.toJson()),
          end,
          reason: 'Won states are stable',
        );
      });
      test('${level.id} wrong trace cannot win; reset and undo recover', () {
        final s = PuzzleSession(level);
        for (final a in level.wrongTrace) {
          s.act(PuzzleAction(a));
        }
        expect(s.state.won, false);
        s.reset();
        expect(s.state.values, s.reducer.initial().values);
        s.act(PuzzleAction.inspect);
        final before = s.state.values;
        s.act(PuzzleAction(level.solution[1]));
        s.undo();
        expect(s.state.values, before);
        for (final id in level.solution.skip(1)) {
          s.act(PuzzleAction(id));
        }
        expect(s.state.won, true);
      });
      test('${level.id} resume halfway preserves solution', () {
        final s = PuzzleSession(level);
        final halfway = level.solution.length ~/ 2;
        for (final a in level.solution.take(halfway)) {
          s.act(PuzzleAction(a));
        }
        final serialized = object(jsonDecode(jsonEncode(s.state.toJson())));
        final restored = PuzzleSession(
          level,
          resume: PuzzleState(
            values: Map<String, int>.from(serialized['values']! as Map),
            moves: serialized['moves']! as int,
            ticks: serialized['ticks']! as int,
          ),
        );
        for (final a in level.solution.skip(halfway)) {
          restored.act(PuzzleAction(a));
        }
        expect(restored.state.won, true);
      });
    }
  });
  test('All devices reject input before room inspection', () {
    for (final l in levels) {
      final s = PuzzleSession(l);
      for (final c in l.controls.where((c) => !c.isRoomAction)) {
        expect(s.act(PuzzleAction(c.id)).accepted, false);
      }
      expect(s.state.won, false);
    }
  });
  test('Closed optical loops terminate', () {
    final result = OpticalSystem.trace(
      {
        'width': 4,
        'height': 4,
        'emitters': [
          {'x': 1, 'y': 1, 'direction': 0, 'color': 7},
        ],
        'nodes': [
          {'type': 'mirror', 'x': 3, 'y': 1, 'field': 'a'},
          {'type': 'mirror', 'x': 3, 'y': 3, 'field': 'b'},
          {'type': 'mirror', 'x': 1, 'y': 3, 'field': 'c'},
          {'type': 'mirror', 'x': 1, 'y': 1, 'field': 'd'},
        ],
      },
      {'a': 1, 'b': 0, 'c': 1, 'd': 0},
    );
    expect(result.beams.length, lessThanOrEqualTo(512));
  });
  test('Water conserved on legal and rejected transfers', () {
    for (final l in levels.where((l) => l.massFields.isNotEmpty)) {
      final s = PuzzleSession(l);
      for (final id in l.room!.solution) {
        s.act(PuzzleAction(id));
      }
      final total = l.massFields.fold(0, (sum, k) => sum + s.state[k]);
      for (var i = 0; i < 80; i++) {
        s.act(PuzzleAction(l.controls[i % l.controls.length].id));
        expect(l.massFields.fold(0, (sum, k) => sum + s.state[k]), total);
        for (final k in l.massFields) {
          expect(s.state[k], greaterThanOrEqualTo(0));
        }
      }
    }
  });
  test('Unfiltered water contaminates; filtering consumes finite charges', () {
    final s = PuzzleSession(levels[4]);
    for (final id in levels[4].room!.solution) {
      s.act(PuzzleAction(id));
    }
    s.act(const PuzzleAction('ACT_SOURCE'));
    s.act(PuzzleAction.tick);
    expect(s.state['aDirty'], 1);
    expect(s.state['charge'], 3);
    s.undo();
    s.act(const PuzzleAction('ACT_FILTER'));
    s.act(PuzzleAction.tick);
    expect(s.state['aDirty'], 0);
    expect(s.state['charge'], 2);
  });
  test('Reactor shuts down on excess heat', () {
    final s = PuzzleSession(levels[9]);
    for (final id in levels[9].room!.solution) {
      s.act(PuzzleAction(id));
    }
    s.act(const PuzzleAction('ACT_POWER'));
    s.act(const PuzzleAction('ACT_POWER'));
    s.act(PuzzleAction.tick);
    s.act(PuzzleAction.tick);
    expect(s.state['power'], 0);
    expect(s.state.errors, greaterThan(0));
    expect(s.state.won, false);
  });
  test('Final reactor loses synchronization if optical path is broken', () {
    final l = levels.last, s = PuzzleSession(levels.last);
    for (final id in l.solution.take(l.solution.indexOf('ACT_ARM') + 1)) {
      s.act(PuzzleAction(id));
    }
    expect(s.state['stage'], 2);
    s.act(const PuzzleAction('ACT_SHUTTER'));
    expect(s.state['stage'], 1);
    expect(s.state['stable'], 0);
    expect(s.state.won, false);
  });
  test('Hints only offer trace actions from matching states', () {
    for (final l in levels) {
      final s = PuzzleSession(l);
      expect(s.hint(), isNotEmpty);
      expect(s.hint(), isNotEmpty);
      expect(s.hint(), contains('giấy'));
    }
  });
}
