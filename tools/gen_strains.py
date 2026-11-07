"""Strain (creature) battle sprites: 64x64 front + 64x64 back, plus 32x32 menu icons.
Each species is drawn from shapes, then cel-shaded and outlined by pix.part()."""
import os
from PIL import Image
from pix import *

S = 64


def M(fn):
    return mask_from(S, S, fn)


def face(a, cx, cy, mood='happy', gap=10, big=True):
    if mood == 'sleepy':
        eye(a, cx - gap // 2 - 3, cy, closed=True, big=big)
        eye(a, cx + gap // 2, cy, closed=True, big=big)
    else:
        eye(a, cx - gap // 2 - 3, cy, look=1, big=big)
        eye(a, cx + gap // 2, cy, look=1, big=big)
    my = cy + 7
    if mood == 'happy':
        for x in range(cx - 2, cx + 2):
            px(a, x, my + 1, OUT)
        px(a, cx - 3, my, OUT); px(a, cx + 2, my, OUT)
        rect(a, cx - 1, my + 1, 2, 1, rgb('e0506a'))
    elif mood == 'angry':
        for i in range(4):
            px(a, cx - gap // 2 - 3 + i, cy - 3 + i // 2, OUT)
            px(a, cx + gap // 2 + 3 - i, cy - 3 + i // 2, OUT)
        rect(a, cx - 2, my + 1, 4, 1, OUT)
    elif mood == 'sleepy':
        rect(a, cx - 1, my, 2, 2, OUT)
    elif mood == 'sly':
        for x in range(cx - 2, cx + 3):
            px(a, x, my + (1 if x > cx else 0), OUT)
    # blush
    for dx in (-gap // 2 - 5, gap // 2 + 3):
        px(a, cx + dx, cy + 5, rgb('f08a9a')); px(a, cx + dx + 1, cy + 5, rgb('f08a9a'))


def tulipup(back=False):
    a = canvas(S, S)
    # stem / legs
    part(a, M(lambda d: d.rectangle([29, 46, 34, 58], fill=1)), rgb('4a9a4a'), edge=1)
    part(a, M(lambda d: d.ellipse([22, 54, 31, 60], fill=1)), rgb('3e7a3e'), edge=1)
    part(a, M(lambda d: d.ellipse([32, 54, 41, 60], fill=1)), rgb('3e7a3e'), edge=1)
    # leaf arms
    part(a, M(lambda d: d.polygon([(22, 40), (6, 30), (10, 44), (22, 46)], fill=1)), rgb('5ab05a'), edge=2)
    part(a, M(lambda d: d.polygon([(42, 40), (58, 30), (54, 44), (42, 46)], fill=1)), rgb('5ab05a'), edge=2)
    # bloom cup
    cup = M(lambda d: (d.ellipse([14, 16, 50, 52], fill=1),
                       d.polygon([(14, 30), (16, 6), (26, 18)], fill=1),
                       d.polygon([(24, 20), (32, 2), (40, 20)], fill=1),
                       d.polygon([(50, 30), (48, 6), (38, 18)], fill=1)))
    part(a, cup, rgb('ec6a3a'), edge=3)
    # petal seams
    for t in range(20):
        px(a, 24 + t // 6, 22 + t, rgb('c04a2a'))
        px(a, 40 - t // 6, 22 + t, rgb('c04a2a'))
    if not back:
        face(a, 32, 30, 'happy', gap=10)
    else:
        part(a, M(lambda d: d.ellipse([27, 8, 37, 18], fill=1)), rgb('f8b040'), edge=1)
    return a


def stroopuff(back=False):
    a = canvas(S, S)
    # little feet
    for x in (18, 38):
        part(a, M(lambda d: d.ellipse([x, 50, x + 10, 58], fill=1)), rgb('a8743c'), edge=1)
    body = M(lambda d: d.ellipse([8, 18, 56, 56], fill=1))
    part(a, body, rgb('d49a54'), edge=3)
    # waffle grid
    bm = body & erode(erode(erode(body)))
    for y in range(18, 56):
        for x in range(8, 56):
            if bm[y, x] and ((x + y) % 7 == 0 or (x - y) % 7 == 0):
                px(a, x, y, rgb('a8743c'))
    # syrup drips on top
    syrup = M(lambda d: (d.ellipse([12, 16, 52, 30], fill=1), d.rectangle([18, 24, 22, 34], fill=1),
                         d.ellipse([17, 31, 23, 37], fill=1), d.rectangle([40, 24, 44, 30], fill=1), d.ellipse([39, 28, 45, 34], fill=1)))
    part(a, syrup & body | (syrup & ~body & M(lambda d: d.rectangle([0, 28, 64, 64], fill=1))), rgb('a0522a'), edge=1)
    # sleepy nightcap (Indica purple)
    cap = M(lambda d: d.polygon([(14, 22), (50, 22), (44, 4), (30, 2), (20, 10)], fill=1))
    part(a, cap, rgb('7a5ad0'), edge=2)
    part(a, M(lambda d: d.rounded_rectangle([12, 18, 52, 25], radius=3, fill=1)), rgb('e8e0f8'), edge=1)
    part(a, M(lambda d: d.ellipse([44, 0, 54, 10], fill=1)), rgb('e8e0f8'), edge=1)
    if not back:
        face(a, 32, 36, 'sleepy', gap=12)
        # Z
        for (x, y) in [(54, 14), (55, 14), (56, 14), (55, 15), (54, 16), (55, 16), (56, 16)]:
            px(a, x, y, rgb('c8b8f8'))
    return a


def klompy(back=False):
    a = canvas(S, S)
    # clog body
    clog = M(lambda d: (d.rounded_rectangle([8, 30, 52, 54], radius=10, fill=1),
                        d.ellipse([40, 30, 60, 50], fill=1), d.polygon([(52, 34), (62, 30), (60, 40)], fill=1)))
    part(a, clog, rgb('f0c04a'), edge=3)
    # opening (where face lives)
    hole = M(lambda d: d.ellipse([10, 26, 36, 40], fill=1))
    put(a, hole, rgb('3a2a1e'))
    put(a, hole & ~shift(hole, 0, 2), rgb('5a4430'))
    # painted green band + tulip motif
    band = M(lambda d: d.rectangle([8, 44, 60, 47], fill=1)) & clog
    put(a, band, rgb('3e9a5a'))
    for (x, y, c) in [(44, 38, rgb('e0383c')), (50, 40, rgb('e0383c'))]:
        rect(a, x, y, 3, 2, c); px(a, x + 1, y + 2, rgb('3e9a5a'))
    # sprout on top (Hybrid leaf)
    for (pts) in [[(22, 28), (12, 12), (22, 16)], [(24, 28), (24, 6), (30, 16)], [(26, 28), (36, 12), (28, 18)]]:
        part(a, M(lambda d: d.polygon(pts, fill=1)), rgb('4ab06a'), edge=1)
    # feet
    for x in (14, 40):
        part(a, M(lambda d: d.ellipse([x, 52, x + 9, 60], fill=1)), rgb('a8742c'), edge=1)
    if not back:
        eye(a, 15, 30, big=True)
        eye(a, 26, 30, big=True)
        rect(a, 21, 37, 3, 1, (250, 250, 250))
    return a


def stowaweed(back=False):
    a = canvas(S, S)
    sack = M(lambda d: (d.ellipse([10, 22, 54, 60], fill=1), d.polygon([(20, 26), (32, 10), (44, 26)], fill=1)))
    part(a, sack, rgb('b8a07a'), edge=3)
    # burlap weave
    for y in range(12, 60, 3):
        for x in range(10, 54, 3):
            if sack[y, x] and erode(sack)[y, x]:
                px(a, x, y, rgb('9a845e'))
    # tie
    rect(a, 25, 18, 14, 3, rgb('6a4a2c')); px(a, 40, 21, rgb('6a4a2c')); px(a, 41, 22, rgb('6a4a2c'))
    # patch
    part(a, M(lambda d: d.rectangle([38, 40, 48, 50], fill=1)), rgb('6a7ac0'), edge=1)
    for i in range(0, 10, 2):
        px(a, 38 + i, 40, (240, 240, 240)); px(a, 38 + i, 50, (240, 240, 240))
    # sprout poking out
    part(a, M(lambda d: d.polygon([(31, 12), (22, 0), (33, 6), (40, 0), (34, 12)], fill=1)), rgb('5ab05a'), edge=1)
    if not back:
        # one eye peeking from a tear
        tear = M(lambda d: d.ellipse([18, 32, 34, 42], fill=1))
        put(a, tear, rgb('2a2018'))
        eye(a, 21, 34, big=True)
        eye(a, 27, 34, big=False)
    return a


def grachtling(back=False):
    a = canvas(S, S)
    blob = M(lambda d: (d.ellipse([8, 10, 56, 50], fill=1),
                        d.ellipse([6, 40, 20, 58], fill=1), d.ellipse([18, 44, 32, 60], fill=1),
                        d.ellipse([32, 44, 46, 60], fill=1), d.ellipse([44, 40, 58, 58], fill=1)))
    part(a, blob, rgb('5aa8d8'), edge=3)
    # translucent inner swirl
    sw = M(lambda d: d.arc([16, 18, 48, 46], 200, 340, fill=1, width=2))
    put(a, sw & blob, rgb('a8dcf8'))
    for (x, y) in [(14, 18), (50, 22), (44, 12)]:
        put(a, M(lambda d: d.ellipse([x, y, x + 5, y + 5], outline=1)), rgb('d8f4ff'))
    # canal weed strand
    for t in range(14):
        px(a, 40 + (t % 3) - 1, 40 + t, rgb('3e8a5a'))
    if not back:
        # glowing eyes
        for x in (21, 36):
            rect(a, x, 26, 6, 7, rgb('f8f8d8'))
            rect(a, x + 1, 27, 4, 5, rgb('ffe86a'))
            rect(a, x + 2, 29, 2, 2, OUT)
        for x in range(28, 36):
            px(a, x, 38 + (1 if x % 2 else 0), OUT)
    return a


def cookush(back=False):
    a = canvas(S, S)
    # legs
    for x in (24, 36):
        rect(a, x, 52, 2, 7, rgb('e07a7a')); rect(a, x - 2, 58, 6, 2, rgb('e07a7a'))
    body = M(lambda d: d.ellipse([8, 22, 54, 56], fill=1))
    part(a, body, rgb('8a8aa0'), edge=3)
    wing = M(lambda d: d.ellipse([10, 32, 38, 52], fill=1))
    part(a, wing, rgb('6e6e88'), edge=2)
    for y in (40, 44, 48):
        rect(a, 14, y, 18, 1, rgb('4a4a64'))
    head = M(lambda d: d.ellipse([28, 6, 54, 32], fill=1))
    part(a, head, rgb('9a9ab0'), edge=2)
    # iridescent neck (Kush purple / green)
    neck = M(lambda d: d.ellipse([28, 24, 52, 36], fill=1)) & (body | head)
    put(a, neck, rgb('6a9a7a'))
    put(a, neck & ~shift(neck, 0, -2), rgb('8a5ad0'))
    # kush leaf crest
    for pts in [[(38, 8), (32, 0), (40, 4)], [(40, 8), (42, -2), (44, 6)], [(42, 8), (52, 2), (46, 10)]]:
        part(a, M(lambda d: d.polygon(pts, fill=1)), rgb('8a5ad0'), edge=1)
    if not back:
        eye(a, 42, 14, big=False, col=rgb('c04a2a'))
        beak = M(lambda d: d.polygon([(52, 18), (60, 21), (52, 23)], fill=1))
        part(a, beak, rgb('e8b04a'), edge=1)
        px(a, 50, 16, (250, 250, 250))
    return a


def bitterbal(back=False):
    a = canvas(S, S)
    ball = M(lambda d: d.ellipse([8, 12, 56, 58], fill=1))
    part(a, ball, rgb('c4782e'), edge=3)
    r = noise_rng(5)
    em = erode(erode(ball))
    for _ in range(120):
        x, y = r.randrange(8, 56), r.randrange(12, 58)
        if em[y, x]:
            px(a, x, y, rgb('e0a050') if r.random() < .5 else rgb('8a4a1e'))
    # crumbly spikes (Diesel = spiky, oily)
    for (x, y) in [(10, 20), (52, 22), (8, 40), (56, 42), (20, 56), (44, 56)]:
        part(a, M(lambda d: d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=1)), rgb('a85e22'), edge=1)
    # mustard dollop hat + cocktail stick
    rect(a, 31, 0, 2, 14, rgb('e8d8a8'))
    part(a, M(lambda d: d.ellipse([20, 6, 44, 18], fill=1)), rgb('f0c82a'), edge=2)
    if not back:
        face(a, 32, 32, 'angry', gap=12)
    return a


SPECIES = {
    'tulipup': tulipup, 'stroopuff': stroopuff, 'klompy': klompy, 'stowaweed': stowaweed,
    'grachtling': grachtling, 'cookush': cookush, 'bitterbal': bitterbal,
}


def finish(arr):
    outline_all(arr)
    return arr


def make_back(fn):
    a = finish(fn(back=True))
    img = to_img(a).transpose(Image.FLIP_LEFT_RIGHT)
    # back view sits lower and is cropped at the bottom, like the handheld games
    out = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    out.paste(img, (0, 12), img)
    return out


def build_strains(outdir):
    p = os.path.join(outdir, 'strains')
    os.makedirs(p, exist_ok=True)
    for name, fn in SPECIES.items():
        front = to_img(finish(fn()))
        front.save(os.path.join(p, name + '.png'))
        make_back(fn).save(os.path.join(p, name + '_back.png'))
        icon = front.resize((32, 32), Image.NEAREST)
        icon.save(os.path.join(p, name + '_icon.png'))
