"""Rebuild every generated asset. Usage: python3 tools/build_assets.py"""
import os
import sys
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from pix import *
from gen_tiles_ui import build_tiles, build_font, build_frames, build_icons, GLYPHS, TILE_NAMES
from gen_props_chars import build_props, text
from gen_strains import build_strains
from gen_audio import build_audio

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
A = os.path.join(ROOT, 'assets')


def gradient_sky(a, top, bottom, y0, y1, bands=8):
    for y in range(y0, y1):
        t = (y - y0) / max(1, (y1 - y0 - 1))
        t = round(t * bands) / bands   # banded like a 15-bit palette
        rect(a, 0, y, a.shape[1], 1, mix(top, bottom, t))


def battle_bg(kind):
    W, H = 270, 232
    a = canvas(W, H)
    r = noise_rng(3 if kind == 'ferry' else 4)
    if kind == 'ferry':
        gradient_sky(a, rgb('6ab0e8'), rgb('d8eef8'), 0, 120)
        # clouds
        for (x, y, w) in [(20, 30, 50), (150, 18, 70), (210, 60, 40)]:
            m = mask_from(W, H, lambda d: (d.ellipse([x, y, x + w, y + 14], fill=1), d.ellipse([x + w // 4, y - 8, x + w * 3 // 4, y + 10], fill=1)))
            put(a, m, (250, 252, 255))
            put(a, m & ~shift(m, 0, -2), rgb('c8dcf0'))
        # distant coast
        put(a, mask_from(W, H, lambda d: d.polygon([(0, 112), (60, 104), (120, 110), (180, 102), (270, 108), (270, 120), (0, 120)], fill=1)), rgb('8aa4b8'))
        gradient_sky(a, rgb('3a7ab8'), rgb('1e4a7a'), 120, 170, 5)
        for _ in range(60):
            x, y = r.randrange(W), r.randrange(122, 170)
            rect(a, x, y, r.randrange(3, 9), 1, rgb('7ab0e0'))
        # deck floor
        for y in range(170, H, 6):
            rect(a, 0, y, W, 5, rgb('b07c4c') if (y // 6) % 2 else rgb('c08a56'))
            rect(a, 0, y + 5, W, 1, rgb('6a4630'))
        rect(a, 0, 164, W, 6, rgb('eceef2')); rect(a, 0, 170, W, 1, rgb('a4a8b8'))
        for x in range(4, W, 22):
            rect(a, x, 150, 3, 16, rgb('eceef2'))
        rect(a, 0, 150, W, 2, rgb('eceef2'))
    else:
        gradient_sky(a, rgb('2a2a6a'), rgb('f0906a'), 0, 110, 10)
        # sun glow
        put(a, mask_from(W, H, lambda d: d.ellipse([170, 70, 220, 120], fill=1)), rgb('f8c08a'))
        # canal house silhouettes with lit windows
        x = 0
        while x < W:
            w = r.choice([20, 24, 28])
            h = r.randrange(50, 80)
            top = 118 - h
            col = rgb('2a1e3a')
            rect(a, x, top, w, h, col)
            # gable
            put(a, mask_from(W, H, lambda d: d.polygon([(x, top), (x + w // 2, top - 10), (x + w, top)], fill=1)), col)
            for wy in range(top + 6, 112, 12):
                for wx in (x + 4, x + w - 9):
                    if r.random() < .6:
                        rect(a, wx, wy, 4, 6, rgb('f8c860'))
            x += w + 1
        # canal
        gradient_sky(a, rgb('3a4a8a'), rgb('1e2a5a'), 118, 160, 5)
        for _ in range(50):
            xx, y = r.randrange(W), r.randrange(120, 160)
            rect(a, xx, y, r.randrange(2, 7), 1, rgb('f8c860') if r.random() < .3 else rgb('5a6aaa'))
        # quay ground (brick)
        for y in range(160, H, 4):
            for xx in range(-(y // 4 % 2) * 4, W, 8):
                rect(a, xx, y, 7, 3, rgb('8a4c40') if (xx + y) % 3 else rgb('7a4038'))
            rect(a, 0, y + 3, W, 1, rgb('4a2a2a'))
        rect(a, 0, 158, W, 3, rgb('9a96a2'))
    return a


def platform(col):
    a = canvas(112, 28)
    m = mask_from(112, 28, lambda d: d.ellipse([0, 0, 111, 27], fill=1))
    part(a, m, col, edge=3, hi=False)
    inner = mask_from(112, 28, lambda d: d.ellipse([10, 4, 101, 23], fill=1))
    put(a, inner & ~shift(inner, 0, -3), mix(col, (255, 255, 255), .2))
    return a


def logo():
    word1, word2 = 'DEAL DEX', '2'
    sc = 3
    w = len(word1) * 6 * sc + 8
    a = canvas(w + 40, 8 * sc + 12)
    tmp = canvas(len(word1) * 6, 8)
    text(tmp, 0, 0, word1, (255, 255, 255))
    big = to_img(tmp).resize((len(word1) * 6 * sc, 8 * sc), Image.NEAREST)
    import numpy as np
    b = np.array(big)
    mask = b[:, :, 3] > 0
    h = mask.shape[0]
    for y in range(h):
        t = y / (h - 1)
        c = mix(rgb('ffe86a'), rgb('f07a2a'), t)
        for x in range(mask.shape[1]):
            if mask[y, x]:
                px(a, x + 4, y + 4, c)
    m = a[:, :, 3] > 0
    for _ in range(2):
        m2 = shift(m, 1, 0) | shift(m, -1, 0) | shift(m, 0, 1) | shift(m, 0, -1)
        ring = m2 & ~m
        put(a, ring, OUT)
        m = m2
    drop = shift(m, 0, 2) & ~m
    put(a, drop, rgb('5a2a6a'))
    # big "2" in a badge
    bx = len(word1) * 6 * sc + 12
    badge = mask_from(a.shape[1], a.shape[0], lambda d: d.ellipse([bx, 1, bx + 26, a.shape[0] - 2], fill=1))
    part(a, badge, rgb('3cae6e'), edge=2)
    t2 = canvas(6, 8)
    text(t2, 0, 0, word2, (255, 255, 255))
    b2 = np.array(to_img(t2).resize((18, 24), Image.NEAREST))
    for y in range(24):
        for x in range(18):
            if b2[y, x, 3] > 0:
                px(a, bx + 5 + x, 6 + y, (255, 255, 255))
    return a


def write_tile_ids(names):
    p = os.path.join(ROOT, 'src', 'gen')
    os.makedirs(p, exist_ok=True)
    with open(os.path.join(p, 'tile_ids.gd'), 'w') as f:
        f.write('# GENERATED by tools/build_assets.py - do not edit\n')
        f.write('extends RefCounted\n\n')
        f.write('const NAMES := [' + ', '.join('"%s"' % n for n in names) + ']\n')
        f.write('const COLS := 8\n')


def main():
    os.makedirs(A, exist_ok=True)
    ui = os.path.join(A, 'ui')
    os.makedirs(ui, exist_ok=True)
    names = build_tiles(A)
    write_tile_ids(names)
    build_font(ui)
    build_frames(ui)
    build_icons(ui)
    build_props(A)
    build_strains(A)
    bg = os.path.join(A, 'battle')
    os.makedirs(bg, exist_ok=True)
    save(battle_bg('ferry'), os.path.join(bg, 'bg_ferry.png'))
    save(battle_bg('canal'), os.path.join(bg, 'bg_canal.png'))
    save(platform(rgb('c8a878')), os.path.join(bg, 'plat_ferry.png'))
    save(platform(rgb('8a8696')), os.path.join(bg, 'plat_canal.png'))
    save(logo(), os.path.join(ui, 'logo.png'))
    build_audio(os.path.join(A, 'audio'))
    print('assets built')


if __name__ == '__main__':
    main()
