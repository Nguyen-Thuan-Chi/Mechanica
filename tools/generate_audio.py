"""Original synthesis; no external music or samples. Loop endpoints periodic."""
from pathlib import Path
import wave
import numpy as np
R=Path(__file__).resolve().parents[1]/'assets/audio'
RATE=22050
def save(path,signal):
    signal=np.tanh(signal)*.65
    data=(signal*32767).astype('<i2')
    with wave.open(str(R/path),'wb') as w:w.setparams((1,2,RATE,0,'NONE','not compressed'));w.writeframes(data.tobytes())
for chapter,chord in enumerate([[55,82.5,110,138.75],[65.5,98.25,131,164.75],[73.5,110,147,185],[49,73.5,98,123.5]]):
    duration=24;t=np.arange(RATE*duration)/RATE
    s=np.zeros_like(t)
    for i,f in enumerate(chord):
        f=round(f*duration)/duration
        s+=(.10/(1+i*.35))*np.sin(2*np.pi*f*t+.25*np.sin(2*np.pi*t/12))*((.7+.3*np.cos(2*np.pi*t/(12 if i%2 else 24))))
        s+=.025*np.sin(2*np.pi*f*2*t)
    # Periodic mechanical pulses / water shimmer / starlight / core heartbeat.
    if chapter==0:s+=.035*np.sin(2*np.pi*440*t)*np.exp(-((t%3)/.12))
    if chapter==1:s+=.025*np.sin(2*np.pi*660*t+np.sin(2*np.pi*t/6))*np.sin(np.pi*t/3)**8
    if chapter==2:s+=.032*np.sin(2*np.pi*880*t)*np.sin(np.pi*t/6)**12
    if chapter==3:s+=.06*np.sin(2*np.pi*49*t)*np.sin(np.pi*t/1.5)**16
    # Tiny endpoint fades avoid clicks even with codecs lacking gapless loop.
    s[:220]*=np.linspace(0,1,220);s[-220:]*=np.linspace(1,0,220)
    save(Path('music')/f'ch{chapter+1}.wav',s)
rng=np.random.default_rng(941)
names=['click','switch','metal','gear','steam','valve','water','beam','door','win','fail']
for i,name in enumerate(names):
    d={'door':1.4,'win':1.8,'steam':.8,'water':.65,'fail':.55}.get(name,.28)
    t=np.arange(int(RATE*d))/RATE;env=np.exp(-t/(d/3))*np.minimum(1,t/.005)
    s=.35*np.sin(2*np.pi*(220+i*37)*t)*env
    if name in ['metal','gear','valve','switch']:s+=.16*np.sin(2*np.pi*1327*t)*env+.10*rng.normal(0,1,len(t))*env
    if name in ['steam','water','door']:s=.16*rng.normal(0,1,len(t))*env+.1*np.sin(2*np.pi*(70+130*t)*t)*env
    if name=='beam':s=.25*np.sin(2*np.pi*(640*t+600*t*t))*env
    if name=='win':
        s=np.zeros_like(t)
        for k,f in enumerate([261.63,329.63,392,523.25]):
            tt=np.maximum(0,t-k*.2);s+=.22*np.sin(2*np.pi*f*tt)*np.exp(-tt*3)*(t>=k*.2)
    if name=='fail':s=.25*np.sin(2*np.pi*(230*t-90*t*t))*env
    save(Path('sfx')/(name+'.wav'),s)
print('4 ambient loops (24 s each), 11 original SFX, PCM 22050 Hz.')
