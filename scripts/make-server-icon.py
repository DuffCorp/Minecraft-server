#!/usr/bin/env python3
"""
make-server-icon.py
Generates server-icon.png (64x64) for the Ballsnia Minecraft server:
a Pokeball whose top half is the Bosnian flag (blue field, yellow triangle,
diagonal white stars), with the classic black band and white centre button.

Drawn on a large canvas and downscaled with LANCZOS so the 64x64 edges are clean.
No external tools needed - just Pillow (PIL).

    python scripts/make-server-icon.py
"""

import math
import os
from PIL import Image, ImageDraw

S = 1024                      # supersample canvas
OUT_SIZE = 64                 # Minecraft server-icon.png must be 64x64
cx = cy = S / 2

# Bosnia & Herzegovina flag palette + Pokeball parts
BLUE   = (0, 47, 135)
YELLOW = (252, 209, 22)
WHITE  = (255, 255, 255)
BLACK  = (26, 26, 26)

R_RIM    = 0.49 * S           # outer black rim radius
R_INNER  = 0.45 * S           # content radius (inside the rim)
BAND_H   = 0.16 * S           # black equatorial band height
BTN_OUT  = 0.155 * S          # button black ring radius
BTN_IN   = 0.10 * S           # button white centre radius


def star(draw, x, y, r_out, fill, rot=-math.pi / 2):
    r_in = r_out * 0.42
    pts = []
    for i in range(10):
        ang = rot + i * math.pi / 5
        r = r_out if i % 2 == 0 else r_in
        pts.append((x + r * math.cos(ang), y + r * math.sin(ang)))
    draw.polygon(pts, fill=fill)


# --- 1. content layer (full square, clipped to a disc later) -----------------
content = Image.new("RGB", (S, S), WHITE)
d = ImageDraw.Draw(content)

# top half blue, bottom half stays white
d.rectangle([0, 0, S, cy], fill=BLUE)

# Bosnia motif: yellow right-triangle + diagonal white stars (upper-left field)
A = (0.42 * S, 0.10 * S)
B = (0.74 * S, 0.10 * S)
C = (0.74 * S, 0.40 * S)
d.polygon([A, B, C], fill=YELLOW)
for t in (0.2, 0.5, 0.8):
    sx = A[0] + t * (C[0] - A[0])
    sy = A[1] + t * (C[1] - A[1])
    star(d, sx, sy, 0.052 * S, WHITE)

# black band across the middle
d.rectangle([0, cy - BAND_H / 2, S, cy + BAND_H / 2], fill=BLACK)

# centre button
d.ellipse([cx - BTN_OUT, cy - BTN_OUT, cx + BTN_OUT, cy + BTN_OUT], fill=BLACK)
d.ellipse([cx - BTN_IN, cy - BTN_IN, cx + BTN_IN, cy + BTN_IN], fill=WHITE)

# --- 2. compose onto a black disc (the rim) ----------------------------------
base = Image.new("RGB", (S, S), BLACK)
inner_mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(inner_mask).ellipse(
    [cx - R_INNER, cy - R_INNER, cx + R_INNER, cy + R_INNER], fill=255)
base.paste(content, (0, 0), inner_mask)

# --- 3. clip the whole thing to the outer disc (transparent corners) ---------
outer_mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(outer_mask).ellipse(
    [cx - R_RIM, cy - R_RIM, cx + R_RIM, cy + R_RIM], fill=255)
icon = base.convert("RGBA")
icon.putalpha(outer_mask)

# --- 4. downscale + save into assets/ ----------------------------------------
icon = icon.resize((OUT_SIZE, OUT_SIZE), Image.LANCZOS)
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
assets = os.path.join(root, "assets")
os.makedirs(assets, exist_ok=True)
out = os.path.join(assets, "server-icon.png")
icon.save(out)
print(f"Wrote {out} ({OUT_SIZE}x{OUT_SIZE})")

# also a crisp 256px version for use as the Prism/MultiMC launcher icon
launcher = base.convert("RGBA")
launcher.putalpha(outer_mask)
launcher = launcher.resize((256, 256), Image.LANCZOS)
lout = os.path.join(assets, "ballsnia-icon.png")
launcher.save(lout)
print(f"Wrote {lout} (256x256 launcher icon)")
