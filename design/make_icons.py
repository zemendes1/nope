# Renders design/app-icon.svg geometry with transparency (qlmanage adds a white bg).
import sys
from PIL import Image, ImageDraw
out = sys.argv[1]
SS = 4096  # supersampled canvas, 4x the 1024 design grid
k = SS / 1024
top = (0x2D, 0xD4, 0xBF); bot = (0x0D, 0x94, 0x88)
grad = Image.new("RGBA", (SS, SS))
gd = ImageDraw.Draw(grad)
for y in range(SS):
    t = y / (SS - 1)
    gd.line([(0, y), (SS, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bot)) + (255,))
mask = Image.new("L", (SS, SS), 0)
ImageDraw.Draw(mask).rounded_rectangle([100*k, 100*k, 924*k, 924*k], radius=185*k, fill=255)
img = Image.new("RGBA", (SS, SS), (0, 0, 0, 0))
img.paste(grad, (0, 0), mask)
d = ImageDraw.Draw(img)
w = 72*k; r = 300*k; c = 512*k
d.ellipse([c-r-w/2, c-r-w/2, c+r+w/2, c+r+w/2], fill="white")
d.ellipse([c-r+w/2, c-r+w/2, c+r-w/2, c+r-w/2], fill=(0, 0, 0, 0))
# re-fill inner disc with gradient
inner = Image.new("L", (SS, SS), 0)
ImageDraw.Draw(inner).ellipse([c-r+w/2, c-r+w/2, c+r-w/2, c+r-w/2], fill=255)
img.paste(grad, (0, 0), inner)
d.line([(300*k, 300*k), (724*k, 724*k)], fill="white", width=round(w))
for n in (16, 32, 128, 256, 512):
    img.resize((n, n), Image.LANCZOS).save(f"{out}/AppIcon-{n}.png")
    img.resize((2*n, 2*n), Image.LANCZOS).save(f"{out}/AppIcon-{n}@2x.png")
