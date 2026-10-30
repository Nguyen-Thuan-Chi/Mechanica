> Tài liệu bàn giao V2, giữ để tra cứu lịch sử. Trạng thái/code/APK hiện tại: [V3_REPORT](V3_REPORT.md).

# Kiểm tra repository trước bàn giao

## Phạm vi

Chuẩn hóa repository để đưa lên GitHub và nộp đồ án. Không đổi gameplay, UI, dependency version hoặc source `lib/`, `test/`, `integration_test/`. Version giữ **1.1.0+2**. Chưa có `.git` ở root; không khởi tạo Git ở root, commit, push hoặc tạo GitHub Release.

Một repository Git tạm nằm trong `build/handover-audit-index/` chỉ phục vụ tính danh sách file theo ignore. Nó được ignore cùng toàn bộ `build/`, không chứa commit và không phải repository người dùng.

## File thay đổi

| File / nhóm | Thay đổi |
|---|---|
| `.gitignore` | Bỏ ngoại lệ cho log; loại trừ build/cache, bằng chứng thô, backup, binary APK/AAB, credential/local config và tư liệu chưa xác minh quyền phân phối |
| `pubspec.yaml` | Bỏ comment mẫu dài; giữ nguyên version, SDK, dependencies, asset và font declarations |
| `README.md` | Viết lại tiếng Việt: tính năng thật, bốn chương, ảnh thực tế, môi trường, chạy/build, thao tác, Dev Mode, credit và giới hạn |
| `README_FIRST.md` | Thay hướng dẫn khởi tạo project trống đã lỗi thời bằng lối vào tài liệu hiện hành |
| `docs/GUIDE.md` | Chuyển tới GAMEPLAY; giữ nội dung cũ trong `docs/history/GUIDE_PHASE1.md` |
| `docs/QA_REPORT.md`, `FINAL_HANDOFF.md`, `PHASE2_REPORT.md`, `ASSET_SOURCES.md`, `PRODUCTION_PLAN.md` | Thêm ghi chú lịch sử và link tài liệu hiện hành; giữ nguyên nội dung phát triển |
| `tools/fix_test_io.py` | Xóa patcher một lần đã hoàn thành, không được pipeline/import gọi; không cần để build/test |

## File mới

- `docs/ARCHITECTURE.md`, `GAMEPLAY.md`, `TESTING.md`, `ASSET_CREDITS.md`, `DEV_GUIDE.md`.
- `docs/RELEASE_HANDOVER.md`, `REPOSITORY_AUDIT.md`, `RELEASE_CHECKS.json`.
- `docs/screenshots/README.md` và tám JPEG chụp Android thật, tổng 1.186.581 byte.
- `docs/evidence/README.md`: giải thích vì sao bằng chứng local không ở GitHub.
- `docs/history/GUIDE_PHASE1.md`: lưu nguyên hướng dẫn Phase 1.

## Dọn và loại trừ

Không chạy `flutter clean` sau build vì cần giữ APK nộp bài. Build khoảng 4,7 GB và bằng chứng QA khoảng 147 MB tại thời điểm kiểm tra được **giữ local nhưng ignore**. Bản preview/build kiểm tra mới cũng nằm dưới `build/`.

Không xóa bất kỳ file nào trong 74 asset đang được manifest kiểm kê. Art nguồn Phase 2 vẫn giữ để tái chuẩn hóa sprite. Web scaffold được giữ và ghi rõ chưa nghiệm thu, thay vì xóa tài nguyên còn được chính scaffold tham chiếu.

`references/` và `reference_workflow.txt` chứa tư liệu bên thứ ba chưa xác minh quyền phân phối: giữ local, không đưa lên GitHub/APK. Backup ZIP lịch sử cũng giữ local và ignore; các tài liệu phát triển Markdown, master prompt, GDD và Art Bible vẫn có trong tập file xuất bản.

## Cấu hình local và thông tin nhạy cảm

- Phát hiện `android/local.properties`; đã được ignore, không copy vào preview GitHub.
- Không phát hiện keystore/private key trong source project ở lượt quét tên file; không tạo khóa production mới.
- Quét file văn bản của tập chuẩn bị GitHub theo các mẫu private key, token GitHub, AWS access key, Google API key và OpenAI key: kết quả cuối ghi tại `RELEASE_CHECKS.json`. Đây là quét mẫu, không phải chứng minh tuyệt đối không có thông tin nhạy cảm.
- Các key save trong source là tên preference, không phải credential. Đường dẫn tạo ảnh trong tài liệu provenance không cần tồn tại trên máy clone.
- Không thêm license MIT/CC0 chung khi chưa có quyết định của chủ dự án. Giữ nguyên SIL OFL của Noto và ghi rõ nguồn art/audio.

## Kiểm tra khả năng build từ tập GitHub

Dùng `git ls-files --others --exclude-standard` với repository tạm để xuất đúng các file không bị ignore sang `build/github_preview/`. Snapshot đầu có 184 file / 42.503.804 byte; không copy `local.properties`, wrapper JAR, build cache hay SDK path local.

Trong bản preview đã chạy `flutter pub get` và `flutter build apk --release`: **PASS**. Flutter tự chuẩn bị cấu hình local và Gradle wrapper còn thiếu theo template. Tài liệu bàn giao bổ sung sau snapshot không thay đổi build inputs. Đây là kiểm tra sao chép sạch trên cùng máy và cùng caches package/Gradle; chưa phải clone qua GitHub hoặc build trên máy thứ hai.

## Trước khi người dùng stage

Đưa source/config/asset/license/test/tools/docs và lockfile lên GitHub. Xem bảng chi tiết trong [RELEASE_HANDOVER](RELEASE_HANDOVER.md). `.gitignore` không gỡ file đã được track trong một repository khác; nếu người dùng nhập vào repo cũ cần kiểm tra staged files. Không đưa APK, dữ liệu emulator, keystore hoặc log local vào commit.
