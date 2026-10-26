> **Thông tin bàn giao:** Kế hoạch sản xuất lịch sử, không phải danh sách tính năng đã hoàn thành. Tính năng và kết quả hiện hành: [README](../README.md) và [RELEASE_HANDOVER](RELEASE_HANDOVER.md).

# Mechanica — production run

Target: Flutter 3.47.7 / Dart 3.13.5, Flame, Android landscape, offline.
Environment: Android SDK 36/37, emulator-5554 available. Windows desktop compiler absent; not required.

1. Canonical JSON level definitions and pure Dart deterministic reducer with bounded optical rays, integer fluid transfers, mechanical and reactor constraints.
2. Four illustrated room environments, independent transparent device art, runtime props, Vietnamese custom interface.
3. Twelve authored levels with exploration, machine view, undo, three hints, solutions, failure and recovery.
4. Local versioned progress/resume, generated original ambient audio and SFX, lifecycle and settings.
5. Domain/solution/widget/integration verification, Android APK, emulator screenshots, honest gate report.

Risks: generated art availability/alpha; Android toolchain/network dependencies; screen space on short landscape phones; audio lifecycle; final visual quality requires screenshots. No gate is passed before evidence.

Source of truth: assets/data/levels.json. References are never packaged. Flutter owns navigation; Flame owns rendered room/machine, input mapping and animation; domain owns all rules and victory.
