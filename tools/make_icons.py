from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parents[1]
gear=Image.open(root/'assets/images/chapters/brass/prop0.png').convert('RGBA')
base=Image.new('RGBA',(512,512),'#0b131a');base.alpha_composite(gear)
d=ImageDraw.Draw(base);d.ellipse((170,170,342,342),fill='#0b131a',outline='#deb06e',width=5)
font=ImageFont.truetype(str(root/'assets/fonts/NotoSerif.ttf'),104)
d.text((256,247),'M',font=font,fill='#deb06e',anchor='mm')
base.save(root/'assets/images/ui/icon.png')
for directory,side in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    base.resize((side,side),Image.Resampling.LANCZOS).save(root/f'android/app/src/main/res/mipmap-{directory}/ic_launcher.png')
base.resize((32,32)).save(root/'web/favicon.png')
# Initial thumbnails are authored compositions. Android screenshots replace them
# after the actual on-device playthrough, never mislabeled as screenshots.
for i in range(12):
    biome=['brass','water','prism','core'][i//3]
    bg=Image.open(root/f'assets/images/chapters/{biome}/room.png').convert('RGBA').resize((640,360))
    sprite=Image.open(root/f'assets/images/chapters/{biome}/prop0.png').convert('RGBA')
    for j in range(2+i%3):
        side=115 if i%3!=1 else 92
        p=sprite.resize((side,side));bg.alpha_composite(p,(160+j*100,120+(j%2)*20))
    bg.convert('RGB').save(root/f'assets/images/ui/lv{i+1:02}.png')
print('Launcher icon and twelve authored thumbnails generated.')
