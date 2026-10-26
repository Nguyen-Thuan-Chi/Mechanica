"""Original periodic ambient scores and interaction Foley; no sampled audio."""
from pathlib import Path
import numpy as np,wave,json
R=Path(__file__).resolve().parents[1];RATE=22050;D=32;N=RATE*D;t=np.arange(N)/RATE
def write(path,s):
 s=np.tanh(s)*.72
 with wave.open(str(path),'wb') as w:w.setparams((1,2,RATE,0,'NONE','not compressed'));w.writeframes((s*32767).astype('<i2').tobytes())
def sine(f):return np.sin(2*np.pi*round(f*D)/D*t)
def note(s,at,f,amp,decay,metal=False):
 tt=np.arange(int(RATE*min(8,decay*8)))/RATE
 env=(1-np.exp(-tt*90))*np.exp(-tt/decay)
 voice=np.sin(2*np.pi*f*tt)+(.28 if metal else .12)*np.sin(2*np.pi*f*(2.71 if metal else 2)*tt)+.07*np.sin(2*np.pi*f*4*tt)
 idx=(np.arange(len(tt))+int(at*RATE))%N;s[idx]+=voice*env*amp
rng=np.random.default_rng(705)
names=['Nhịp người thợ vắng','Những trang dưới nước','Bầu trời ghi nhớ','Hơi thở dưới lòng núi']
reports=[]
for ch,base in enumerate([55,49,65.406,36.708]):
 s=.07*sine(base)+.045*sine(base*1.5)+.025*sine(base*2)*(1+.2*np.sin(2*np.pi*t/16))
 if ch==0:
  for at,f in zip([0,4,9,14,18,24,28],[220,329.63,261.63,196,293.66,246.94,164.81]):note(s,at,f,.095,1.8)
  for at in np.arange(0,D,.8):note(s,at,1760,.011,.035,True)
  note(s,12,523.25,.035,3,True)
 elif ch==1:
  for at,f in zip([1,6,13,19,25],[196,146.83,220,164.81,130.81]):note(s,at,f,.045,3)
  for at in rng.uniform(0,D,50):note(s,at,rng.uniform(300,700),.012,.16)
  s+=.018*sine(82.406)*(np.sin(2*np.pi*t/8)**2)
 elif ch==2:
  for at,f in zip([0,5,11,16,22,27],[523.25,783.99,659.25,392,587.33,440]):
   for echo in range(4):note(s,at+echo*.7,f,.07*(.47**echo),2.5,True)
 else:
  s+=.035*sine(49)*np.sin(np.pi*t/2)**12
  for at,f in zip([2,10,18,26],[73.416,98,110,82.406]):note(s,at,f,.07,3.5)
  for at in np.arange(0,D,4):note(s,at,294,.022,.25,True)
 p=R/f'assets/audio/music/ch{ch+1}.wav';write(p,s)
 reports.append(dict(file=p.relative_to(R).as_posix(),title=names[ch],seconds=D,source='Original additive synthesis; tools/upgrade_audio.py',license='Original project audio, no samples',boundary_difference=float(abs(s[0]-s[-1]))))
for i,name in enumerate(['inventory','pickup','clue','latch','transition','motor_start','motor_stop','jam']):
 d=1.2 if name.startswith('motor') else .8 if name in ['clue','transition'] else .35
 tt=np.arange(int(d*RATE))/RATE;env=(1-np.exp(-tt*160))*np.exp(-tt/(d/4))
 f=[310,660,880,140,240,70,150,95][i]
 if name.startswith('motor'):
  phase=2*np.pi*(f*tt+(100 if name=='motor_start' else -45)*tt**2)
  s=(.16*np.sin(phase)+.045*rng.normal(size=len(tt)))*env
 else:s=(.2*np.sin(2*np.pi*f*tt)+.08*np.sin(2*np.pi*f*2.71*tt))*env
 if name=='jam':s+=.15*rng.normal(size=len(tt))*env
 write(R/f'assets/audio/sfx/{name}.wav',s)
(R/'docs/PHASE2_AUDIO_MANIFEST.json').write_text(json.dumps(reports,ensure_ascii=False,indent=2),encoding='utf8')
print('4 original 32-second periodic scores; 8 new SFX (19 SFX total).')
