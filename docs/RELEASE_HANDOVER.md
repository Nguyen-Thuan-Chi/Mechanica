# Mechanica — bàn giao repository và APK cuối

Phiên bản source: **1.1.0+2**. Phạm vi lượt này là chuẩn hóa tài liệu/repository và QA, không thêm gameplay, thiết kế lại UI hoặc refactor engine. Chi tiết thay đổi: [REPOSITORY_AUDIT](REPOSITORY_AUDIT.md).

## Tài liệu hiện hành

| Tài liệu | Nội dung |
|---|---|
| [README](../README.md) | Giới thiệu đồ án, tính năng thực tế, bốn chương, ảnh chạy thật, cài/chạy/build, thao tác và giới hạn |
| [ARCHITECTURE](ARCHITECTURE.md) | Flutter/Flame, controller, reducer, cơ chế, save/audio/lifecycle |
| [GAMEPLAY](GAMEPLAY.md) | Thao tác, vật phẩm, quy tắc 12 màn, gợi ý, sao và tiến trình |
| [TESTING](TESTING.md) | Test case, phương pháp, kết quả mới và phân biệt bằng chứng Android lịch sử |
| [ASSET_CREDITS](ASSET_CREDITS.md) | Tên, nguồn, giấy phép art/audio/font và tư liệu không phân phối |
| [DEV_GUIDE](DEV_GUIDE.md) | Môi trường, debug, Developer Mode, version code và tools |
| [RELEASE_CHECKS.json](RELEASE_CHECKS.json) | Tóm tắt máy đọc được và hash APK |

## Kết quả QA chạy lại

| Lệnh | Kết quả |
|---|---|
| `flutter pub get` | PASS |
| `dart format --output=none --set-exit-if-changed .` | PASS, 0 thay đổi; 30 file source, kiểm tra cuối gồm preview local là 60 |
| `flutter analyze` | PASS, không issue |
| `flutter test` | PASS, 77 test |
| `flutter build apk --release` | PASS, APK universal từ entrypoint chơi bình thường |
| `python tools/verify_assets.py` | PASS, 74 asset / 46 ảnh / 4 BGM / 19 SFX; coverage, alpha và hash |
| Build từ preview tập file GitHub | PASS: pub get + release build; không copy local.properties hoặc wrapper JAR |

Raw log và dump chỉ giữ local tại `docs/evidence/final/`. Không báo gameplay Android PASS chỉ từ bảng unit test.

## APK nộp bài

- Đường dẫn: **`build/app/outputs/flutter-apk/app-release.apk`**.
- Dung lượng: **85.602.663 byte / 81,64 MiB**.
- SHA-256: `6e012804d2d7f8ca96a436c082e9c7f4533788e1e5e90f45b67fb0e2e1cff0bd`.
- Package: `com.mechanica.mechanica`; label: `Mechanica`; versionName `1.1.0`, versionCode `2`.
- ABI: `armeabi-v7a`, `arm64-v8a`, `x86_64`; min SDK 24, target/compile SDK 36.
- Ký bằng debug key có sẵn của môi trường theo cấu hình project; không tạo production key hoặc cấu hình Play Store.
- Gửi APK riêng để nộp bài; `build/`, `.apk`, `.aab` đều bị ignore trên GitHub.

Đối chiếu từng file trong APK: **74/74 hash khớp manifest**, không đóng gói references hoặc entrypoint integration test. Chuỗi tiêu đề Dev Menu không có trong AOT; `aapt` không báo `application-debuggable`. Source bảo vệ cả UI lẫn lệnh Dev bằng `kDebugMode`.

## Kiểm tra Android thực tế ở lượt bàn giao

Đã cài chính APK universal trên emulator API 37 và quan sát:

- Menu chính tải art/font, title và layout landscape đúng; release không có Phòng thử máy.
- Nút bắt đầu mở phòng 1, background/prop/thiết bị/tutorial hiển thị, không có màn đen do asset lỗi trong phần đã xem.
- `dumpsys media.player` ghi player của package đang loop, renderer không pause, 22.05 kHz mono và volume 0,45. Đây là xác nhận playback native, không phải đánh giá nghe/mix.
- Manifest hợp nhất chỉ dùng permission nội bộ `com.mechanica.mechanica.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`; không có quyền Internet, camera, microphone, vị trí hoặc bộ nhớ dùng chung.
- Android manifest đặt `sensorLandscape`; Dart bootstrap yêu cầu hai hướng landscape.
- Sau smoke release, đã cài lại debug và mở Developer Mode thấy đủ 12 lựa chọn màn.

Preferences của app trên emulator được sao lưu trước cài thử, phục hồi và đối chiếu byte-for-byte; sau kiểm tra menu debug cũng phục hồi lại bản ban đầu. Backup là dữ liệu local, không đưa GitHub. Emulator cuối trở về bản debug trước đó; APK release mới vẫn nằm ở đường dẫn nộp bài nêu trên.

Luồng đầy đủ 12 màn và ending, Dev Mode truy cập 12 màn, native audio/lifecycle đã thực chạy ở Phase 2; lượt này không chạy lại toàn bộ các integration test vì gameplay source không đổi. Xem phân loại kết quả trong [TESTING](TESTING.md).

## File đưa lên GitHub

| Đưa lên | Ghi chú |
|---|---|
| `lib/`, `assets/` | Source và toàn bộ asset cần chơi; giữ license font và manifest |
| `android/` theo ignore hiện có | Gradle/Kotlin/manifest/icon/styles; không local.properties/cache/keystore/registrant sinh tự động |
| `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.metadata`, `.gitignore` | Cấu hình và phiên bản dependency |
| `test/`, `integration_test/`, `test_driver/` | Bộ kiểm thử thực tế |
| `tools/`, `art_sources/` | Tools còn dùng và hai atlas nguồn Phase 2 |
| `docs/` theo ignore, `README.md`, `README_FIRST.md` | Năm tài liệu kỹ thuật, screenshot chọn lọc, báo cáo và lịch sử thiết kế |
| `MECHANICA_MASTER_PROMPT_CODEX.md` | Bản yêu cầu thiết kế gốc |
| `web/` | Scaffold giữ lại, README ghi rõ chưa nghiệm thu |

Không đưa lên: `build/`, `.dart_tool/`, `.idea/`, `.gradle/`, `.flutter-plugins-dependencies`, APK/AAB, log/dump/backup emulator, `backups/`, `references/`, `reference_workflow.txt`, file local và credential. Screenshot GitHub chỉ dùng tám JPEG khoảng 1,19 MB trong `docs/screenshots/`.

## Giới hạn chưa kiểm chứng

- Chưa thử APK trên điện thoại ARM thật hoặc ma trận nhiều thiết bị/cutout, chưa đo FPS/RAM/pin.
- Chưa có playtest độc lập và thẩm định audio trên nhiều loa/tai nghe; không cam kết 60 FPS hoặc độ khó/thời lượng.
- Chưa nghiệm thu web, ký production, Play Store hoặc build trên máy thứ hai/clone GitHub thật.
- Bố cục khám phá còn lặp và nhạc loop ngắn là giới hạn sản phẩm đã ghi trong README.
- Chưa có license chung cho toàn bộ source/art; không tự gán MIT hoặc CC0.

## Bước cuối do người dùng thực hiện

Workspace root chưa có `.git`; chưa commit, push hoặc tạo GitHub Release. Người dùng kiểm tra tài liệu, tập file và APK rồi tự chọn repository, stage và commit. Không cần đưa APK vào Git để nộp source đồ án.

Commit message đề xuất:

```text
chore: prepare Mechanica 1.1.0 handover and release documentation
```
