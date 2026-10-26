> **Thông tin bàn giao:** Báo cáo lịch sử Phase 2. APK universal và kiểm tra repository cuối được ghi tại [RELEASE_HANDOVER](RELEASE_HANDOVER.md).

# MECHANICA — Báo cáo triển khai Phase 2

Ngày bàn giao: 26/10/2026. Đây là phần nâng cấp project hiện có, không tạo project mới. Bản nguồn trước nâng cấp được giữ tại `backups/phase1_source.zip`. Các tài liệu QA_REPORT/FINAL_HANDOFF là lịch sử Phase 1; kết quả dưới đây dành cho Phase 2.

## 1. Hệ thống đã nâng cấp

- Phòng có 6 vùng tương tác đặt trong hệ tọa độ 1280×720, dùng chung phép biến đổi với camera: lời nhắn, manh mối, ngăn dụng cụ, vật thể phụ, chỗ sửa và bộ máy chính. Có góc cận cảnh, trở lại phòng, xem đồ, nhật ký chỉ ghi manh mối đã tìm được. Android Back đóng túi trước, rồi trở lại phòng, rồi tạm dừng.
- Inventory có stable ID, hình/miêu tả độc lập, nhặt/chọn/kéo sử dụng, ghép hai món, đánh dấu đã dùng. Luật sửa và ghép nằm trong reducer, không chỉ khóa bằng UI. Sai đồ không bị mất; hoàn tác khôi phục vật phẩm.
- Cả 12 màn phải khám phá và sửa chỗ hỏng trước khi vận hành cơ chế gốc. Tên màn, bốn chương và luật bánh răng/nước/quang học/lõi giữ nguyên. Có ngăn khóa theo manh mối ở 4 màn, ghép đồ ở 4 màn.
- Mục tiêu, ghi chép, phản hồi và gợi ý viết lại bằng tiếng Việt. Gợi ý xét bước khám phá hiện tại; cấp cuối chỉ gợi bước kế tiếp khi khớp trace đã kiểm chứng, nếu không đưa hướng phục hồi. Sổ tay chia 7 thẻ ngắn; tutorial theo ngữ cảnh và lưu trạng thái đã xem.
- Lưu offline schema 2, chấp nhận schema 1 và điền trạng thái phòng mới khi khôi phục. Sao, màn mở, âm lượng, manh mối và vật phẩm được lưu. Bản dự phòng và hàng đợi ghi vẫn hoạt động. Đổi cài đặt trước khi mở bản lưu cũ không làm mất khả năng migration.
- UI có ẩn/hiện thanh công cụ; dialog và túi đồ cuộn được trên landscape. Giữ phong cách kim loại và bốn nền vẽ riêng của bốn chương.

## 2. Màn đã thay đổi

| Màn | Khám phá/sửa mới | Cơ chế tiếp nối |
|---|---|---|
| 01 Tia lửa đầu tiên | Tìm và lắp khớp nối trục | Tỷ số, chiều quay, chốt an toàn |
| 02 Đồng hồ không kim | Ghép bánh dẫn với chốt giữa | Cặp đồng hồ cùng tiến, giữ kim |
| 03 Trái tim lò hơi | Đọc dấu khóa, tìm vòng đệm | Tích hơi, lấy lực, xả quá áp |
| 04 Bình cân bằng | Ghép ống mềm với vòng siết | Đong và bảo toàn nước |
| 05 Nước qua ký ức | Lắp lõi lọc còn nguyên | Nguồn sạch/đục, giới hạn lọc |
| 06 Cánh cửa thủy áp | Dấu khóa, chốt giữ nước | Cân hai khoang rồi xả cửa |
| 07 Con mắt ánh sáng | Thay cầu chì nguồn đèn | Hướng gương, khe chắn, hai mắt |
| 08 Sắc phổ vỡ | Ghép lăng kính với đế | Tách màu, giảm cường độ, quá tải |
| 09 Bản đồ tinh tú | Dấu khóa, lắp vòng nhớ | Ghi Bắc trước rồi chuyển Nam |
| 10 Vòng tuần hoàn | Nối lại ống nước lạnh | Công suất, nhiệt và nhịp ổn định |
| 11 Ba khóa an toàn | Dấu khóa, cầu chì liên động | Khóa cơ → nước → quang |
| 12 Cỗ máy cuối cùng | Ghép vòng dẫn với lõi thủy tinh | Hiệu chỉnh → đồng bộ → tự giữ nhịp |

Không có vật phẩm xuyên màn, nhiệm vụ phụ xuyên chương hay nội dung bí mật yêu cầu quay lại màn cũ.

## 3. Animation

Mới: ngăn kéo dịch ra theo `cabinetOpen`; bộ phận lắp vào và sáng xác nhận theo `repairReady`; giọt rò ở chương nước ngừng sau khi sửa; đồ đã nhặt/đã dùng đổi hiển thị; bánh răng tăng tốc, quay, giảm tốc, kẹt/quá tải và giữ góc khi dừng. Giữ chuyển cảnh phóng to, van/gương/cần chuyển nấc, kim nội suy, nước/tia theo trạng thái và cửa mở sau thắng. Giảm chuyển động vẫn giữ luật chơi. Cảnh Flame giữ session riêng để tránh đọc session đã bị xóa khi rời Dev Mode.

## 4. Audio thực sự đóng gói

4 WAV PCM mono 22.05 kHz, 32 giây/bản, tổng hợp gốc bằng `tools/upgrade_audio.py`, không dùng sample thương mại:

- `music/ch1.wav`: Nhịp người thợ vắng — nốt mềm kiểu piano, tiếng tích tắc, kim loại.
- `music/ch2.wav`: Những trang dưới nước — drone thấp, giọt nước, tiếng ngân thưa.
- `music/ch3.wav`: Bầu trời ghi nhớ — pha lê, chuông và tiếng vọng.
- `music/ch4.wav`: Hơi thở dưới lòng núi — drone trầm, nhịp máy chậm.

19 SFX trong `assets/audio/sfx/`: `click`, `switch`, `metal`, `gear`, `steam`, `valve`, `water`, `beam`, `door`, `win`, `fail`, `inventory`, `pickup`, `clue`, `latch`, `transition`, `motor_start`, `motor_stop`, `jam` (đều `.wav`).

Audio dùng một BGM loop, 4 voice SFX tái sử dụng; khởi tạo idempotent; cùng chương không phát lại; chuyển chương fade-out/fade-in và bỏ yêu cầu cũ nếu chuyển nhanh. Có BGM/SFX riêng, bật/tắt nhạc, tắt toàn bộ, lưu cài đặt và xử lý background. Đây là nhạc tổng hợp ngắn, chưa phải soundtrack được nhạc sĩ thu/mix chuyên nghiệp.

## 5. Developer Mode

Debug build: menu chính → **Phòng thử máy** → chọn bất kỳ 12 màn. Trong màn bấm **Thử** để xem điều kiện thắng, trạng thái, đặt lại, hoàn tác, hiện vùng chạm hoặc xóa dữ liệu thử. **Về hành trình thật** trở lại save thường.

`kDebugMode` bảo vệ cả UI lẫn lệnh controller. Save thường: `mechanica_save_v1`/backup; save thử: `mechanica_development_v2`/backup riêng. Truy cập màn không tự ghi sao. Xóa dữ liệu thử không xóa save thường.

## 6. Kiểm thử và build

Môi trường: Flutter 3.47.7 / Dart 3.13.5, Flame 1.38.2, Android emulator API 37, landscape 2400×1080 (logic khoảng 914×411). Log nằm tại `docs/evidence/phase2/`. Ảnh `docs/evidence/p2_*.png` là ảnh chạy thật trên Android, không phải concept.

| Lệnh / phạm vi | Kết quả đã thực hiện | Bằng chứng |
|---|---|---|
| `flutter pub get` | PASS | `pub_get.log` |
| `flutter analyze` | PASS, không issue | `analyze.log` |
| `flutter test` | PASS, 77 ca | `flutter_test.log` |
| Android hành trình Phase 2 | PASS cả hai lượt, đủ 12 màn và kết thúc; lượt cuối 4 phút 24 giây | `playthrough_first.log`, `playthrough_final.log` |
| Android Developer UI | PASS, mở đủ 12 màn, reset, vùng chạm, thoát về save thường không đổi | `developer_android.log` |
| Android audio/lifecycle | PASS, BGM đang phát và vị trí tiến, SFX không cắt BGM, loop mode, chống trùng, chuyển chương nhanh, mute/musicEnabled, background/resume và restore | `audio_android.log` |
| `python tools/verify_assets.py` | PASS, 74 file/46 ảnh/4 BGM/19 SFX, hash và alpha | `../asset_integrity.json` |

77 ca unit/widget bao gồm 12 lời giải, 12 trace sai và reset/undo, 12 khôi phục giữa màn, bảo toàn nước/lọc hữu hạn/nhiệt/quang, 12 luật sửa–dùng đồ, 4 tổ hợp ghép, save migration, namespace debug, mở 12 màn, controller pause/back/zoom, motion state, mất asset và frame cuối của scene đã rời. Menu/cài đặt/sổ tay được kiểm tra ở 960×540, 1170×540 và 914×411.

Các lỗi đã phát hiện rồi sửa: bước chuẩn bị mới làm test cũ không còn tác động lên máy; chữ mất dấu khi ghi file mới qua PowerShell; save v1 được ghi lại trước migration; scene cũ đọc session null khi thoát Dev Mode; test nút Đóng cần cuộn ở màn hình thấp. Có lượt emulator bị ngắt/mất kết nối và lượt công cụ chờ VM extension lâu; không tính các lượt đó là PASS. Chưa có kết luận về nguyên nhân môi trường bị ngắt.

Đã build từ `lib/main.dart`: `flutter build apk --debug`, `flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64 -t lib/main.dart`. Bản debug bàn giao được build lại thêm `--build-number=5002` để nâng cấp lên trên version code 4002 của release x86_64 đã smoke test, giữ dữ liệu emulator; mã game không đổi. Log `build_debug.log` / `build_release.log`.

Đã cài/mở APK debug và release x86_64 thực tế. Release hiện menu thường, mở phòng 1, không có nút Dev; `aapt dump badging` không có `application-debuggable`. Chuỗi tiêu đề Dev Menu không có trong AOT cả ARM64 và x86_64 (`release_guard.json`); các lệnh vẫn được bảo vệ bằng `kDebugMode` trong source. Chưa chạy ARM64 trên điện thoại thật. Debug cuối đã cài trên emulator, version 1.1.0/code 5002, đủ ABI arm64-v8a/armeabi-v7a/x86_64. Dữ liệu thường vẫn giữ sau lượt đổi build.

Nhãn bể thu màn 6 được chỉnh vị trí sau lượt playthrough; đã kiểm tra trực tiếp góc cận cảnh trên APK đóng gói (`lv6_label_fixed.png`). Unit/widget và analyze chạy lại đạt sau thay đổi. Ảnh bàn giao: `main_release.png`, `release_room.png`, `final_debug.png` trong thư mục bằng chứng Phase 2.

`python tools/verify_apks.py`: PASS, từng APK chứa đúng SHA-256 của cả 74 asset hiện tại và không chứa references. Các APK dưới đây là bản chơi bình thường, không phải entrypoint integration test.

## 7. Art, nguồn và tái tạo

Giữ bốn môi trường brass/water/prism/core cùng 16 prop của Phase 1. Thêm 8 PNG alpha 512×512 tại `assets/images/exploration/`: cabinet, notebook, key, coupler, hose, filter, gasket, fuse. Tạo bằng công cụ imagegen tích hợp, không dùng CLI. Prompt: vật thể phiêu lưu cơ khí nhìn trước, vật liệu cũ có texture, ánh sáng từ trái trên, atlas 2×2 tách nền alpha, không chữ/logo/UI; hai nhóm vật thể được ghi trong `PHASE2_ART_SOURCES.json`. Atlas được kiểm tra rồi cắt/căn bằng `tools/prepare_exploration.py` và đã tích hợp trong game. Không coi output AI là CC0.

Manifest hiện có 74 file: 46 ảnh, 4 BGM, 19 SFX, font/license và dữ liệu. Mọi file có SHA-256; ảnh tham chiếu không đóng gói. Thumbnail 12 màn được cập nhật từ screenshot Android Phase 2.

## 8. Giới hạn và phần chưa đạt mức hoàn thiện cao nhất

- Có 4 nền phòng theo chương, không phải 12 căn phòng vẽ hoàn toàn riêng. Bố cục sáu hotspot và chuỗi tìm–sửa còn dùng chung; phần giải cơ khí cốt lõi khác nhau theo màn. Khám phá chưa có nhiều góc camera trong cùng phòng.
- Máy vẫn có mặt bảng cơ khí ở góc cận cảnh. Art có texture và các vật thể thật để tương tác, nhưng chưa đạt mức mọi thiết bị hòa hoàn toàn vào kiến trúc phòng; chưa tuyên bố đạt toàn bộ tiêu chí mỹ thuật chủ quan của prompt.
- Manh mối chủ yếu là giấy/nhãn/miêu tả; chưa có toàn bộ chữ/sơ đồ riêng được vẽ lên từng bề mặt vật thể. Bốn khóa biểu tượng là cơ chế đơn giản, không được coi là câu đố chính.
- Không có playtest người chơi độc lập để xác nhận độ khó/thời lượng và chất lượng tiếng Việt. Chưa đo 60 FPS/hiệu năng trên điện thoại thật hoặc thử ma trận nhiều thiết bị/cutout. Log debug/emulator có skipped frames; không báo đạt 60 FPS.
- Audio đã kiểm tra đường phát native và lifecycle; chưa có đánh giá nghe/mix trên loa và tai nghe thiết bị thật. Bản loop chỉ 32 giây, mức biến hóa còn hạn chế.
- APK release vẫn dùng khóa debug của môi trường; chưa là gói phát hành cửa hàng đã ký production.

Các hạn chế trên khiến bản nâng cấp này chưa được tuyên bố là nghiệm thu toàn bộ chất lượng indie thành phẩm theo prompt, dù các hệ thống đã triển khai có thể được chơi và kiểm chứng.


## APK bàn giao

| File | Dung lượng | SHA-256 |
|---|---:|---|
| [app-debug.apk](../build/app/outputs/flutter-apk/app-debug.apk) | 184.58 MiB | `da04efe9450441e239db68553e6ed09ca5f0c4560b4b4b028936573bcfadae56` |
| [app-arm64-v8a-release.apk](../build/app/outputs/flutter-apk/app-arm64-v8a-release.apk) | 49.85 MiB | `1041a50d72f88aae6ee23333cb6d21321fdab8d9d7181f55c18540af43abc5b4` |
| [app-x86_64-release.apk](../build/app/outputs/flutter-apk/app-x86_64-release.apk) | 51.26 MiB | `a5a9b0f139785fb9284bece2bab460dde68155a3ee9e064db03f74e267c6e9de` |

Bản release dùng khóa debug, phục vụ cài thử trực tiếp; chưa có ký production/store listing. Không coi kiểm thử tự động và smoke test là playtest thẩm mỹ hay xác nhận chất lượng âm thanh trên phần cứng thật.
