"""World props (buildings, ferry parts, street furniture) and character walk sheets."""
import os
from pix import *
from gen_tiles_ui import GLYPHS


def text(arr, x, y, s, col):
    for ch in s:
        g = GLYPHS.get(ch, GLYPHS['?'])
        for cx, bits in enumerate(g):
            for cy in range(8):
                if bits & (1 << cy):
                    px(arr, x + cx, y + cy, col)
        x += 6


def tiny_text(arr, x, y, s, col):
    """3x5 micro font for shop signs."""
    F = {
        'A': ['010', '101', '111', '101', '101'], 'B': ['110', '101', '110', '101', '110'], 'C': ['011', '100', '100', '100', '011'],
        'D': ['110', '101', '101', '101', '110'], 'E': ['111', '100', '110', '100', '111'], 'F': ['111', '100', '110', '100', '100'],
        'G': ['011', '100', '101', '101', '011'], 'H': ['101', '101', '111', '101', '101'], 'I': ['111', '010', '010', '010', '111'],
        'K': ['101', '110', '100', '110', '101'], 'L': ['100', '100', '100', '100', '111'], 'M': ['101', '111', '111', '101', '101'],
        'N': ['110', '101', '101', '101', '101'], 'O': ['010', '101', '101', '101', '010'], 'P': ['110', '101', '110', '100', '100'],
        'R': ['110', '101', '110', '101', '101'], 'S': ['011', '100', '010', '001', '110'], 'T': ['111', '010', '010', '010', '010'],
        'U': ['101', '101', '101', '101', '111'], 'V': ['101', '101', '101', '101', '010'], 'W': ['101', '101', '111', '111', '101'],
        'Y': ['101', '101', '010', '010', '010'], ' ': ['000'] * 5, '2': ['110', '001', '010', '100', '111'], 'J': ['001', '001', '001', '101', '010'],
        'X': ['101', '101', '010', '101', '101'], '-': ['000', '000', '111', '000', '000'],
    }
    for ch in s:
        g = F.get(ch, F[' '])
        for yy, row in enumerate(g):
            for xx, c in enumerate(row):
                if c == '1':
                    px(arr, x + xx, y + yy, col)
        x += 4


def brick_fill(a, x0, y0, w, h, base, r, mortar_t=.35):
    dk = mix(base, (30, 20, 30), mortar_t)
    rect(a, x0, y0, w, h, dk)
    for row in range(h // 3 + 1):
        off = 0 if row % 2 == 0 else 3
        for col in range(-1, w // 6 + 1):
            bx = x0 + col * 6 + off
            by = y0 + row * 3
            c = mix(base, (255, 220, 190), r.random() * .12) if r.random() < .5 else mix(base, (40, 20, 40), r.random() * .1)
            for yy in range(by, min(by + 2, y0 + h)):
                for xx in range(max(bx, x0), min(bx + 5, x0 + w)):
                    px(a, xx, yy, c)


def window(a, x, y, w=6, h=9, frame=(240, 236, 226), lit=True, r=None):
    rect(a, x - 1, y - 1, w + 2, h + 2, OUT)
    rect(a, x, y, w, h, frame)
    glass = rgb('f8d070') if lit else rgb('3a4a72')
    glass2 = rgb('f0a848') if lit else rgb('2a3458')
    rect(a, x + 1, y + 1, w - 2, h - 2, glass)
    rect(a, x + 1, y + h // 2 + 1, w - 2, h - h // 2 - 2, glass2)
    rect(a, x + w // 2, y + 1, 1, h - 2, frame)
    rect(a, x + 1, y + h // 2, w - 2, 1, frame)
    if not lit:
        px(a, x + 1, y + 1, rgb('8aa4d8'))


def canal_house(variant, r):
    W, H = 32, 88
    a = canvas(W, H)
    palettes = [rgb('5a2e2a'), rgb('7a3c30'), rgb('2e2c38'), rgb('d8c8a4'), rgb('8a5a3c')]
    base = palettes[variant % len(palettes)]
    body_top = 24
    brick_fill(a, 1, body_top, 30, H - body_top - 1, base, r)
    # gable shapes
    gable = variant % 3
    if gable == 0:      # step gable
        steps = [(1, 30, 6), (4, 24, 6), (8, 16, 6), (12, 8, 8)]
        for (x, w, h) in [(1, 30, 0)]:
            pass
        brick_fill(a, 4, body_top - 6, 24, 6, base, r)
        brick_fill(a, 8, body_top - 12, 16, 6, base, r)
        brick_fill(a, 12, body_top - 18, 8, 6, base, r)
        for (x, y, w) in [(1, body_top, 3), (28, body_top, 3), (4, body_top - 6, 4), (24, body_top - 6, 4), (8, body_top - 12, 4), (20, body_top - 12, 4), (12, body_top - 18, 8)]:
            rect(a, x, y - 1, w, 1, rgb('e8e4dc'))
    elif gable == 1:    # bell gable
        m = mask_from(W, H, lambda d: (d.ellipse([3, body_top - 22, 28, body_top + 6], fill=1)))
        m2 = mask_from(W, H, lambda d: d.rectangle([0, body_top, W, H], fill=1))
        mm = m & ~m2
        tmp = canvas(W, H)
        brick_fill(tmp, 0, body_top - 24, W, 26, base, r)
        a[mm] = tmp[mm]
        ring = mm & ~erode(mm)
        put(a, ring, rgb('e8e4dc'))
        # scroll ornaments
        for x in (1, 28):
            rect(a, x, body_top - 4, 3, 4, rgb('e8e4dc'))
    else:               # neck gable
        brick_fill(a, 9, body_top - 20, 14, 20, base, r)
        for (pts) in [[(1, body_top), (9, body_top - 8), (9, body_top)], [(31, body_top), (23, body_top - 8), (23, body_top)]]:
            m = mask_from(W, H, lambda d: d.polygon(pts, fill=1))
            put(a, m, rgb('e8e4dc'))
        rect(a, 8, body_top - 21, 16, 2, rgb('e8e4dc'))
        px(a, 15, body_top - 23, rgb('e8e4dc')); px(a, 16, body_top - 23, rgb('e8e4dc'))
    # hoist beam
    top_y = body_top - (18 if gable == 0 else 20)
    rect(a, 15, top_y + 2, 2, 5, rgb('3a2a22'))
    rect(a, 15, top_y + 7, 1, 3, rgb('8a8a8a'))
    # cornice line
    rect(a, 1, body_top + 1, 30, 1, mix(base, (255, 255, 255), .25))
    # windows
    lit_pattern = [(r.random() < .7) for _ in range(12)]
    k = 0
    for row in range(4):
        y = body_top + 5 + row * 13
        if row == 3:
            break
        for x in (5, 20):
            window(a, x, y, 7, 9, lit=lit_pattern[k]); k += 1
    # ground floor: door + window
    gy = H - 22
    rect(a, 3, gy, 12, 20, OUT)
    door_col = [rgb('2e5a3a'), rgb('2e3c6a'), rgb('6a2a2a'), rgb('1e1e26')][variant % 4]
    rect(a, 4, gy + 1, 10, 19, door_col)
    rect(a, 5, gy + 2, 8, 7, mix(door_col, (255, 255, 255), .15))
    rect(a, 4, gy + 1, 10, 3, rgb('f8d070'))  # fanlight
    rect(a, 8, gy + 1, 1, 3, rgb('e8e4dc'))
    px(a, 12, gy + 12, rgb('e0c050'))
    window(a, 19, gy + 2, 9, 12, lit=True)
    # steps
    rect(a, 2, H - 2, 14, 2, rgb('8a8696'))
    rect(a, 0, H - 1, W, 1, OUT)
    # side shading (row houses abut)
    rect(a, 0, body_top, 1, H - body_top, OUT)
    rect(a, W - 1, body_top, 1, H - body_top, OUT)
    outline_all(a)
    return a


def shop(kind, r):
    W, H = 48, 88
    a = canvas(W, H)
    if kind == 'coffeeshop':
        base = rgb('234a34')
    else:
        base = rgb('e2d6b4')
    body_top = 18
    brick_fill(a, 1, body_top, 46, H - body_top - 1, base, r, .2)
    # flat cornice with dentils
    rect(a, 0, body_top - 3, 48, 4, rgb('e8e4dc'))
    for x in range(1, 47, 3):
        px(a, x, body_top + 1, rgb('a8a4a0'))
    # roof
    rect(a, 4, 6, 40, body_top - 9, rgb('3a3a4a'))
    for x in range(4, 44, 4):
        rect(a, x, 6, 1, body_top - 9, rgb('2a2a38'))
    rect(a, 18, 2, 12, 5, rgb('3a3a4a'))
    window(a, 20, 3, 8, 3, lit=True)
    # upper windows
    for x in (5, 20, 35):
        window(a, x, body_top + 6, 8, 10, lit=True)
        window(a, x, body_top + 22, 8, 10, lit=(kind != 'hostel' or x != 35))
    # shopfront
    gy = H - 30
    rect(a, 1, gy - 9, 46, 9, OUT)
    if kind == 'coffeeshop':
        rect(a, 2, gy - 8, 44, 7, rgb('101814'))
        tiny_text(a, 8, gy - 7, 'BULLFROG', rgb('7cff9a'))
    else:
        rect(a, 2, gy - 8, 44, 7, rgb('2a3c7a'))
        tiny_text(a, 12, gy - 7, 'HOSTEL', rgb('f8f4e8'))
    rect(a, 2, gy, 44, 28, rgb('2a2420'))
    window(a, 4, gy + 3, 16, 18, lit=True)
    window(a, 30, gy + 3, 14, 18, lit=True)
    rect(a, 22, gy + 4, 7, 24, OUT)
    rect(a, 23, gy + 5, 5, 23, rgb('f8d070') if kind == 'coffeeshop' else rgb('c8a060'))
    rect(a, 22, H - 2, 8, 2, rgb('8a8696'))
    if kind == 'coffeeshop':
        # frog logo
        m = mask_from(W, H, lambda d: d.ellipse([7, gy + 8, 16, gy + 16], fill=1))
        put(a, m, rgb('5ad06a'))
        px(a, 9, gy + 9, OUT); px(a, 14, gy + 9, OUT)
        rect(a, 10, gy + 13, 4, 1, OUT)
        # plant pots
        for x in (2, 44):
            rect(a, x, H - 6, 3, 4, rgb('a85a3c'))
            rect(a, x - 1, H - 10, 5, 4, rgb('3e8a4a'))
    rect(a, 0, H - 1, W, 1, OUT)
    outline_all(a)
    return a


def lamp():
    a = canvas(16, 48)
    pole, pole_l = rgb('2a3c34'), rgb('4a6458')
    rect(a, 7, 12, 2, 34, pole); rect(a, 7, 12, 1, 34, pole_l)
    rect(a, 5, 44, 6, 3, pole); rect(a, 4, 46, 8, 2, pole)
    rect(a, 6, 20, 4, 2, pole)
    # lantern
    rect(a, 4, 3, 8, 9, OUT)
    rect(a, 5, 4, 6, 7, rgb('ffe8a0'))
    rect(a, 5, 8, 6, 3, rgb('f8c060'))
    rect(a, 3, 2, 10, 2, pole); rect(a, 6, 0, 4, 2, pole)
    rect(a, 7, 4, 2, 7, rgb('fff8d8'))
    outline_all(a)
    return a


def tree(r):
    a = canvas(32, 52)
    trunk = mask_from(32, 52, lambda d: d.polygon([(13, 50), (19, 50), (18, 30), (14, 30)], fill=1))
    part(a, trunk, rgb('6a4a34'), edge=1)
    blobs = [(4, 6, 22, 26), (12, 2, 29, 22), (2, 16, 18, 34), (14, 14, 31, 34), (8, 10, 24, 30)]
    col = rgb('3e7a46')
    for b in blobs:
        m = mask_from(32, 52, lambda d: d.ellipse(b, fill=1))
        part(a, m, col, edge=2, outline=False)
    allm = a[:, :, 3] > 0
    # leaf clusters texture
    for _ in range(60):
        x, y = r.randrange(32), r.randrange(36)
        if allm[y, x] and y < 34:
            px(a, x, y, rgb('2c5a3a') if r.random() < .5 else rgb('6ab06a'))
    outline_all(a)
    return a


def bikes():
    a = canvas(32, 24)
    for i, (x, col) in enumerate([(2, rgb('2a2a2e')), (14, rgb('a83c3c'))]):
        for wx in (x, x + 11):
            m = mask_from(32, 24, lambda d: d.ellipse([wx, 13, wx + 7, 20], outline=1, width=1))
            put(a, m, OUT)
            px(a, wx + 3, 16, rgb('a8a8b0'))
        # frame
        for t in range(9):
            px(a, x + 4 + t, 16 - t // 3, col)
        for t in range(6):
            px(a, x + 7 + t // 2, 16 - t, col)
        rect(a, x + 6, 10, 4, 1, OUT)       # saddle
        rect(a, x + 13, 9, 3, 1, rgb('c0c0c8'))  # bars
        rect(a, x + 14, 10, 1, 4, col)
        if i == 1:
            rect(a, x + 15, 10, 4, 3, rgb('8a6a3c'))  # basket
    rect(a, 0, 21, 32, 2, rgb('5a5e6a'))
    rect(a, 1, 12, 1, 10, rgb('5a5e6a')); rect(a, 30, 12, 1, 10, rgb('5a5e6a')); rect(a, 1, 12, 30, 1, rgb('7a7e8a'))
    return a


def bench():
    a = canvas(32, 18)
    wood, wood_d = rgb('8a5c3c'), rgb('5a3a28')
    rect(a, 2, 2, 28, 3, wood); rect(a, 2, 5, 28, 1, wood_d)
    rect(a, 2, 8, 28, 3, wood); rect(a, 2, 11, 28, 1, wood_d)
    for x in (4, 26):
        rect(a, x, 2, 2, 15, rgb('2a2a30'))
    outline_all(a)
    return a


def bollard():
    a = canvas(8, 14)
    m = mask_from(8, 14, lambda d: (d.rounded_rectangle([1, 2, 6, 13], radius=1, fill=1), d.ellipse([1, 0, 6, 4], fill=1)))
    part(a, m, rgb('7a2a26'), edge=1)
    for y in (4, 7, 10):  # the three St Andrew's crosses
        px(a, 2, y, (240, 240, 240)); px(a, 4, y, (240, 240, 240)); px(a, 3, y + 1, (240, 240, 240))
        px(a, 2, y + 2, (240, 240, 240)); px(a, 4, y + 2, (240, 240, 240))
    outline_all(a)
    return a


def houseboat(r):
    a = canvas(64, 34)
    hull = mask_from(64, 34, lambda d: d.polygon([(2, 20), (62, 20), (58, 31), (6, 31)], fill=1))
    part(a, hull, rgb('2e4a6a'), edge=1)
    rect(a, 4, 22, 56, 1, rgb('e8e4dc'))
    cabin = mask_from(64, 34, lambda d: d.rectangle([10, 8, 54, 20], fill=1))
    part(a, cabin, rgb('d8cfae'), edge=1)
    roof = mask_from(64, 34, lambda d: d.polygon([(7, 9), (57, 9), (52, 3), (12, 3)], fill=1))
    part(a, roof, rgb('3a6a4a'), edge=1)
    for x in (14, 26, 38):
        window(a, x, 11, 7, 5, lit=True)
    rect(a, 48, 11, 4, 9, OUT); rect(a, 49, 12, 2, 8, rgb('a83c3c'))
    for x in (8, 12, 52, 56):
        rect(a, x, 17, 3, 3, rgb('3e8a4a'))
        px(a, x + 1, 16, rgb('e0383c'))
    outline_all(a)
    return a


def ferry_cabin(r):
    W, H = 112, 60
    a = canvas(W, H)
    body = mask_from(W, H, lambda d: d.rounded_rectangle([0, 14, W - 1, H - 1], radius=3, fill=1))
    part(a, body, rgb('e6e8ee'), edge=2)
    top = mask_from(W, H, lambda d: d.rounded_rectangle([12, 0, W - 13, 16], radius=3, fill=1))
    part(a, top, rgb('f2f4f8'), edge=2)
    rect(a, 14, 6, W - 28, 6, OUT)
    rect(a, 15, 7, W - 30, 4, rgb('3a5a8a'))
    for x in range(18, W - 18, 8):
        px(a, x, 7, rgb('8ab0e0'))
    for x in range(6, W - 10, 13):
        window(a, x, 22, 9, 8, frame=rgb('d0d4dc'), lit=False)
    # door
    rect(a, 50, 36, 12, 24, OUT); rect(a, 51, 37, 10, 23, rgb('9aa0b0')); rect(a, 52, 39, 8, 8, rgb('3a5a8a'))
    rect(a, 0, 33, W, 2, rgb('c23c3c'))
    # lifebuoys
    for x in (12, 92):
        m = mask_from(W, H, lambda d: d.ellipse([x, 38, x + 10, 48], outline=1, width=3))
        put(a, m, rgb('f07a2a'))
        for (dx, dy) in [(4, 0), (4, 9), (0, 4), (9, 4)]:
            px(a, x + dx, 38 + dy, (250, 250, 250)); px(a, x + dx + 1, 38 + dy, (250, 250, 250))
    outline_all(a)
    return a


def funnel():
    a = canvas(32, 44)
    m = mask_from(32, 44, lambda d: d.polygon([(6, 43), (26, 43), (28, 4), (8, 4)], fill=1))
    part(a, m, rgb('c23c3c'), edge=2)
    rect(a, 8, 2, 21, 8, rgb('1e1e26'))
    m2 = mask_from(32, 44, lambda d: d.ellipse([12, 18, 23, 29], fill=1))
    put(a, m2, rgb('f2f4f8'))
    tiny_text(a, 14, 21, 'X', rgb('3a5a8a'))
    outline_all(a)
    return a


def lifeboat():
    a = canvas(48, 22)
    m = mask_from(48, 22, lambda d: d.ellipse([0, 4, 47, 21], fill=1))
    part(a, m, rgb('f07a2a'), edge=2)
    rect(a, 4, 9, 40, 2, rgb('e6e8ee'))
    rect(a, 2, 0, 2, 12, rgb('8a8e9a')); rect(a, 44, 0, 2, 12, rgb('8a8e9a'))
    outline_all(a)
    return a


def crate(w=16, h=22, seed=0):
    a = canvas(w, h)
    m = mask_from(w, h, lambda d: d.rectangle([0, 4, w - 1, h - 1], fill=1))
    part(a, m, rgb('b08450'), edge=1)
    top = mask_from(w, h, lambda d: d.rectangle([0, 0, w - 1, 5], fill=1))
    part(a, top, rgb('d0a46c'), edge=1)
    for x in range(3, w - 2, 5):
        rect(a, x, 7, 1, h - 9, rgb('7a5634'))
    rect(a, 1, h // 2 + 2, w - 2, 1, rgb('7a5634'))
    tiny_text(a, 2, 8, 'NL' if seed else 'UK', rgb('3a2a1c'))
    outline_all(a)
    return a


def sign():
    a = canvas(16, 24)
    rect(a, 7, 12, 2, 12, rgb('5a3a28'))
    m = mask_from(16, 24, lambda d: d.rectangle([0, 1, 15, 12], fill=1))
    part(a, m, rgb('b07c4c'), edge=1)
    for y in (4, 7, 10):
        rect(a, 3, y, 10, 1, rgb('6a4630'))
    outline_all(a)
    return a


def gull():
    a = canvas(32, 10)
    for f, wing in enumerate([0, 1]):
        ox = f * 16
        body = [(6, 5), (7, 5), (8, 5), (9, 5), (7, 6), (8, 6)]
        for (x, y) in body:
            px(a, ox + x, y, (240, 240, 244))
        px(a, ox + 10, 5, rgb('f0b040'))
        if wing == 0:
            pts = [(1, 2), (2, 3), (3, 3), (4, 4), (5, 4), (10, 4), (11, 3), (12, 3), (13, 2), (14, 2)]
        else:
            pts = [(1, 7), (2, 7), (3, 6), (4, 6), (5, 5), (10, 5), (11, 6), (12, 6), (13, 7), (14, 7)]
        for (x, y) in pts:
            px(a, ox + x, y, (220, 222, 230))
        px(a, ox + 1, pts[0][1], (60, 60, 70)); px(a, ox + 14, pts[-1][1], (60, 60, 70))
    return a


def shadow():
    a = canvas(16, 6)
    m = mask_from(16, 6, lambda d: d.ellipse([1, 0, 14, 5], fill=1))
    a[m] = (24, 20, 37, 90)
    return a


# ------------------------------------------------------------------ characters
CHARS = {
    # skin, hair, hair_style, top, top2, legs, shoes, extra
    'hero':     dict(skin='f2c4a0', hair='4a3426', style='short', top='3a6ad0', top2='f2f2f2', legs='2e3448', shoes='e8e8e8', cap='d83c3c'),
    'kettle':   dict(skin='f0c09a', hair='c89a5a', style='short', top='2e8a5a', top2='1e5a3a', legs='5a4a3a', shoes='3a2a22', beard='b08a50'),
    'oli':      dict(skin='e8b48e', hair='2a2220', style='quiff', top='1e1e26', top2='f0c040', legs='3a4a6a', shoes='f0f0f0'),
    'deckhand': dict(skin='e0a888', hair='6a6a70', style='short', top='f07a2a', top2='e6e8ee', legs='2e3a5a', shoes='2a2a2e', cap='2e3a5a'),
    'tourist':  dict(skin='f6d0b0', hair='e8c870', style='long', top='e06aa8', top2='f8f0f8', legs='5a8ad0', shoes='f0f0f0'),
    'local':    dict(skin='c08a62', hair='1e1a1a', style='bun', top='7a5ac8', top2='f0e8d8', legs='2a2a30', shoes='6a3a2a'),
    'oldman':   dict(skin='f0c8a8', hair='e8e8ec', style='bald', top='6a5a4a', top2='a89070', legs='4a4a52', shoes='2a2220', cap='3a3a44'),
    'cyclist':  dict(skin='dca07c', hair='8a4a2a', style='short', top='f0d040', top2='2a2a2e', legs='1e1e26', shoes='f04040', cap='f0f0f0'),
    'clerk':    dict(skin='e8b898', hair='5a3a2a', style='long', top='3a8a8a', top2='f8f4e8', legs='2a3a4a', shoes='2a2220'),
}


def char_frame(c, d, f):
    """d: 0 down,1 left,2 right,3 up. f: 0 stand, 1 step A, 2 step B."""
    a = canvas(16, 24)
    skin, hair, top, top2, legs, shoes = (rgb(c[k]) for k in ('skin', 'hair', 'top', 'top2', 'legs', 'shoes'))
    bob = 1 if f in (1, 2) else 0
    side = d in (1, 2)
    # legs
    ly = 18
    if not side:
        lo = [0, 0]
        if f == 1: lo = [-1, 1]
        if f == 2: lo = [1, -1]
        for i, x in enumerate((5, 9)):
            h = 4 + (1 if lo[i] > 0 else 0) - (1 if lo[i] < 0 else 0)
            rect(a, x, ly, 2, h, legs)
            rect(a, x, ly + h, 2, 1, shoes)
    else:
        if f == 0:
            rect(a, 7, ly, 3, 4, legs); rect(a, 7, ly + 4, 3, 1, shoes)
        else:
            sp = 2 if f == 1 else -2
            rect(a, 7 - sp // 2 - 1, ly, 2, 4, legs); rect(a, 7 - sp // 2 - 1 + (-1 if d == 1 else 1), ly + 4, 2, 1, shoes)
            rect(a, 8 + sp // 2, ly, 2, 4, mix(legs, (0, 0, 0), .25)); rect(a, 8 + sp // 2, ly + 4, 2, 1, shoes)
    # torso
    ty = 11 + bob
    if not side:
        rect(a, 4, ty, 8, 7, top)
        rect(a, 4, ty + 6, 8, 1, mix(top, (20, 10, 40), .35))
        if d == 0:
            rect(a, 7, ty, 2, 4, top2)
        # arms
        swing = [0, 1, -1][f]
        rect(a, 3, ty + 1 + max(0, swing), 1, 5, top); rect(a, 3, ty + 5 + max(0, swing), 1, 1, skin)
        rect(a, 12, ty + 1 + max(0, -swing), 1, 5, top); rect(a, 12, ty + 5 + max(0, -swing), 1, 1, skin)
    else:
        rect(a, 5, ty, 6, 7, top)
        rect(a, 5, ty + 6, 6, 1, mix(top, (20, 10, 40), .35))
        ax = 7 if f == 0 else (6 if f == 1 else 9)
        rect(a, ax, ty + 1, 2, 5, mix(top, (20, 10, 40), .2)); rect(a, ax, ty + 5, 2, 1, skin)
    # head
    hy = 2 + bob
    rect(a, 4, hy, 8, 9, skin)
    style = c['style']
    if d == 3:
        rect(a, 4, hy, 8, 8, hair if style != 'bald' else skin)
        if style == 'long':
            rect(a, 4, hy + 8, 8, 2, hair)
        if style == 'bun':
            rect(a, 6, hy - 2, 4, 2, hair)
    else:
        if style != 'bald':
            rect(a, 4, hy, 8, 3, hair)
            if style == 'quiff':
                rect(a, 5, hy - 2, 6, 2, hair)
            if style == 'long':
                rect(a, 3, hy + 1, 1, 9, hair); rect(a, 12, hy + 1, 1, 9, hair)
            if style == 'bun':
                rect(a, 6, hy - 2, 4, 2, hair)
            if side:
                if d == 1:
                    rect(a, 9, hy, 3, 6, hair)
                else:
                    rect(a, 4, hy, 3, 6, hair)
        else:
            rect(a, 4, hy + 2, 1, 3, hair); rect(a, 11, hy + 2, 1, 3, hair)
        # face
        if d == 0:
            px(a, 6, hy + 5, OUT); px(a, 9, hy + 5, OUT)
            px(a, 6, hy + 4, (255, 255, 255)) if False else None
            px(a, 5, hy + 7, mix(skin, (230, 100, 100), .4)); px(a, 10, hy + 7, mix(skin, (230, 100, 100), .4))
        elif d == 1:
            px(a, 5, hy + 5, OUT)
        elif d == 2:
            px(a, 10, hy + 5, OUT)
        if 'beard' in c and d != 3:
            bc = rgb(c['beard'])
            if d == 0:
                rect(a, 4, hy + 7, 8, 2, bc); rect(a, 6, hy + 8, 4, 1, bc)
            else:
                rect(a, 4 if d == 1 else 7, hy + 7, 5, 2, bc)
    if 'cap' in c:
        cc = rgb(c['cap'])
        rect(a, 4, hy - 1, 8, 3, cc)
        rect(a, 5, hy - 2, 6, 1, cc)
        if d == 0:
            rect(a, 4, hy + 2, 8, 1, mix(cc, (0, 0, 0), .3))
        elif d == 1:
            rect(a, 2, hy + 1, 4, 1, mix(cc, (0, 0, 0), .3))
        elif d == 2:
            rect(a, 10, hy + 1, 4, 1, mix(cc, (0, 0, 0), .3))
    outline_all(a)
    return a


def char_sheet(c):
    sheet = canvas(16 * 3, 24 * 4)
    for d in range(4):
        for f in range(3):
            fr = char_frame(c, d, f)
            sheet[d * 24:(d + 1) * 24, f * 16:(f + 1) * 16] = fr
    return sheet


def build_props(outdir):
    r = noise_rng(11)
    p = os.path.join(outdir, 'props')
    os.makedirs(p, exist_ok=True)
    for v in range(5):
        save(canal_house(v, r), os.path.join(p, f'house{v}.png'))
    save(shop('coffeeshop', r), os.path.join(p, 'coffeeshop.png'))
    save(shop('hostel', r), os.path.join(p, 'hostel.png'))
    save(lamp(), os.path.join(p, 'lamp.png'))
    save(tree(r), os.path.join(p, 'tree.png'))
    save(bikes(), os.path.join(p, 'bikes.png'))
    save(bench(), os.path.join(p, 'bench.png'))
    save(bollard(), os.path.join(p, 'bollard.png'))
    save(houseboat(r), os.path.join(p, 'houseboat.png'))
    save(ferry_cabin(r), os.path.join(p, 'ferry_cabin.png'))
    save(funnel(), os.path.join(p, 'funnel.png'))
    save(lifeboat(), os.path.join(p, 'lifeboat.png'))
    save(crate(16, 22, 0), os.path.join(p, 'crate.png'))
    save(crate(16, 22, 1), os.path.join(p, 'crate_nl.png'))
    save(sign(), os.path.join(p, 'sign.png'))
    save(gull(), os.path.join(p, 'gull.png'))
    save(shadow(), os.path.join(p, 'shadow.png'))
    cp = os.path.join(outdir, 'chars')
    os.makedirs(cp, exist_ok=True)
    for name, c in CHARS.items():
        save(char_sheet(c), os.path.join(cp, name + '.png'))
