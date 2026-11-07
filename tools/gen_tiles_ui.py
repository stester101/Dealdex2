"""Tiles, pixel font and UI frames."""
import os
import numpy as np
from pix import *

TS = 16
TILE_NAMES = [
    'grass', 'grass2', 'tallgrass', 'brick', 'sidewalk', 'quay', 'water', 'water_edge',
    'sea', 'deck', 'deck2', 'rail', 'hull', 'net', 'tulips', 'dirt',
    'void', 'stairs', 'canalwall', 'bridge', 'floor', 'wall', 'hedge', 'sea_edge',
]

G = dict(g0=rgb('2f6e44'), g1=rgb('3f8a4c'), g2=rgb('58a65a'), g3=rgb('7cc46a'), g4=rgb('a8dc84'))


def tile_grass(r, flowers=False):
    a = canvas(TS, TS)
    rect(a, 0, 0, TS, TS, G['g2'])
    for _ in range(14):
        x, y = r.randrange(16), r.randrange(16)
        px(a, x, y, G['g1']); px(a, x, (y + 1) % 16, G['g1'])
    for _ in range(10):
        x, y = r.randrange(16), r.randrange(16)
        px(a, x, y, G['g3'])
    for _ in range(4):
        x, y = r.randrange(16), r.randrange(16)
        px(a, x, y, G['g4'])
    if flowers:
        for (x, y, c) in [(3, 4, rgb('f4f0e0')), (11, 10, rgb('f6d84a')), (6, 12, rgb('f4f0e0'))]:
            px(a, x, y, c); px(a, x - 1, y, mix(c, G['g2'], .5)); px(a, x + 1, y, mix(c, G['g2'], .5))
            px(a, x, y - 1, mix(c, G['g2'], .5)); px(a, x, y + 1, G['g0'])
    return a


def tile_tall(r):
    a = canvas(TS, TS)
    rect(a, 0, 0, TS, TS, G['g1'])
    for row in range(3):
        y0 = 4 + row * 5
        for col in range(4):
            x0 = col * 4 + (row % 2) * 2
            # a tuft: dark core, light tips
            for i, h in enumerate([4, 6, 5]):
                x = (x0 + i) % 16
                for k in range(h):
                    y = y0 - k + 1
                    if 0 <= y < 16:
                        px(a, x, y, G['g0'] if k < 2 else (G['g2'] if k < h - 1 else G['g3']))
    for _ in range(6):
        px(a, r.randrange(16), r.randrange(16), G['g4'])
    return a


def tile_brick(r):
    a = canvas(TS, TS)
    mortar = rgb('6e4848')
    rect(a, 0, 0, TS, TS, mortar)
    cols = [rgb('a85c48'), rgb('b8684e'), rgb('9a5244'), rgb('b0704c')]
    # herringbone-ish klinker: alternating 4x2 / 2x4 blocks in a 4x4 grid
    for gy in range(4):
        for gx in range(4):
            c = cols[r.randrange(4)]
            x0, y0 = gx * 4, gy * 4
            if (gx + gy) % 2 == 0:
                rect(a, x0, y0, 3, 1, c); rect(a, x0, y0 + 2, 3, 1, cols[r.randrange(4)])
                px(a, x0, y0, mix(c, (255, 230, 200), .25))
            else:
                rect(a, x0, y0, 1, 3, c); rect(a, x0 + 2, y0, 1, 3, cols[r.randrange(4)])
                px(a, x0, y0, mix(c, (255, 230, 200), .25))
    return a


def tile_sidewalk(r):
    a = canvas(TS, TS)
    base, lt, dk = rgb('a8a6b4'), rgb('c4c2ce'), rgb('7e7c92')
    rect(a, 0, 0, TS, TS, base)
    for (x, y) in [(0, 0), (8, 0), (0, 8), (8, 8)]:
        rect(a, x, y, 8, 1, lt); rect(a, x, y, 1, 8, lt)
        rect(a, x, y + 7, 8, 1, dk); rect(a, x + 7, y, 1, 8, dk)
    for _ in range(6):
        px(a, r.randrange(16), r.randrange(16), mix(base, dk, .5))
    return a


def tile_water(r, sea=False, edge=False):
    a = canvas(TS, TS)
    base = rgb('2c5f96') if not sea else rgb('24508a')
    lt = rgb('4682bc') if not sea else rgb('3a72ae')
    dk = rgb('1f4474')
    rect(a, 0, 0, TS, TS, base)
    for y in (3, 9, 13):
        x = r.randrange(12)
        rect(a, x, y, r.randrange(3, 6), 1, lt)
    for _ in range(5):
        px(a, r.randrange(16), r.randrange(16), dk)
    if edge:
        rect(a, 0, 0, TS, 3, dk); rect(a, 0, 3, TS, 1, mix(dk, base, .5))
    return a


def tile_quay(r):
    a = canvas(TS, TS)
    top, face, dk, lt = rgb('9a96a2'), rgb('6e6878'), rgb('4a4458'), rgb('c8c4cc')
    rect(a, 0, 0, TS, 9, top)
    rect(a, 0, 0, TS, 1, lt)
    for x in (0, 8):
        rect(a, x, 0, 1, 9, dk)
    rect(a, 0, 8, TS, 1, dk)
    rect(a, 0, 9, TS, 7, face)
    for y in (11, 14):
        for x in range(0, 16, 4):
            rect(a, x + (2 if y == 14 else 0), y, 3, 1, mix(face, lt, .25))
    rect(a, 0, 15, TS, 1, dk)
    return a


def tile_canalwall(r):
    a = canvas(TS, TS)
    face, dk = rgb('6a3c38'), rgb('48282c')
    rect(a, 0, 0, TS, TS, dk)
    for row in range(4):
        off = 0 if row % 2 == 0 else 4
        for col in range(-1, 3):
            x = col * 8 + off
            rect(a, x + 1, row * 4 + 1, 6, 2, mix(face, rgb('8a4c44'), r.random() * .6))
    return a


def tile_deck(r, cleat=False):
    a = canvas(TS, TS)
    cols = [rgb('b07c4c'), rgb('c08a56'), rgb('a4744a')]
    seam = rgb('6a4630')
    for i in range(4):
        y = i * 4
        rect(a, 0, y, TS, 3, cols[(i + r.randrange(2)) % 3])
        rect(a, 0, y + 3, TS, 1, seam)
        sx = r.randrange(2, 14)
        rect(a, sx, y, 1, 3, seam)
        px(a, (sx + 3) % 16, y + 1, rgb('d8a874'))
    if cleat:
        rect(a, 5, 6, 6, 3, rgb('5a5e6a')); rect(a, 6, 5, 4, 1, rgb('8a8e9a')); rect(a, 4, 7, 8, 1, rgb('3a3e4a'))
    return a


def tile_rail(r):
    a = tile_deck(r)
    white, sh = rgb('eceef2'), rgb('a4a8b8')
    rect(a, 0, 3, TS, 2, white); rect(a, 0, 5, TS, 1, sh)
    rect(a, 0, 9, TS, 1, white)
    for x in (2, 10):
        rect(a, x, 3, 2, 10, white); rect(a, x + 1, 4, 1, 9, sh)
    rect(a, 0, 13, TS, 1, rgb('6a4630'))
    return a


def tile_hull(r):
    a = canvas(TS, TS)
    white, sh, red = rgb('e6e8ee'), rgb('b4b8c8'), rgb('c23c3c')
    rect(a, 0, 0, TS, TS, white)
    rect(a, 0, 0, TS, 1, sh)
    rect(a, 0, 7, TS, 3, red); rect(a, 0, 10, TS, 1, rgb('8a2430'))
    rect(a, 0, 13, TS, 3, sh)
    for x in (3, 11):
        px(a, x, 3, sh)
    return a


def tile_net(r):
    a = tile_deck(r)
    rope, dk = rgb('d8b878'), rgb('8a6a3c')
    for i in range(-16, 32, 5):
        for t in range(16):
            px(a, i + t, t, rope if t % 2 else dk)
            px(a, i + 16 - t, t, rope if t % 2 else dk)
    return a


def tile_tulips(r):
    a = canvas(TS, TS)
    rect(a, 0, 0, TS, TS, rgb('5a3c2c'))
    rect(a, 0, 0, TS, 1, rgb('7a5440'))
    rect(a, 0, 15, TS, 1, rgb('3a2820'))
    cols = [rgb('e0383c'), rgb('f6c63c'), rgb('f07ab0'), rgb('f4f0e0')]
    for (x, y) in [(2, 3), (7, 2), (12, 4), (4, 9), (10, 9), (14, 11), (1, 12), (7, 13)]:
        c = cols[r.randrange(4)]
        px(a, x, y + 2, G['g1']); px(a, x, y + 3, G['g1']); px(a, x + 1, y + 3, G['g2'])
        rect(a, x - 1, y, 3, 2, c)
        px(a, x, y - 1, c)
        px(a, x - 1, y, mix(c, (255, 255, 255), .4))
    return a


def tile_dirt(r):
    a = canvas(TS, TS)
    base = rgb('c8a878')
    rect(a, 0, 0, TS, TS, base)
    for _ in range(14):
        px(a, r.randrange(16), r.randrange(16), rgb('a88a60'))
    for _ in range(6):
        px(a, r.randrange(16), r.randrange(16), rgb('e0c494'))
    return a


def tile_stairs(r):
    a = canvas(TS, TS)
    for i in range(4):
        rect(a, 0, i * 4, TS, 3, rgb('b4b0bc')); rect(a, 0, i * 4 + 3, TS, 1, rgb('6e6878'))
        rect(a, 0, i * 4, TS, 1, rgb('d4d0dc'))
    return a


def tile_bridge(r):
    a = canvas(TS, TS)
    cols = [rgb('8a5c3c'), rgb('9a6844'), rgb('7a5034')]
    for i in range(4):
        rect(a, i * 4, 0, 3, TS, cols[(i + r.randrange(2)) % 3]); rect(a, i * 4 + 3, 0, 1, TS, rgb('4a3024'))
    rect(a, 0, 0, TS, 1, rgb('2e1e18')); rect(a, 0, 15, TS, 1, rgb('2e1e18'))
    return a


def tile_floor(r):
    a = canvas(TS, TS)
    for i in range(4):
        c = [rgb('c49a66'), rgb('b88e5c'), rgb('cca472')][(i + r.randrange(2)) % 3]
        rect(a, 0, i * 4, TS, 3, c); rect(a, 0, i * 4 + 3, TS, 1, rgb('8a6440'))
        rect(a, (i * 7) % 16, i * 4, 1, 3, rgb('8a6440'))
    return a


def tile_wall(r):
    a = canvas(TS, TS)
    rect(a, 0, 0, TS, TS, rgb('e8dcc4'))
    rect(a, 0, 11, TS, 5, rgb('6a8a6e')); rect(a, 0, 11, TS, 1, rgb('8aaa8c')); rect(a, 0, 15, TS, 1, rgb('3e5a46'))
    for x in range(0, 16, 4):
        rect(a, x, 0, 1, 11, rgb('ddd0b6'))
    return a


def tile_hedge(r):
    a = canvas(TS, TS)
    rect(a, 0, 0, TS, TS, rgb('2c5a3c'))
    for _ in range(26):
        x, y = r.randrange(16), r.randrange(16)
        px(a, x, y, rgb('3e7a4a')); px(a, x + 1, y, rgb('3e7a4a'))
    for _ in range(10):
        px(a, r.randrange(16), r.randrange(8), rgb('5a9a5c'))
    rect(a, 0, 14, TS, 2, rgb('1e3e2c'))
    return a


def build_tiles(outdir):
    r = noise_rng(7)
    fns = dict(
        grass=lambda: tile_grass(r), grass2=lambda: tile_grass(r, True), tallgrass=lambda: tile_tall(r),
        brick=lambda: tile_brick(r), sidewalk=lambda: tile_sidewalk(r), quay=lambda: tile_quay(r),
        water=lambda: tile_water(r), water_edge=lambda: tile_water(r, edge=True), sea=lambda: tile_water(r, sea=True),
        deck=lambda: tile_deck(r), deck2=lambda: tile_deck(r, True), rail=lambda: tile_rail(r), hull=lambda: tile_hull(r),
        net=lambda: tile_net(r), tulips=lambda: tile_tulips(r), dirt=lambda: tile_dirt(r),
        void=lambda: (lambda a: (rect(a, 0, 0, 16, 16, (10, 10, 18)), a)[1])(canvas(16, 16)),
        stairs=lambda: tile_stairs(r), canalwall=lambda: tile_canalwall(r), bridge=lambda: tile_bridge(r),
        floor=lambda: tile_floor(r), wall=lambda: tile_wall(r), hedge=lambda: tile_hedge(r),
        sea_edge=lambda: tile_water(r, sea=True, edge=True),
    )
    cols = 8
    rows = (len(TILE_NAMES) + cols - 1) // cols
    atlas = canvas(cols * TS, rows * TS)
    for i, n in enumerate(TILE_NAMES):
        t = fns[n]()
        x, y = (i % cols) * TS, (i // cols) * TS
        atlas[y:y + TS, x:x + TS] = t
    save(atlas, os.path.join(outdir, 'tiles.png'))
    return TILE_NAMES


# ------------------------------------------------------------------ font
# Classic 5x7 font, one list of column bytes per glyph, LSB = top row.
GLYPHS = {
    ' ': [0, 0, 0, 0, 0], '!': [0, 0, 0x5f, 0, 0], '"': [0, 7, 0, 7, 0], '#': [0x14, 0x7f, 0x14, 0x7f, 0x14],
    '$': [0x24, 0x2a, 0x7f, 0x2a, 0x12], '%': [0x23, 0x13, 0x08, 0x64, 0x62], '&': [0x36, 0x49, 0x55, 0x22, 0x50],
    "'": [0, 5, 3, 0, 0], '(': [0, 0x1c, 0x22, 0x41, 0], ')': [0, 0x41, 0x22, 0x1c, 0], '*': [0x08, 0x2a, 0x1c, 0x2a, 0x08],
    '+': [0x08, 0x08, 0x3e, 0x08, 0x08], ',': [0, 0x50, 0x30, 0, 0], '-': [0x08] * 5, '.': [0, 0x60, 0x60, 0, 0],
    '/': [0x20, 0x10, 0x08, 0x04, 0x02], '0': [0x3e, 0x51, 0x49, 0x45, 0x3e], '1': [0, 0x42, 0x7f, 0x40, 0],
    '2': [0x42, 0x61, 0x51, 0x49, 0x46], '3': [0x21, 0x41, 0x45, 0x4b, 0x31], '4': [0x18, 0x14, 0x12, 0x7f, 0x10],
    '5': [0x27, 0x45, 0x45, 0x45, 0x39], '6': [0x3c, 0x4a, 0x49, 0x49, 0x30], '7': [0x01, 0x71, 0x09, 0x05, 0x03],
    '8': [0x36, 0x49, 0x49, 0x49, 0x36], '9': [0x06, 0x49, 0x49, 0x29, 0x1e], ':': [0, 0x36, 0x36, 0, 0],
    ';': [0, 0x56, 0x36, 0, 0], '<': [0, 0x08, 0x14, 0x22, 0x41], '=': [0x14] * 5, '>': [0x41, 0x22, 0x14, 0x08, 0],
    '?': [0x02, 0x01, 0x51, 0x09, 0x06], '@': [0x32, 0x49, 0x79, 0x41, 0x3e], 'A': [0x7e, 0x11, 0x11, 0x11, 0x7e],
    'B': [0x7f, 0x49, 0x49, 0x49, 0x36], 'C': [0x3e, 0x41, 0x41, 0x41, 0x22], 'D': [0x7f, 0x41, 0x41, 0x22, 0x1c],
    'E': [0x7f, 0x49, 0x49, 0x49, 0x41], 'F': [0x7f, 0x09, 0x09, 0x01, 0x01], 'G': [0x3e, 0x41, 0x41, 0x51, 0x32],
    'H': [0x7f, 0x08, 0x08, 0x08, 0x7f], 'I': [0, 0x41, 0x7f, 0x41, 0], 'J': [0x20, 0x40, 0x41, 0x3f, 0x01],
    'K': [0x7f, 0x08, 0x14, 0x22, 0x41], 'L': [0x7f, 0x40, 0x40, 0x40, 0x40], 'M': [0x7f, 0x02, 0x04, 0x02, 0x7f],
    'N': [0x7f, 0x04, 0x08, 0x10, 0x7f], 'O': [0x3e, 0x41, 0x41, 0x41, 0x3e], 'P': [0x7f, 0x09, 0x09, 0x09, 0x06],
    'Q': [0x3e, 0x41, 0x51, 0x21, 0x5e], 'R': [0x7f, 0x09, 0x19, 0x29, 0x46], 'S': [0x46, 0x49, 0x49, 0x49, 0x31],
    'T': [0x01, 0x01, 0x7f, 0x01, 0x01], 'U': [0x3f, 0x40, 0x40, 0x40, 0x3f], 'V': [0x1f, 0x20, 0x40, 0x20, 0x1f],
    'W': [0x7f, 0x20, 0x18, 0x20, 0x7f], 'X': [0x63, 0x14, 0x08, 0x14, 0x63], 'Y': [0x03, 0x04, 0x78, 0x04, 0x03],
    'Z': [0x61, 0x51, 0x49, 0x45, 0x43], '[': [0, 0x7f, 0x41, 0x41, 0], '\\': [0x02, 0x04, 0x08, 0x10, 0x20],
    ']': [0, 0x41, 0x41, 0x7f, 0], '^': [0x04, 0x02, 0x01, 0x02, 0x04], '_': [0x40] * 5, '`': [0, 1, 2, 4, 0],
    'a': [0x20, 0x54, 0x54, 0x54, 0x78], 'b': [0x7f, 0x48, 0x44, 0x44, 0x38], 'c': [0x38, 0x44, 0x44, 0x44, 0x20],
    'd': [0x38, 0x44, 0x44, 0x48, 0x7f], 'e': [0x38, 0x54, 0x54, 0x54, 0x18], 'f': [0x08, 0x7e, 0x09, 0x01, 0x02],
    'g': [0x08, 0x54, 0x54, 0x54, 0x3c], 'h': [0x7f, 0x08, 0x04, 0x04, 0x78], 'i': [0, 0x44, 0x7d, 0x40, 0],
    'j': [0x20, 0x40, 0x44, 0x3d, 0], 'k': [0, 0x7f, 0x10, 0x28, 0x44], 'l': [0, 0x41, 0x7f, 0x40, 0],
    'm': [0x7c, 0x04, 0x18, 0x04, 0x78], 'n': [0x7c, 0x08, 0x04, 0x04, 0x78], 'o': [0x38, 0x44, 0x44, 0x44, 0x38],
    'p': [0x7c, 0x14, 0x14, 0x14, 0x08], 'q': [0x08, 0x14, 0x14, 0x18, 0x7c], 'r': [0x7c, 0x08, 0x04, 0x04, 0x08],
    's': [0x48, 0x54, 0x54, 0x54, 0x20], 't': [0x04, 0x3f, 0x44, 0x40, 0x20], 'u': [0x3c, 0x40, 0x40, 0x20, 0x7c],
    'v': [0x1c, 0x20, 0x40, 0x20, 0x1c], 'w': [0x3c, 0x40, 0x30, 0x40, 0x3c], 'x': [0x44, 0x28, 0x10, 0x28, 0x44],
    'y': [0x0c, 0x50, 0x50, 0x50, 0x3c], 'z': [0x44, 0x64, 0x54, 0x4c, 0x44], '{': [0, 0x08, 0x36, 0x41, 0],
    '|': [0, 0, 0x7f, 0, 0], '}': [0, 0x41, 0x36, 0x08, 0], '~': [0x02, 0x01, 0x02, 0x04, 0x02],
    # slot 127: right-pointing cursor triangle
    '\x7f': [0x7f, 0x3e, 0x1c, 0x08, 0x00],
}


def build_font(outdir):
    cw, ch = 6, 8
    cols, rows = 16, 6
    a = canvas(cols * cw, rows * ch)
    for code in range(32, 128):
        g = GLYPHS.get(chr(code), GLYPHS['?'])
        i = code - 32
        ox, oy = (i % cols) * cw, (i // cols) * ch
        for cx, colbits in enumerate(g):
            for cy in range(8):
                if colbits & (1 << cy):
                    px(a, ox + cx, oy + cy, (255, 255, 255))
    save(a, os.path.join(outdir, 'font.png'))


def build_frames(outdir):
    # Dialog / menu frame, 24x24 nine-patch with 8px margins (GBA style)
    a = canvas(24, 24)
    ink, blue, blue_l, cream = OUT, rgb('3c5a9a'), rgb('7aa2dc'), rgb('f8f4e8')
    m = mask_from(24, 24, lambda d: d.rounded_rectangle([0, 0, 23, 23], radius=4, fill=1))
    put(a, m, ink)
    m2 = mask_from(24, 24, lambda d: d.rounded_rectangle([1, 1, 22, 22], radius=3, fill=1))
    put(a, m2, blue)
    m3 = mask_from(24, 24, lambda d: d.rounded_rectangle([2, 2, 21, 21], radius=2, fill=1))
    put(a, m3, blue_l)
    m4 = mask_from(24, 24, lambda d: d.rounded_rectangle([3, 3, 20, 20], radius=2, fill=1))
    put(a, m4, ink)
    m5 = mask_from(24, 24, lambda d: d.rectangle([4, 4, 19, 19], fill=1))
    put(a, m5, cream)
    save(a, os.path.join(outdir, 'frame.png'))
    # Dark HUD frame (battle info boxes)
    b = canvas(24, 24)
    mm = mask_from(24, 24, lambda d: d.rounded_rectangle([0, 0, 23, 23], radius=5, fill=1))
    put(b, mm, ink)
    mm2 = mask_from(24, 24, lambda d: d.rounded_rectangle([1, 1, 22, 22], radius=4, fill=1))
    put(b, mm2, rgb('f6f0d8'))
    mm3 = mask_from(24, 24, lambda d: d.rounded_rectangle([1, 18, 22, 22], radius=4, fill=1))
    put(b, mm3 & mm2, rgb('d8ccaa'))
    save(b, os.path.join(outdir, 'frame_hud.png'))
    # Button (touch) 24x24
    c = canvas(24, 24)
    mc = mask_from(24, 24, lambda d: d.rounded_rectangle([0, 0, 23, 23], radius=6, fill=1))
    put(c, mc, ink)
    mc2 = mask_from(24, 24, lambda d: d.rounded_rectangle([1, 1, 22, 21], radius=5, fill=1))
    put(c, mc2, rgb('3a3654'))
    mc3 = mask_from(24, 24, lambda d: d.rounded_rectangle([2, 2, 21, 19], radius=4, fill=1))
    put(c, mc3, rgb('504a72'))
    rect(c, 5, 3, 14, 1, rgb('6e6894'))
    save(c, os.path.join(outdir, 'button.png'))
    c2 = canvas(24, 24)
    put(c2, mc, ink)
    put(c2, mc2, rgb('2a2640'))
    put(c2, mask_from(24, 24, lambda d: d.rounded_rectangle([2, 4, 21, 21], radius=4, fill=1)), rgb('3e3a5c'))
    save(c2, os.path.join(outdir, 'button_down.png'))


def build_icons(outdir):
    # Tin (catch item) 16x16, item bag icons, HP bar end caps
    t = canvas(16, 16)
    body = mask_from(16, 16, lambda d: d.ellipse([2, 4, 13, 13], fill=1))
    part(t, body, rgb('c8ccd8'), edge=1)
    lid = mask_from(16, 16, lambda d: d.ellipse([2, 3, 13, 8], fill=1))
    part(t, lid, rgb('3cae6e'), edge=1)
    rect(t, 6, 5, 4, 1, rgb('d8f8d8'))
    save(t, os.path.join(outdir, 'tin.png'))
    # cuppa (heal)
    c = canvas(16, 16)
    cup = mask_from(16, 16, lambda d: d.rounded_rectangle([3, 6, 11, 14], radius=2, fill=1))
    part(c, cup, rgb('f0ece0'), edge=1)
    hand = mask_from(16, 16, lambda d: d.ellipse([10, 8, 14, 12], outline=1, width=1))
    put(c, hand, OUT)
    rect(c, 4, 6, 7, 2, rgb('8a5634'))
    for i, y in enumerate([2, 1, 3]):
        px(c, 5 + i * 2, y, rgb('d0d4e0')); px(c, 5 + i * 2, y + 1, rgb('d0d4e0'))
    save(c, os.path.join(outdir, 'cuppa.png'))
    # star sparkle 8x8
    s = canvas(8, 8)
    for (x, y) in [(3, 0), (3, 1), (3, 2), (3, 4), (3, 5), (3, 6), (0, 3), (1, 3), (2, 3), (4, 3), (5, 3), (6, 3)]:
        px(s, x, y, (255, 240, 180))
    px(s, 3, 3, (255, 255, 255))
    save(s, os.path.join(outdir, 'spark.png'))
    # exclamation emote 8x12
    e = canvas(8, 12)
    m = mask_from(8, 12, lambda d: d.rounded_rectangle([0, 0, 7, 11], radius=2, fill=1))
    put(e, m, OUT); put(e, erode(m), (250, 250, 250))
    rect(e, 3, 2, 2, 5, rgb('d83c3c')); rect(e, 3, 8, 2, 2, rgb('d83c3c'))
    save(e, os.path.join(outdir, 'emote_alert.png'))
    # D-pad 48x48
    dp = canvas(48, 48)
    cross = mask_from(48, 48, lambda d: (d.rounded_rectangle([16, 0, 31, 47], radius=3, fill=1),
                                         d.rounded_rectangle([0, 16, 47, 31], radius=3, fill=1)))
    put(dp, cross, OUT)
    inner = erode(erode(cross))
    put(dp, inner, rgb('3a3654'))
    put(dp, inner & ~shift(inner, 0, -2), rgb('504a72'))
    ctr = mask_from(48, 48, lambda d: d.ellipse([19, 19, 28, 28], fill=1))
    put(dp, ctr, rgb('2a2640'))
    for (pts) in [[(24, 4), (20, 9), (28, 9)], [(24, 43), (20, 38), (28, 38)], [(4, 24), (9, 20), (9, 28)], [(43, 24), (38, 20), (38, 28)]]:
        put(dp, mask_from(48, 48, lambda d: d.polygon(pts, fill=1)), rgb('8a84b4'))
    save(dp, os.path.join(outdir, 'dpad.png'))
    # round A/B buttons 28x28
    for name, col in [('btn_a', rgb('d8484a')), ('btn_b', rgb('4a6ad8'))]:
        b = canvas(28, 28)
        m = mask_from(28, 28, lambda d: d.ellipse([0, 0, 27, 27], fill=1))
        part(b, m, col, edge=2)
        save(b, os.path.join(outdir, name + '.png'))
