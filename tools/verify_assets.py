from pathlib import Path
import json,hashlib,wave
from PIL import Image
root=Path(__file__).resolve().parents[1]
records=json.loads((root/'assets/manifest.json').read_text(encoding='utf8'))
ids=set(); image_count=0
for a in records:
    assert a['id'] not in ids;ids.add(a['id'])
    path=root/a['path'];assert path.is_file(),path
    if path.suffix.lower()=='.png':
        image_count+=1
        with Image.open(path) as im:
            im.load();assert im.width>0 and im.height>0
            if a['alpha']:
                assert im.mode=='RGBA'
                lo,hi=im.getchannel('A').getextrema();assert lo==0 and hi==255
    assert a['sha256']==hashlib.sha256(path.read_bytes()).hexdigest(),path
for path in (root/'assets/audio').rglob('*.wav'):
    with wave.open(str(path)) as w:
        assert w.getnframes()>2000 and w.getsampwidth()==2
        content=w.readframes(w.getnframes());assert any(content)
assert len(list((root/'assets/audio/music').glob('*.wav')))==4
assert len(list((root/'assets/audio/sfx').glob('*.wav')))==19
levels=json.loads((root/'assets/data/levels.json').read_text(encoding='utf8'))['levels']
assert len(levels)==12
for l in levels:
    assert (root/f"assets/images/ui/lv{l['number']:02}.png").is_file()
assert 'references/' not in (root/'pubspec.yaml').read_text()
shipped={p.relative_to(root).as_posix() for p in (root/'assets').rglob('*') if p.is_file() and p.name!='manifest.json'}
assert shipped=={a['path'] for a in records},'Manifest coverage differs from asset tree'
(root/'docs/evidence/asset_integrity.json').write_text(json.dumps({'status':'PASS','asset_count':len(records),'image_count':image_count,'music_count':4,'sfx_count':19,'assets':records},ensure_ascii=False,indent=2),encoding='utf8')
print(f'PASS: {len(records)} manifested assets, {image_count} images, 12 thumbnails, 4 music loops, 19 nonempty SFX; source references excluded.')
