> Báo cáo V3 mới nhất: [V3_REPORT](V3_REPORT.md). Các bảng Phase 2/handover bên dưới giữ lịch sử, không phải số ca V3.

# Kiểm thử Mechanica

## Phạm vi và phân loại

Kết quả cuối được chạy trên source 1.1.0+2 trong lượt chuẩn bị bàn giao. Lượt này chỉ đổi tài liệu, pubspec comments và ignore; không thêm gameplay hoặc refactor engine. **Unit/widget PASS không được dùng làm bằng chứng UI/gameplay Android PASS.**

- Unit/widget: luật và UI Flutter trong môi trường test.
- Integration Android: chạm Flutter/Flame trên emulator, phát âm thanh native và quan sát state.
- Smoke APK release: cài gói `lib/main.dart`, quan sát menu/phòng, landscape và menu debug.
- Static/package: kiểm tra manifest, quyền, icon, asset hashes và AOT.

## Môi trường

Flutter 3.47.7 / Dart 3.13.5; Flame 1.38.2, flame_audio 2.12.2, shared_preferences 2.5.6. Windows PowerShell; Android compile/target SDK 36, min 24, JBR 25 của Android Studio. Emulator `emulator-5554`, Android API 37, 2400×1080 landscape, logic khoảng 914×411 ở cấu hình đã dùng.

## Các lệnh bắt buộc — chạy lại trong lượt bàn giao

| Lệnh | Kết quả thực tế |
|---|---|
| `flutter pub get` | PASS, exit 0; giữ lockfile, không nâng dependency |
| `dart format --output=none --set-exit-if-changed .` | PASS, 0 thay đổi; 30 file source, hoặc 60 khi có bản preview local |
| `flutter analyze` | PASS, không issue |
| `flutter test` | PASS, 77 test |
| `flutter build apk --release` | PASS, tạo `build/app/outputs/flutter-apk/app-release.apk` |
| `python tools/verify_assets.py` | Kết quả kiểm kê cuối ghi trong RELEASE_HANDOVER |

Log thô ở local `docs/evidence/final/`, được ignore để tránh đưa output lớn và đường dẫn máy lên GitHub. Tóm tắt chia sẻ và hash APK: [RELEASE_HANDOVER](RELEASE_HANDOVER.md). Không cần log thô để build/test.

## Ma trận unit và widget

| Nhóm | Ca kiểm tra / kết quả mong đợi | File |
|---|---|---|
| Hợp đồng 12 màn | Đủ definition, ba hint; trace giải hợp lệ, replay xác định, state thắng ổn định | `test/domain_test.dart` |
| Sai và phục hồi | Trace sai không thắng; undo/reset rồi giải được | `test/domain_test.dart` |
| Resume | Khôi phục giữa trace vẫn giải được | `test/domain_test.dart` |
| Nước / nhiệt / quang | Bảo toàn nước, contamination, lọc hữu hạn, tự ngắt nhiệt, tia vòng lặp kết thúc | `test/domain_test.dart`, `test/mechanics_test.dart` |
| GearNetwork | Mạng truyền có tỷ số/chiều quay và chặn kẹt | `test/mechanics_test.dart` |
| Vật phẩm | 12 màn chặn trước sửa; dùng đồ thật; bốn công thức ghép; undo trả đồ; sai đồ không tiêu thụ | `test/phase2_test.dart` |
| Save | Backup khi bản chính hỏng; từ chối state bất hợp lệ; migration v1 và lưu settings trước restore | `test/persistence_test.dart`, `test/phase2_test.dart` |
| Dev isolation | Truy cập đủ 12 màn, hoàn thành/reset thử không đổi save thường | `test/phase2_test.dart` |
| Presentation state | Motion start/run/stop/jam/overload/reduced motion không đổi luật | `test/phase2_test.dart` |
| UI Flutter | Menu/settings/sổ tay ở 960×540, 1170×540, 914×411; pause chặn thao tác; undo/reset | `test/ui_test.dart` |
| Asset / scene exit | Thiếu art có thông báo; frame sau khi session bị đóng không crash | `test/asset_failure_test.dart` |

Không tuyên bố vét cạn mọi state hoặc mọi thứ tự thao tác. 77 test là số ca trong suite, không phải số thiết bị hay lượt playtest.

## Android integration đã thực hiện ở Phase 2

Các kết quả lịch sử dưới đây có log/screenshot local Phase 2. Gameplay source giữ nguyên trong lượt bàn giao, nên không chạy lại toàn bộ hành trình chỉ vì chỉnh tài liệu.

| Bài kiểm tra | Kết quả Phase 2 thực chạy | Bằng chứng local |
|---|---|---|
| `phase2_playthrough_test.dart` | PASS hai lượt: normal progression đủ 12 màn, khám phá/thu thập/ghép/lắp, kéo đồ màn đầu, pause/back, chạm thiết bị, kết thúc và lưu; lượt cuối 4 phút 24 giây | `docs/evidence/phase2/playthrough_final.log`, ảnh `p2_*.png` |
| `developer_test.dart` | PASS: UI mở cả 12 màn, tải art không lỗi, reset, hiện hotspot, thoát Dev giữ save thường | `docs/evidence/phase2/developer_android.log` |
| `audio_lifecycle_test.dart` | PASS: player đang phát/vị trí tiến, SFX không cắt BGM, loop mode, không trùng cùng chương, chuyển nhanh giữ chương cuối, mute/musicEnabled, background/resume và restore | `docs/evidence/phase2/audio_android.log` |

Ảnh chọn lọc: [screenshots](screenshots/README.md). Báo cáo lịch sử: [PHASE2_REPORT](PHASE2_REPORT.md). Các lượt mất kết nối hoặc test thất bại trước khi sửa không tính là PASS.

## Chạy lại Android integration

```sh
flutter drive --driver=test_driver/integration_driver.dart --target=integration_test/phase2_playthrough_test.dart -d <device-id>
flutter drive --driver=test_driver/integration_driver.dart --target=integration_test/developer_test.dart -d <device-id>
flutter drive --driver=test_driver/integration_driver.dart --target=integration_test/audio_lifecycle_test.dart -d <device-id>
```

Dùng emulator/test data riêng: bài hành trình xóa save thường trước chạy. `playthrough_test.dart` chuyển tiếp tới bài Phase 2. Sau integration test cần build lại `lib/main.dart`; APK target test không phải bản bàn giao.

## APK cuối

APK universal được đối chiếu SHA-256 của 74 file với manifest; không chứa tư liệu tham chiếu hoặc entrypoint integration test. Kiểm tra label/icon, version, ABI, landscape, quyền hợp nhất và absence chuỗi Dev Menu trong AOT. Tìm chuỗi AOT không phải bằng chứng bảo mật độc lập; bảo vệ còn nằm ở `kDebugMode` của UI và controller.

Trạng thái smoke APK cuối và sao lưu/khôi phục emulator được cập nhật trong [RELEASE_HANDOVER](RELEASE_HANDOVER.md). Không tạo production signing key.

## Chưa kiểm chứng

Chưa kiểm tra trên điện thoại ARM thật, ma trận nhiều tỷ lệ/cutout, pin/RAM hoặc đo 60 FPS; chưa playtest độc lập và đánh giá nghe nhiều loa/tai nghe. Chưa nghiệm thu web hoặc Play Store. Các giới hạn này không được đổi thành PASS bằng unit test.


## Kiểm thử V3

- `test/v3_test.dart`: tutorial tài khoản mới, không nhảy bước khi thao tác sai, reload đúng bước, skip/replay/completed, hướng dẫn tới thắng với sao luyện tập; gợi ý từ trace và off-trace đủ 12 màn, tách guest/UID/outbox và validation form.
- `test/ui_test.dart`: thêm mở Tài khoản chưa cấu hình ở ba cỡ landscape, không overflow.
- `integration_test/onboarding_test.dart`: chạm chính mục được coach chỉ, hoàn thành màn 01, 3 sao và completed; ảnh intro/gears/complete.
- `integration_test/firebase_test.dart`: Android Auth Emulator/Firestore thật, register/login/logout/reset, profile, query/transaction, offline queue/retry, dedupe attempts, thành tích tốt hơn, hai UID, download vào local store mới, Dev không upload.
- `integration_test/account_ui_test.dart`: thao tác các form thật, email lỗi, đăng ký/hồ sơ/logout/reset/login với Emulator; xác minh bàn phím landscape không làm tràn.
- `tools/firebase/rules.test.cjs`: owner/anonymous/cross-UID, field/type/range, unlock và thành tích đơn điệu, receipt bất biến.

93 unit/widget tests và 6 rules tests đã chạy đạt trong V3. Lượt normal progression cả 12 màn + ending, tutorial, Firebase coordinator, account UI và Dev Mode cũng đã chạy trên Android. Kết quả lệnh build/analyze cuối, audio regression và các giới hạn được chốt trong V3_REPORT. Không tính test chưa chạy là PASS.

Schema cloud version 3 khác schema local 1/2. Emulator là backend local thật, không thay cho kiểm tra project cloud của người dùng. Chưa kiểm chứng email tới inbox thật, deployment production hoặc đồng bộ giữa hai điện thoại vật lý.


## Xác nhận workspace và cấu hình Firebase — 31/10/2026

Người dùng xác nhận workspace chính thức là `C:\src\gamew\mechanica`, cũng là Git root. Không chuyển code từ bản khác trong lượt này.

- `flutter pub get`: đạt.
- `flutter analyze`: không có lỗi, chạy lại sau khi thêm test native.
- `flutter test`: 94 bài đạt, gồm test đối chiếu native JSON với Dart Firebase options.
- `npm test --prefix tools/firebase`: 6 bài Rules đạt trên Emulator; các log permission-denied trong trường hợp bị cấm là phản hồi mong đợi.
- `dart format --output=none --set-exit-if-changed lib test integration_test`: đạt tại thời điểm kiểm tra; các file test mới được format khi tạo.
- `flutter build apk --debug`: thành công với Google Services plugin và cấu hình project test thật.
- `integration_test/firebase_configuration_test.dart` trên Android Emulator: đạt; chỉ khởi tạo và đối chiếu native Firebase app, không tạo tài khoản hoặc ghi dữ liệu.

Đọc trực tiếp cấu hình project thật: CLI đã đăng nhập, Email/Password đã bật, Firestore mặc định ở asia-southeast1 đã tồn tại. Rules cloud vẫn deny-all tại thời điểm kiểm tra. Chưa xác nhận đăng ký/đồng bộ đầu cuối trên cloud thật. Xem log `docs/evidence/v3/workspace_*` và hướng dẫn Publish ở FIREBASE_SETUP.

- Kiểm tra lại sau cấu hình native: Firebase Auth/Firestore integration và account UI integration trên Android Emulator đều đạt.
- `flutter build apk --release`: thành công, entrypoint `lib/main.dart`; 74 asset trong APK khớp SHA-256 với manifest. Đây là bản ký debug phục vụ cài đặt trực tiếp, chưa phải bản phát hành Play Store.
- Tóm tắt lượt này: `docs/evidence/v3/workspace_resume_summary.json`. Các kết quả V3 trước đó là lịch sử, không thay cho kiểm thử cloud sau Publish rules.


## Sau deploy rules được người dùng cho phép — 31/10/2026

- Deploy rules project test `mechanica-e9e41`: thành công; readback khớp repository.
- `flutter analyze`: không có lỗi sau khi thêm test cloud thật.
- `flutter drive --driver=test_driver/integration_driver.dart --target=integration_test/firebase_cloud_test.dart --dart-define=FIREBASE_CLOUD_TEST=true -d emulator-5554`: đạt. SDK Android kết nối cloud thật; đăng ký/đăng nhập, hồ sơ, thành tích, chống retry, download, cross-UID và unauthenticated denial đều được xác nhận.
- Hai Auth QA user và hai nhánh dữ liệu Firestore đã được dọn. Không gửi email reset thật.
- Test này tách khỏi các bài Emulator; không chạy tự động trên project khác. Không coi đây là kiểm thử hai thiết bị vật lý hoặc email delivery.
