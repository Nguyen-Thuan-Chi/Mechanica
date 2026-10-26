> **Thông tin bàn giao:** Báo cáo lịch sử Phase 1. Kết quả hiện hành: [TESTING](TESTING.md) và [RELEASE_HANDOVER](RELEASE_HANDOVER.md).

# Báo cáo QA — 26/10/2026

Phạm vi: Windows host, Flutter 3.47.7 / Dart 3.13.5, Flame 1.38.2, Android emulator `emulator-5554` API 37, màn hình 2400×1080 landscape. Không có thử nghiệm trên điện thoại vật lý. Log nằm trong `docs/evidence/`; các lỗi ở log cũ được giữ làm lịch sử, kết quả cuối được chỉ rõ dưới đây.

## PASS — đã chạy

| Kiểm tra | Lệnh/bằng chứng | Kết quả |
|---|---|---|
| Static analysis | `flutter analyze`, `analyze_final.log` | Không issue |
| Unit/widget | `flutter test`, `unit_final.log` | 56 test pass |
| 12 lời giải | `test/domain_test.dart` | Mỗi màn từ trạng thái mới đến thắng; replay xác định |
| 12 đường sai | Cùng file | Không thắng sai; undo/reset phục hồi |
| 12 trạng thái giữa màn | Cùng file | Serialize/reload rồi giải tiếp |
| Ràng buộc engine | domain + mechanics tests | Bảo toàn nước, lọc hữu hạn, quá nhiệt, vòng tia hữu hạn, hướng/màu mắt, tỷ số bánh răng, mesh loop jam, mất đồng bộ lõi |
| Lưu tiến trình | `persistence_test.dart` | Ghi tuần tự, giữ điểm tốt nhất, settings, backup JSON lỗi, primary lỗi không làm bẩn backup, từ chối thể tích vô lý |
| UI co giãn | `ui_test.dart` | Menu/settings/chapter/level ở 960×540 và 1170×540; không exception layout |
| Thiếu asset | `asset_failure_test.dart` | Cố tình tải phòng không tồn tại; thông báo Việt, không exception thoát ra |
| Android chơi xuyên 12 màn | `flutter drive --driver=test_driver/integration_driver.dart --target=integration_test/playthrough_test.dart -d emulator-5554`, `integration_final.log` | PASS, khoảng 3 phút 38 giây. Chạm đúng device, đối chiếu state sau mỗi thao tác, mở khóa đến 12, xem ending và trở lại home |
| Android thao tác | Cùng integration | Kéo bánh vào chốt, double tap debounce, pause/resume, Back thoát zoom, xác nhận reset, 3 cấp hint, 4 góc máy cuối |
| Asset thật | `python tools/verify_assets.py`, `asset_integrity.json` | 58 mục có hash; 38 PNG; 4 WAV ambient + 11 WAV SFX; font/license; 12 thumbnail; reference không đóng gói |
| Art review trực quan | `android_home.png`, `android_lv01…12.png`, `android_ending.png`, `runtime_contact_sheet.jpg` | Đã xem 4 chương, sửa chồng nhãn; các chương khác màu, vật liệu, máy và bố cục |

Integration driver báo `+2` gồm test và teardown; đây là **một kịch bản xuyên 12 màn**, không phải tuyên bố hai test gameplay độc lập. Thao tác giải dùng touch thật qua GameWidget, không gọi trực tiếp reducer để thắng; reducer chỉ cung cấp kết quả đối chiếu.

## Audio và lifecycle — PASS

`flutter drive --driver=test_driver/integration_driver.dart --target=integration_test/audio_lifecycle_test.dart -d emulator-5554` đã PASS (`audio_lifecycle.log`, một kịch bản, khoảng 4 giây ngoài build/khởi động). Kiểm tra native player đang phát và vị trí nhạc tăng sau hai SFX, mute về volume 0, lifecycle paused dừng nhạc/máy, lưu state, resumed vẫn đòi người chơi bấm tiếp tục, nhạc phát lại và không lỗi audio. Lifecycle được phát bằng test binding; smoke Home/launch Android thật được báo riêng khi hoàn tất.

## Đóng gói

**BUILD_GATE: PASS.** APK cuối dùng `lib/main.dart`, không phải entrypoint integration.

| Lệnh | Kết quả / evidence |
|---|---|
| `flutter build apk --debug -t lib/main.dart` | PASS, `build_debug.log`, 23,2 giây |
| `flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64 -t lib/main.dart` | PASS, `build_release.log`, 88,1 giây |
| `adb install -r …/app-debug.apk` và `am start -W …/.MainActivity` | Success; menu và phòng hiển thị, `android_install_debug.log`, `debug_apk_home.png` |
| Android Home → mở lại | Máy ở màn tạm dừng, `debug_apk_background_resume.png` |
| Force-stop → launch lại | Home có Chơi tiếp; save native giữ inspected=1, `native_save_before_restart.xml`, `debug_apk_restart_home.png` |
| Cài/launch APK x86_64 release | Success; Chơi tiếp khôi phục phòng có bản khắc đã đọc, `release_apk_home.png`, `release_apk_resume_room.png` |
| `python tools/verify_apks.py` | PASS: 58 asset trong cả 3 APK khớp hash nguồn cuối; reference không nằm trong APK |

Kích thước/hash chính xác trong `build_artifacts.json` và `apk_integrity.json`: debug 223.436.617 byte; ARM64 release 48.209.758 byte (45,98 MiB); x86_64 release 49.627.994 byte (47,33 MiB). Min SDK 24, target SDK 36. Bản release vẫn ký debug. Playthrough đầy đủ chạy ở debug; bản release đã smoke menu/resume/phòng, chưa chạy lại toàn bộ 12 màn và chưa cài ARM64 trên máy thật.

## FAIL hiện tại

Chưa có assertion thất bại còn mở trong bộ test đã chạy. **Phát hành store: FAIL/BLOCKED**, vì chưa có khóa ký riêng/cấu hình phát hành cửa hàng. Các hạng mục chưa chạy nằm bên dưới, không được tính PASS.

## Lỗi đã sửa

| Mức độ | Lỗi | Xác minh sau sửa |
|---|---|---|
| BLOCKER | Gradient ba màu thiếu stops gây assert render | Android full playthrough pass |
| MAJOR | Vùng chạm gương gần nhau nhận hai thao tác | Hit test tròn; full playthrough LV08 pass, so state từng touch |
| MAJOR | Future tải ảnh lỗi của cache phát exception thứ hai | Decode trước khi cache; missing-asset test pass |
| MAJOR | Dữ liệu primary lỗi có thể để lại field trước khi restore backup | Parse rồi commit nguyên khối; regression test pass |
| MINOR | Nhãn van/chốt chồng lên bình hoặc trạng thái hai dòng | Chuyển nhãn xuống, tăng rộng nameplate; screenshot cuối đã xem |
| MINOR | Hàm drag test dùng tham số API không tồn tại | Chuyển timedDragFrom; drag Android pass |

## NOT RUN / giới hạn còn lại

- **MAJOR — PERFORMANCE_GATE: NOT RUN** cho chuẩn 60fps, tiêu thụ pin và memory profiling dài hạn. Particle/text/audio caches có giới hạn, texture phòng cũ được giải phóng. Log debug khi chụp screenshot có skipped frames; không coi đó là đo FPS release, cũng không tuyên bố đạt 60fps.
- **MAJOR — playtest độ khó:** trace chứng minh giải được, không chứng minh lời giải tối ưu hay độ khó hấp dẫn cho người mới. Chưa có nhóm người chơi độc lập hoặc thống kê thời lượng chơi.
- **MAJOR — thiết bị:** chưa kiểm thử điện thoại vật lý, GPU/Android đời cũ, tablet, font scale lớn, TalkBack. Cơ cấu Flame không có semantics đầy đủ.
- **MINOR — art:** 4 tranh phòng được tái dùng trong từng chương với 12 bố cục máy khác nhau; không có 12 tranh phòng riêng. Chốt, đồng hồ, ray và nước là đồ họa lập trình ghép với sprite minh họa; không phải mọi bộ phận đều là sprite vẽ riêng. Số răng trong sprite mang tính minh họa; luật tỷ số dùng số răng dữ liệu.
- **MINOR — sound:** file/trigger native được kiểm tra; chưa thẩm định chất lượng nghe, nối vòng hoặc cân bằng âm trên nhiều loa/tai nghe.
- **MINOR — exploration:** khám phá dựa vào bản khắc và góc nhìn máy, chưa có hệ inventory/vật phẩm ẩn nhiều lớp. Đoạn kết là tranh có cửa mở và hạt sáng, không phải phim hoạt hình nhân vật.
- **MINOR — reset animation:** reset giữa chuyển động được hỗ trợ; chưa có kịch bản Android riêng bấm reset đúng giữa animation cửa thắng.
- **BLOCKER cho phát hành store:** chưa có khóa ký phát hành riêng hoặc upload Google Play. APK release nếu build sử dụng khóa debug để cài thử; không gọi là bản store-ready.

## Gates

ENGINE và LEVELS: PASS theo các test nêu trên. UI: PASS trong kích thước/thiết bị đã thử, không bao quát accessibility. ART: PASS cho 4 biome, 12 composition, sprite alpha, provenance và screenshot runtime; mức hoàn thiện hình ảnh thương mại chưa được thẩm định độc lập. SOUND: PASS chức năng/file/native lifecycle; chất lượng nghe độc lập NOT RUN. BUILD: PASS. PERFORMANCE: NOT RUN profiling. **Không tuyên bố đã đạt toàn bộ nghiệm thu sản phẩm thương mại** khi các mục chưa đo/chưa thử vẫn còn.
