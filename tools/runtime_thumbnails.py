"""Make level cards from real Android captures, never mockups."""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
root=Path(__file__).resolve().parents[1]
sheet=Image.new('RGB',(1280,1080),'#0b131a')
for n in range(1,13):
    path=root/f'docs/evidence/p2_lv{n:02}.png'
    if not path.exists():path=root/f'docs/evidence/android_lv{n:02}.png'
    with Image.open(path) as image:
        w,h=image.size
        # Exclude the Flutter HUD, preserving the rendered machine and room.
        crop=image.crop((int(w*.10),int(h*.17),int(w*.90),int(h*.80)))
        thumbnail=ImageOps.fit(crop,(640,360),method=Image.Resampling.LANCZOS)
        thumbnail.save(root/f'assets/images/ui/lv{n:02}.png')
        tile=ImageOps.fit(image.convert('RGB'),(426,270),method=Image.Resampling.LANCZOS)
        sheet.paste(tile,(((n-1)%3)*426,((n-1)//3)*270))
sheet.save(root/'docs/evidence/runtime_contact_sheet.jpg',quality=92)
print('12 level cards cropped from actual Android screenshots; runtime contact sheet saved.')
