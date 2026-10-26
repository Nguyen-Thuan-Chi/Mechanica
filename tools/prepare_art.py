from pathlib import Path
import json, csv, urllib.request
from PIL import Image, ImageOps, ImageDraw

root=Path(__file__).resolve().parents[1]
sources=json.loads((root/'tools/art_sources.json').read_text())
manifest=[]
gallery=Image.new('RGB',(1200,1000),'#10151b')
for i,(biome,paths) in enumerate(sources.items()):
    folder=root/'assets/images/chapters'/biome
    folder.mkdir(parents=True,exist_ok=True)
    room=Image.open(paths['room']).convert('RGB')
    room=ImageOps.fit(room,(1600,900),method=Image.Resampling.LANCZOS)
    room.save(folder/'room.png',optimize=True)
    gallery.paste(room.resize((600,337)),((i%2)*600,(i//2)*500))
    kit=Image.open(paths['kit']).convert('RGBA')
    w,h=kit.size
    for k in range(4):
        cell=kit.crop(((k%2)*w//2,(k//2)*h//2,(k%2+1)*w//2,(k//2+1)*h//2))
        bbox=cell.getchannel('A').point(lambda x:255 if x>12 else 0).getbbox()
        if not bbox: raise RuntimeError('Empty sprite')
        cell=cell.crop(bbox)
        cell.thumbnail((480,480),Image.Resampling.LANCZOS)
        sprite=Image.new('RGBA',(512,512))
        sprite.alpha_composite(cell,((512-cell.width)//2,(512-cell.height)//2))
        sprite.save(folder/f'prop{k}.png',optimize=True)
        preview=sprite.resize((140,140))
        gallery.paste(preview,((i%2)*600+k*150,(i//2)*500+345),preview)
        manifest.append(dict(id=f'ART_CH{i+1:02}_PROP{k}',path=f'assets/images/chapters/{biome}/prop{k}.png',chapter=f'CH{i+1:02}',role=['device','secondary device','foreground','light'][k],size='512x512',alpha=True,pivot='0.5,0.5',format='PNG',method='image_gen; normalized alpha crop',license='AI-generated original output',qa='DECODED_ALPHA'))
    manifest.append(dict(id=f'ART_CH{i+1:02}_ROOM',path=f'assets/images/chapters/{biome}/room.png',chapter=f'CH{i+1:02}',role='room environment',size='1600x900',alpha=False,pivot='center',format='PNG',method='image_gen; aspect crop',license='AI-generated original output',qa='DECODED'))
    room.resize((640,360)).save(folder/'card.png')
gallery.save(root/'docs/evidence/art_contact_sheet.jpg',quality=92)
(root/'assets/manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
with (root/'docs/ASSET_MANIFEST.csv').open('w',encoding='utf8',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=manifest[0].keys());writer.writeheader();writer.writerows(manifest)
for family in ['notosans','notoserif']:
    name={'notosans':'NotoSans','notoserif':'NotoSerif'}[family]
    url=f'https://raw.githubusercontent.com/google/fonts/main/ofl/{family}/{name}%5Bwdth,wght%5D.ttf'
    urllib.request.urlretrieve(url,root/f'assets/fonts/{name}.ttf')
    urllib.request.urlretrieve(f'https://raw.githubusercontent.com/google/fonts/main/ofl/{family}/OFL.txt',root/f'assets/fonts/{name}-OFL.txt')
print('Four rooms, sixteen alpha props, four cards and two font families prepared.')
