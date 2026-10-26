import 'dart:math' as math;

enum MotionPhase { idle, starting, running, stopping, blocked, overloaded }

/// Presentation-only inertia. Physical rules never read this clock/velocity.
class DeviceMotion {
  MotionPhase phase = MotionPhase.idle;
  double velocity = 0, angle = 0, shake = 0, elapsed = 0;
  void update(
    double dt, {
    required bool driven,
    required bool jammed,
    required bool overloaded,
    double ratio = 1,
    double direction = 1,
    bool reduced = false,
  }) {
    elapsed += dt;
    final target = driven && !jammed && !overloaded
        ? ratio * direction * 1.4
        : 0.0;
    velocity += (target - velocity) * math.min(1, dt * 6);
    if (velocity.abs() < .01) velocity = 0;
    phase = overloaded
        ? MotionPhase.overloaded
        : jammed
        ? MotionPhase.blocked
        : target == 0
        ? (velocity == 0 ? MotionPhase.idle : MotionPhase.stopping)
        : (velocity - target).abs() < .05
        ? MotionPhase.running
        : MotionPhase.starting;
    if (!reduced) angle += velocity * dt;
    shake = !reduced && (jammed || overloaded)
        ? math.sin(elapsed * 38) * 1.4
        : 0;
  }
}
