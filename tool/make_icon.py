# Genera el ícono y las imágenes del splash de ApuntIA.
# Uso: python3 tool/make_icon.py  (requiere Pillow)
from PIL import Image, ImageDraw, ImageFilter
import math

PURPLE=(91,63,245,255); NAVY=(17,19,46,255); LAV=(236,232,255,255)
ORANGE=(255,181,65,255); WHITE=(255,255,255,255); LINE=(205,198,245,255)
SS=4  # supersampling

def rounded_card(w,h,r,fill,shadow=False):
    pad=60*SS
    im=Image.new('RGBA',(w+2*pad,h+2*pad),(0,0,0,0))
    d=ImageDraw.Draw(im)
    if shadow:
        sh=Image.new('RGBA',im.size,(0,0,0,0)); ds=ImageDraw.Draw(sh)
        ds.rounded_rectangle([pad,pad+18*SS,pad+w,pad+h+18*SS],r,fill=(20,10,80,90))
        sh=sh.filter(ImageFilter.GaussianBlur(22*SS)); im=Image.alpha_composite(im,sh); d=ImageDraw.Draw(im)
    d.rounded_rectangle([pad,pad,pad+w,pad+h],r,fill=fill)
    return im,pad,d

def sparkle(d,cx,cy,R,fill):
    # estrella de 4 puntas con lados curvos
    pts=[]
    for i in range(400):
        t=2*math.pi*i/400
        c,s=math.cos(t),math.sin(t)
        # astroid-like: |x|^(2/3)+|y|^(2/3)=R^(2/3) suavizado
        x=R*math.copysign(abs(c)**3,c); y=R*math.copysign(abs(s)**3,s)
        pts.append((cx+x,cy+y))
    d.polygon(pts,fill=fill)

def art(size):
    """Arte (tarjetas + chispa) sobre lienzo transparente de size*size."""
    S=size*SS
    k=S/1024
    canvas=Image.new('RGBA',(S,S),(0,0,0,0))
    # tarjeta trasera
    w,h,r=int(540*k),int(380*k),int(56*k)
    back,pad,_=rounded_card(w,h,r,LAV,shadow=True)
    back=back.rotate(13,resample=Image.BICUBIC,expand=True)
    canvas.alpha_composite(back,(int(420*k-back.width/2),int(445*k-back.height/2)))
    # tarjeta frontal
    w,h,r=int(580*k),int(410*k),int(60*k)
    front,pad,d=rounded_card(w,h,r,WHITE,shadow=True)
    x0,y0=pad+int(70*k),pad+int(95*k)
    d.rounded_rectangle([x0,y0,x0+int(300*k),y0+int(54*k)],int(27*k),fill=PURPLE)
    d.rounded_rectangle([x0,y0+int(110*k),x0+int(440*k),y0+int(150*k)],int(20*k),fill=LINE)
    d.rounded_rectangle([x0,y0+int(190*k),x0+int(340*k),y0+int(230*k)],int(20*k),fill=LINE)
    front=front.rotate(-5,resample=Image.BICUBIC,expand=True)
    canvas.alpha_composite(front,(int(500*k-front.width/2),int(575*k-front.height/2)))
    # chispa IA
    d=ImageDraw.Draw(canvas)
    sparkle(d,735*k,300*k,175*k,ORANGE)
    sparkle(d,850*k,170*k,62*k,ORANGE)
    return canvas.resize((size,size),Image.LANCZOS)

def full_icon(size=1024):
    bg=Image.new('RGBA',(size*SS,size*SS),PURPLE)
    # degradado sutil
    g=Image.new('RGBA',bg.size,(0,0,0,0)); dg=ImageDraw.Draw(g)
    for i in range(0,bg.height,4):
        a=int(70*i/bg.height); dg.rectangle([0,i,bg.width,i+4],fill=(30,10,120,a))
    bg=Image.alpha_composite(bg,g).resize((size,size),Image.LANCZOS)
    a=art(int(size*0.86)); off=(size-a.width)//2
    bg.alpha_composite(a,(off,off+int(size*0.01)))
    return bg.convert('RGB')

def centered(canvas_size, art_size, bg=(0,0,0,0)):
    c=Image.new('RGBA',(canvas_size,canvas_size),bg)
    a=art(art_size); off=(canvas_size-art_size)//2
    c.alpha_composite(a,(off,off)); return c

import os
out=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','assets','branding'); os.makedirs(out,exist_ok=True)
full_icon().save(f'{out}/icon.png')
# Android adaptativo: zona segura 66% -> arte en ~62%
centered(1024,int(1024*0.66)).save(f'{out}/icon_foreground.png')
# Splash: logo en mosaico morado redondeado
tile=Image.new('RGBA',(768*SS,768*SS),(0,0,0,0)); dt=ImageDraw.Draw(tile)
dt.rounded_rectangle([0,0,768*SS-1,768*SS-1],180*SS,fill=PURPLE)
tile=tile.resize((768,768),Image.LANCZOS); a=art(660); tile.alpha_composite(a,(54,60))
tile.save(f'{out}/splash_logo.png')
# Android 12: imagen 1152 con el arte dentro del círculo de 768
c=Image.new('RGBA',(1152,1152),(0,0,0,0)); a=art(700); c.alpha_composite(a,(226,232)); c.save(f'{out}/splash_android12.png')
print('Listo: assets/branding')
