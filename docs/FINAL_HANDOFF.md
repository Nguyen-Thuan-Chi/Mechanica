> **Thông tin bàn giao:** Bàn giao lịch sử Phase 1. Bản bàn giao cuối để nộp đồ án: [RELEASE_HANDOVER](RELEASE_HANDOVER.md).

# Mechanica — bàn giao

Đã triển khai game offline Flutter + Dart + Flame có thể chơi xuyên **4 chương / 12 màn**, từ menu tiếng Việt đến khu vườn kết thúc và quay lại menu. Có lời giải và đường sai kiểm thử cho từng màn. Không xem báo cáo này là chứng nhận đạt mọi tiêu chí phát hành thương mại: performance, playtest độ khó và thiết bị thật còn chưa kiểm chứng.

## Artifact tồn tại

| File | Dùng cho | Kích thước |
|---|---|---|
| [app-arm64-v8a-release.apk](../build/app/outputs/flutter-apk/app-arm64-v8a-release.apk) | Android ARM64 | 45,98 MiB |
| [app-x86_64-release.apk](../build/app/outputs/flutter-apk/app-x86_64-release.apk) | Emulator x86_64, đã cài chạy | 47,33 MiB |
| [app-debug.apk](../build/app/outputs/flutter-apk/app-debug.apk) | Debug đa kiến trúc, đã cài chạy | 213,09 MiB |

Release được tối ưu nhưng **ký bằng khóa debug**, chỉ dùng cài thử. Không có secret phát hành, không upload cửa hàng. Hash SHA-256 và kiểm tra toàn bộ asset trong APK: [apk_integrity.json](evidence/apk_integrity.json).

## Nội dung đã chạy

- Bánh răng có tỷ số hữu tỉ/đảo chiều/jam; ly hợp ghép cặp; áp suất/mô-men.
- Nước bảo toàn thể tích, dung tích bình khác nhau, nhiễm bẩn, bộ lọc hữu hạn và chốt thủy áp nhớ trạng thái.
- Tia phản xạ hình học, hướng mắt nhận, tách/lọc màu, cường độ, giới hạn vòng lặp và bộ nhớ hai pha.
- Lõi nhiệt/công suất/làm lạnh, khóa liên động, mất điều kiện kéo rơi khóa, màn cuối ba giai đoạn và bốn nhịp ổn định.
- Khám phá bản khắc, góc phòng/cận máy, kéo thả ở màn 1, ba vùng máy cuối, nhật ký/hint tiếng Việt, undo/reset, pause, settings, lưu giữa màn, sao/lượt tốt nhất, mở khóa tuần tự.
- Animation gear/kim/nước/tia/piston/cửa, ambient hữu hạn, kết thúc mở cửa nhìn vào khu vườn; giảm chuyển động.
- 4 môi trường minh họa, 16 sprite alpha, icon/cards/12 thumbnail thật; 4 vòng nhạc ambient và 11 SFX tổng hợp riêng; Noto Sans/Serif OFL kèm license.

Tên 12 màn, quy tắc và ngưỡng sao ở [LEVEL_MATRIX.md](LEVEL_MATRIX.md). Dữ liệu chuẩn và trace ở `assets/data/levels.json`; đây là luật được runtime thực sự chạy, không chỉ mô tả thiết kế.

## Kiểm thử thực tế

`flutter analyze`: không issue. `flutter test`: **56 pass**. Hai kịch bản Android riêng đã pass: chạm giải toàn bộ 12 màn tới ending/home; native audio + lifecycle/settings/save. APK debug và release build thành công. Debug có smoke Android Home/foreground/force-stop/relaunch; release x86_64 có smoke menu và khôi phục phòng. 58 asset trong cả ba APK đã đối chiếu hash.

Xem [QA_REPORT.md](QA_REPORT.md) để biết lệnh, lỗi đã sửa, PASS/FAIL/NOT RUN và phạm vi chính xác. Log debug có skipped frames khi screenshot; không suy ra FPS release.

## Ảnh thật và source

[Tổng hợp 12 màn](evidence/runtime_contact_sheet.jpg), [Home](evidence/android_home.png), [Xưởng](evidence/android_lv01.png), [Thư viện](evidence/android_lv04.png), [Đài thiên văn](evidence/android_lv07.png), [Lõi cuối](evidence/android_lv12.png), [Kết thúc](evidence/android_ending.png).

- `lib/game/puzzles/`: state/reducer/undo/hint; `lib/game/mechanics/`: gear và optical graph.
- `lib/game/mechanica_game.dart`: Flame scene, device interaction, rendering/animation.
- `lib/ui/`, `lib/app/`, `lib/core/`: navigation/settings/controller/save/audio.
- `assets/`: mọi file cần cho build; không cần gọi AI hoặc tải art để chạy.
- `test/`, `integration_test/`, `test_driver/`: kiểm thử có thể chạy lại.
- `tools/`: author levels, tổng hợp audio, normalize art, tạo icon/thumbnail, kiểm kê/hash.

[Nguồn asset](ASSET_SOURCES.md), [manifest](ASSET_MANIFEST.csv), [Art Bible](ART_BIBLE.md), [hướng dẫn chơi](GUIDE.md), [README chạy/build](../README.md). Bốn ảnh và DOCX trong references đã được nghiên cứu; không nằm trong asset bundle. Không gắn CC0 cho ảnh AI.

## Giới hạn bàn giao

Chưa profile 60fps/pin/bộ nhớ dài hạn, chưa thử máy ARM64 thật, chưa playtest độ khó với người mới, chưa QA audio trên nhiều thiết bị, chưa hỗ trợ đầy đủ TalkBack, chưa ký phát hành cửa hàng. Art dùng bốn tranh phòng và 12 cách ghép máy; bộ phận động kết hợp sprite với đồ họa lập trình, không phải 12 phòng vẽ riêng. Khám phá hiện xoay quanh bản khắc và máy, không có inventory mở rộng. Các giới hạn này được ghi để tiếp tục sản xuất, không được gán PASS vì các test khác đã qua.
