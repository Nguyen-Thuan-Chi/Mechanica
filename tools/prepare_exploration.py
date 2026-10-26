from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parents[1]
folder=root/'assets/images/exploration';folder.mkdir(exist_ok=True)
source=root/'art_sources/phase2'
atlases=[('exec-7816a07b-041c-4c2b-9a7e-e33b2812f729.png',['cabinet','notebook','key','coupler']),('exec-7ed0bfbc-91fd-40e6-b0fe-85e886a04637.png',['hose','filter','gasket','fuse'])]
for file,names in atlases:
 with Image.open(source/file) as im:
  im=im.convert('RGBA');w,h=im.size
  for i,name in enumerate(names):
   cell=im.crop((i%2*w//2,i//2*h//2,(i%2+1)*w//2,(i//2+1)*h//2))
   bbox=cell.getchannel('A').point(lambda x:255 if x>12 else 0).getbbox();assert bbox
   cell=cell.crop(bbox);cell.thumbnail((480,480),Image.Resampling.LANCZOS)
   out=Image.new('RGBA',(512,512));out.alpha_composite(cell,((512-cell.width)//2,(512-cell.height)//2));out.save(folder/f'{name}.png')
(root/'docs/PHASE2_ART_SOURCES.json').write_text(json.dumps({'tool':'built-in image_gen','license':'AI-generated original output, not CC0','source_folder':str(source),'atlases':atlases,'contract':'Front-facing illustrated mechanical adventure, tactile worn materials, upper-left light, 2x2 isolated true-alpha sprites. Cabinet/notebook/key/coupler; hose/filter/gasket/fuse. No text, logos or UI.','runtime_folder':'assets/images/exploration'},ensure_ascii=False,indent=2),encoding='utf8')
print('8 original exploration sprites normalized to 512x512 true alpha.')
