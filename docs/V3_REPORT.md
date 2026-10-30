# Mechanica V3 — kiểm tra và triển khai

**Trạng thái mới nhất 31/10/2026:** đã được cho phép deploy rules vào project test và kiểm thử SDK Android với cloud thật đạt. Các mục dưới ghi lại các checkpoint trước và sau deploy; xem cập nhật cuối tài liệu.

## Audit trước sửa

Working tree ban đầu sạch; remote giữ nguyên `https://github.com/Nguyen-Thuan-Chi/Mechanica.git`. Đã đọc lại README, tài liệu gameplay/architecture/testing/dev/handover, master prompt, definition 12 màn, controller, persistence/audio, reducer, Flame scene, UI và test liên quan.

Vấn đề V2: tutorial là lời nhắc đóng bằng “Đã rõ”, không xác nhận hành động; hint cấp cuối lệ thuộc trace mẫu; phòng/thiết bị không chỉ rõ mục tiêu chạm cho người mới; thành công giữa các màn ít giải thích hệ quả. Chưa có backend hoặc tài khoản.

Tái dùng: reducer xác định, GearNetwork/OpticalSystem, 12 lời giải, inventory, namespace dev, cache ảnh, 4 BGM/19 SFX. Không tạo lại engine/asset, không sinh ảnh AI.

Các module thay đổi: controller/persistence/main, guidance/onboarding mới, cloud_service và account UI mới, PlayScreen/RoomScene/menus/dev menu, nội dung mục tiêu/hoàn thành và tests. Save schema local giữ chấp nhận 1/2, thêm trường tùy chọn; guest key cũ giữ nguyên, account dùng key theo UID. Chỉ nhập guest khi người dùng chọn; không tự ghi đè.

Cập nhật 31/10/2026: workspace chính thức được người dùng xác nhận là `C:\src\gamew\mechanica`. FlutterFire đã cấu hình project test `mechanica-e9e41`, package `com.mechanica.mechanica`. Email/Password đã bật; database đã tồn tại. Rules đang hoạt động vẫn deny-all, chưa deploy rules repository. Không sửa thư mục `C:\src\mechanica` trong lượt xác nhận này. Emulator `demo-mechanica` chỉ là namespace test theo quy ước Firebase, không phải project cloud được tạo giả.

## Các checkpoint

- Tutorial dựa state, spotlight đối diện panel, xác nhận đọc/nhặt/chọn/lắp/cấu hình/chạy; skip/replay/resume, không trừ sao cho luyện tập màn 01.
- Gợi ý và Chỉ tôi cách làm: kiểm tra phòng/đồ; lời giải mẫu hoặc tìm kiếm tối đa 3.500 state/220 ms trong isolate, nếu chưa xác minh thì chỉ phục hồi rõ ràng. Hint cấp 3 dùng ngân sách nhỏ hơn.
- Firebase: email/password và reset, hồ sơ, transaction merge thành tích, query kết quả, durable outbox, receipts chống retry tăng đếm, local UID isolation. Dev không tải kết quả lên.
- Liên kết chương: lời hoàn thành giải thích hệ quả và mục tiêu tiếp theo; map chương đếm máy đã sửa.
- Art/audio V2 được giữ; bổ sung highlight bằng renderer hiện có, không thêm asset sinh ảnh.

Kết quả cuối, APK và hạn chế sẽ cập nhật sau khi các lệnh QA hoàn tất. Log/screenshot ở `docs/evidence/v3/` và `docs/evidence/v3_*.png`.


## Tiếp tục trong workspace chính thức — 31/10/2026

Không sao chép code từ thư mục khác. Tận dụng các module V3 đã có: onboarding/guidance, tài khoản, cloud outbox và save theo UID. Đối chiếu cấu hình Firebase JSON/Dart bằng test mới; thêm guard Emulator trước khi bài integration tạo tài khoản; thêm native smoke test khởi tạo project thật không ghi dữ liệu. README, FIREBASE_SETUP, DEV_GUIDE, ARCHITECTURE và TESTING đã sửa thông tin cấu hình cũ.

Kết quả chạy lại: pub get đạt; analyze không lỗi; 94 unit/widget test đạt; 6 Rules test đạt; format 41 file source/test không thay đổi; build debug và release thành công. Trên Android Emulator, ba bài native configuration, Firebase coordinator và account UI đều đạt. Asset integrity xác minh 74 file, 4 BGM/19 SFX; 74 asset trong APK release cũng khớp manifest.

APK release: `build/app/outputs/flutter-apk/app-release.apk`. Hash/size và log mới ở `docs/evidence/v3/workspace_resume_summary.json` và `workspace_*`. Bản release ký debug để cài trực tiếp; chưa có signing phát hành Play Store.

Chưa hoàn tất: rules cloud hiện deny-all; cần Publish file firestore.rules theo FIREBASE_SETUP và kiểm thử đầu cuối project test thật. Chưa kiểm chứng email tới hộp thư hoặc hai điện thoại thật. Cảnh báo Gradle về Kotlin của package Firebase còn tồn tại nhưng các build đã thành công. Chưa chạy lại toàn bộ hành trình 12 màn trong lượt này; kết quả playthrough trước đó không được coi là test mới. Không commit/push, không tạo project Firebase.

Đã cài APK debug từ main lên emulator và kiểm tra ảnh màn hình chính landscape: art, nút Tài khoản và điều hướng hiển thị. Ảnh ở `docs/evidence/v3/workspace_main_smoke.png`. Chưa smoke UI trên chính APK release mới trong lượt này.

## Sau khi được phép deploy rules — 31/10/2026

Đã chạy `firebase deploy --only firestore:rules --project mechanica-e9e41` thành công. Readback xác nhận ruleset `da170909-f999-47cb-81f2-a1c947993c40` khớp file repository. Không sửa nội dung rules để vượt test, không tạo lại Firebase project.

Thêm `integration_test/firebase_cloud_test.dart` với cờ opt-in riêng và kiểm tra project đích. Chạy trên Android Emulator nhưng kết nối **Auth/Firestore cloud thật**, dùng Firebase apps tách khỏi phiên mặc định. Đạt trong khoảng 20 giây: đăng ký hai user, hồ sơ, đăng nhập lại, upload/download unlock và thành tích, kết quả tốt hơn không bị ghi đè, retry không tăng attempts, từ chối đọc/ghi khác UID và đọc chưa đăng nhập. Guest save giữ nguyên.

Đã xóa hai Auth user QA trong cleanup của test và dọn đúng hai nhánh Firestore theo UID qua CLI; các query hậu kiểm trong log cleanup không còn tài liệu con. Không xóa dữ liệu người chơi khác. Analyze sau khi thêm test không có lỗi. Release APK hiện có giữ nguyên vì source runtime không đổi trong lượt deploy này.

Bằng chứng: `docs/evidence/v3/cloud_rules_deploy.log`, `cloud_admin_audit.json`, `cloud_real_android.log`, `cloud_qa_cleanup.log`. Chưa kiểm chứng inbox email thật hoặc đồng bộ trên hai điện thoại vật lý. Không commit/push.
