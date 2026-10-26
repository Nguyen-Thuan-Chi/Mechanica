"""Authoring helper. The generated levels.json is the runtime source of truth."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
L=[]
def E(op,*args):return [op,*args]
def eq(field,value):return E('==','$'+field,value)
def both(*args):return E('all',*args)
def S(**values):return {'set':values}
def IF(cond,yes,no=None):return {'if':cond,'then':yes,'else':no or []}
def C(id,label,kind,x,y,field=None,effects=None,guard=1,reason='',options=None,sound=None,help='',group=0):
    return dict(id='ACT_'+id,label=label,kind=kind,x=x,y=y,field=field,effects=effects or [],guard=guard,reason=reason or 'Cơ cấu chưa sẵn sàng. Đọc lại bản khắc.',options=options or [],sound=sound or {'valve':'valve','gear':'gear','mirror':'beam','lever':'switch','button':'click','shutter':'metal'}.get(kind,'switch'),help=help,group=group)
def cycle(id,label,kind,x,y,field,n,options=None,**kw):return C(id,label,kind,x,y,field,[S(**{field:E('%',E('+','$'+field,1),n)})],options=options,**kw)
def O(label,condition):return dict(label=label,condition=condition)
def G(field,label,max=10,kind='gauge',x=.5,y=.35,target=None):return dict(field=field,label=label,max=max,kind=kind,x=x,y=y,target=target)
def transfer(a,b,cap,amount=1,**kw):return {'transfer':dict({'from':a,'to':b,'capacity':cap,'amount':amount},**kw)}
def base(num,title,goal,note,story,rule,initial,controls,objectives,solution,hints,inferences,**kw):
    initial={'inspected':0,'flow':0,'fault':0,**initial}
    level=dict(id=f'LV{num:02}',number=num,chapter=(num-1)//3,title=title,goal=goal,note=note,story=story,introduced_rule=rule,initial=initial,controls=controls,objectives=objectives,solution=['ACT_INSPECT']+['ACT_'+a for a in solution],wrong_trace=['ACT_INSPECT','ACT_'+kw.pop('wrong','LOCK')],hints=hints,required_inferences=inferences,target_moves=len(solution)+3,derived={},constraints=[],gauges=[],mass_fields=[],**{})
    level.update(kw);L.append(level);return level

base(1,'Tia lửa đầu tiên','Lắp bộ truyền tốc độ ×2, quay thuận và mở khóa an toàn.',
'Bản khắc: bánh lớn 24 răng ở chốt trái, bánh 12 răng ở chốt phải. Hai lần ăn khớp giữ nguyên chiều nguồn. Trục cửa cần quay thuận với tốc độ gấp đôi. Nhấc chốt an toàn rồi gạt cần. Chạm bánh để đổi cỡ; kéo bánh từ khay vào chốt. Nút mũi tên đổi chiều nguồn.',
'Trong lớp bụi, một dòng chữ còn rõ: “Đừng đánh thức tất cả cùng một lúc.”',
'Tỷ số răng, chiều quay và khóa chống ngược',
dict(gearA=0,gearB=0,reverse=1,safety=0,powered=0,ratio=0,direction=-1,jam=0),[
 cycle('GEAR_A','Chốt truyền I','gear',.30,.43,'gearA',3,['Trống','12 răng','24 răng']),
 cycle('GEAR_B','Chốt truyền II','gear',.54,.43,'gearB',3,['Trống','12 răng','24 răng']),
 cycle('REVERSE','Chiều nguồn','lever',.12,.68,'reverse',2,['Thuận','Ngược']),
 cycle('SAFETY','Chốt an toàn','lever',.75,.28,'safety',2,['Đóng','Mở']),
 C('START','Khởi động','lever',.79,.65,'powered',[S(powered=1)],guard=eq('jam',0),reason='Khóa chống ngược đang giữ trục. Hãy nhả khóa trước.'),
 C('RELEASE','Nhả khóa','button',.54,.77,None,[S(jam=0,powered=0)])],
 [O('Bộ truyền ×2',eq('ratio',2)),O('Quay thuận',eq('direction',1)),O('Nguồn đang chạy',eq('powered',1))],
 ['GEAR_A','GEAR_A','GEAR_B','REVERSE','SAFETY','START'],
 ['Đọc số răng khắc trên hai trục. Một bánh lớn kéo bánh nhỏ sẽ tăng tốc.','Cần đồng thời đúng cỡ bánh, đúng chiều nguồn và chốt đã mở.','Nếu khóa bật, nhả khóa rồi kiểm tra chiều nguồn trước khi kéo cần.'],
 ['Tỷ số 24/12 bằng 2','Hai lần đảo chiều trả về chiều nguồn','Khóa an toàn độc lập với bộ truyền'],wrong='START',
 derived=dict(ratio=E('if',both(eq('gearA',2),eq('gearB',1)),2,0),direction=E('if',eq('reverse',0),1,-1)),
 constraints=[dict(when=both(eq('powered',1),E('any',eq('ratio',0),eq('direction',-1),eq('safety',0))),effects=[S(powered=0,jam=1)],message='Khóa chống ngược bật! Kiểm tra răng, chiều quay và chốt an toàn.')],
 gauges=[G('ratio','Tỷ số',2,x=.43,y=.20,target=2)])

base(2,'Đồng hồ không kim','Đưa ba kim đến I: 3 · II: 5 · III: 4, rồi đóng chốt giữ.',
'Ba ly hợp ghép từng cặp trục: I+II, II+III, I+III. Mỗi nhịp quay tăng cả hai kim đang ghép một vạch, vòng mặt số có 6 vạch (0…5). Đổi ly hợp không tự dịch kim. Ba mốc phải đúng cùng lúc khi đóng chốt.',
'Ba mặt đồng hồ không đo thời gian. Chúng đếm những lần người gác máy quay trở lại.',
'Ly hợp ghép cặp và đồng dư',dict(clutch=0,dialA=0,dialB=0,dialC=0,locked=0,powered=0),[
 cycle('CLUTCH','Ly hợp','gear',.50,.65,'clutch',3,['I + II','II + III','I + III']),
 C('STEP','Một nhịp','lever',.15,.65,None,[S(dialA=E('%',E('+','$dialA',E('if',E('!=','$clutch',1),1,0)),6),dialB=E('%',E('+','$dialB',E('if',E('!=','$clutch',2),1,0)),6),dialC=E('%',E('+','$dialC',E('if',E('!=','$clutch',0),1,0)),6),powered=1)]),
 C('LOCK','Chốt giữ','lever',.84,.65,'locked',[S(locked=1)],guard=both(eq('dialA',3),eq('dialB',5),eq('dialC',4)),reason='Ba kim chưa cùng nằm trên vạch khắc 3 · 5 · 4.')],
 [O('Kim I = 3',eq('dialA',3)),O('Kim II = 5',eq('dialB',5)),O('Kim III = 4 và đã giữ',both(eq('dialC',4),eq('locked',1)))],
 ['STEP','STEP','CLUTCH','STEP','STEP','STEP','CLUTCH','STEP','LOCK'],
 ['Một nhịp luôn quay hai kim. Hãy nghĩ theo cặp thay vì từng mặt số.','Số nhịp của I+II đóng góp cho cả kim I lẫn kim II. Kim III chỉ nhận hai cặp còn lại.','Đếm chênh lệch giữa các mốc; dùng hoàn tác nếu một cặp vừa làm kim đi quá xa.'],
 ['Mỗi kim thuộc hai cặp','Cả ba mục tiêu phải đồng thời','Vòng quay modulo 6'],
 gauges=[G('dialA','I · đích 3',5,'dial',.25,.30,3),G('dialB','II · đích 5',5,'dial',.5,.30,5),G('dialC','III · đích 4',5,'dial',.75,.30,4)])

base(3,'Trái tim lò hơi','Tích đủ 2 nhịp mô-men và mở cửa khi áp suất trong vùng 4–6.',
'Van cấp thêm 2 áp mỗi nhịp. Bộ truyền đang ghép tiêu thụ 1 áp mỗi nhịp; chỉ tích mô-men khi áp trước nhịp từ 4 trở lên. Cửa cần 2 mô-men và áp 4–6. Trên 7 áp, van cứu hộ xả toàn bộ. Van ở nấc Xả giảm 2 áp. Chạy và Dừng chỉ điều khiển nhịp mô phỏng.',
'Khi cánh cửa đầu tiên mở, hơi ấm thoát ra như một nhịp thở. Công trình này vẫn đang chờ ai đó.',
'Áp suất, mô-men và cửa sổ an toàn',dict(steam=0,drive=0,pressure=0,torque=0,door=0,powered=0),[
 cycle('VALVE','Van hơi','valve',.24,.54,'steam',3,['Đóng','Cấp +2','Xả −2']),
 cycle('DRIVE','Bộ truyền','gear',.65,.53,'drive',2,['Tách','Ghép']),
 C('STEP','Một nhịp','button',.45,.77,None,[S(torque=E('min',2,E('+','$torque',E('if',both(eq('drive',1),E('>=','$pressure',4)),1,0))),pressure=E('max',0,E('+','$pressure',E('if',eq('steam',1),2,E('if',eq('steam',2),-2,0)),E('*','$drive',-1))),powered='$drive')]),
 C('LOCK','Mở cửa','lever',.85,.65,'door',[S(door=1)],guard=both(E('>=','$pressure',4),E('<=','$pressure',6),E('>=','$torque',2)),reason='Cửa cần áp 4–6 và 2 nhịp mô-men đã tích.')],
 [O('Áp an toàn 4–6',both(E('>=','$pressure',4),E('<=','$pressure',6))),O('Mô-men đủ',E('>=','$torque',2)),O('Cửa mở',eq('door',1))],
 ['VALVE','STEP','STEP','DRIVE','STEP','STEP','LOCK'],
 ['Đọc áp kế trước khi ghép bộ truyền. Mô-men chỉ tích khi đã đủ áp.','Van cấp +2, truyền lực lấy −1. Khi ghép, áp vẫn tiếp tục tăng.','Sau khi tích đủ mô-men, mở cửa trước khi áp đi khỏi vùng an toàn.'],
 ['Cần tích áp trước','Bộ truyền thay đổi tốc độ tăng áp','Cửa có cửa sổ thời gian'],gauges=[G('pressure','Áp suất',8,'gauge',.43,.30,5),G('torque','Mô-men',2,'gauge',.72,.24,2)],constraints=[dict(when=E('>','$pressure',7),effects=[S(pressure=0,torque=0,steam=0,powered=0)],message='Quá áp! Van cứu hộ đã xả hơi. Bộ truyền có thể khởi động lại.')])

routes=[('a','b',5),('b','c',3),('c','a',8),('c','b',5),('b','a',8),('a','c',3)]
effects=[IF(eq('route',i),[transfer(a,b,cap,E('min','$'+a,E('-',cap,'$'+b)))]) for i,(a,b,cap) in enumerate(routes)]
base(4,'Bình cân bằng','Chia 8 đơn vị thành 4 ở bể I, 4 ở bể II; bể III không vượt 2.',
'Dung tích ba bình: 8, 5, 3. Mỗi nhịp bơm là một lần xi-phông: chảy đến khi nguồn hết hoặc đích đầy. Chọn tuyến bằng van sáu nấc. Không có nguồn cấp ngoài và không đổ bỏ nước. Mốc cửa: I=4, II=4, III≤2.',
'Nước vẫn trong. Những cuốn sách sau lớp kính đã được giữ nguyên qua nhiều thế hệ.',
'Bảo toàn thể tích và dung tích khác nhau',dict(a=8,b=0,c=0,route=0,door=0),[
 cycle('ROUTE','Van phân tuyến','valve',.39,.74,'route',6,['I → II','II → III','III → I','III → II','II → I','I → III']),
 C('STEP','Bơm xi-phông','lever',.65,.74,None,effects,sound='water'),
 C('LOCK','Khóa cân bằng','button',.85,.74,'door',[S(door=1)],guard=both(eq('a',4),eq('b',4),E('<=','$c',2)),reason='Cảm biến cần I=4, II=4 và III≤2.')],
 [O('Bể I = 4',eq('a',4)),O('Bể II = 4',eq('b',4)),O('Khóa cân bằng mở',eq('door',1))],
 ['STEP','ROUTE','STEP','ROUTE','STEP']+['ROUTE']*5+['STEP']+['ROUTE']*5+['STEP','ROUTE','STEP','ROUTE','STEP','LOCK'],
 ['Không thể dừng giữa một lần xi-phông. Hãy dùng bình nhỏ làm đơn vị đo.','Đổ đầy bình 5 rồi chuyển sang bình 3 sẽ để lại 2.','Tận dụng phần còn lại sau khi bình nhỏ đầy. Giữ tổng nước là 8.'],
 ['Xi-phông đầy/kiệt','Hiệu dung tích tạo lượng dư','Bảo toàn tổng 8'],gauges=[G('a','Bình I / 8',8,'tank',.22,.34,4),G('b','Bình II / 5',5,'tank',.5,.34,4),G('c','Bình III / 3',3,'tank',.78,.34,0)],mass_fields=['a','b','c'])

water5=[]
for source,source_field,dirty in [(0,'clean','cleanDirty'),(1,'dirty','dirtyFlag')]:
 for target,target_field,cap in [(0,'a',2),(1,'b',4)]:
  water5.append(IF(both(eq('source',source),eq('route',target)),[transfer(source_field,target_field,cap,dirty_from=dirty,dirty_to=target_field+'Dirty',filter='filter',charge='charge')]))
base(5,'Nước qua ký ức','Cấp 2 đơn vị sạch vào I và 4 vào II, giữ lại các bản ghi.',
'Nguồn sạch có 3 đơn vị, nguồn bẩn có 3. Màng lọc xử lý được đúng 3 đơn vị bẩn; chỉ tiêu hao khi có nước bẩn đi qua và van Lọc đang bật. Mỗi nhịp chuyển 1 đơn vị. Một giọt bẩn vào đích làm ô nhiễm cả bình, không tự sạch khi pha loãng. Dấu ✓ là sạch, dấu ! là nhiễm.',
'Trong ống kính hiện lên một vườn cây. Thư viện không lưu sách; nó lưu ký ức về sự sống.',
'Chất lượng nước và ngân sách lọc',dict(clean=3,dirty=3,cleanDirty=0,dirtyFlag=1,a=0,b=0,aDirty=0,bDirty=0,source=0,route=0,filter=0,charge=3,door=0),[
 cycle('SOURCE','Chọn nguồn','valve',.12,.72,'source',2,['Sạch ✓','Bẩn !']),
 cycle('ROUTE','Đích đến','valve',.36,.72,'route',2,['Bình I','Bình II']),
 cycle('FILTER','Màng lọc','lever',.60,.72,'filter',2,['Bỏ qua','Lọc ✓']),
 C('STEP','Bơm 1 đơn vị','button',.82,.72,None,water5,sound='water'),
 C('LOCK','Niêm phong','button',.87,.25,'door',[S(door=1)],guard=both(eq('a',2),eq('b',4),eq('aDirty',0),eq('bDirty',0)),reason='Hai bình phải đủ 2 và 4 đơn vị, cùng mang dấu sạch ✓.')],
 [O('I: 2 sạch',both(eq('a',2),eq('aDirty',0))),O('II: 4 sạch',both(eq('b',4),eq('bDirty',0))),O('Đã niêm phong',eq('door',1))],
 ['STEP','STEP','ROUTE','STEP','SOURCE','FILTER','STEP','STEP','STEP','LOCK'],
 ['Nguồn sạch không cần dùng màng lọc. Nước bẩn phải lọc trước khi đến bình.','Tổng nước bẩn bằng đúng số lượt lọc còn lại. Không để nước bẩn đi tắt.','Nếu một bình có dấu !, hoàn tác lần chuyển bẩn đó; pha thêm nước sạch không sửa được.'],
 ['Chia nguồn hữu hạn','Ô nhiễm là trạng thái lan truyền','Lọc chỉ tiêu hao với nước bẩn'],gauges=[G('clean','Nguồn ✓',3,'tank',.12,.30),G('dirty','Nguồn !',3,'tank',.30,.30),G('a','Bình I ✓ / !',2,'tank',.54,.30,2),G('b','Bình II ✓ / !',4,'tank',.74,.30,4)],mass_fields=['clean','dirty','a','b'])

base(6,'Cánh cửa thủy áp','Cân hai khoang ở mức 3, giữ khóa rồi rút khô khoang cửa.',
'Khóa chỉ giữ khi I=II=3. Khoang cửa III bắt đầu ở mức 2 và chỉ được xả sau khi giữ khóa. Mỗi nhịp chuyển 1 đơn vị. Sau khi giữ, nếu làm lệch áp I/II hoặc để III>3, hệ cứu hộ đưa nước về mốc 3/3/2 (tổng vẫn là 8). Ống xả dẫn tới bể thu kín.',
'Dưới chân cửa là dấu bàn tay nhỏ. Người xây máy đã định đưa cả gia đình đến đây.',
'Cân bằng áp, chốt nhớ và checkpoint',dict(a=6,b=0,c=2,drain=0,route=0,latch=0,door=0),[
 cycle('ROUTE','Van liên thông','valve',.30,.73,'route',4,['I → II','II → III','III → thu','III → I']),
 C('STEP','Bơm một nhịp','lever',.54,.73,None,[IF(eq('route',0),[transfer('a','b',6)]),IF(eq('route',1),[transfer('b','c',4)]),IF(eq('route',2),[transfer('c','drain',8)]),IF(eq('route',3),[transfer('c','a',6)])],guard=E('any',E('!=','$route',2),eq('latch',1)),reason='Van xả bị khóa: cân I và II rồi giữ chốt trước.'),
 C('LATCH','Giữ áp','lever',.77,.32,'latch',[S(latch=1)],guard=both(eq('a',3),eq('b',3)),reason='Hai khoang phải cùng ở mức 3.'),
 C('LOCK','Mở cửa','button',.80,.73,'door',[S(door=1)],guard=both(eq('latch',1),eq('a',3),eq('b',3),eq('c',0)),reason='Giữ áp I=II=3 và rút cạn khoang cửa III.')],
 [O('Hai áp cân bằng',both(eq('a',3),eq('b',3))),O('Khoang cửa khô',eq('c',0)),O('Cửa đã mở',eq('door',1))],
 ['STEP','STEP','STEP','LATCH','ROUTE','ROUTE','STEP','STEP','LOCK'],
 ['Cửa chịu cả chênh áp lẫn nước trong khoang. Phải xử lý hai điều kiện riêng.','Giữ chốt tại 3/3 trước khi mở đường từ III về bể thu.','Sau khi khóa đã giữ, tránh mọi tuyến làm thay đổi I hoặc II.'],
 ['Cân áp trước khi xả','Chốt nhớ mở đường xả','Thao tác sau khóa vẫn có hậu quả'],gauges=[G('a','Khoang I',6,'tank',.18,.32,3),G('b','Khoang II',6,'tank',.40,.32,3),G('c','Khoang cửa',4,'tank',.61,.32,0)],mass_fields=['a','b','c','drain'],constraints=[dict(when=E('any',E('>','$c',3),both(eq('latch',1),E('any',E('!=','$a',3),E('!=','$b',3)))),effects=[S(a=3,b=3,c=2,drain=0,latch=0,flow=0)],message='Cứu hộ thủy áp: nước trở về 3/3/2. Cân bằng lại chốt trước khi xả.')])

def node(type,x,y,**kw):return dict(type=type,x=x,y=y,**kw)
def optical(nodes,color=7,power=1):return dict(width=10,height=6,emitters=[dict(x=0,y=3,direction=0,color=color,power=power,enabled='$light')],nodes=nodes)
def mirror(id,x,y,field,**kw):return cycle(id,'Gương '+id[-1],'mirror',.10+.08*x,.12+.10*y,field,2,['/','\\'],help='Mỗi chạm xoay gương 90°.',**kw)

nodes7=[node('mirror',3,3,field='m1'),node('shutter',3,2,field='shutter'),node('sensor',3,1,field='s1',direction=3,color=7,through=True),node('mirror',3,0,field='m2'),node('sensor',8,0,field='s2',direction=0,color=7)]
base(7,'Con mắt ánh sáng','Chiếu tia vào cả hai mắt theo hướng khắc trên viền.',
'Nguồn đi từ trái sang phải. Gương / phản xạ tia sang hướng vuông góc; gương \\ phản xạ về phía còn lại. Mắt I nhận tia đi lên và cho tia đi tiếp; mắt II chỉ nhận tia đi sang phải. Khe chắn nằm giữa gương I và mắt I. Mở nguồn bằng cần phát.',
'Một tia sáng xuyên qua bụi sao. Trên trần, bản đồ của một bầu trời xa lạ dần hiện ra.',
'Hình học phản xạ và hướng nhận',dict(light=0,m1=1,m2=1,shutter=0,s1=0,s2=0,optical_fault=0),[
 mirror('M1',3,3,'m1'),mirror('M2',3,0,'m2'),cycle('SHUTTER','Khe chắn','shutter',.68,.63,'shutter',2,['Đóng','Mở']),cycle('LIGHT','Nguồn sáng','lever',.13,.73,'light',2,['Tắt','Bật'])],
 [O('Mắt I nhận từ dưới',eq('s1',1)),O('Mắt II nhận từ trái',eq('s2',1))],
 ['M1','M2','SHUTTER','LIGHT'],
 ['Theo đường tia từng đoạn. Các mũi tên trên mắt là hướng tia phải đi khi chạm mắt.','Gương I phải đưa tia lên, gương II đưa tia từ trên về phía phải.','Nếu tia dừng giữa đường, kiểm tra khe chắn trước khi xoay thêm gương.'],
 ['Gương I định tuyến lên','Khe chắn quyết định đường có thông','Gương II phải đúng hướng mắt'],wrong='LIGHT',optics=optical(nodes7))

nodes8=[node('mirror',2,3,field='m1'),node('fragile',2,5,max_power=1),node('mirror',2,1,field='m2'),node('splitter',5,1,directions=[0,1,3]),node('filter',7,1,field='fr',masks=[7,1,2,4]),node('sensor',9,1,field='sr',direction=0,color=1),node('filter',5,2,field='fg',masks=[7,1,2,4]),node('sensor',5,5,field='sg',direction=1,color=2),node('filter',5,0,field='fb',masks=[7,1,2,4]),node('mirror',5,0,field='unused')]
# Upper branch uses a sensor at the edge; filter sits at same y? Avoid overlapping
# nodes: splitter at (5,2), upper filter (5,1), blue sensor (5,0).
nodes8=[node('mirror',2,3,field='m1'),node('fragile',2,5,max_power=1),node('mirror',2,2,field='m2'),node('splitter',5,2,directions=[0,1,3]),node('filter',7,2,field='fr',masks=[7,1,2,4]),node('sensor',9,2,field='sr',direction=0,color=1),node('filter',5,4,field='fg',masks=[7,1,2,4]),node('sensor',5,6,field='sg',direction=1,color=2),node('filter',5,1,field='fb',masks=[7,1,2,4]),node('sensor',5,0,field='sb',direction=3,color=4)]
base(8,'Sắc phổ vỡ','Cấp đúng đỏ, lục, lam cho ba mắt; bảo vệ tinh thể mỏng.',
'Ánh trắng chứa ba dải: đỏ=1, lục=2, lam=4. Bộ chia tạo ba nhánh yếu (cường độ 1) từ nguồn mạnh (2). Kính lọc chỉ cho dải được chọn đi qua. Tinh thể ở dưới gương I chỉ chịu cường độ 1: đừng đưa nguồn mạnh thẳng vào đó. Hãy chỉnh đường tia trước khi bật nguồn.',
'Màu sắc không phải mật mã. Chúng là chỉ dẫn để đánh thức những hạt giống đang ngủ.',
'Bộ chia, mặt nạ màu và cường độ',dict(light=0,m1=1,m2=1,fr=0,fg=0,fb=0,sr=0,sg=0,sb=0,optical_fault=0),[
 mirror('M1',2,3,'m1'),mirror('M2',2,2,'m2'),cycle('RED','Lọc nhánh phải','filter',.72,.32,'fr',4,['Trắng','Đỏ · 1','Lục · 2','Lam · 4']),cycle('GREEN','Lọc nhánh dưới','filter',.50,.61,'fg',4,['Trắng','Đỏ · 1','Lục · 2','Lam · 4']),cycle('BLUE','Lọc nhánh trên','filter',.50,.18,'fb',4,['Trắng','Đỏ · 1','Lục · 2','Lam · 4']),cycle('LIGHT','Nguồn sáng','lever',.12,.76,'light',2,['Tắt','Bật'])],
 [O('Đỏ đúng mắt',eq('sr',1)),O('Lục đúng mắt',eq('sg',1)),O('Lam đúng mắt',eq('sb',1))],
 ['M1','M2','RED','GREEN','GREEN','BLUE','BLUE','BLUE','LIGHT'],
 ['Định tuyến qua bộ chia trước. Ba nhánh sau bộ chia có thể lọc riêng.','Mỗi mắt cần đúng một dải, không chấp nhận ánh trắng dù ánh trắng chứa dải đó.','Nếu tinh thể quá tải, nguồn đã tự ngắt. Đổi hướng gương đầu tiên trước khi bật lại.'],
 ['Định tuyến tránh tinh thể','Bộ chia giảm cường độ','Mỗi nhánh có bộ lọc riêng'],wrong='LIGHT',optics=optical(nodes8,power=2),constraints=[dict(when=eq('optical_fault',1),effects=[S(light=0)],message='Tinh thể quá tải! Nguồn tự ngắt trước khi vỡ. Hãy đưa tia lên bộ chia.')])

nodes9=[node('mirror',3,3,field='m1'),node('shutter',3,2,field='shutterA'),node('mirror',3,0,field='m2'),node('sensor',8,0,field='sA',direction=0,color=7),node('shutter',3,4,field='shutterB'),node('mirror',3,6,field='m3'),node('sensor',8,6,field='sB',direction=0,color=7)]
base(9,'Bản đồ tinh tú','Ghi nhớ sao Bắc ở pha A, đổi pha rồi dẫn ánh sáng đến sao Nam.',
'Pha A: mắt Bắc phải sáng, khe Bắc mở và khe Nam đóng để ghi nhớ. Một nhịp sẽ giữ ký ức Bắc và đổi sang pha B. Sau đó đóng khe Bắc, mở khe Nam và đổi đường tia xuống mắt Nam. Mắt Nam nhận từ trái. Khóa sao cần cả ký ức Bắc và tia Nam đang sáng.',
'Bản đồ không dẫn đến một hành tinh. Nó ghi lại đường trở về, nếu một ngày thế giới ngoài kia hồi sinh.',
'Bộ nhớ quang học hai pha',dict(light=0,m1=1,m2=1,m3=0,shutterA=0,shutterB=0,sA=0,sB=0,phase=0,memory=0,locked=0,optical_fault=0),[
 mirror('M1',3,3,'m1'),mirror('M2',3,0,'m2'),mirror('M3',3,6,'m3'),cycle('NORTH','Khe Bắc','shutter',.65,.26,'shutterA',2,['Đóng','Mở']),cycle('SOUTH','Khe Nam','shutter',.65,.68,'shutterB',2,['Đóng','Mở']),cycle('LIGHT','Nguồn sáng','lever',.12,.74,'light',2,['Tắt','Bật']),
 C('STEP','Ghi pha A','button',.82,.43,'phase',[S(memory=1,phase=1)],guard=both(eq('phase',0),eq('sA',1),eq('shutterA',1),eq('shutterB',0)),reason='Chỉ ghi được pha A khi sao Bắc sáng và khe Nam đóng.'),
 C('LOCK','Khóa tinh tú','button',.83,.75,'locked',[S(locked=1)],guard=both(eq('phase',1),eq('memory',1),eq('sB',1),eq('shutterA',0),eq('shutterB',1)),reason='Cần ký ức Bắc, khe Bắc đóng và sao Nam đang sáng.')],
 [O('Đã ghi sao Bắc',eq('memory',1)),O('Sao Nam đang sáng',eq('sB',1)),O('Bản đồ khóa',eq('locked',1))],
 ['M1','M2','NORTH','LIGHT','STEP','NORTH','SOUTH','M1','M3','LOCK'],
 ['Sao Bắc có bộ nhớ, sao Nam thì không. Không cần chiếu cả hai cùng lúc.','Đúng pha A mới ghi được. Đừng mở khe Nam khi đang ghi Bắc.','Sau khi ghi, ký ức Bắc vẫn giữ dù đổi đường tia. Đóng khe cũ rồi mở khe mới.'],
 ['Ghi nhớ đúng pha','Shutter ngăn nhiễu chéo','Tái sử dụng gương đầu cho pha B'],wrong='STEP',optics=optical(nodes9),gauges=[G('memory','Ký ức Bắc',1,'gauge',.82,.18,1)])

def reactor_controls(final=False):
    return [cycle('GEAR','Khớp truyền','gear',.20,.38,'gear',3,['Rời','1:1','2:1'],group=0),cycle('VALVE','Tuyến lạnh','valve',.46,.69,'valve',3,['Đóng','Hồi lưu','Vào lõi'],group=1),cycle('PUMP','Máy bơm','lever',.20,.70,'pump',2,['Tắt','Bật'],guard=E('>=','$gear',1),reason='Bơm chưa nối với trục truyền động.',group=1),cycle('POWER','Công suất','lever',.77,.67,'power',4,['0','1','2','3'],group=2)]
def reactor_tick(extra=None):
    return [S(heat=E('max',0,E('+','$heat',E('*','$power',2),E('*','$cooling',-1))),powered=E('if',E('>','$power',0),1,0))]+(extra or [])

base(10,'Vòng tuần hoàn','Giữ công suất 2, nhiệt 2–6 qua 3 nhịp liên tiếp.',
'Trục tỷ số 2:1 mới đủ lực kéo bơm. Bơm chỉ làm lạnh khi van hướng Vào lõi; khi đó giảm 4 nhiệt mỗi nhịp. Công suất tạo 2 nhiệt mỗi bậc mỗi nhịp. Bắt đầu ở nhiệt 4; vùng ổn định 2–6. Cần công suất đúng 2 qua ba nhịp liên tiếp. Nhiệt trên 8 gây ngắt tự động.',
'Dòng lạnh trở lại. Trên thành lõi hiện ra biểu tượng một chiếc lá, không phải một tia chớp.',
'Ngân sách nhiệt và ổn định liên tục',dict(gear=0,valve=0,pump=0,power=0,cooling=0,heat=4,stable=0,powered=0),reactor_controls()+[
 C('STEP','Một nhịp lò','button',.51,.78,None,reactor_tick([S(stable=E('if',both(eq('power',2),E('>=','$heat',2),E('<=','$heat',6),eq('cooling',4)),E('+','$stable',1),0))]),sound='steam')],
 [O('Công suất 2',eq('power',2)),O('Nhiệt 2–6',both(E('>=','$heat',2),E('<=','$heat',6))),O('Ổn định 3 nhịp',E('>=','$stable',3))],
 ['GEAR','GEAR','VALVE','VALVE','PUMP','POWER','POWER','STEP','STEP','STEP'],
 ['Nhiệt tăng theo công suất, nhưng bơm chỉ có tác dụng khi nối đúng cả trục lẫn van.','Ở công suất 2, cần bù đúng 4 nhiệt mỗi nhịp. Tuyến hồi lưu không đi qua lõi.','Quan sát chỉ báo làm lạnh trước khi chạy liên tục. Một nhịp sai làm đếm ổn định về 0.'],
 ['Tỷ số truyền quyết định bơm','Van quyết định tuyến làm lạnh','Nhiệt cần cân bằng qua nhiều nhịp'],wrong='STEP',derived=dict(cooling=E('if',both(eq('gear',2),eq('pump',1),eq('valve',2)),4,0)),gauges=[G('heat','Nhiệt / 8',8,'gauge',.77,.30,4),G('cooling','Làm lạnh',4,'tank',.48,.32,4),G('stable','Nhịp ổn định',3,'gauge',.50,.12,3)],constraints=[dict(when=E('>','$heat',8),effects=[S(power=0,pump=0,heat=4,stable=0,powered=0)],message='Quá nhiệt: bộ ngắt đã cắt nguồn và đưa lõi về 4 nhiệt.')])

nodes11=[node('mirror',4,3,field='mirror'),node('sensor',4,0,field='sensor',direction=3,color=7)]
base(11,'Ba khóa an toàn','Giữ ba khóa cơ, nước, quang theo các điều kiện liên động.',
'Khóa cơ cần trục 2:1 đang gài. Nó mở đường bơm (mỗi nhịp tăng 1 áp từ nguồn). Khóa nước cần đúng 3 áp và van đã đóng để không còn dao động. Nó cấp điện cho đèn kiểm quang. Gương đưa tia lên mắt mới được giữ khóa quang. Đổi khớp sau khi giữ sẽ làm cả ba khóa rơi; áp lệch 3 làm khóa nước và quang rơi.',
'Ba hệ thống không canh giữ một bí mật. Chúng bảo vệ một điều mong manh hơn.',
'Liên động và mất điều kiện duy trì',dict(gear=0,pump=0,pressure=0,mech=0,hydro=0,opt=0,light=0,mirror=1,sensor=0,optical_fault=0),[
 cycle('GEAR','Khớp 2:1','gear',.18,.34,'gear',3,['Rời','1:1','2:1']),C('MECH','Giữ khóa cơ','button',.17,.69,'mech',[S(mech=1)],guard=eq('gear',2),reason='Khóa cơ cần tỷ số 2:1.'),
 cycle('PUMP','Van cấp áp','valve',.46,.45,'pump',2,['Đóng','Cấp'],guard=eq('mech',1),reason='Khóa cơ chưa cấp lực cho bơm.'),
 C('STEP','Một nhịp bơm','button',.45,.76,None,[S(pressure=E('min',5,E('+','$pressure','$pump')))],guard=eq('mech',1),reason='Giữ khóa cơ trước khi bơm.'),
 C('HYDRO','Giữ khóa nước','button',.47,.13,'hydro',[S(hydro=1)],guard=both(eq('mech',1),eq('pressure',3),eq('pump',0)),reason='Khóa nước cần áp 3 và van cấp đã đóng.'),
 mirror('M1',4,3,'mirror'),cycle('LIGHT','Đèn kiểm quang','lever',.77,.70,'light',2,['Tắt','Bật'],guard=eq('hydro',1),reason='Đèn chỉ nhận điện khi khóa nước đã ổn định.'),
 C('LOCK','Giữ khóa quang','button',.83,.28,'opt',[S(opt=1)],guard=both(eq('mech',1),eq('hydro',1),eq('sensor',1)),reason='Ba khóa phải thỏa cả cơ, nước và tia tới mắt.')],
 [O('Khóa cơ giữ',eq('mech',1)),O('Khóa nước giữ',eq('hydro',1)),O('Khóa quang giữ',eq('opt',1))],
 ['GEAR','GEAR','MECH','PUMP','STEP','STEP','STEP','PUMP','HYDRO','M1','LIGHT','LOCK'],
 ['Mỗi khóa cấp điều kiện cho hệ thống kế tiếp. Đọc thứ tự trên nhật ký.','Đạt áp 3 chưa đủ: phải đóng van để giữ ổn định trước khi giữ khóa nước.','Nếu một khóa rơi, kiểm tra điều kiện nền của nó trước khi giữ lại.'],
 ['Khóa cơ cấp lực','Van đóng giữ áp','Khóa nước cấp nguồn quang và phải duy trì'],wrong='HYDRO',optics=optical(nodes11),gauges=[G('pressure','Áp giữ',5,'gauge',.46,.26,3)],constraints=[dict(when=both(eq('mech',1),E('!=','$gear',2)),effects=[S(mech=0,hydro=0,opt=0,light=0,pump=0)],message='Trục đã đổi tỷ số: khóa cơ rơi và cắt hai khóa phụ thuộc.'),dict(when=both(eq('hydro',1),E('!=','$pressure',3)),effects=[S(hydro=0,opt=0,light=0)],message='Áp đã lệch 3: khóa nước rơi, điện kiểm quang bị cắt.')])

nodes12=[node('mirror',4,3,field='mirror'),node('shutter',4,2,field='shutter'),node('sensor',4,0,field='sensor',direction=3,color=7)]
stageA=both(eq('gear',2),eq('pressure',4))
stageB=both(eq('sensor',1),eq('cooling',4),eq('power',2))
base(12,'Cỗ máy cuối cùng','Hiệu chỉnh truyền động, dẫn quang năng rồi giữ lõi ổn định 4 nhịp.',
'A — Trục 2:1 kéo bơm. Van Hồi lưu tăng 1 áp mỗi nhịp, giữ ở 4 rồi chốt hiệu chỉnh. B — Chuyển van Vào lõi để làm lạnh; áp được giữ bằng van một chiều. Gương và khe chắn phải đưa tia lên mắt. Công suất 2 cộng 4 nhiệt, làm lạnh trừ 4. C — Duy trì áp 4, tia sáng, nhiệt 2–6 qua 4 nhịp rồi xác nhận. Đổi tỷ số hoặc mất áp làm chốt A rơi; mất tia/làm lạnh đưa về B, xóa chuỗi ổn định.',
'Cỗ máy chưa từng là một nguồn vũ khí. Nó là khu vườn cuối cùng — chờ bàn tay đủ kiên nhẫn để mở cửa.',
'Hiệu chỉnh nhiều giai đoạn và ràng buộc xuyên hệ thống',dict(gear=0,valve=0,pump=0,power=0,cooling=0,heat=4,pressure=0,stage=0,stable=0,light=0,mirror=1,shutter=0,sensor=0,optical_fault=0,door=0,powered=0),reactor_controls(True)+[
 mirror('M1',4,3,'mirror',group=2),cycle('SHUTTER','Khe quang','shutter',.65,.20,'shutter',2,['Đóng','Mở'],group=2),cycle('LIGHT','Nguồn quang','lever',.82,.44,'light',2,['Tắt','Bật'],guard=E('>=','$stage',1),reason='Nguồn quang chỉ mở sau hiệu chỉnh A.',group=2),
 C('CALIBRATE','Chốt hiệu chỉnh A','button',.16,.15,'stage',[S(stage=1)],guard=both(eq('stage',0),stageA),reason='Chốt A cần trục 2:1 và áp đúng 4.',group=0),
 C('ARM','Đồng bộ B','button',.50,.14,'stage',[S(stage=2,stable=0)],guard=both(eq('stage',1),stageB),reason='B cần tia tới mắt, làm lạnh 4 và công suất 2.',group=2),
 C('STEP','Một nhịp tổng','button',.51,.80,None,[IF(both(eq('stage',0),eq('gear',2),eq('pump',1),eq('valve',1)),[S(pressure=E('min',6,E('+','$pressure',1)))]),IF(E('>=','$stage',1),reactor_tick()),IF(eq('stage',2),[S(stable=E('if',both(stageA,stageB,E('>=','$heat',2),E('<=','$heat',6)),E('+','$stable',1),0))])],sound='steam',group=0),
 C('LOCK','Khởi động sự sống','button',.84,.80,'door',[S(door=1)],guard=both(eq('stage',2),E('>=','$stable',4),stageA,stageB,E('>=','$heat',2),E('<=','$heat',6)),reason='Cần đủ 4 nhịp ổn định, các khóa vẫn giữ và nhiệt 2–6.',group=2)],
 [O('A · truyền động và áp',both(E('>=','$stage',1),stageA)),O('B · quang và lạnh',stageB),O('C · bốn nhịp và cửa mở',both(E('>=','$stable',4),eq('door',1)))],
 ['GEAR','GEAR','VALVE','PUMP','STEP','STEP','STEP','STEP','CALIBRATE','VALVE','POWER','POWER','M1','SHUTTER','LIGHT','ARM','STEP','STEP','STEP','STEP','LOCK'],
 ['Ba cụm dùng chung trục và bơm. Hiệu chỉnh A tạo nền cho quang năng B và ổn định C.','Sau chốt A, chuyển van từ hồi lưu sang lõi. Nếu để hồi lưu, lò sẽ thiếu làm lạnh.','Khi C mất ổn định, trở lại điều kiện của B. Chỉ xác nhận sau bốn nhịp an toàn liên tiếp.'],
 ['Hồi lưu tạo áp, vào lõi làm lạnh','Chốt A cấp điện cho quang','Mất nền làm giai đoạn sau rơi','Cần duy trì chứ không chỉ chạm mốc'],wrong='ARM',optics=optical(nodes12),derived=dict(cooling=E('if',both(eq('gear',2),eq('pump',1),eq('valve',2)),4,0)),gauges=[G('pressure','Áp · đích 4',6,'gauge',.18,.56,4),G('heat','Nhiệt · 2–6',8,'gauge',.78,.16,4),G('stable','Chuỗi / 4',4,'gauge',.51,.58,4)],constraints=[dict(when=both(E('>=','$stage',1),E('any',E('!=','$gear',2),E('!=','$pressure',4))),effects=[S(stage=0,stable=0,light=0,power=0)],message='Nền hiệu chỉnh bị thay đổi: chốt A rơi, nguồn quang bị cắt.'),dict(when=both(eq('stage',2),E('any',eq('sensor',0),E('!=','$cooling',4),E('!=','$power',2))),effects=[S(stage=1,stable=0)],message='Mất đồng bộ: quay lại B và thiết lập chuỗi ổn định mới.'),dict(when=E('>','$heat',8),effects=[S(stage=1,power=0,heat=4,stable=0,powered=0)],message='Ngắt nhiệt khẩn cấp. Áp hiệu chỉnh còn giữ; hãy khôi phục làm lạnh trước.')])

L[0]['initial'].update(ratioNumerator=0,ratioDenominator=1,networkJam=0)
L[0]['derived']={}
L[0]['mechanical']=dict(source='input',output='output',direction=E('if',eq('reverse',0),1,-1),nodes=[dict(id='input',teeth=24),dict(id='gearA',teeth=E('*','$gearA',12)),dict(id='idler',teeth=12),dict(id='gearB',teeth=E('*','$gearB',12)),dict(id='output',teeth=12)],edges=[dict(a='input',b='gearA',type='shaft'),dict(a='gearA',b='idler',type='mesh'),dict(a='idler',b='gearB',type='mesh'),dict(a='gearB',b='output',type='shaft')])
L[0]['constraints'][0]['when']=both(eq('powered',1),E('any',E('!=','$ratio',2),E('!=','$direction',1),eq('safety',0),eq('networkJam',1)))
from phase2_content import upgrade
upgrade(L)
(ROOT/'assets/data/levels.json').write_text(json.dumps(dict(schema_version=2,levels=L),ensure_ascii=False,indent=2),encoding='utf8')
rows=['# Level matrix — authored baseline','', '| ID | Rule | Inferences | Target moves |', '|---|---|---|---|']
for l in L: rows.append(f"| {l['id']} — {l['title']} | {l['introduced_rule']} | {'; '.join(l['required_inferences'])} | {l['target_moves']} |")
rows+=['','Reference and wrong traces, guards, explicit consequences, objectives, layouts and hints live in assets/data/levels.json. These move thresholds are baselines, not optimality claims.']
(ROOT/'docs/LEVEL_MATRIX.md').write_text('\n'.join(rows),encoding='utf8')
print(f'Authored {len(L)} canonical levels.')
