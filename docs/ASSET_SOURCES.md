> **Thông tin bàn giao:** Nguồn/phương pháp phát triển được giữ để tra cứu lịch sử; mục audio 24 giây thuộc Phase 1. Kiểm kê và credit hiện hành: [ASSET_CREDITS](ASSET_CREDITS.md).

# Nguồn và quyền sử dụng asset

## Hình ảnh đã tích hợp

Tạo riêng bằng công cụ `image_gen`: bốn căn phòng, bốn kit 2×2 (tách thành 16 sprite alpha) và khu vườn kết thúc. Không tải stock không rõ nguồn; không sử dụng pixel từ bốn ảnh tham chiếu trong bản build. Đây là đầu ra AI tạo riêng, **không gắn nhãn CC0 và không bảo đảm tính độc quyền**.

- `assets/images/chapters/brass/`: đồng thau, gỗ óc chó, ánh hổ phách, piston.
- `assets/images/chapters/water/`: đồng ôxy hóa, kính ướt, rêu, bình chứa và van.
- `assets/images/chapters/prism/`: đá tối, bạc, tím chàm, gương và tinh thể.
- `assets/images/chapters/core/`: titan cháy, đèn đỏ, turbine và buồng làm lạnh.
- `assets/images/ui/ending.png`: khu vườn dưới lòng núi.

`tools/prepare_art.py` chuẩn hóa kích thước và tách alpha. `tools/art_sources.json` và `tools/ending_source.json` ghi đường dẫn nguồn tạo tại máy phát triển; các đường dẫn này không cần tồn tại để build. Asset chuẩn hóa đã nằm trong project. Các atlas nguồn lớn chưa được đóng gói lại trong repository.

Icon là composition từ bánh răng đã tạo và chữ M render bằng Noto Serif. Chapter cards là crop từ phòng. **12 thumbnail màn chơi được crop từ screenshot Android thật**, bằng `tools/runtime_thumbnails.py`. Nước, tia sáng, chốt, kim, nút, bụi và cửa là đồ họa runtime tự viết, không phải hiệu ứng có sẵn trong tranh nền.

Prompt contract và nội dung cảnh được lưu ở `ART_PROMPTS.json` và `ART_BIBLE.md`; chúng là bản tóm tắt sản xuất, không tuyên bố tái tạo chính xác đầu ra sinh ảnh bằng seed.

## Âm thanh đã tích hợp

`tools/generate_audio.py` tổng hợp riêng bốn vòng ambient 24 giây và 11 SFX từ dao động/nhiễu có seed. Không dùng bản ghi, sample, nhạc hoặc giọng nói của bên thứ ba. WAV PCM thật nằm trong `assets/audio/`. Việc phát file/trigger được kiểm tra trên Android; chưa có thẩm định nghe trên nhiều loa/tai nghe.

## Phông chữ

Noto Sans và Noto Serif tải từ repository Google Fonts chính thức:

- https://github.com/google/fonts/tree/main/ofl/notosans
- https://github.com/google/fonts/tree/main/ofl/notoserif

Giấy phép **SIL Open Font License 1.1** được giữ nguyên trong `assets/fonts/NotoSans-OFL.txt` và `NotoSerif-OFL.txt`, có đóng gói cùng ứng dụng.

## Phụ thuộc và kiểm kê

Phiên bản thư viện cài thật nằm ở `pubspec.lock`; Flutter cung cấp registry license của các package. `ASSET_MANIFEST.csv` / `assets/manifest.json` kiểm kê mọi asset ship (74 mục), phương pháp, định dạng, alpha, kích thước và SHA-256. Chạy `python tools/update_manifest.py` sau thay đổi asset; `python tools/verify_assets.py` xác minh file và coverage.

Tài liệu DOCX và ảnh trong `references/` chỉ dùng nghiên cứu workflow/art direction; không suy diễn rằng chúng được cấp phép phân phối.


## Bổ sung Phase 2

8 sprite alpha mới được tạo bằng imagegen tích hợp và dùng trực tiếp trong phòng/túi đồ; nguồn và hợp đồng prompt ở [PHASE2_ART_SOURCES.json](PHASE2_ART_SOURCES.json). Nhạc bốn chương được thay bằng bản tổng hợp gốc 32 giây; 8 SFX mới bổ sung cho tổng 19 SFX. Chạy `tools/upgrade_audio.py` sau `tools/generate_audio.py` để giữ bản Phase 2. Chi tiết file/giấy phép ở [PHASE2_AUDIO_MANIFEST.json](PHASE2_AUDIO_MANIFEST.json) và manifest SHA-256 hiện hành.
