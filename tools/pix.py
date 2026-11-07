"""Shared pixel-art helpers for the Deal Dex 2 asset generators.

All art is generated from code so it stays on one palette and one style.
Run tools/build_assets.py to rebuild every PNG under assets/.
"""
import random
import numpy as np
from PIL import Image, ImageDraw

OUT = (24, 20, 37)          # global outline / ink colour
SHADOW = (24, 20, 37, 70)


def rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def ramp(base, light_t=0.32, dark_t=0.34):
    """Return (ink, dark, base, light, highlight) ramp from a base colour.
    Shadows shift toward purple, lights toward warm yellow (classic GBA hue shifting)."""
    base = tuple(base)
    dark = mix(base, (40, 28, 74), dark_t)
    ink = mix(base, (24, 20, 37), 0.72)
    light = mix(base, (255, 246, 210), light_t)
    hi = mix(base, (255, 255, 240), 0.62)
    return ink, dark, base, light, hi


def canvas(w, h):
    return np.zeros((h, w, 4), dtype=np.uint8)


def to_img(arr):
    return Image.fromarray(arr, 'RGBA')


def mask_from(w, h, fn):
    im = Image.new('L', (w, h), 0)
    d = ImageDraw.Draw(im)
    fn(d)
    return np.array(im) > 0


def shift(m, dx, dy):
    out = np.zeros_like(m)
    h, w = m.shape
    xs0, xs1 = max(0, -dx), min(w, w - dx)
    ys0, ys1 = max(0, -dy), min(h, h - dy)
    out[ys0 + dy:ys1 + dy, xs0 + dx:xs1 + dx] = m[ys0:ys1, xs0:xs1]
    return out


def erode(m):
    return m & shift(m, 1, 0) & shift(m, -1, 0) & shift(m, 0, 1) & shift(m, 0, -1)


def put(arr, mask, col, a=255):
    arr[mask, 0] = col[0]
    arr[mask, 1] = col[1]
    arr[mask, 2] = col[2]
    arr[mask, 3] = a


def part(arr, mask, base, edge=2, outline=True, light_dir=(-1, -1), hi=True):
    """Paint a cel-shaded part: ink outline, dark bottom-right, light top-left, highlight."""
    ink, dark, b, light, hil = ramp(base)
    put(arr, mask, b)
    lx, ly = light_dir
    near_light = mask & ~shift(mask, -lx * edge, -ly * edge)
    near_dark = mask & ~shift(mask, lx * edge, ly * edge)
    put(arr, near_dark & ~near_light, dark)
    put(arr, near_light & ~near_dark, light)
    if hi:
        hm = mask & ~shift(mask, -lx * (edge + 2), -ly * (edge + 2)) & ~near_light
        hm2 = hm & erode(mask)
        # sparse highlight band, only the inner rim
        put(arr, hm2 & ~shift(mask, lx * 3, ly * 3), hil)
    if outline:
        put(arr, mask & ~erode(mask), ink)
    return arr


def outline_all(arr, col=OUT):
    a = arr[:, :, 3] > 0
    ring = (shift(a, 1, 0) | shift(a, -1, 0) | shift(a, 0, 1) | shift(a, 0, -1)) & ~a
    put(arr, ring, col)
    return arr


def px(arr, x, y, col, a=255):
    h, w = arr.shape[:2]
    if 0 <= x < w and 0 <= y < h:
        arr[y, x, :3] = col[:3]
        arr[y, x, 3] = a


def rect(arr, x, y, w, h, col, a=255):
    arr[max(0, y):y + h, max(0, x):x + w, :3] = col[:3]
    arr[max(0, y):y + h, max(0, x):x + w, 3] = a


def eye(arr, x, y, look=0, closed=False, big=False, col=(30, 26, 48)):
    """Draw a cute 3x4 (or 4x5) eye with highlight. x,y = top-left."""
    if closed:
        for i in range(4 if big else 3):
            px(arr, x + i, y + 2, col)
        px(arr, x - 1, y + 1, col)
        return
    w, h = (4, 5) if big else (3, 4)
    rect(arr, x, y, w, h, (250, 250, 250))
    rect(arr, x + (1 if look >= 0 else 0), y + 1, w - 1, h - 1, col)
    px(arr, x + (1 if look >= 0 else 0), y + 1, (255, 255, 255))
    # lid line
    for i in range(w):
        px(arr, x + i, y - 1, OUT)


def noise_rng(seed):
    return random.Random(seed)


def save(arr_or_img, path):
    img = arr_or_img if isinstance(arr_or_img, Image.Image) else to_img(arr_or_img)
    img.save(path)
