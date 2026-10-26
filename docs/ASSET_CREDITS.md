# Asset credits và nguồn tài nguyên

Tài liệu mô tả 74 file trong `assets/manifest.json`; manifest không tự tính vào 74 mục. Bản kê từng đường dẫn, kích thước, phương pháp và SHA-256: [ASSET_MANIFEST.csv](ASSET_MANIFEST.csv). Không đặt một license chung thay cho quyền của từng thành phần.

## Hình ảnh

| Nhóm | File / vị trí | Nguồn và phương pháp | Ghi nhận quyền |
|---|---|---|---|
| Xưởng Đồng Hồ | `assets/images/chapters/brass/` | Background, bốn prop và chapter card tạo riêng bằng image_gen; chuẩn hóa/crop bởi tools dự án | Output AI tạo riêng; không CC0, không cam kết độc quyền |
| Thư Viện Chìm | `assets/images/chapters/water/` | Đồng ôxy hóa, kính, nước và rêu tạo riêng | Như trên |
| Đài Thiên Văn | `assets/images/chapters/prism/` | Đá tối, bạc, gương và tinh thể tạo riêng | Như trên |
| Lõi Vĩnh Cửu | `assets/images/chapters/core/` | Kim loại cháy, turbine và làm lạnh tạo riêng | Như trên |
| Vật thể phòng / túi đồ | `exploration/cabinet.png`, `notebook.png`, `key.png`, `coupler.png`, `hose.png`, `filter.png`, `gasket.png`, `fuse.png` | Hai atlas imagegen, tách alpha và căn khung 512×512 | Output AI tạo riêng, không CC0 |
| Kết thúc | `assets/images/ui/ending.png` | Khu vườn tạo riêng bằng image_gen | Output AI tạo riêng |
| Launcher icon / UI | File UI trong manifest, icon Android trong `mipmap-*` | Composition/crop từ art dự án; chữ M dùng Noto Serif | Theo nguồn art và font |
| Thumbnail màn | `assets/images/ui/lv01.png`–`lv12.png` | Crop screenshot Android thật bằng `runtime_thumbnails.py` | Bản dựng từ hình ảnh/UI dự án |
| Ảnh tài liệu | `docs/screenshots/*.jpg` | Screenshot Phase 2 chạy thật, thu nhỏ/nén để xem trên GitHub | Theo thành phần art và font trong ảnh |
| Đồ họa runtime | Nước, tia, kim, ống, chốt, hạt và cửa | Renderer/effects do source dự án vẽ | Mã nguồn dự án; chưa đặt license tổng thể |

Tên chính xác của cả 46 PNG nằm trong manifest. Prompts và provenance: [ART_PROMPTS.json](ART_PROMPTS.json), [ART_BIBLE](ART_BIBLE.md), [PHASE2_ART_SOURCES.json](PHASE2_ART_SOURCES.json), `tools/art_sources.json`, `tools/ending_source.json`.

Hai atlas Phase 2 giữ tại `art_sources/phase2/`, không được pubspec đóng gói. Một số đường dẫn tạo ảnh Phase 1 thuộc máy tác giả và chỉ có giá trị provenance; build sử dụng các asset chuẩn hóa có sẵn trong `assets/`.

## Nhạc nền gốc

Không dùng nhạc Pixabay, Freesound, Kenney hoặc soundtrack thương mại. Âm thanh được tổng hợp bằng dao động/nhiễu có seed trong source dự án, không chứa sample hoặc giọng hát bên thứ ba. Ghi nhận: **original project audio, no samples**; chưa phát hành dưới license mở riêng.

| File trong `assets/audio/music/` | Tên | Nội dung | Định dạng |
|---|---|---|---|
| `ch1.wav` | Nhịp người thợ vắng | Nốt mềm kiểu piano, tích tắc, kim loại | PCM mono 22.05 kHz, 16-bit, 32 giây |
| `ch2.wav` | Những trang dưới nước | Drone trầm, giọt nước, tiếng ngân | Như trên |
| `ch3.wav` | Bầu trời ghi nhớ | Pha lê, chuông và tiếng vọng | Như trên |
| `ch4.wav` | Hơi thở dưới lòng núi | Drone thấp, nhịp máy chậm | Như trên |

Pipeline hiện hành: `tools/generate_audio.py` **rồi** `tools/upgrade_audio.py`. Tên, thời lượng và nguồn ghi tại [PHASE2_AUDIO_MANIFEST.json](PHASE2_AUDIO_MANIFEST.json). Chạy script Phase 1 riêng lẻ sẽ thay BGM bằng bản cũ.

## Hiệu ứng âm thanh

19 WAV trong `assets/audio/sfx/`; đều tổng hợp gốc, không sample:

| Tên file | Vai trò |
|---|---|
| `click.wav` | Nút UI |
| `switch.wav` | Gạt/chuyển vị trí |
| `metal.wav` | Va/lắp kim loại và hoàn tác |
| `gear.wav` | Bánh răng |
| `steam.wav` | Hơi nước |
| `valve.wav` | Van |
| `water.wav` | Dòng nước |
| `beam.wav` | Tia sáng |
| `door.wav` | Cửa mở |
| `win.wav` | Hoàn thành |
| `fail.wav` | Thao tác sai / cảnh báo |
| `inventory.wav` | Mở/đóng túi |
| `pickup.wav` | Nhặt đồ |
| `clue.wav` | Ghi nhận manh mối |
| `latch.wav` | Chốt / lắp bộ phận |
| `transition.wav` | Chuyển trang |
| `motor_start.wav` | Máy bắt đầu chạy |
| `motor_stop.wav` | Máy dừng |
| `jam.wav` | Cơ cấu kẹt |

## Font bên thứ ba

| Tên | File | Tác giả / nguồn | Giấy phép đi kèm |
|---|---|---|---|
| Noto Sans | `assets/fonts/NotoSans.ttf` | The Noto Project Authors; [Google Fonts](https://github.com/google/fonts/tree/main/ofl/notosans) | [NotoSans-OFL.txt](../assets/fonts/NotoSans-OFL.txt), SIL OFL 1.1 |
| Noto Serif | `assets/fonts/NotoSerif.ttf` | The Noto Project Authors; [Google Fonts](https://github.com/google/fonts/tree/main/ofl/notoserif) | [NotoSerif-OFL.txt](../assets/fonts/NotoSerif-OFL.txt), SIL OFL 1.1 |

Hai license ghi Copyright 2022 The Noto Project Authors, được giữ nguyên và khai báo đóng gói trong pubspec. Flutter Material Icons và package dùng license do Flutter/pub cung cấp; `cupertino_icons` có trong lockfile. Không nhận tác quyền thư viện hoặc font này.

## Tư liệu không phân phối

Bốn ảnh và DOCX trong `references/`, cùng bản trích `reference_workflow.txt`, phục vụ nghiên cứu. Chưa xác minh quyền tái phân phối nên `.gitignore` loại chúng khỏi GitHub; pubspec không đóng gói. Không xóa bản local. Master prompt, GDD, Art Bible và báo cáo thiết kế được giữ.

## Kiểm kê

4 BGM + 19 SFX + 46 PNG + 2 TTF + 2 license + 1 JSON màn chơi = **74 file**. `python tools/verify_assets.py` kiểm tra alpha, WAV không rỗng, hash và coverage. APK cuối được đối chiếu hash với toàn bộ 74 mục.
