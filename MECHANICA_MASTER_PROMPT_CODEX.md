# MASTER PROMPT — MECHANICA: BÍ ẨN CỖ MÁY CUỐI CÙNG

> Dành cho Codex (ưu tiên GPT-6 Astra, reasoning High/XHigh). Đây là **lệnh triển khai sản phẩm**, không phải yêu cầu brainstorming, lập kế hoạch rồi dừng. Hãy làm việc trực tiếp trong repository hiện tại, tạo file, chạy công cụ, sinh/tải/chuẩn hóa art, triển khai và kiểm thử. Không được tuyên bố hoàn tất nếu chưa kiểm chứng.

## 0. VAI TRÒ, NHIỆM VỤ VÀ NGUYÊN TẮC CHỐT

Bạn là một nhóm phát triển game indie senior gồm Game Director, Puzzle Designer, 2D Art Director, Technical Artist, Flutter/Flame Engineer, Sound Designer, QA Engineer. Hành động như **một coding agent có quyền làm việc trên filesystem** và thực hiện trọn quy trình trong **một phiên giao việc liên tục**. Không dừng sau khi đưa kế hoạch, viết GDD, tạo khung UI hoặc hoàn thiện một màn demo.

**Mục tiêu bắt buộc:** tạo game giải đố 2D hoàn chỉnh bằng **Flutter + Dart + Flame**, chạy **Android ở chế độ landscape**, **offline**, UI/lời thoại/hướng dẫn/hint **100% tiếng Việt**, gồm **4 chương/12 màn có thể chơi từ đầu tới cuối**, câu đố thực sự vận hành, animation, art chất lượng cao và khác biệt rõ giữa các chương, âm thanh/nhạc nền nếu có asset được phép sử dụng. Không triển khai một ứng dụng kéo nối dây đơn giản, một slideshow ảnh tĩnh hay một mockup giả tương tác.

**Mức ưu tiên khi có xung đột:** (1) Game có thể chạy và người chơi hoàn thành toàn bộ 12 màn; (2) cơ chế logic đúng, có nghiệm, khó dần; (3) art và animation đạt chất lượng game thương mại indie nhỏ; (4) UI/audio/save/UX hoàn thiện; (5) tính năng phụ. Không tự cắt số màn để báo 'done'. Không làm multiplayer, backend, quảng cáo, mua hàng, tài khoản, mạng xã hội, AI chatbot hoặc level editor. Không cần Firebase; save offline là đủ.

**Bắt buộc tự triển khai và kiểm chứng**: inspect môi trường và repo, ghi chú rủi ro, chọn package tương thích thực tế, tạo kế hoạch ngắn trong `docs/PRODUCTION_PLAN.md`, rồi ngay lập tức thực hiện. Nếu công cụ thiếu, tìm phương án hợp pháp tương đương và tiếp tục các phần làm được. Không được giả vờ có công cụ tạo ảnh hoặc giả vờ chạy test. Không hỏi người dùng về quyết định nhỏ; tự chọn theo nguyên tắc ở đây. Không xóa/sửa dữ liệu ngoài phạm vi project. Trước khi thực hiện thao tác có thể phá hủy dữ liệu hiện có, phải bảo toàn hoặc kiểm tra trạng thái. Không đưa key/secret vào repo.

## 1. GAME VISION — GAME DESIGN BIBLE

**Tên:** MECHANICA — Bí Ẩn Cỗ Máy Cuối Cùng.

**Thể loại:** 2D puzzle adventure / mechanical escape room, góc nhìn front-facing 2D, tương tác chạm-kéo-xoay-lắp-gạt, có lớp khám phá căn phòng và lớp zoom-in vào từng máy. Không nhân vật điều khiển di chuyển tự do, không combat. Đây là **game** với luật, mục tiêu, hậu quả, khả năng thắng/thua/chơi lại; không phải app luyện logic dạng sơ đồ AND/OR trên nền trống.

**Cốt truyện ngắn:** Một công trình máy móc cổ đại gồm bốn khu đã ngừng hoạt động. Người chơi lần theo nhật ký kỹ sư vô danh, sửa chữa các hệ thống để khởi động lại Cỗ Máy Cuối Cùng. Kết thúc chương mở thêm bí mật về chức năng thực sự của công trình. Chuyện kể qua bối cảnh, vài mảnh ghi chú và animation môi trường, không qua hội thoại dài. Viết câu chữ tiếng Việt tự nhiên, tiết chế, có không khí bí ẩn.

**Core loop:** Bản đồ chương → vào căn phòng → quan sát dấu vết, đọc mục tiêu → khám phá đồ vật/hotspot → zoom-in vào máy → kéo/gạt/xoay/lắp linh kiện, theo dõi nguyên nhân-hệ quả → kiểm tra điều kiện → nếu sai: phản hồi trực quan, cảnh báo/hỏng tạm thời, undo hoặc reset; nếu đúng: toàn bộ máy chuyển động, hoạt cảnh thắng, mở cửa → kết quả → màn kế. Mỗi level phải có ít nhất một tương tác khám phá trong phòng và một cụm máy tương tác chi tiết; các phần liên kết bằng trạng thái thực.

**Độ khó:** L1 và L2 dạy tương tác nhưng không quá tầm thường; L3–L6 kết hợp 2–3 hệ thống; L7–L9 đòi suy luận chuỗi/không gian/điều kiện; L10–L12 là các câu đố nhiều giai đoạn và có hậu quả khi thao tác sai. Không tăng độ khó bằng cách làm hotspot nhỏ, giấu thông tin bắt buộc, hoặc ép thử ngẫu nhiên. Người chơi luôn có đủ quy tắc hoặc manh mối để suy luận. Mỗi level sau phải giới thiệu biến thể hoặc phối hợp mới, không chỉ đổi màu/trị số.

**Cơ chế hỗ trợ:** gợi ý 3 cấp (C1 nhận diện quy luật, C2 chỉ hệ thống/quan hệ quan trọng, C3 gợi thao tác kế tiếp nhưng không công bố toàn bộ đáp án); undo nếu phù hợp, reset rõ ràng; tiếng Việt. Không dùng năng lượng trả phí/hết lượt rồi chặn chơi. Cho phép bỏ qua tutorial đã xem. Game lưu màn mở khóa, sao/điểm và cài đặt; có thể replay màn.

## 2. ART DIRECTION — ĐIỀU KIỆN NGHIỆM THU CỨNG

**Tuyệt đối không lặp lại lỗi prototype cũ:** không nền màu trơn + hộp chữ AND/XOR + vài đường thẳng; không hình chữ nhật phẳng, nút mặc định Material, icon emoji thay sprite, debug grid chiếm gameplay, hình mockup tĩnh giả game; không lấy một ảnh AI chứa toàn bộ nút và cơ cấu rồi đặt hotspot vô hình phía trên và gọi đó là animation.

**Phong cách chung (Art Bible):** hand-painted / illustrated 2D mechanical puzzle adventure, có texture vật liệu, cạnh bị mài mòn, rivet, bóng đổ, ambient occlusion giả lập, điểm sáng chủ đích, chiều sâu 2.5D bằng layer/parallax nhẹ, readability cao. Học cảm giác từ ảnh tham khảo của người dùng: (1) bánh răng steampunk gỉ sét, (2) sơ đồ logic phân nhánh, (3) câu đố mạch có tính hệ thống, (4) thiết bị khoa học viễn tưởng kim loại chi tiết. **Không sao chép ảnh hay tài sản thuộc game khác**. Dùng ngôn ngữ thiết kế thống nhất: bảng điều khiển kim loại có bevel, viền khắc, phản hồi cơ khí, typography rõ, bố cục 16:9; nhưng palette, vật liệu, prop, light, particles, sound và dạng puzzle khác hẳn theo chương.

**CH1 — XƯỞNG ĐỒNG HỒ / BRASS WORKS:** đồng thau, sắt đen, gỗ sẫm, kim rỉ; vàng hổ phách + đỏ than. Visual: bánh răng có răng thật, trục quay, piston, dây curoa, khóa cửa, hơi nước, mặt đồng hồ, đồng hồ áp, tia lửa nhỏ. Environmental motion: gear spin, steam burst, indicator needle, piston translation.

**CH2 — THƯ VIỆN CHÌM / DROWNED ARCHIVES:** kim loại oxy hóa, kính ướt, rong rêu, ống đồng, bể kính, bọt khí, sàn ướt; xanh ngọc + xanh rêu. Visual: bể chứa có mực chất lỏng thay đổi, van, ống, máy bơm, màng lọc, áp kế. Motion: liquid fill/drain thật trong container, flow particle chạy qua ống, bubble, valve turn, pump vibration.

**CH3 — ĐÀI THIÊN VĂN / PRISM OBSERVATORY:** đá đen, bạc cũ, kính thiên văn, tinh thể, thiên cầu; tím chàm + cyan + ánh trắng. Visual: gương, lăng kính, khe chắn, ống kính, sao, bản đồ chòm sao. Motion: tia sáng thật thay đổi hướng theo ray geometry, glow, glint, rotating lens/ring, star dust.

**CH4 — LÕI VĨNH CỬU / THE LAST CORE:** titan cháy, thép đen, lõi năng lượng, ống lạnh, cảnh báo đỏ; đỏ thẫm + cam nóng + trắng điện. Visual: lõi phản ứng nhiều vòng xoay, buồng từ, quạt, cửa an toàn, buồng làm mát, đèn báo; kết hợp motif 3 chương trước. Motion: energy pulses, turbine ring, coolant flow, safety shutters, progressive power-up cinematic.

**Image/asset production contract:**
1. Trước khi sinh/thu thập art, viết `docs/ART_BIBLE.md`, `docs/ASSET_MANIFEST.csv` và `docs/ASSET_SOURCES.md`. Dùng asset IDs ổn định. Ghi mỗi asset: ID, path, chapter, intended layer/role, kích thước, alpha, anchor/pivot, format, source/generation method, license, trạng thái QA.
2. Nếu có tool tạo ảnh thật: dùng nó để tạo 4 environment master backgrounds + ít nhất 4 lớp trang trí đặc trưng cho mỗi chương và các sprite máy chính, đồng nhất góc nhìn front-on và hướng sáng. Background tách **khung phòng/địa hình** khỏi vùng máy tương tác. Không yêu cầu image model xuất sprite sheet 50 frame không chính xác: tạo **layer riêng**, chuyển động bằng runtime transform hoặc strip chuẩn hóa. Dùng true alpha cho sprite foreground nếu hỗ trợ; nếu không, xử lý masking/crop và kiểm tra viền.
3. Nếu có web: chủ động tìm art/texture/SFX/music thực sự phù hợp, ưu tiên CC0 hoặc license cho phép tích hợp và phân phối; lưu URL, tác giả, giấy phép, attribution nếu cần. Không tải asset từ Pinterest, screenshot game hoặc kết quả tìm kiếm không xác định quyền sử dụng. Không hotlink asset. Không sao chép game thương mại. Không giả định tất cả asset 'free' là dùng lại được.
4. Với artwork hình ảnh AI: kiểm tra mô hình thực sự có tool tạo hình/saving image không. Nếu không có, dùng nguồn asset đã xác minh + composition bằng 2D layering, texture, custom sprites, hiệu ứng shader/particle. **Không âm thầm hạ chuẩn thành giao diện hộp phẳng.** Nếu chất lượng art vẫn không đạt, ghi rõ `ART_GATE: FAIL` trong báo cáo, vẫn hoàn thiện phần code/gameplay có thể làm, không tuyên bố game art hoàn thiện.
5. Tối thiểu tạo: 4 background chương khác nhau thực sự; 12 scene compositions có bố trí và chi tiết khác nhau (có thể tái dùng background chapter nhưng thay props và máy); 8 nhóm thiết bị khác nhau trở lên, mỗi nhóm có trạng thái idle/active/failure; title illustration, chapter cards, 12 level thumbnails, các nút chính custom theo art bible. Không cần 12 bức tranh hoàn toàn độc lập, nhưng tuyệt đối không được 12 màn cùng một layout chỉ đổi màu.
6. Preferred environment art gốc cỡ 1920×1080 hoặc tương đương đúng tỷ lệ 16:9; sprite/kết cấu được export ở độ phân giải đủ đẹp trên điện thoại. Không cố định pixel sizes trong engine: dùng camera/viewport scale phù hợp 16:9 và 19.5:9; safe area, tránh stretch méo. Tối ưu texture, chia layer đúng; không dùng 12 ảnh 4K vô ích gây quá tải bộ nhớ.
7. Tách background (ít chuyển động), props (lớp động), tương tác, VFX, UI; parallax nhẹ có kiểm soát. Audio/visual states phải ánh xạ tới state trong engine, không chỉ playback độc lập.
8. Art QA: đúng camera/góc nhìn, nhất quán shading và đường viền, không chữ lỗi do AI trong ảnh (text overlay render bằng Flutter), sprite không có nền trắng giả, máy/đèn/van có vị trí tương tác khớp hình, không có vật thể thiết yếu bị UI che, art theo 4 chương nhận ra ngay từ thumbnail. Lưu 4 screenshots thật từ game nếu có emulator và xác minh bằng mắt.

**Animation contract:** Bắt buộc có animation runtime nhìn thấy được: gear rotation (đúng chiều theo nối trục), lever flip + spring, button depress, valve rotation, pump piston, flow particle, liquid level easing, beam ray update + glows, warning alarm, door unlock/open, chapter completion. Chuyển động nhất quán vật lý giả lập, tăng tốc/giảm tốc hợp lý, 200–800ms tùy động tác, idle ambient liên tục nhẹ. Không liên tục reset animation mỗi frame. Cho phép giảm chuyển động trong Settings. Không báo animation hoạt động chỉ vì widget có `AnimationController`; phải có runtime behavior và kiểm thử/ảnh/video bằng công cụ khả dụng.

**Audio contract:** Nhạc nền ambient khác nhau cho 4 chương, loop mượt, âm lượng độc lập Music/SFX, mute, lưu setting. SFX cụ thể cho click/switch/metal gear/steam/valve/water/beam/door/win/fail. Audio phải được preload/cache, dừng/tiếp tục hợp lý khi app background/resume, không phát chồng vô hạn. Nếu không thể tải/tạo audio có quyền hợp lệ, ghi thiếu sót trung thực; không chèn file rỗng rồi tuyên bố có âm thanh.

## 3. PUZZLE ENGINE — ĐỘ SÂU THỰC SỰ

Engine thuần Dart, deterministic, data-driven, độc lập render/Flutter/Flame. Có `PuzzleState`, `PuzzleAction`, `PuzzleReducer/Rules`, `PuzzleDefinition`, `Objective`, `Constraints`, `SimulationTick`, `EventLog`, `UndoSnapshot`, `ValidationResult`, `WinCondition`. Dùng model immutable/copy rõ ràng, không viết game logic rải rác trong `onTap` của widget. Mỗi hành động hợp lệ phát ra events -> renderer và audio lắng nghe để phát animation, đảm bảo **UI phản ánh hệ thống, không quyết định thắng thua**.

**Bốn nhóm luật:**
- Mechanical: trục, bánh răng, khớp nối/clutch, tỉ số truyền đơn giản rời rạc, chiều quay, khóa, mô-men theo đơn vị integer; gear network chỉ truyền qua kết nối thực. Có jam/overload khi cấu hình sai và cách reset.
- Hydraulic: tank capacity integer, lượng nước theo discrete tick, van route, pump, filter, contamination/temperature flags nếu dùng; bảo toàn lượng chất lỏng (trừ nguồn/sink được khai báo), không sinh nước từ hư không.
- Optical: ánh sáng như ray/đường đi có hướng, mirror/prism orientation discrete 45°/90°, splitter, filter, shutter, sensor nhận đúng màu/tín hiệu, không phải chỉ đổi màu wire khi chạm; thuật toán ray/grid phải giới hạn vòng lặp.
- Reactor/control: stage prerequisites, interlocks, heat/power/coolant budgets, order dependency, timed ticks rời rạc (có nút Run/Step/Pause), cảnh báo khi vi phạm. Kết hợp các luật đã học ở chương trước, hạn chế trạng thái bùng nổ.

**Luật bắt buộc:** trạng thái đầu xác định, action có precondition, transition xác định, thời gian mô phỏng tách thời gian animation, condition thắng kiểm tra từ dữ liệu, failure có phản hồi và khả năng recover, không có ngõ cụt không thể reset. Chỉ animate gear khi state thực sự quay, đèn khi có điện, fluid khi có flow, beam khi path hợp lệ. Bảo toàn bất biến như mass/energy discrete theo luật đã công bố.

**Solver/QA:** với mỗi màn, tạo một bộ bước giải tham chiếu (solution trace) dưới dạng dữ liệu/test, chạy qua reducer để chứng minh màn giải được. Có thể viết BFS/A*/bounded search cho các puzzle nhỏ để xác nhận và sinh hint nhưng không bắt buộc solver tối ưu cho mọi trạng thái phức tạp; tuyệt đối không giả vờ tìm được nghiệm. Viết test để chống hành động 'thắng' khi thiếu điều kiện, sai thứ tự, vượt tài nguyên, xoay hướng sai. Nếu random chỉ dùng cho VFX/ambient, không ảnh hưởng đáp án. `hint3` phải luôn là bước hợp lệ từ trạng thái hiện tại; nếu không tính được thì dùng hint nguyên tắc, đừng hướng sai.

**Độ khó được kiểm chứng**, không dựa vào số click. Với mỗi màn ghi `introduced_rule`, `required_inferences`, `mechanisms_combined`, `critical_mistake`, `reference_solution`, `target_moves` (chỉ là baseline để playtest, không tự nhận là số tối ưu). Ít nhất màn L7–L12 có 3 quan hệ ràng buộc phụ thuộc hoặc chuỗi quyết định có nhánh sai rõ rệt. Không khóa tương tác bằng một 'đúng trình tự' vô cớ: trình tự đúng phải xuất phát từ luật đã thể hiện bằng đồng hồ, ghi chú, kỹ thuật, phản hồi hoặc môi trường.

## 4. 12 LEVELS — NỘI DUNG CANON BẮT BUỘC

Đúng 4 chương, mỗi chương 3 màn. Đây là **nội dung thiết kế bắt buộc**, bạn có quyền điều chỉnh thông số và sắp đặt nếu cần nhưng phải giữ mục tiêu/cơ chế và lý do suy luận. Mỗi level cần scene thật (room+zoom machine), rules, data, hints 3 cấp, 1 lời giải được engine xác minh, feedback success/failure, art chủ đề.

### CH1 — XƯỞNG ĐỒNG HỒ (ĐỒNG THAU / CƠ KHÍ)
**L01 — Tia lửa đầu tiên:** Người chơi phát hiện nguồn quay bị ngắt, phải lắp bánh răng vào đúng hai chốt, xác định chiều quay của trục ra và mở chốt an toàn trước khi kéo cần. Không chỉ chạm nút: đầu ra phải đạt chiều và tỷ số tốc độ được ký hiệu bằng biểu tượng trên máy. Sai hướng -> khóa chống ngược bật và dừng máy; reset được. Dạy quan sát manh mối khắc trên khung, kéo thả và rotate.

**L02 — Đồng hồ không kim:** Ba nhánh trục truyền đến các mặt số; dùng clutch để lần lượt căn kim đúng ba mốc, nhưng mỗi clutch kết nối/khóa các bánh răng khác nhau. Mỗi lần đổi clutch có ảnh hưởng tới trục khác; muốn thắng phải giữ các mốc đúng đồng thời và kích hoạt ổ khóa cuối. Dạy hệ phụ thuộc và thứ tự thao tác có ý nghĩa.

**L03 — Trái tim lò hơi:** Kết hợp truyền động, van hơi và đồng hồ áp. Phải nâng áp vào vùng an toàn, bật bộ truyền lực đúng lúc và mở cửa trước khi quá áp. Sai thao tác gây xả hơi/reset áp và tăng lượt, không phá save; có giới hạn budget/tick rõ ràng, gauge đọc được, có giải pháp kiểm chứng. Cửa là hoạt cảnh kết thúc chương.

### CH2 — THƯ VIỆN CHÌM (THỦY LỰC / CHẤT LỎNG)
**L04 — Bình cân bằng:** Hệ bể dung tích khác nhau, ống chuyển, van chiều, một máy bơm. Đạt đúng lượng nước ở hai cảm biến và giữ bể thứ ba dưới ngưỡng. Người chơi quan sát vạch đo và điều khiển transfer/tick. Phải mô hình hóa lưu lượng theo integer và conservation.

**L05 — Nước qua ký ức:** Hai nguồn nước (sạch/bẩn), bộ lọc có số lượt sử dụng hữu hạn, hai bể cần nước sạch với lượng khác nhau. Phải quyết định tuyến đường, tránh làm ô nhiễm đích và tránh dùng cạn bộ lọc. Luật chất lượng nước/filtration hiển thị bằng biểu tượng màu + ký hiệu, không chỉ màu.

**L06 — Cánh cửa thủy áp:** Ba khoang áp liên thông qua các van, có các gate khóa liên động và mức tràn nguy hiểm. Phải cân bằng đúng hai khoang để mở khóa, sau đó rút nước ở khoang cửa trước khi cửa mở; thao tác sai kích hoạt emergency relief và đưa về checkpoint. Kết hợp sequence, level, safety.

### CH3 — ĐÀI THIÊN VĂN (QUANG HỌC / KHÔNG GIAN)
**L07 — Con mắt ánh sáng:** Một beam source, mirror rotatable, shutter, hai sensor có ký hiệu hướng nhận. Người chơi định tuyến ánh sáng qua không gian bằng xoay gương, mở/đóng shutter đúng logic. Đích chỉ kích hoạt nếu tia đến đúng hướng và sensor không bị chặn; đường tia vẽ cập nhật thật.

**L08 — Sắc phổ vỡ:** Nguồn sáng đi qua splitter/filter, phải cấp đúng màu cho ba sensor, tránh tia cường độ mạnh đụng fragile crystal. Dùng mô hình màu rời rạc/bitmask định nghĩa rõ, không giả vật lý chính xác nếu engine không mô phỏng; có bảng ký hiệu để người chơi suy luận quy tắc.

**L09 — Bản đồ tinh tú:** Nhiều vòng gương và hai shutter, có một lần đổi pha theo `Step`. Người chơi phải thiết lập đường sáng ở pha A, khóa một sensor rồi thay cơ cấu cho pha B sao cho cả hai nhớ trạng thái cần thiết. Có kiểm tra thứ tự thật và manh mối trong bản đồ sao, không phải bấm theo sequence bí mật không giải thích.

### CH4 — LÕI VĨNH CỬU (HỆ THỐNG TỔNG HỢP)
**L10 — Vòng tuần hoàn:** Nguồn điện cấp pump, coolant giảm heat, reactor cần đủ power nhưng không được quá nhiệt. Người chơi nối trục truyền động/pump, chọn van coolant và lập trình các bước `Run/Step` để đạt target. Có gauges power, heat, flow; các ngưỡng rõ, khi sai kích hoạt automatic shutdown.

**L11 — Ba khóa an toàn:** Ba interlock thuộc cơ khí, thủy lực và quang học. Mỗi khóa phải thỏa điều kiện và duy trì ổn định khi kích hoạt latch; nếu bật sai thứ tự sẽ reset một phần hệ thống nhưng người chơi hiểu vì sao. Có nhật ký kỹ sư cho manh mối. Không dùng ba nút giả định sẵn đáp án.

**L12 — Cỗ máy cuối cùng:** Multi-stage final puzzle: (A) hiệu chỉnh truyền động + áp suất; (B) định tuyến quang năng + bật làm mát; (C) giữ reactor trong vùng an toàn qua N simulation ticks và xác nhận interlocks. Người chơi thấy toàn bộ hệ thống lớn với nhiều cụm zoom-in, phải kết nối kết quả của các cụm; puzzle có ít nhất hai quyết định tương tác giữa các giai đoạn, không chỉ ba mini-game tách rời. Khi thắng phát cinematic khởi động, title kết game và có thể replay.

**Lưu ý cân bằng:** 12 màn là 12 level đầy đủ; không thay bằng 'coming soon' hay cửa đã mở từ đầu. Có thể chuyển thông số sang JSON để dễ điều chỉnh. Mọi reference solution phải được test tự động, riêng L12 test end-to-end. Nội dung gợi ý phải là tiếng Việt và tương ứng trạng thái.

## 5. NAVIGATION, MÀN HÌNH VÀ UX

Cần các scene/screen hoàn chỉnh: (A) Splash/loading với logo tự thiết kế, (B) Home art-rich gồm Chơi tiếp / Chọn chương / Cài đặt / Thoát nếu Android phù hợp, (C) Chapter selection 4 card hình riêng và trạng thái unlock, (D) Level selection 12 thumbnails, (E) Room scene có camera pan/zoom kiểm soát, hotspot highlight khi người chơi chọn, (F) close-up machine puzzle với back, goal, controls, undo/reset/hint, (G) pause menu, (H) success/victory với stats và next, (I) final cinematic/credits, (J) tutorial tiếng Việt contextual; không overlay 10 nút trên máy.

**Onboarding:** L01 hiện tooltip tương tác ngắn, minh họa bằng cử chỉ động: chạm quan sát → kéo gear → xoay gear → gạt cần. Các tutorial tiếp theo chỉ hiện khi luật mới xuất hiện (van, chất lỏng, gương, tick). Cung cấp màn 'Cách chơi' mở lại được trong Settings: thao tác, biểu tượng trạng thái, reset/hint và giải thích game không yêu cầu kiến thức điện tử trước. Không dùng tiếng Anh trong giao diện, kể cả thông báo lỗi/hint.

**Mobile landscape:** landscapeLeft/Right, camera design size chuẩn 16:9, viewport expand/letterbox art-directed ở màn hình dài, giữ aspect ratio sprite/máy; hit targets >= 44 logical px nếu thiết kế cho touch; pinch zoom/drag pan không xung đột kéo linh kiện; tooltip không che điểm cần bấm; SafeArea cho cutout. Mọi màn hoạt động ở ít nhất hai tỷ lệ giả lập (16:9 và 19.5:9 landscape), không overflow. Back của Android mở pause/đóng zoom đúng cách, không mất tiến trình. Settings: âm lượng Music/SFX, giảm chuyển động, reset tiến trình có xác nhận.

**Feedback:** mỗi thao tác thành công nhận phản hồi ngay; hành động không hợp lệ có rung/đèn/bong bóng cảnh báo và giải thích ngắn, không im lặng. Màn thắng phải có payoff: máy thật sự hoạt động, cơ cấu cửa/màn đổi, không chỉ AlertDialog('Win'). Hướng dẫn từng màn có goal rõ và cách hiểu các biểu tượng, không tiết lộ đáp án. Hint mở dần C1→C2→C3 theo nút có xác nhận/đếm; không khóa bằng quảng cáo.

**Ratings:** 1–3 sao theo lượt di chuyển/undo/hint hoặc số lỗi, nhưng chơi xong luôn được mở màn kế. Thresholds là design baseline cần test, không áp mức phạt gây khó chịu. Lưu best score, unlock, tutorial state; game hoàn toàn offline.

## 6. KIẾN TRÚC FLUTTER + DART + FLAME

- Dùng phiên bản stable Flutter/Dart có thật trên máy; kiểm tra `flutter --version`, `flutter doctor`, `dart --version`, chọn Flame stable tương thích qua package manager, không hardcode package phiên bản không tồn tại. Nếu repo trống thì `flutter create` chuẩn Android. Nếu repo có code cũ thì inspect trước, tránh xóa bừa.
- Flutter quản lý shell, overlays, menus, route/navigation, settings, dialog, typography, accessibility. Flame quản lý game loop, scene/camera, components, input mapping, layer, sprites, effects, particles. Việc sử dụng Flame có thể tối giản nhưng phải có GameWidget/game world thật, tránh hack toàn bộ thành một Widget khổng lồ.
- Domain engine là Dart thuần, không import Flutter để dễ test. Render adapters nhận `GameEvent`/`PuzzleState`, update sprite/effects, âm thanh qua event bus rõ ràng. Input map từ màn hình sang world/local machine coordinates, tránh phụ thuộc scale.
- Modular folders gợi ý:
```
lib/
  main.dart
  app/ (bootstrap, theme, navigation, settings)
  core/ (IDs, persistence, events, asset registry, audio)
  game/
    mechanica_game.dart
    scenes/ (room, machine, chapter, cinematic)
    components/ (interactive parts, sprites, gauges, wires, particles)
    mechanics/ (gears, shafts, hydraulic, optical, reactor)
    puzzles/ (state, reducer, action, rules, validation, objectives, hints)
    levels/ (level definitions, loader, schemas)
    rendering/ (chapter art layers, animation triggers, transitions)
  ui/ (home, chapter selector, level selector, settings, overlays, tutorial)
assets/
  images/ (chapters/{brass,water,prism,core}, devices, ui, effects)
  audio/ (music, sfx)
  data/ (levels, hints, script)
test/ (domain, level-solutions, persistence, widgets)
integration_test/ (if environment supports)
docs/ (GDD, ART_BIBLE, manifest, GUIDE, QA, limitations)
AGENTS.md
README.md
```
- Canonical IDs: `CH01...CH04`, `LV01...LV12`, `MCH_*`, `ACT_*`, `ART_*`, `SFX_*`, `HINT_*`; mỗi ID xác định 1 ý nghĩa. Data file là Source of Truth; không hardcode rải rác một level trong widget. Có schema validation duplicate IDs, missing asset references, invalid level graph, missing hint/solution.
- Persistence: local only, chọn `shared_preferences` nếu chỉ cần dữ liệu đơn giản hoặc phương án local ổn định được kiểm tra; cấu trúc `save_version`, unlocked levels, best results, settings, hint usage và serialized state khi resume nếu an toàn. Atomic save/migration tối thiểu, không mất dữ liệu khi app tạm dừng. Không yêu cầu Firebase hay kết nối Internet.
- Audio: dùng package tương thích thực tế (`flame_audio` hoặc tương đương) và lifecycle. Giữ gameplay độc lập khi sound disabled hoặc thiếu audio, log truthful QA.
- Performance: chỉ repaint/compute khi cần; pre-cache texture của chapter đang chơi, unload chương cũ, tránh allocate trong tick; không gọi disk IO trong update loop, không tạo particles vô hạn; đặt 60fps làm mục tiêu chứ không tự tuyên bố đạt nếu không profile.
- Code maintainable, constants, typed models, no dynamic spaghetti, tránh dependency lớn không cần. Không chèn AI model hay gọi external API trong gameplay.

## 7. GAME STATE, ANIMATION VÀ PHẢN HỒI

Mỗi action thực hiện theo pipeline duy nhất:
`Touch/Drag/Rotate -> HitTest -> Validated Action -> Reducer -> New PuzzleState + DomainEvents -> Animation/SFX/HUD -> Win/Failure check -> Save if necessary`.
Ví dụ `RotateValve(V2, +90°)` -> validate có thể xoay -> state valve orientation mới -> `ValveRotated` -> sprite tween quay -> cập nhật network -> `FluidFlowChanged` -> fluid particle/tank fill diễn hoạt -> condition eval. Hạn chế animation blocking gây double input: lock component ngắn hoặc queue actions theo chính sách rõ ràng; animation completion không phải nguồn sự thật logic.

Create scene transitions: room idle breathing, camera dolly vào máy, bật bảng điều khiển bằng metal slide, puzzle solved machinery cascade, cửa mở + dust light, chapter completion. Bắt buộc có một cinematic đặc biệt ở L12. Nếu người chơi bật Reduce Motion thì rút ngắn transform/particles nhưng vẫn rõ trạng thái. Không dùng `Timer` vô hạn không dispose; pause/resume lifecycle chuẩn.

## 8. TẠO ASSET, LICENSE VÀ CHẤT LƯỢNG THỊ GIÁC

**Workflow bắt buộc**:
1. Khóa GDD (chỉ vừa đủ code), Art Bible, asset IDs trước sinh asset.
2. Kiểm tra tool có thể dùng thật (image generation/web/downloader, thư viện hình, audio). Không tự tuyên bố 'đã tạo' nếu chưa có file hợp lệ trên đĩa.
3. Tạo/tải background theo từng chương, kiểm tra tỷ lệ và độ phân giải, rồi tách máy/props thành layer có thể động. Dùng scripts (Pillow/ImageMagick/SVG) khi cần crop, alpha cleanup, chuẩn hóa anchors; không biến mọi thứ thành hình vẽ vector tối giản nếu user yêu cầu hand-painted textured art.
4. Tạo `assets/manifest.json` hoặc CSV + registry; integrity script xác minh file tồn tại, decode hình được, alpha tương thích, nguồn/license rõ.
5. Tích hợp mỗi nhóm art vào engine, xem screenshot in-game của cả 4 chương, sửa contrast/pivot/readability.
6. Phong cách GUI thống nhất (font Việt có đầy đủ dấu, nút/khung chủ đề cơ khí, high-contrast labels), không để typography khó đọc do texture rối.

**Quy tắc cấm:** không đưa ảnh concept collage vào làm scene duy nhất; không ship watermark; không dùng asset thuộc IP khác nếu chưa rõ quyền; không fake animation bằng đổi opacity toàn màn; không dùng assets tạm vô thời hạn hoặc 'TODO' mà đánh dấu done. Nếu không thể tạo đúng asset chất lượng, báo blocker cụ thể và làm phần còn lại, không làm sai lệch chất lượng mục tiêu.

## 9. QUY TRÌNH MỘT LƯỢT CHẠY — THỰC HIỆN, KHÔNG DỪNG Ở KẾ HOẠCH

### Phase 0 — Discovery (ngắn)
Inspect repository, tools, Flutter/Android SDK, khả năng image generation/web/audio, phiên bản package. Tạo `docs/PRODUCTION_PLAN.md` với dependencies, art strategy, game architecture, acceptance test, và bảng blocker. Phải chuyển tiếp ngay Phase 1 trong cùng lượt.

### Phase 1 — Source of Truth
Tạo `docs/GDD.md`, `docs/ART_BIBLE.md`, `docs/LEVEL_MATRIX.md`, `docs/ASSET_SOURCES.md`, asset manifest, IDs/schemas, level specs và solution tests. Ưu tiên *contract có thể chạy được*, không viết tài liệu dài thay cho code. Lập bảng check 12 level.

### Phase 2 — Runtime & Visual Foundation
Initialize Flutter/Flame, game router, 4 chapter themes, asset loading, camera/layout, audio, saves, error handling, custom UI, scene room/zoom machine. Đưa một background chất lượng thật, máy có animation thật vào game trước khi nhân bản hệ thống; sau khi tích hợp ổn định, tiếp tục không dừng yêu cầu review.

### Phase 3 — Mechanic Engine
Implement deterministic reducers và components cho mechanical/hydraulic/optical/reactor, unit tests; event-to-animation adapters; action history, undo/reset; solver traces. Không viết 12 màn với logic riêng không thể tái sử dụng.

### Phase 4 — Twelve Levels
Author `LV01...LV12` data, rooms, machine zoom scenes, goal/hint/solution, visual/sound cues, animations. Implement 3 màn/chương và chapter unlock. Sau mỗi chapter chạy solver/reducer tests và playability smoke tests. Không dùng same-layout recolor cho các chapter.

### Phase 5 — Polish
Integrate 4 distinct chapter soundtracks/ambience nếu có quyền dùng; SFX, UI animations, cutscene finale, onboarding/contextual tutorials, accessibility, settings, high-quality buttons/panels, save best results, icon/splash.

### Phase 6 — Verify & Repair
Run `dart format`, `flutter analyze`, `flutter test`, `flutter build apk --debug` (hoặc release khi môi trường phù hợp). Chạy integration test/emulator nếu có; thực sự launch trên Android nếu có device/emulator. Lặp fix lỗi, kiểm tra log build. Trên môi trường có visual capability, capture screenshot của Home, CH1, CH2, CH3, CH4, L12 và kết thúc; kiểm tra từng screen, sửa art/clipping. Không gắn nhãn PASS cho điều chưa chạy.

### Phase 7 — Delivery
Đảm bảo source runnable, hướng dẫn thật trong `README.md` gồm prerequisites, cài Flutter, `flutter pub get`, `flutter run`, `flutter build apk`, nơi đặt assets, giấy phép, cách chơi tiếng Việt, sơ đồ kiến trúc, mô tả logic các chương. Viết `docs/QA_REPORT.md` tách `PASS`, `FAIL`, `NOT RUN` với lệnh, bằng chứng, giới hạn. Viết `docs/FINAL_HANDOFF.md` tóm tắt file, gameplay, 12 level, screenshots, asset provenance, build output path **chỉ nếu file thực sự tồn tại**, blocker chưa giải quyết.

Nếu phiên bị giới hạn công cụ/thời lượng/hạn mức: ưu tiên sản phẩm có thể chạy > lượng documentation, tiếp tục triển khai thay vì dừng để hỏi; **không lách** các tiêu chí bằng cách báo chưa triển khai thành hoàn thiện. Để lại source, logs, checklist chính xác và mô tả hạn chế.

## 10. TEST MATRIX VÀ GATES — TUYỆT ĐỐI KHÔNG GIẢ MẠO

**Gate ENGINE:** reducer unit tests deterministic; illegal action rejected, undo/reset đúng, no negative fluid, optical loops terminated, clutches/gear direction consistent, cross-system prerequisites enforced, stable win/fail.

**Gate LEVELS:** tất cả 12 level loader pass schema, solution trace runs from fresh state to win, không thể thắng ngay khi vào, mọi level có ít nhất 3 hints tiếng Việt, path đầu/cuối full playthrough, không dead-end không reset. L12 end-to-end reference solution pass.

**Gate UI:** landscape Android, back navigation, paused state, hints, reset confirm, volume/mute/reduced-motion, level unlock, no clipped text tiếng Việt, touch targets, animation event mapping. Chụp màn hình nếu có thiết bị.

**Gate ART:** 4 biome art distinct, 12 compositions distinct, interactive devices có sprite/illustration chất lượng và states, no plain boxes as core graphics, texture/shadow/layers consistent; 4 chapter screenshots được review, provenance rõ.

**Gate SOUND:** music/SFX thực sự có playable audio files và trigger, background app pause works; if no license-compliant assets, sound remains FAIL/PARTIAL, not silently PASS.

**Gate BUILD:** `flutter analyze` không error; `flutter test` pass; `flutter build apk --debug` pass, Android launch smoke tested nếu emulator/device available; không tự nói 'APK hoàn chỉnh' nếu build chưa chạy.

**Gate PERFORMANCE:** không leak animation controller, không infinite particle growth, không crash khi đổi nhanh levels và background/foreground. FPS/performance chỉ ghi con số nếu có profiling thật.

**Tối thiểu 12 test nghiệm thu hành vi:** mỗi màn 1 trace solve + 1 trace sai; và test gián đoạn khi puzzle chưa xong, reset giữa animation, double tap switch, pause/resume, screen scaling, missing asset handling, save/reload. Report tất cả theo severity BLOCKER/MAJOR/MINOR.

## 11. GHI CHÚ CHO AGENT KHI DÙNG REFERENCE

- Nếu repo có 4 ảnh reference và file `So_Tay_AI_Game_2D_Prompt_Godot_Production(2).docx`, hãy đọc như tài liệu workflow, **không thay Flutter bằng Godot**, không copy class/NPC/combat không liên quan. Tham khảo nguyên tắc Art Bible, stable IDs, contract, QA, source of truth.
- Đánh giá bằng game runtime, không bằng mockup AI. Hình đẹp nhưng game không hoạt động = FAIL. Code chạy nhưng nền phẳng/hộp vuông thiếu art = ART FAIL. 12 level lặp quy tắc không có tiến triển = DESIGN FAIL.
- Không giả tạo benchmark, license, asset nguồn, screenshot, test kết quả. Không tạo nhiệm vụ 'user must manually source sprites'. Tự giải quyết art trong phạm vi công cụ cấp; ghi blocker chỉ khi thực sự không thể.
- Không ngắt phiên để xin phép lựa chọn phong cách/phiên bản phụ thuộc nhỏ. Chỉ hỏi nếu bắt buộc vì thiếu quyền truy cập, tài khoản hoặc secret. Bản chất game offline không cần các thứ đó.

## 12. DEFINITION OF DONE VÀ ĐẦU RA CUỐI

**Chỉ coi Mechanica hoàn chỉnh nếu:** có thể mở Android app, vào menu tiếng Việt, chơi 12 màn thật ở 4 chương, thao tác máy theo luật, nhận feedback hình/âm, thất bại rồi phục hồi, gợi ý đúng, thắng từng màn, mở khóa chương, xem kết thúc, quay về menu, lưu tiến trình; đồ họa đủ chi tiết và riêng biệt của mỗi biome; có animations observable; unit/integration/build evidence minh bạch và source sạch.

Khi kết thúc, trả lời ngắn gọn bằng tiếng Việt theo mẫu:
1. `DELIVERED`: những gì thực sự chạy (số chương/màn, cơ chế, art, audio).
2. `VERIFICATION`: lệnh đã chạy và pass/fail/not-run; đường dẫn APK chỉ nếu APK thật tồn tại.
3. `ART & LICENSE`: asset nào tự tạo/nguồn hợp lệ, khác biệt 4 chương, điều chưa đạt.
4. `HOW TO RUN`: 3–5 lệnh chạy thực tế.
5. `BLOCKERS`: tất cả thiếu sót trung thực, đặc biệt nếu ART_GATE/BUILD_GATE/LEVEL_GATE FAIL.

**BẮT ĐẦU THỰC THI NGAY. Không kết thúc bằng kế hoạch, wireframe, vài widget hoặc đề nghị người dùng tìm asset.**
