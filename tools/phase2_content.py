"""Room dependencies and player-facing Vietnamese copy layered over canon rules."""
GOALS = [
 'Căn phòng vẫn còn một nguồn lực yếu ớt. Hãy tìm bộ phận còn thiếu và đánh thức cánh cửa đầu tiên.',
 'Ba chiếc đồng hồ đã ngừng chạy. Hãy tìm dấu vết người thợ để biết chúng từng chỉ về đâu.',
 'Hơi nước đang thoát ra khỏi một khớp nối. Sửa chỗ rò rồi tìm cách dùng sức hơi mở cửa.',
 'Cửa thư viện bị giữ bởi những bình nước lệch nhau. Có một cách cân bằng chúng mà không bỏ phí giọt nào.',
 'Những trang ký ức cần nước trong để hiện lại. Hãy tìm cách đưa nước sạch đến hai bình lưu trữ.',
 'Nước đang đè nặng lên cửa. Hãy tìm cách giữ hai bên cân bằng trước khi rút nước khỏi lối đi.',
 'Hai con mắt bằng kính đang chờ ánh sáng. Khôi phục nguồn sáng rồi lần theo những dấu khắc trên viền.',
 'Ánh sáng trắng quá mạnh với tinh thể mỏng. Hãy tìm cách chia nó thành những dòng dịu hơn.',
 'Bầu trời trên trần đã mất một nửa. Có lẽ bộ máy nhớ được những ngôi sao không sáng cùng lúc.',
 'Lõi máy vẫn còn nóng. Hãy sửa đường làm lạnh trước khi thử đánh thức nó.',
 'Ba chốt giữ cánh cửa cuối hành lang. Tìm xem chốt nào nuôi sức cho những chốt còn lại.',
 'Tất cả đường ống đều dẫn tới đây. Hãy nối lại những bộ phận còn thiếu và để cỗ máy tự giữ nhịp sống.',
]
NOTES = [
 'Trên bản vẽ, bánh ở trục cửa quay hai vòng khi bánh nguồn quay một vòng. Mũi tên ở cả hai đầu cùng hướng. Bánh lớn kéo bánh nhỏ sẽ làm bánh nhỏ quay nhanh hơn; mỗi lần hai bánh ăn răng, chiều quay đổi lại. Bánh giữa đã nằm sẵn trên trục. Một nét bút khoanh riêng chốt an toàn: phải nhấc chốt trước khi kéo cần.',
 'Tờ lịch bảo dưỡng ghi: chiếc bên trái dừng ở vạch thứ ba, chiếc giữa ở vạch thứ năm, chiếc phải ở vạch thứ tư. Mỗi mặt số có sáu vạch. Cần giữa chọn hai đồng hồ cùng chạy; mỗi lần kéo cần nhịp, cả hai tiến một vạch. Chốt giữ chỉ khép khi cả ba cùng trở về những vạch cũ.',
 'Vạch xanh trên đồng hồ hơi trải từ 4 đến 6. Khi chưa nối bộ truyền, mỗi nhịp bơm thêm hai vạch áp. Khi đã nối, máy dùng bớt hơi và tích lực đẩy. Cần hai nhịp lấy lực rồi mới kéo cửa. Kim vượt vạch 7 sẽ khiến van tự xả. Van xả đóng lại được; có thể tích hơi từ đầu.',
 'Dòng chữ sau vỏ đồng hồ: “Chia đều tám phần cho hai bình giữ cửa. Bình nhỏ chỉ để đong.” Ba bình chứa tối đa tám, năm và ba phần. Bơm luôn chuyển đến khi bình nhận đầy hoặc bình nguồn cạn. Dấu khắc ở cửa cho phép bình nhỏ còn nhiều nhất hai phần; nước không biến mất khi đổi đường.',
 'Hai trang nhãn còn đọc được: bình bên trái cần hai phần nước trong, bình bên phải cần bốn. Có ba phần sạch và ba phần đục. Màng lọc giữ được cặn của ba phần nước, rồi hết khả năng lọc. Chỉ một phần nước đục cũng làm bẩn cả bình nhận. Hãy chọn nguồn và đường đi trước khi bơm.',
 'Bản vẽ cạnh bánh khóa có hai vạch ngang cùng độ cao: ba phần nước ở mỗi khoang giữ cửa. Khi cả hai đạt vạch, chốt giữa giữ lại thế cân bằng. Chỉ lúc đó mới được rút một phần khỏi khoang cửa vào bể kín phía dưới. Cố rút trước, van an toàn sẽ trả nước về vị trí ban đầu.',
 'Mũi tên trên mắt bên trên chỉ lên; mắt bên phải chỉ sang phải. Gương nghiêng hắt tia sang góc vuông. Mắt trên còn cho tia đi qua để đến gương tiếp theo. Khe chắn nằm giữa đường: đóng khe thì gương phía sau dù quay đúng cũng không nhận được ánh sáng.',
 'Ba mắt có viền đỏ, xanh lá và xanh lam. Chúng chỉ nhận đúng màu của mình. Lăng kính tách một tia mạnh thành ba tia nhẹ; bộ lọc giữ lại một màu, không làm tia mạnh yếu đi. Tinh thể có vết nứt không chịu được tia trực tiếp. Hãy đổi hướng tia trước khi bật nguồn.',
 'Nét mực trên bản đồ: “Giữ sao Bắc trước. Khi ký ức đã lưu, nhường đường cho sao Nam.” Hai khe chắn tách hai con đường. Cần ghi nhớ chỉ hoạt động khi sao Bắc sáng, sao Nam tối. Sau đó đóng đường Bắc, đổi các gương cần thiết và mở đường Nam; ký ức Bắc vẫn ở lại.',
 'Bơm lạnh cần khớp truyền mạnh và van dẫn vào lõi. Khi đủ nước, mỗi nhịp lấy đi bốn phần nhiệt. Mỗi bậc công suất lại thêm hai phần nhiệt. Lõi cần công suất ở bậc thứ hai, kim nhiệt nằm trong vùng xanh và giữ yên ba nhịp. Vượt vạch 8, máy tự ngắt để bảo vệ buồng trong.',
 'Ba hình khắc nối thành chuỗi: bánh răng → bình hơi → con mắt. Chốt cơ cần bộ truyền mạnh; có nó bơm mới giữ được hơi. Khi áp ở vạch 3, đóng van rồi giữ chốt nước. Chốt nước cấp điện cho đèn kiểm tra. Đổi bộ truyền hoặc để áp trôi sẽ làm các chốt phía sau rơi xuống.',
 'Trang cuối chia làm ba đoạn. Đầu tiên, nối bộ truyền mạnh, cho bơm hồi lưu đến vạch áp 4 rồi giữ chốt hiệu chỉnh. Sau đó đưa nước vào lõi, dẫn tia lên mắt và nâng công suất lên bậc hai để giữ chốt đồng bộ. Cuối cùng, để máy chạy bốn nhịp với nhiệt trong vùng xanh. Mất nền áp, ánh sáng hoặc nước lạnh thì chuỗi phải bắt đầu lại. Chốt cuối không cần sức mạnh hơn; nó cần sự ổn định.',
]
ITEMS = [
 ('Khớp nối trục', 'coupler', 'Rãnh ở đầu khớp khớp với trục trống bên phải. Nó nối nguồn quay với bộ bánh răng.'),
 ('Bánh dẫn nhỏ', 'gear', 'Bánh còn nguyên răng nhưng thiếu chốt giữa. Có thể ghép với chốt trong hộp kính.'),
 ('Vòng đệm chịu nhiệt', 'gasket', 'Vòng mềm vừa miệng ống hơi đang rò. Lắp ở khớp nối, không phải trên tay van.'),
 ('Ống mềm', 'hose', 'Đầu ống chưa có vòng siết. Nếu lắp ngay, nước sẽ thoát qua khe hở.'),
 ('Lõi lọc', 'filter', 'Giấy gấp bên trong còn trắng. Đưa vào buồng lọc trống để giữ cặn.'),
 ('Chốt giữ nước', 'key', 'Đầu chốt có ba cạnh, cùng hình với ổ khóa trên bể cân bằng.'),
 ('Cầu chì thủy tinh', 'fuse', 'Sợi sáng bên trong còn liền. Hộp nguồn có một khe trống vừa nó.'),
 ('Thân lăng kính', 'crystal', 'Mặt dưới còn thiếu vòng giữ. Lăng kính cần đứng chắc trước khi nhận tia.'),
 ('Vòng nhớ', 'coupler', 'Những rãnh nhỏ giữ vị trí khi ánh sáng tắt. Cần lắp vào bộ ghi nhớ bên phải.'),
 ('Ống nước lạnh', 'hose', 'Ống có hai đầu kim loại, nối được đường lạnh bị đứt cạnh lõi.'),
 ('Cầu chì liên động', 'fuse', 'Cầu chì nối ba khóa với nhau. Ổ của nó nằm trên hộp an toàn.'),
 ('Vòng dẫn năng lượng', 'coupler', 'Vòng dẫn bị rỗng ở giữa. Một lõi thủy tinh sẽ hoàn thiện đường dẫn.'),
]
SECOND = {2:('Chốt giữa','key'),4:('Vòng siết','gasket'),8:('Đế giữ kính','coupler'),12:('Lõi thủy tinh','fuse')}
REPAIRS = ['Trục nguồn','Bộ chọn đồng hồ','Khớp ống hơi','Đường bơm','Buồng lọc','Ổ chốt cân bằng','Hộp nguồn đèn','Đế lăng kính','Bộ ghi nhớ','Đường nước lạnh','Hộp an toàn','Ổ dẫn năng lượng']
REPAIR_TEXT = [
 'Đầu trục quay nhưng không kéo được máy. Một khớp nối đã bị tháo khỏi ổ.',
 'Cần giữa lỏng lẻo. Bộ chọn thiếu một bánh dẫn có chốt giữ.',
 'Hơi trắng phụt ra ở miệng ống. Vòng đệm cũ đã nứt.',
 'Giữa bơm và bình có một đoạn đường bị đứt. Cần một ống có đầu siết kín.',
 'Buồng lọc trống rỗng. Đẩy nước bẩn qua đây lúc này chỉ làm bẩn thêm đường ống.',
 'Ổ khóa quay tự do. Thiếu chốt thì hai khoang không giữ được cùng độ cao.',
 'Nguồn đèn đã nguội. Khe cầu chì trong hộp đang trống.',
 'Đế dưới tia sáng trống không. Lăng kính phải có vòng giữ mới lắp chắc được.',
 'Vòng nhớ đã bị lấy ra. Không có nó, máy quên sao Bắc ngay khi chuyển gương.',
 'Ống lạnh bị tháo khỏi lõi. Khởi động lúc này chỉ làm nhiệt tăng.',
 'Ba dây kiểm tra đều về hộp này, nhưng cầu chì nối chúng đã mất.',
 'Ổ dẫn cuối cùng chưa có lõi. Hai phần rời phải khớp vào nhau trước khi lắp.',
]
TUTORIALS = [
 'Chạm đồ vật trong phòng để quan sát. Đồ nhặt được nằm trong Túi đồ; chọn đồ rồi chạm nơi cần sửa.',
 'Chọn một món trong Túi đồ rồi chọn món còn lại để ghép. Cần giữa máy đổi cặp đồng hồ cùng chuyển động.',
 'Gạt cần bằng cách kéo lên hoặc xuống. Quan sát kim sau mỗi nhịp; có thể dừng để suy nghĩ.',
 'Chạm van để xoay một nấc. Kéo cần bơm một lần rồi nhìn xem bình nào đầy, bình nào vơi.',
 'Nhìn cả mức nước và dấu sạch/đục dưới bình. Màng lọc chỉ hao khi nước đục đi qua.',
 'Một chốt có thể giữ lại điều đã làm được. Hãy quan sát nó trước khi đổi đường nước.',
 'Chạm gương để đổi góc nghiêng. Tia sáng đi thật qua các gương; mũi tên trên mắt chỉ hướng nhận.',
 'Bộ lọc và lăng kính có việc khác nhau. Có thể tắt nguồn trong lúc đổi đường tia.',
 'Nút ghi nhớ giữ lại một phần bầu trời. Đóng đường cũ trước khi mở đường mới.',
 'Một nhịp cho máy chạy từng bước; Chạy để chạy liên tục, Dừng để kiểm tra. Đừng vội tăng công suất.',
 'Theo dõi các chốt đang sáng. Đổi một bộ phận phía trước có thể làm chốt phía sau nhả ra.',
 'Nút Toàn bộ đưa bạn tới từng cụm máy. Trở về Căn phòng để xem lại đồ vật và ghi chú bất cứ lúc nào.',
]

NATURAL_FEEDBACK = {
 'Cơ cấu chưa sẵn sàng. Đọc lại bản khắc.':'Bộ phận này chưa sẵn sàng. Hãy quan sát chỗ đang bị giữ và xem lại ghi chép trong phòng.',
 'Ba kim chưa cùng nằm trên vạch khắc 3 · 5 · 4.':'Có kim chưa về dấu hẹn. Đối chiếu cả ba mặt đồng hồ với tờ lịch bảo dưỡng.',
 'Cửa cần áp 4–6 và 2 nhịp mô-men đã tích.':'Cửa chưa đủ sức mở. Giữ kim trong vùng xanh và cho bộ truyền tích thêm lực.',
 'Cảm biến cần I=4, II=4 và III≤2.':'Mực nước chưa trùng các vạch sau kính. Kiểm tra cả hai bình lớn và phần dư trong bình nhỏ.',
 'Hai bình phải đủ 2 và 4 đơn vị, cùng mang dấu sạch ✓.':'Cửa còn giữ. Hai bình cần đúng vạch đã đánh dấu và nước trong cả hai phải sạch.',
 'Hai khoang phải cùng ở mức 3.':'Chốt chưa vào được. Đưa hai mặt nước về cùng vạch giữa trước.',
 'Giữ áp I=II=3 và rút cạn khoang cửa III.':'Cánh cửa vẫn ngập. Giữ hai khoang cân nhau rồi rút nước khỏi khoang cửa.',
 'Cứu hộ thủy áp: nước trở về 3/3/2. Cân bằng lại chốt trước khi xả.':'Van an toàn vừa trả nước về bể. Cân lại hai khoang và gài chốt trước khi xả tiếp.',
 'Chỉ ghi được pha A khi sao Bắc sáng và khe Nam đóng.':'Bộ nhớ chưa thấy riêng sao Bắc. Kiểm tra đường tới sao Bắc và đóng khe phía Nam.',
 'Quá nhiệt: bộ ngắt đã cắt nguồn và đưa lõi về 4 nhiệt.':'Lõi nóng đỏ rồi tự ngắt. Máy đã nguội bớt; khôi phục nước lạnh trước khi cấp điện lại.',
 'Khóa cơ cần tỷ số 2:1.':'Chốt cơ chưa khớp. Đối chiếu hai bánh răng với hình trong sơ đồ ba khóa.',
 'Khóa nước cần áp 3 và van cấp đã đóng.':'Chốt nước chưa giữ được. Đưa kim về dấu giữa và ngừng cấp thêm nước.',
 'Ba khóa phải thỏa cả cơ, nước và tia tới mắt.':'Một khóa vẫn còn tối. Kiểm tra lần lượt đường truyền, nước và ánh sáng.',
 'Trục đã đổi tỷ số: khóa cơ rơi và cắt hai khóa phụ thuộc.':'Đổi bánh răng làm chốt đầu nhả ra. Hai khóa sau cũng mất lực; hãy bắt đầu lại từ chốt cơ.',
 'Áp đã lệch 3: khóa nước rơi, điện kiểm quang bị cắt.':'Kim rời vạch giữ nên chốt nước bật ra. Nguồn đèn cũng tắt theo.',
 'Nguồn quang chỉ mở sau hiệu chỉnh A.':'Đèn chưa được cấp điện. Cần giữ được chốt hiệu chỉnh đầu tiên.',
 'Chốt A cần trục 2:1 và áp đúng 4.':'Chốt chưa khớp. Kiểm tra cặp bánh răng và vạch áp trong trang ghi chép cuối.',
 'B cần tia tới mắt, làm lạnh 4 và công suất 2.':'Bộ đồng bộ chưa nhận đủ tín hiệu. Kiểm tra tia sáng, đường lạnh và mức cấp điện trong ghi chép.',
 'Cần đủ 4 nhịp ổn định, các khóa vẫn giữ và nhiệt 2–6.':'Máy chưa tự giữ nhịp. Để máy chạy thêm trong vùng nhiệt an toàn và quan sát xem các chốt có còn sáng.',
}

def upgrade(levels):
 def eq(k,v):return ['==','$'+k,v]
 def both(*a):return ['all',*a]
 def action(id,label,kind,effects,guard=1,reason='',options=None,field=None,feedback=''):
  return dict(id=id,label=label,kind='room_'+kind,x=.5,y=.5,field=field,effects=effects,guard=guard,reason=reason or 'Vật này chưa dùng được ở đây. Hãy quan sát thêm.',options=options or [],sound={'take':'pickup','clue':'clue','repair':'latch','combine':'metal','dial':'switch'}.get(kind,'click'),help=feedback,feedback=feedback)
 for l in levels:
  n=l['number'];name,art,desc=ITEMS[n-1];comb=n in SECOND;locked=n in [3,6,9,11];code=(n%2)+1
  l['goal']=GOALS[n-1];l['note']=NOTES[n-1];l['tutorial']=TUTORIALS[n-1]
  l['completion']='Những tiếng động rời rạc đã tìm được cùng một nhịp. Cánh cửa trước mặt đang mở.' if n<12 else 'Cỗ máy đã tự giữ được nhịp sống. Sau cánh cửa, khu vườn đầu tiên đang thức dậy.'
  l['initial'].update(clueFound=0,repairReady=0,itemA=0,itemB=0,itemC=0,caseDial=0,cabinetOpen=0)
  old=l['solution'][1:];wrong=l['wrong_trace'][1:]
  for c in l['controls']:
   c['reason']=NATURAL_FEEDBACK.get(c['reason'],c['reason'])
   c['guard']=both(eq('repairReady',1),c['guard'])
   c['feedback']= {'gear':'Bánh răng đã vào vị trí. Hãy nhìn xem trục nào sẽ kéo trục nào.', 'valve':'Van đã đổi hướng. Theo đường ống để biết dòng nước sẽ đi đâu.', 'mirror':'Gương đã nghiêng sang phía khác. Hãy nhìn đường tia mới.', 'lever':'Cần đã chuyển vị trí. Tiếng máy cũng thay đổi theo.', 'shutter':'Các lá chắn vừa chuyển động. Quan sát con đường ánh sáng.', 'filter':'Màu kính đã đổi. Chỉ ánh sáng hợp màu mới đi qua.'}.get(c['kind'],'Chốt vừa dịch chuyển. Hãy quan sát phần máy nối với nó.')
   if not c['help']:c['help']='Chạm để thử một nấc, rồi quan sát phần máy nối với nó.'
  for constraint in l['constraints']:
   constraint['message']=NATURAL_FEEDBACK.get(constraint['message'],constraint['message'])
  l['objectives'].append(dict(label='Bộ phận hỏng đã được sửa',condition=eq('repairReady',1)))
  l['hints']=[
   ['Nhìn những dấu khắc trên khung cửa và bản vẽ ở bên kia phòng.','Ba mặt số để lại dấu gì trong tờ lịch bảo dưỡng?','Hãy nhìn vạch xanh và chỗ hơi đang thoát ra.','Bình nhỏ có thể giúp đong nước cho hai bình lớn.','Phân biệt nguồn sạch với nguồn đục trước khi bơm.','Hai khoang giữ cửa phải cân nhau trước.','Nhìn mũi tên trên từng con mắt.','Tinh thể nứt nằm trên đường nào của tia mạnh?','Chữ Bắc trên bản đồ được gạch trước chữ Nam.','Bơm lạnh có thật sự nhận được lực từ trục chưa?','Bắt đầu từ chốt có hình bánh răng.','Theo ba đoạn trong trang ghi chép cuối.'][n-1],
   ['Bánh lớn kéo bánh nhỏ làm trục sau nhanh hơn; bánh giữa đảo chiều thêm một lần.','Mỗi lần kéo cần, hai đồng hồ cùng tiến. Chọn cặp khác sẽ giữ chiếc thứ ba đứng yên.','Tích hơi khi bộ truyền chưa nối, rồi dùng lượng hơi ấy để lấy lực đẩy.','Bơm dừng khi một bên đầy hoặc một bên cạn. Phần nước còn dư là chìa khóa.','Hãy dành sức lọc cho nước đục; nguồn sạch không cần đi qua màng lọc.','Chốt giữa giữ thế cân bằng để đường xả có thể hoạt động.','Một mắt cho tia đi tiếp; gương sau vẫn cần đường tới đó thông suốt.','Bộ chia làm tia yếu đi, bộ lọc chỉ giữ màu. Đừng nhầm hai việc này.','Sau khi giữ ký ức Bắc, bạn có thể đổi gương mà không mất ngôi sao ấy.','Công suất tạo nhiệt, nước lạnh lấy nhiệt đi. Hai bên phải cân nhau qua nhiều nhịp.','Khóa sau nhờ khóa trước cấp lực. Hãy giữ điều kiện cũ khi làm bước mới.','Áp giữ nền hiệu chỉnh; sau đó đổi đường nước từ hồi lưu sang làm lạnh.'][n-1],
   'Nếu máy vừa dừng, đọc lời cảnh báo rồi hoàn tác thao tác gây ra nó. Giữ những phần đang ổn trước khi thử lại.'
  ]
  prefix=['ACT_INSPECT','ACT_CLUE']
  if locked:prefix+=['ACT_CASE']*code
  prefix+=['ACT_SEARCH']
  if comb:prefix+=['ACT_SECOND','ACT_COMBINE']
  prefix+=['ACT_REPAIR']
  l['controls'] += [
   action('ACT_CLUE','Ghi lại manh mối','clue',[{'set':{'clueFound':1}}],eq('clueFound',0),feedback='Bạn đã ghi lại những dấu vết này trong nhật ký.'),
   action('ACT_CASE','Xoay mặt khóa','dial',[{'set':{'caseDial':['%', ['+','$caseDial',1],3]}}],field='caseDial',options=['Mặt trời','Giọt nước','Ngôi sao'],feedback='Mặt khóa khẽ kêu. Đối chiếu hình này với dấu trên giấy.'),
   action('ACT_SEARCH','Lấy vật trong ngăn','take',[{'set':{'itemA':1,'cabinetOpen':1}}],both(eq('itemA',0),eq('caseDial',code) if locked else 1),reason='Ngăn kéo còn khóa. Hãy tìm dấu cùng hình trên tờ giấy, rồi xoay mặt khóa.',feedback='Bạn đã cất '+name.lower()+' vào túi đồ.'),
   action('ACT_REPAIR','Lắp bộ phận','repair',[{'set':{'repairReady':1,('itemC' if comb else 'itemA'):2}}],both(eq('repairReady',0),eq('itemC' if comb else 'itemA',1)),reason='Chỗ này cần một bộ phận vừa khít. Chọn món phù hợp trong túi đồ.',feedback='Bộ phận đã khớp vào ổ. Đường truyền liền lại; giờ có thể thử máy.'),
  ]
  itemlist=[dict(id=f'{l["id"]}_ITEM_A',field='itemA',name=name,image=art,description=desc)]
  if comb:
   name2,art2=SECOND[n]
   itemlist += [dict(id=f'{l["id"]}_ITEM_B',field='itemB',name=name2,image=art2,description='Hình ở đầu món này khớp với phần còn thiếu của '+name.lower()+'. Hãy thử ghép hai món trong túi đồ.'),dict(id=f'{l["id"]}_ITEM_C',field='itemC',name={2:'Bánh dẫn có chốt',4:'Ống có vòng siết',8:'Lăng kính có đế',12:'Vòng dẫn hoàn chỉnh'}[n],image=art,description='Hai phần đã gắn chắc. Bộ phận này dùng được tại '+REPAIRS[n-1].lower()+'.')]
   l['controls'] += [action('ACT_SECOND','Lấy bộ phận thứ hai','take',[{'set':{'itemB':1}}],eq('itemB',0),feedback='Bạn đã nhặt '+name2.lower()+'.'),action('ACT_COMBINE','Ghép hai bộ phận','combine',[{'set':{'itemA':2,'itemB':2,'itemC':1}}],both(eq('itemA',1),eq('itemB',1)),reason='Cần cả hai phần còn nguyên trong túi đồ.',feedback='Hai phần vừa khít nhau. Bạn có thể lắp bộ phận hoàn chỉnh vào máy.')]
  locknote=(' Ở góc giấy có dấu '+['mặt trời','giọt nước','ngôi sao'][code]+', trùng với hình trên khóa ngăn kéo.') if locked else ''
  def spot(id,kind,title,text,rect,image,action=''):
   return dict(id=id,kind=kind,title=title,text=text,rect=rect,image=image,action=action)
  l['room']=dict(items=itemlist,combine=comb,locked=locked,repairItem=itemlist[-1]['id'],repairTitle=REPAIRS[n-1],solution=prefix,
   hotspots=[
    spot('journal','intro','Ghi chép bỏ lại','Một trang giấy mắc dưới chiếc đèn. '+GOALS[n-1],[95,125,210,140],'notebook','ACT_INSPECT'),
    spot('clue','clue',['Bản vẽ trên tường','Tờ lịch bảo dưỡng','Phiếu kiểm tra hơi','Vạch đo sau kính','Nhãn bình lưu trữ','Bản vẽ cửa nước','Dấu khắc thiên văn','Trang nghiên cứu ánh sáng','Bản đồ sao','Sổ trực lõi','Sơ đồ ba khóa','Trang cuối người thợ'][n-1],NOTES[n-1]+locknote,[1015,115,190,150],'notebook','ACT_CLUE'),
    spot('cabinet','cabinet','Ngăn dụng cụ',('Mặt khóa mang ba hình. Tìm dấu phù hợp ở nơi người thợ thường ghi chép.' if locked else 'Một ngăn kéo có tay nắm còn sạch bụi. Bên trong có thứ dùng được.'),[95,365,225,185],'cabinet','ACT_SEARCH'),
    spot('aux','aux','Hộp kính nhỏ' if comb else 'Dấu vết bên đường ống',('Một bộ phận nhỏ còn nằm trong hộp kính.' if comb else REPAIR_TEXT[n-1]),[335,470,160,100],SECOND[n][1] if comb else ['coupler','filter','crystal','fuse'][l['chapter']],'ACT_SECOND' if comb else ''),
    spot('repair','repair',REPAIRS[n-1],REPAIR_TEXT[n-1],[1025,330,185,225],['coupler','filter','fuse','hose'][l['chapter']],'ACT_REPAIR'),
    spot('machine','machine','Bộ máy chính','Chạm để đến gần. Có thể quay lại căn phòng bất cứ lúc nào.',[350,185,585,275],'',''),
   ])
  l['solution']=prefix+old;l['wrong_trace']=prefix+wrong;l['target_moves']+=len(prefix)-1

