# Gameplay và tiến trình

## Mục tiêu và nhịp chơi

Khám phá 12 căn phòng thuộc bốn chương, sửa thiết bị rồi giải cơ chế mở cửa. Một màn gồm quan sát → đọc manh mối ở vị trí khác → tìm đồ → ghép nếu cần → lắp bộ phận → vận hành và quan sát → mở cửa. Mỗi màn chỉ dùng vật phẩm của chính màn đó.

Sáu vùng trong dữ liệu phòng: lời nhắn người thợ, manh mối, ngăn dụng cụ, vật thể phụ, chỗ sửa và bộ máy chính. Hotspot ở vị trí sprite trong cảnh; menu debug có thể hiện rectangle để kiểm tra.

## Điều khiển

| Thao tác | Hành vi |
|---|---|
| Chạm đồ vật | Mở quan sát/ghi manh mối hoặc nhìn gần máy |
| Chạm món trong Túi đồ | Chọn vật phẩm còn dùng được |
| Giữ món trong túi | Xem mô tả; đồ đã dùng vẫn xem lại được |
| Chọn món thứ hai | Thử ghép hai phần khi definition có công thức |
| Kéo món tới thiết bị | Dùng tại hotspot tương ứng; hoặc chọn rồi chạm chỗ sửa |
| Chạm bánh răng/van/gương | Đổi một nấc |
| Kéo/gạt cần | Thay đổi một nấc theo thiết bị |
| Một nhịp / Chạy / Dừng | Tiến một bước hoặc điều khiển nhịp tự động ở màn có hỗ trợ |
| Nhật ký / Gợi ý | Xem thông tin đã phát hiện / nhận chỉ dẫn theo trạng thái |
| Căn phòng / Android Back | Về phòng; Back ưu tiên đóng túi, thoát zoom, rồi pause |

Đồ sai không bị tiêu hao. Ghép hợp lệ tiêu thụ hai món và sinh món hoàn chỉnh; lắp hợp lệ đánh dấu món đã dùng. Hoàn tác có thể trả vật phẩm về trạng thái trước. Đặt lại khởi tạo lại cả màn, gồm đồ và manh mối, nhưng giữ thành tích đã đạt trong store.

## Bốn chương và 12 màn

| Màn | Tên | Suy luận chính |
|---|---|---|
| 01 | Tia lửa đầu tiên | Chọn cặp bánh, hiểu tỷ số/chiều quay và nhả chốt an toàn |
| 02 | Đồng hồ không kim | Ghép bộ chọn; một thao tác làm hai đồng hồ cùng tiến |
| 03 | Trái tim lò hơi | Sửa vòng đệm, tích áp rồi chuyển sức hơi thành lực |
| 04 | Bình cân bằng | Ghép ống kín, đong qua các bình có dung tích khác nhau |
| 05 | Nước qua ký ức | Phân biệt sạch/đục, dùng lượng lọc hữu hạn đúng chỗ |
| 06 | Cánh cửa thủy áp | Giữ hai khoang cân bằng rồi rút nước khỏi cửa |
| 07 | Con mắt ánh sáng | Gương, hướng nhận mắt và khe chắn liên kết |
| 08 | Sắc phổ vỡ | Ghép lăng kính; chia tia khác với lọc màu, tránh tinh thể quá tải |
| 09 | Bản đồ tinh tú | Ghi sao Bắc rồi thay đường tia tới sao Nam |
| 10 | Vòng tuần hoàn | Làm lạnh bù công suất, duy trì vùng nhiệt ổn định |
| 11 | Ba khóa an toàn | Khóa cơ cấp lực cho nước, nước cấp điện cho quang |
| 12 | Cỗ máy cuối cùng | Hiệu chỉnh, đồng bộ và giữ các nhánh cùng ổn định qua nhiều nhịp |

Các màn 02/04/08/12 ghép đồ; 03/06/09/11 có khóa biểu tượng dựa vào manh mối. Đây là bước khám phá bổ sung; cơ chế máy mới là câu đố chính. Bố cục phòng còn dùng chung theo mẫu, chưa có nhiều góc khám phá.

## Quy tắc và phục hồi

Bánh răng được giải bằng mạng truyền động có tỷ số/chiều quay. Nước được chuyển theo lượng nguyên và bảo toàn tổng khối lượng; nước đục có thể làm bẩn bình nhận. Tia quang có hướng, màu, cường độ và giới hạn truy vết để kết thúc cả khi gặp vòng lặp. Lõi tính nhiệt theo từng nhịp và kiểm tra liên động.

Quá áp tự xả, quá nhiệt tự ngắt, sai liên động nhả các khóa phụ thuộc; từng constraint quy định state phục hồi. Không có mất mạng vĩnh viễn. Người chơi có thể hoàn tác, cấu hình lại hoặc đặt lại màn. Test trace sai/reset không phải chứng minh vét cạn mọi trạng thái có thể đạt.

## Gợi ý và đánh giá

Ba cấp gợi ý: định hướng, quan hệ và bước tiếp theo. Trước khi sửa, hint xét manh mối/khóa/đồ/ghép/lắp đang thiếu. Sau đó dùng gợi ý của màn; cấp cuối chỉ chỉ ra thao tác tiếp theo khi state khớp trace giải đã xác minh, nếu không nhắc phục hồi. Không tự chơi thay người dùng.

- 3 sao: không dùng gợi ý, không lỗi, không hoàn tác và số lượt không vượt `target_moves`.
- 2 sao: dùng tối đa hai cấp gợi ý và lượt không quá hai lần mục tiêu.
- Còn lại: 1 sao.

Bất kỳ lần hoàn thành nào cũng mở màn kế tiếp; không bắt buộc ba sao. Normal progression bắt đầu từ màn 1. Màn 12 dẫn tới đoạn kết. Chưa có vật phẩm xuyên màn, nhiệm vụ phụ hoặc màn bí mật quay lại chương cũ.

## Lưu tiến trình

Lưu offline gồm màn mở/đã đạt sao, kết quả tốt nhất, tutorial, manh mối và trạng thái vật phẩm giữa màn. Hoàn tác history không được lưu xuyên process; resume giữ state và bộ đếm, không khôi phục danh sách mọi bước undo cũ. Xóa tiến trình trong settings cần xác nhận. Save lỗi được thử backup; state không hợp lệ sẽ bắt đầu lại màn với lời báo.
