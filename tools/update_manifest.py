"""Inventory every shipped asset, including derived cards, fonts and audio."""
from pathlib import Path
from PIL import Image
import json,csv,wave,hashlib
root=Path(__file__).resolve().parents[1]
existing=json.loads((root/'assets/manifest.json').read_text(encoding='utf8'))
by_path={a['path']:a for a in existing}
for p in sorted((root/'assets').rglob('*')):
    if not p.is_file() or p.name=='manifest.json':continue
    rel=p.relative_to(root).as_posix()
    if rel in by_path and p.suffix.lower() != '.wav':continue
    ext=p.suffix.lower();role='data';method='Authored project source';license='Project-authored original';size=str(p.stat().st_size)+' bytes';alpha=False;chapter='ALL';pivot='n/a'
    if ext=='.png':
        with Image.open(p) as im:size=f'{im.width}x{im.height}';alpha=im.mode=='RGBA' and im.getchannel('A').getextrema()[0]==0
        role='UI illustration';method='Derived from original generated project art';license='AI-generated original output';pivot='center'
        if p.name.startswith('lv'):
            number=int(p.stem[2:]);chapter=f'CH{(number-1)//3+1:02}';role='level thumbnail';method='Runtime screenshot crop' if (root/f'docs/evidence/android_lv{number:02}.png').exists() else method
        if p.parent.name=='exploration':role='interactive room and inventory prop';method='Built-in imagegen; alpha crop tools/prepare_exploration.py'
        if p.name=='ending.png':role='final garden environment';method='image_gen; aspect crop'
    elif ext=='.wav':
        with wave.open(str(p)) as w:size=f'{w.getnframes()/w.getframerate():.2f}s PCM {w.getframerate()}Hz mono'
        role='ambient loop' if p.parent.name=='music' else 'sound effect';method='Original deterministic synthesis tools/generate_audio.py + tools/upgrade_audio.py';license='Original project audio; no samples'
    elif ext in ['.ttf','.txt']:
        role='font' if ext=='.ttf' else 'font license';method='Google Fonts official repository';license='SIL Open Font License 1.1'
    a=dict(id=('SFX_' if role=='sound effect' else 'MUSIC_' if role=='ambient loop' else 'FONT_' if role=='font' else 'ART_' if ext=='.png' else 'DATA_')+p.stem.upper().replace('-','_'),path=rel,chapter=chapter,role=role,size=size,alpha=alpha,pivot=pivot,format=ext[1:].upper(),method=method,license=license,qa='FILE_VERIFIED')
    if p.name=='card.png':a['id']='ART_CARD_'+p.parent.name.upper()
    by_path[rel]=a
records=list(by_path.values());ids=[a['id'] for a in records];assert len(ids)==len(set(ids))
for a in records:
    path=root/a['path']
    a['sha256']=hashlib.sha256(path.read_bytes()).hexdigest()
    if path.suffix.lower() not in ['.png','.wav']:a['size']=str(path.stat().st_size)+' bytes'
(root/'assets/manifest.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf8')
with (root/'docs/ASSET_MANIFEST.csv').open('w',encoding='utf8',newline='') as f:
    writer=csv.DictWriter(f,fieldnames=records[0].keys());writer.writeheader();writer.writerows(records)
print(f'Inventoried {len(records)} shipped assets.')
