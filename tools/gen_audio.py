"""Chiptune SFX and music, synthesised to 16-bit mono WAV (no external tools)."""
import math
import os
import random
import struct
import wave

SR = 22050

NOTE = {'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5, 'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'B': 11}


def freq(n):
    """'A4' -> Hz. '-' = rest."""
    if n in ('-', '.', ''):
        return 0.0
    name, octv = n[:-1], int(n[-1])
    semi = NOTE[name] + (octv + 1) * 12
    return 440.0 * 2 ** ((semi - 69) / 12)


def osc(kind, ph, duty=0.5):
    p = ph % 1.0
    if kind == 'sq':
        return 1.0 if p < duty else -1.0
    if kind == 'tri':
        return 4 * abs(p - 0.5) - 1
    if kind == 'saw':
        return 2 * p - 1
    if kind == 'sin':
        return math.sin(2 * math.pi * p)
    return 0.0


def render_voice(seq, step, kind='sq', vol=0.25, duty=0.5, env=(0.005, 0.08, 0.6, 0.06), vib=0.0, total=None):
    """seq: list of note strings, each lasting `step` seconds; '~' holds previous note."""
    n_total = int((total or len(seq) * step) * SR)
    out = [0.0] * n_total
    a_, d_, s_, r_ = env
    i = 0
    while i < len(seq):
        n = seq[i]
        length = 1
        while i + length < len(seq) and seq[i + length] == '~':
            length += 1
        f = freq(n)
        if f > 0:
            start = int(i * step * SR)
            dur = length * step
            ns = int(dur * SR)
            ph = 0.0
            for k in range(ns):
                t = k / SR
                if t < a_:
                    e = t / a_
                elif t < a_ + d_:
                    e = 1 - (1 - s_) * (t - a_) / d_
                else:
                    e = s_
                rem = dur - t
                if rem < r_:
                    e *= max(0.0, rem / r_)
                ff = f * (1 + vib * math.sin(2 * math.pi * 5.5 * t) * min(1, t * 3))
                ph += ff / SR
                idx = start + k
                if idx < n_total:
                    out[idx] += osc(kind, ph, duty) * e * vol
        i += length
    return out


def noise_hits(pattern, step, vol=0.18, total=None, decay=0.05):
    n_total = int((total or len(pattern) * step) * SR)
    out = [0.0] * n_total
    rnd = random.Random(1)
    for i, c in enumerate(pattern):
        if c in 'xXo':
            start = int(i * step * SR)
            dec = decay * (2.2 if c == 'X' else 1)
            lvl = vol * (1.3 if c == 'X' else (0.6 if c == 'o' else 1))
            hold = 0.0
            for k in range(int(dec * 4 * SR)):
                if k % (3 if c == 'o' else 2) == 0:
                    hold = rnd.uniform(-1, 1)
                idx = start + k
                if idx < n_total:
                    out[idx] += hold * lvl * math.exp(-k / SR / dec)
    return out


def mixdown(tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    peak = max(1e-6, max(abs(v) for v in out))
    g = min(1.0, 0.9 / peak)
    return [v * g for v in out]


def write(path, samples):
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s)) * 32000)) for s in samples))


def sweep(f0, f1, dur, kind='sq', vol=0.3, duty=0.5):
    n = int(dur * SR)
    out, ph = [], 0.0
    for k in range(n):
        t = k / n
        f = f0 * (f1 / f0) ** t
        ph += f / SR
        out.append(osc(kind, ph, duty) * vol * (1 - t) ** 0.6)
    return out


def seq_notes(notes, step, kind='sq', vol=0.3, duty=0.5):
    return render_voice(notes, step, kind, vol, duty, env=(0.002, 0.03, 0.7, 0.02))


def parse(s):
    return s.split()


# ------------------------------------------------------------------ music
def song_ferry():
    """Bright sea-shanty-ish travel theme, 6/8 feel, loops."""
    step = 0.125
    mel = parse("""
    G4 ~ A4 B4 ~ G4  D5 ~ ~ B4 ~ ~  C5 ~ B4 A4 ~ G4  A4 ~ ~ ~ ~ ~
    G4 ~ A4 B4 ~ G4  D5 ~ ~ G5 ~ ~  F#5 ~ E5 D5 ~ C5  B4 ~ ~ ~ ~ ~
    E5 ~ D5 C5 ~ B4  C5 ~ D5 E5 ~ ~  D5 ~ C5 B4 ~ A4  B4 ~ G4 ~ ~ ~
    E5 ~ D5 C5 ~ B4  A4 ~ B4 C5 ~ ~  B4 ~ A4 F#4 ~ A4  G4 ~ ~ ~ ~ ~
    """)
    bass = parse("""
    G2 ~ ~ D3 ~ ~  G2 ~ ~ D3 ~ ~  C3 ~ ~ G2 ~ ~  D3 ~ ~ A2 ~ ~
    G2 ~ ~ D3 ~ ~  G2 ~ ~ B2 ~ ~  D3 ~ ~ A2 ~ ~  G2 ~ ~ D3 ~ ~
    C3 ~ ~ G2 ~ ~  A2 ~ ~ E3 ~ ~  D3 ~ ~ A2 ~ ~  G2 ~ ~ B2 ~ ~
    C3 ~ ~ G2 ~ ~  D3 ~ ~ F#2 ~ ~  D3 ~ ~ D2 ~ ~  G2 ~ ~ D3 ~ ~
    """)
    harm = []
    for ch in ['B3 D4', 'B3 D4', 'C4 E4', 'C4 F#4', 'B3 D4', 'B3 D4', 'A3 D4', 'B3 D4',
               'C4 E4', 'C4 E4', 'A3 D4', 'B3 D4', 'C4 E4', 'A3 C4', 'A3 D4', 'B3 D4']:
        n = ch.split()[1]
        harm += ['-', '-', '-', n, '-', n]
    total = len(mel) * step
    drums = ('x..o..x..o..' * 8)[:len(mel)]
    tr = [render_voice(mel, step, 'sq', .22, .25, vib=.004),
          render_voice(bass, step, 'tri', .34),
          render_voice(harm, step, 'sq', .08, .5, env=(0.002, 0.04, 0.4, 0.03)),
          noise_hits(drums, step, .10, total)]
    return mixdown(tr)


def song_quay():
    """Mellow dusk theme for Amsterdam - swung, minor-ish, lamplit."""
    step = 0.15
    mel = parse("""
    A4 ~ C5 ~ E5 ~ D5 C5  B4 ~ ~ ~ G4 ~ ~ ~  A4 ~ C5 ~ E5 ~ G5 F5  E5 ~ ~ ~ ~ ~ ~ ~
    F5 ~ E5 ~ D5 ~ C5 ~  B4 ~ C5 D5 E5 ~ ~ ~  D5 ~ C5 ~ B4 ~ G4 ~  A4 ~ ~ ~ ~ ~ ~ ~
    """)
    bass = parse("""
    A2 ~ E3 ~ A2 ~ E3 ~  G2 ~ D3 ~ G2 ~ D3 ~  F2 ~ C3 ~ F2 ~ C3 ~  E2 ~ B2 ~ E2 ~ G#2 ~
    D3 ~ A2 ~ D3 ~ A2 ~  G2 ~ D3 ~ C3 ~ G2 ~  F2 ~ C3 ~ E2 ~ B2 ~  A2 ~ E3 ~ A2 ~ ~ ~
    """)
    arp = []
    for ch in ['A3 C4 E4', 'G3 B3 D4', 'F3 A3 C4', 'E3 G#3 B3', 'D3 F3 A3', 'G3 C4 E4', 'F3 A3 C4', 'A3 C4 E4']:
        a, b, c = ch.split()
        arp += [a, b, c, b, a, b, c, b]
    total = len(mel) * step
    tr = [render_voice(mel, step, 'sq', .2, .5, env=(0.01, 0.1, 0.55, 0.08), vib=.006),
          render_voice(bass, step, 'tri', .32),
          render_voice(arp, step, 'sq', .07, .125, env=(0.002, 0.05, 0.3, 0.03)),
          noise_hits(('..o...o.' * 8)[:len(mel)], step, .06, total, .03)]
    return mixdown(tr)


def song_battle():
    """Driving wild-battle loop."""
    step = 0.09
    mel = parse("""
    E5 ~ E5 ~ D5 E5 ~ G5  ~ ~ E5 ~ D5 ~ C5 ~  D5 ~ D5 ~ C5 D5 ~ F5  ~ ~ D5 ~ C5 ~ B4 ~
    C5 ~ C5 ~ B4 C5 ~ E5  ~ ~ C5 ~ B4 ~ A4 ~  B4 ~ C5 ~ D5 ~ E5 ~  F5 ~ E5 ~ D5 ~ B4 ~
    """)
    bass = []
    for n in ['A2', 'A2', 'G2', 'G2', 'F2', 'F2', 'E2', 'E2']:
        hi = n[:-1] + str(int(n[-1]) + 1)
        bass += [n, '-', hi, '-', n, '-', hi, n]
    total = len(mel) * step
    tr = [render_voice(mel, step, 'sq', .2, .25, env=(0.002, 0.04, 0.7, 0.02)),
          render_voice(bass, step, 'tri', .36, env=(0.002, 0.03, 0.8, 0.01)),
          render_voice([('A3' if i % 4 == 0 else '-') for i in range(len(mel))], step, 'sq', .06, .5),
          noise_hits(('x.o.X.o.' * 16)[:len(mel)], step, .12, total, .025)]
    return mixdown(tr)


def jingle_victory():
    step = 0.11
    mel = parse('G4 C5 E5 G5 ~ ~ E5 G5 ~ ~ ~ ~ A5 ~ G5 ~ F5 ~ E5 ~ ~ ~ ~ ~')
    bass = parse('C3 ~ ~ ~ ~ ~ C3 ~ ~ ~ ~ ~ F3 ~ ~ ~ G3 ~ C3 ~ ~ ~ ~ ~')
    return mixdown([render_voice(mel, step, 'sq', .25, .5), render_voice(bass, step, 'tri', .35)])


def build_audio(outdir):
    os.makedirs(outdir, exist_ok=True)
    sfx = {
        'blip': seq_notes(['E6'], 0.018, 'sq', .18, .5),
        'select': seq_notes(['A5', 'E6'], 0.035, 'sq', .22, .25),
        'confirm': seq_notes(['C6', 'G6'], 0.05, 'sq', .25, .5),
        'cancel': seq_notes(['G5', 'C5'], 0.05, 'sq', .22, .5),
        'bump': sweep(140, 70, 0.08, 'sq', .25),
        'hit': mixdown([noise_hits('x', 0.12, .5, decay=0.04), sweep(300, 60, 0.12, 'sq', .2)]),
        'crit': mixdown([noise_hits('X', 0.2, .6, decay=0.06), sweep(900, 80, 0.2, 'saw', .2)]),
        'super': mixdown([noise_hits('Xx', 0.08, .5, decay=0.05), sweep(600, 120, 0.25, 'sq', .2, .125)]),
        'faint': sweep(600, 60, 0.6, 'sq', .25, .25),
        'throw': sweep(300, 1200, 0.25, 'sq', .2, .125),
        'shake': mixdown([sweep(200, 150, 0.06, 'tri', .4), noise_hits('o', 0.08, .2, decay=0.02)]),
        'caught': seq_notes(['C5', 'E5', 'G5', 'C6', '~', '~'], 0.07, 'sq', .25, .5),
        'levelup': seq_notes(['C5', 'E5', 'G5', 'E5', 'G5', 'C6', '~', '~'], 0.06, 'sq', .25, .25),
        'heal': seq_notes(['C5', 'E5', 'G5', 'C6', 'E6', 'G6', '~'], 0.07, 'tri', .4),
        'encounter': mixdown([sweep(200, 1600, 0.35, 'sq', .2, .125), sweep(1600, 200, 0.35, 'sq', .12)]),
        'buff': sweep(400, 1400, 0.3, 'sq', .2, .25),
        'debuff': sweep(1400, 300, 0.3, 'sq', .2, .25),
        'door': mixdown([noise_hits('o', 0.15, .3, decay=0.05), sweep(180, 120, 0.12, 'tri', .3)]),
        'horn': mixdown([render_voice(['A2', '~', '~', '~', '~', '~', '~', '~'], 0.18, 'saw', .3, env=(0.08, 0.2, 0.8, 0.3)),
                         render_voice(['E3', '~', '~', '~', '~', '~', '~', '~'], 0.18, 'sq', .15, env=(0.08, 0.2, 0.8, 0.3))]),
        'coin': seq_notes(['B5', 'E6', '~'], 0.05, 'sq', .2, .5),
    }
    for k, v in sfx.items():
        write(os.path.join(outdir, k + '.wav'), v)
    write(os.path.join(outdir, 'music_ferry.wav'), song_ferry())
    write(os.path.join(outdir, 'music_quay.wav'), song_quay())
    write(os.path.join(outdir, 'music_battle.wav'), song_battle())
    write(os.path.join(outdir, 'jingle_victory.wav'), jingle_victory())
