# Firebase cho Mechanica V3

## Trạng thái đã kiểm tra ngày 31/10/2026

Workspace chính thức: `C:\src\gamew\mechanica`. Không sửa bản khác ở `C:\src\mechanica`.

Firebase CLI trong PATH đã đăng nhập và đọc được project test `mechanica-e9e41`. FlutterFire CLI đã tạo `lib/firebase_options.dart`; Android dùng `android/app/google-services.json` và Google Services Gradle plugin. Cả hai cấu hình khớp package `com.mechanica.mechanica`, app ID đầy đủ `1:6334202356:android:a3b9c3b60c4a1e8fa479a1`.

Kiểm tra API quản trị chỉ đọc: Email/Password đã bật; Firestore `(default)` đã tồn tại ở `asia-southeast1`. Sau khi người dùng cho phép, đã deploy `firestore.rules` vào đúng project test và đọc lại xác nhận khớp repository. Native Android integration với hai tài khoản QA trên cloud thật đã đạt: đăng ký/đăng nhập, hồ sơ, upload/download thành tích, transaction giữ kết quả tốt hơn, receipts chống lặp, từ chối truy cập khác UID và chưa đăng nhập. Hai tài khoản QA và dữ liệu Firestore tương ứng đã được dọn. Không tạo lại project/database.

Build Android mặc định dùng project test thật; gameplay vẫn lưu offline. Dùng `--dart-define=FIREBASE_OFFLINE=true` nếu muốn tắt cloud. Emulator dùng Firebase app có tên riêng `mechanica-emulator`, tách khỏi default app thật, chỉ cho phép trong debug.

## Chạy Emulator

Yêu cầu Node tương thích Firebase CLI (môi trường đã dùng Node 24), Java 21+ (môi trường dùng JBR 25). Không cần service-account key hoặc Firebase project cloud để test local.

```powershell
npm ci --prefix tools/firebase
$env:JAVA_HOME = 'C:/Program Files/Android/Android Studio/jbr'
$env:PATH = "$env:JAVA_HOME/bin;$env:PATH"
firebase emulators:start --only auth,firestore --project demo-mechanica
```

Terminal khác:

```sh
flutter run -d emulator-5554 --dart-define=FIREBASE_EMULATOR=true
```

Android emulator truy cập máy host qua `10.0.2.2`. Khi dùng thiết bị khác, truyền `--dart-define=FIREBASE_EMULATOR_HOST=<host-IP>` và cấu hình kết nối/firewall phù hợp. HTTP cleartext chỉ cho phép trong manifest debug. Auth chạy cổng 9099, Firestore 8080. Emulator reset email được in trong terminal, không gửi email thật.

## Cấu hình project Firebase hiện có

Chạy từ workspace chính thức. Dùng Firebase CLI đã có trong PATH:

```powershell
firebase projects:list
# Chỉ chạy firebase login nếu CLI báo chưa đăng nhập.
dart pub global activate flutterfire_cli
dart pub global run flutterfire_cli:flutterfire configure --project=mechanica-e9e41 --platforms=android --android-package-name=com.mechanica.mechanica --out=lib/firebase_options.dart --yes
flutter run
flutter build apk --release
```

Không cần tạo project mới hoặc truyền `firebase.local.json` cho cấu hình mặc định. Các dart-define trong file mẫu vẫn dùng được để chủ động chọn một project khác với đủ bốn client options. Không đưa service-account/private key, token CLI hoặc mật khẩu vào source.

### Rules đã triển khai

Đã chạy theo sự cho phép của người dùng:

```powershell
firebase deploy --only firestore:rules --project mechanica-e9e41
```

Đã đọc lại release `cloud.firestore`, ruleset `da170909-f999-47cb-81f2-a1c947993c40`, xác nhận nội dung khớp `firestore.rules`. Không cần Publish lại rules hiện tại trên Console. Khi sửa rules trong tương lai, chạy lại bộ Rules tests trước khi chủ động deploy đúng project đích.

Rules giới hạn mỗi tài khoản vào dữ liệu UID của chính nó, kiểm tra schema và không cho xóa qua client. Không dùng `allow read, write: if true`.

## Luồng tài khoản

Menu chính → **Tài khoản** → Đăng ký/Đăng nhập/Quên mật khẩu. Form kiểm tra email, tối thiểu sáu ký tự, xác nhận mật khẩu và tên 1–60 ký tự. Nút bị khóa khi đang gửi để tránh request trùng. Auth thành công tạo hồ sơ; nếu Firestore tạm lỗi, hồ sơ được thử lại khi sync.

Khi đăng nhập và máy có save khách, app hỏi có nhập không. Hủy giữ hai hành trình độc lập; Đồng ý hợp nhất màn mở/thành tích tốt hơn, chỉ lấy state giữa màn nếu tài khoản chưa có state. Bản khách vẫn còn. Hồ sơ cho xem kết quả đã query, Đồng bộ lại và Đăng xuất. UI không cho nhập guest trong Dev Mode.

## Schema và đồng bộ

| Đường dẫn | Dữ liệu |
|---|---|
| `users/{uid}` | displayName, email, createdAt, lastPlayedAt, tutorialCompleted, schemaVersion=3 |
| `users/{uid}/progress/current` | unlockedLevel, currentLevel (ID LV01–LV12), completedLevels, lastSavedAt, saveVersion=3 |
| `users/{uid}/levelResults/{levelId}` | completed, bestStars, bestMoves, bestTimeSeconds, attempts, lastCompletedAt |
| `users/{uid}/syncEvents/{operationId}` | kind, createdAt; receipt bất biến chống retry lặp |

`attempts` trong V3 đếm **lượt hoàn thành được đồng bộ**, không đếm mọi lần vào màn hoặc thử công tắc. Đây là điều chỉnh có chủ ý để không ghi backend mỗi lần chơi/thử; import thành tích guest tính một lượt nhập cho mỗi màn. Thời gian là thời gian session chạy, dừng ở pause/background; không phải thời gian server chứng thực.

Local save vẫn nhận schema 1/2 và thêm outbox/best_seconds tùy chọn. Save tài khoản theo UID; guest giữ key cũ; debug dùng namespace riêng. Firestore không chứa state từng bánh/van/inventory, không ghi mỗi chạm/frame/tick. Cloud chuyển thành tích giữa thiết bị; state giữa màn chỉ nằm local.

Hoàn thành tạo operation ID duy nhất. Transaction đọc receipt trước, hợp nhất max sao/min lượt/min thời gian rồi ghi receipt, nên retry cùng operation không tăng attempts. Unlock/completed chỉ tăng; thiết bị cũ không ghi đè thành tích tốt hơn. Mỗi lần chuyển màn/pause tạo checkpoint được gộp trong outbox local. Network lỗi giữ outbox, thử lại sau 20 giây, khi app resume hoặc bấm Đồng bộ lại. Đăng xuất đợi queue hiện tại; mỗi lần xử lý kiểm tra UID, không đem outbox A sang tài khoản B.

Rules chỉ cho owner; kiểm tra field/type, ID/range và tính đơn điệu, không cho client sửa receipt đã có. Đây **không phải hệ thống chống gian lận**: client vẫn có thể gửi điểm hợp lệ về kiểu nhưng không thật sự chơi; muốn chống gian lận cần backend xác minh.

## Kiểm thử

Khi Emulator đang chạy:

```sh
npm test --prefix tools/firebase
flutter drive --driver=test_driver/integration_driver.dart --target=integration_test/firebase_test.dart --dart-define=FIREBASE_EMULATOR=true -d emulator-5554
flutter drive --driver=test_driver/integration_driver.dart --target=integration_test/account_ui_test.dart --dart-define=FIREBASE_EMULATOR=true -d emulator-5554
```

Không chạy bài test tạo tài khoản lên production. Dùng Emulator/snapshot thiết bị QA; các integration test có thể reset save app. Test Firebase tắt/bật networking qua coordinator để xác nhận outbox rồi retry; chưa phải mô phỏng mọi dạng mất mạng hoặc chấm dứt process giữa một transaction.

## Tham khảo chính thức

- [Flutter setup](https://firebase.google.com/docs/flutter/setup)
- [Flutter Authentication](https://firebase.google.com/docs/auth/flutter/start)
- [Authentication Emulator](https://firebase.google.com/docs/emulator-suite/connect_auth)
- [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions)

Chưa kiểm chứng: email gửi tới hộp thư thật, đồng bộ qua hai điện thoại vật lý. Đã kiểm chứng SDK Android với project test thật, không phải nghiệm thu backend production. Không cần cung cấp khóa quản trị để hoàn thiện các bước này.

## Kiểm thử cloud thật có chủ đích

`integration_test/firebase_cloud_test.dart` chỉ chạy khi opt-in `FIREBASE_CLOUD_TEST=true`, kiểm tra project phải là `mechanica-e9e41`, dùng Firebase apps riêng để không đổi phiên đăng nhập mặc định. Bài test tạo hai tài khoản QA tạm và xóa Auth user trong finally. Không gửi email reset thật.

Bài test in các UID bằng marker `MECHANICA_CLOUD_QA_UID=` để người vận hành dọn riêng `users/<UID>` và các subcollection qua Firebase CLI được cấp quyền. Không đưa lệnh xóa toàn bộ collection/database vào quy trình. Trong lượt kiểm tra 31/10/2026, cả hai nhánh QA đã được dọn; query sau xóa trong log cleanup không còn tài liệu con. Local save QA theo UID cũng được gỡ, guest save không thay đổi.

Log: `docs/evidence/v3/cloud_real_android.log`, `cloud_rules_deploy.log`, `cloud_admin_audit.json`, `cloud_qa_cleanup.log`. Chỉ chạy lại bài này trên project test khi chủ động chấp nhận tạo tài khoản/dữ liệu thử và có quy trình cleanup.
