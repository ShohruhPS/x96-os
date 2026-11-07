#!/usr/bin/env python3
"""Generate the X96 OS logo PNGs and wallpapers.

Deterministic: the same script always produces the same images.
Needs only numpy + Pillow (and the Inter font if available).

Usage: make-wallpapers.py OUTPUT_DIR
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1920, 1080
OUT = sys.argv[1] if len(sys.argv) > 1 else "out"
os.makedirs(OUT, exist_ok=True)

FONT_CANDIDATES = [
    "/usr/share/fonts/opentype/inter/InterDisplay-SemiBold.otf",
    "/usr/share/fonts/opentype/inter/Inter-SemiBold.otf",
    "/usr/share/fonts/truetype/inter/Inter-SemiBold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
]


def font(size):
    for f in FONT_CANDIDATES:
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def hex2rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


# ---------------------------------------------------------------- logo
def draw_logo(size, glyph_only=False, glyph_color=(255, 255, 255, 255)):
    """Squircle with a diagonal gradient and a two-stroke 'X'.
    glyph_only=True gives a transparent background (menu/panel icon)."""
    S = size * 4  # supersample
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    if not glyph_only:
        yy, xx = np.mgrid[0:S, 0:S].astype(np.float32) / S
        t = (xx + yy) / 2
        c1, c2, c3 = hex2rgb("#5B5BF7"), hex2rgb("#B44CF0"), hex2rgb("#FF7A59")
        col = np.where(t[..., None] < 0.5,
                       c1 + (c2 - c1) * (t[..., None] / 0.5),
                       c2 + (c3 - c2) * ((t[..., None] - 0.5) / 0.5))
        # soft top highlight
        col = col + 40 * np.clip(1 - yy[..., None] * 2.2, 0, 1)
        grad = Image.fromarray(np.clip(col, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
        mask = Image.new("L", (S, S), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * 0.225), fill=255)
        img.paste(grad, (0, 0), mask)
    glyph = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    back = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    m = S * (0.30 if not glyph_only else 0.16)
    w = int(S * (0.115 if not glyph_only else 0.16))
    r = w // 2
    a, b = (m, m), (S - m, S - m)
    c, e = (S - m, m), (m, S - m)
    gc = glyph_color
    dim = (gc[0], gc[1], gc[2], int(gc[3] * (0.62 if not glyph_only else 1.0)))
    # back stroke (dimmer) then front stroke, each composited properly
    bd = ImageDraw.Draw(back)
    bd.line([c, e], fill=dim, width=w)
    for p in (c, e):
        bd.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=dim)
    fd = ImageDraw.Draw(glyph)
    fd.line([a, b], fill=gc, width=w)
    for p in (a, b):
        fd.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=gc)
    if not glyph_only:
        # soft drop shadow under the glyph
        sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        sh.paste((40, 10, 80, 90), (0, int(S * 0.02)), glyph.split()[3])
        img = Image.alpha_composite(img, sh.filter(ImageFilter.GaussianBlur(S * 0.02)))
    img = Image.alpha_composite(img, back)
    img = Image.alpha_composite(img, glyph)
    return img.resize((size, size), Image.LANCZOS)


# ---------------------------------------------------------------- waves
def wave_wallpaper(name, bg_top, bg_bot, layers, glow=None, seed=1, brand="light", shadow=0.35):
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    u, v = xx / W, yy / H
    t = v[..., None]
    img = hex2rgb(bg_top) * (1 - t) + hex2rgb(bg_bot) * t
    if glow:
        gx, gy, gr, gcol, gs = glow
        dist = np.sqrt(((u - gx) * (W / H)) ** 2 + (v - gy) ** 2)
        g = np.exp(-(dist / gr) ** 2)[..., None] * gs
        img = img * (1 - g) + hex2rgb(gcol) * g
    for i, (base, amp, freq, phase, ca, cb, soft) in enumerate(layers):
        curve = (base
                 + amp * np.sin(2 * math.pi * (freq * u + phase))
                 + amp * 0.45 * np.sin(2 * math.pi * (freq * 2.1 * u + phase * 1.7 + 0.3))
                 + amp * 0.2 * np.sin(2 * math.pi * (freq * 3.7 * u + phase * 0.6)))
        depth = v - curve  # >0 below the curve
        # shadow cast upward onto the layer behind
        sh = (1 - smoothstep(-0.0, 0.10, -depth)) * (depth < 0) * shadow
        img = img * (1 - sh[..., None])
        a = smoothstep(-soft, soft, depth)[..., None]
        tt = np.clip(depth / 0.6, 0, 1)[..., None]
        lc = hex2rgb(ca) * (1 - tt) + hex2rgb(cb) * tt
        # sheen near the crest
        lc = lc + 38 * np.exp(-((depth / 0.035) ** 2))[..., None] * (depth > 0)[..., None]
        img = img * (1 - a) + lc * a
    # vignette
    vg = 1 - 0.28 * (((u - 0.5) * 1.3) ** 2 + ((v - 0.5) * 1.1) ** 2)
    img = img * vg[..., None]
    # film grain kills gradient banding
    img = img + rng.normal(0, 2.2, img.shape)
    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB")
    out = out.filter(ImageFilter.GaussianBlur(0.6))
    add_brand(out, brand)
    out.save(os.path.join(OUT, f"{name}.jpg"), quality=93, subsampling=0, optimize=True)
    return out


def add_brand(img, mode):
    """Small, subtle logo + wordmark in the bottom-right corner."""
    if mode is None:
        return
    col = (255, 255, 255, 150) if mode == "light" else (20, 20, 40, 150)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    logo = draw_logo(34, glyph_only=True, glyph_color=col)
    f = font(26)
    d = ImageDraw.Draw(layer)
    text = "X96 OS"
    tw = d.textlength(text, font=f)
    x = int(W - 56 - tw)
    y = H - 64
    layer.paste(logo, (x - 44, y - 4), logo)
    d.text((x, y - 2), text, font=f, fill=col)
    img.paste(Image.alpha_composite(img.convert("RGBA"), layer).convert("RGB"))


def hero(name, base_img):
    """Dark wallpaper with the full-colour logo centred, used for login."""
    img = base_img.copy().filter(ImageFilter.GaussianBlur(28)).convert("RGBA")
    dark = Image.new("RGBA", img.size, (8, 8, 20, 90))
    img = Image.alpha_composite(img, dark)
    logo = draw_logo(220)
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    cx, cy = W // 2, H // 2 - 70
    gd.ellipse([cx - 220, cy - 220, cx + 220, cy + 220], fill=(150, 90, 255, 110))
    glow = glow.filter(ImageFilter.GaussianBlur(90))
    img = Image.alpha_composite(img, glow)
    img.paste(logo, (cx - 110, cy - 110), logo)
    d = ImageDraw.Draw(img)
    f = font(64)
    text = "X96 OS"
    tw = d.textlength(text, font=f)
    d.text((cx - tw / 2, cy + 140), text, font=f, fill=(255, 255, 255, 235))
    img.convert("RGB").save(os.path.join(OUT, f"{name}.jpg"), quality=93, subsampling=0, optimize=True)


if __name__ == "__main__":
    # logos
    for s in (16, 22, 24, 32, 48, 64, 128, 256, 512):
        draw_logo(s).save(os.path.join(OUT, f"x96os-logo-{s}.png"))
    for s in (16, 22, 24, 32, 48):
        draw_logo(s, glyph_only=True).save(os.path.join(OUT, f"x96os-symbolic-{s}.png"))

    dusk = wave_wallpaper(
        "x96os-dusk", "#0B0B2B", "#1A1046",
        [
            (0.42, 0.06, 0.55, 0.10, "#3B2C9E", "#1B1555", 0.004),
            (0.55, 0.07, 0.45, 0.55, "#6A3FD4", "#2A1A6E", 0.004),
            (0.68, 0.05, 0.60, 0.25, "#B04BD8", "#3C1C78", 0.004),
            (0.80, 0.045, 0.50, 0.80, "#FF7A8A", "#5A2384", 0.004),
        ],
        glow=(0.75, 0.25, 0.55, "#4B3BD6", 0.45), seed=11)
    wave_wallpaper(
        "x96os-dawn", "#F7E9F2", "#E7ECFF",
        [
            (0.45, 0.06, 0.50, 0.35, "#FFC9B5", "#F6A6C1", 0.004),
            (0.58, 0.06, 0.42, 0.70, "#F59AC4", "#C8A5F5", 0.004),
            (0.71, 0.05, 0.58, 0.15, "#A9B5FF", "#8C9BF5", 0.004),
            (0.83, 0.04, 0.48, 0.55, "#7A8CF2", "#5B6BE0", 0.004),
        ],
        glow=(0.25, 0.20, 0.6, "#FFFFFF", 0.55), seed=12, brand="dark", shadow=0.10)
    wave_wallpaper(
        "x96os-ocean", "#04172B", "#062B3D",
        [
            (0.46, 0.06, 0.50, 0.60, "#0F5A73", "#0A3448", 0.004),
            (0.60, 0.065, 0.40, 0.15, "#14889A", "#0C4A5E", 0.004),
            (0.73, 0.05, 0.55, 0.45, "#2CC3B5", "#106070", 0.004),
            (0.85, 0.04, 0.47, 0.90, "#A8F0D8", "#1D7D86", 0.004),
        ],
        glow=(0.70, 0.18, 0.5, "#1E6FA8", 0.5), seed=13)
    wave_wallpaper(
        "x96os-ember", "#1A0A0A", "#2B0F14",
        [
            (0.44, 0.06, 0.52, 0.20, "#5C1A2A", "#2E0E18", 0.004),
            (0.57, 0.065, 0.43, 0.65, "#A3313B", "#4A1420", 0.004),
            (0.70, 0.05, 0.57, 0.35, "#E8663D", "#6E1E26", 0.004),
            (0.82, 0.045, 0.49, 0.85, "#FFC56B", "#8A2C2A", 0.004),
        ],
        glow=(0.3, 0.22, 0.55, "#7A2A4A", 0.45), seed=14)
    hero("x96os-login", dusk)
    print("done:", sorted(os.listdir(OUT)))
