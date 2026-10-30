"""Narrative continuity only; puzzle states, guards and solutions stay intact."""
def upgrade_v3(levels):
    consequences = [
        'Bạn đã sửa thành công cỗ máy đầu tiên! Những căn phòng tiếp theo sẽ cần bạn tự tìm manh mối và vận dụng những gì đã học. Năng lượng giờ đã tới tháp đồng hồ, nhưng ba kim vẫn chạy lệch nhau.',
        'Những đồng hồ đã cùng nhịp. Tín hiệu vừa đánh thức lò hơi ở cuối xưởng; một khớp ống vẫn đang rò.',
        'Nguồn lực của xưởng đã liền mạch. Hơi đẩy cánh cửa xuống thư viện, nơi những bể nước đang lệch nhau.',
        'Bể chứa đã cân bằng. Nước có thể đi sâu vào thư viện, nhưng dòng đục vẫn đe dọa những trang ký ức.',
        'Dòng nước đã trong trở lại. Hai nhánh sạch dẫn tới cửa thủy lực; cần giữ áp trước khi rút nước khỏi lối đi.',
        'Cửa thủy lực đã mở. Bạn lên được đài thiên văn, nơi đường ánh sáng đầu tiên đã tắt từ lâu.',
        'Ánh sáng đã nối lại giữa các mắt kính. Phía trên, tinh thể màu vẫn không chịu nổi tia sáng nguyên vẹn.',
        'Các dòng màu đã dịu và đúng hướng. Chúng soi lộ bản đồ sao chỉ giữ được từng nửa bầu trời.',
        'Bản đồ sao đã giữ cả Bắc lẫn Nam. Tọa độ dẫn tới lõi vĩnh cửu; đường làm lạnh nơi đó đã bị đứt.',
        'Nước lạnh đã giữ được sức nóng của lõi. Ba khóa an toàn phía trước giờ có thể nhận lực theo đúng thứ tự.',
        'Ba khóa đã cùng giữ. Cỗ máy cuối cùng đã nhận đủ đường truyền, nước và ánh sáng; hãy đưa chúng về cùng một nhịp.',
        'Bạn đã đưa toàn bộ đường truyền, nước lạnh và ánh sáng về cùng nhịp. Cỗ máy tự giữ được sự sống; khu vườn sau cánh cửa đang thức dậy.',
    ]
    for i, level in enumerate(levels):
        level['completion'] = consequences[i]
        level['story'] = consequences[i]
        if i:
            level['goal'] = consequences[i-1].split('. ')[-1].rstrip('.') + '. ' + level['goal']
    levels[0]['goal'] = 'Máy phát điện đã ngừng hoạt động. Bạn cần sửa nó để mở cánh cửa phía trước.'
    levels[0]['room']['hotspots'][0]['text'] = 'Máy phát điện đã dừng vì thiếu khớp nối. Tìm linh kiện trong ngăn dụng cụ rồi lắp vào ổ trục bên phải.'
