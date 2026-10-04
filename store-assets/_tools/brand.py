"""Shared FitFlow brand drawing helpers for store-asset generation.

Everything is drawn at 4x and downsampled for clean anti-aliased edges, so
assets can be regenerated at any size without a design tool.
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

INDIGO = (67, 56, 202)
VIOLET = (109, 40, 217)
DEEP = (30, 27, 75)
CORAL = (255, 107, 74)
TEAL = (13, 148, 136)
WHITE = (255, 255, 255)
INK = (17, 17, 39)
MIST = (246, 246, 251)

SS = 4  # supersampling factor

# Lightning bolt, normalised to a unit square centred on (0.5, 0.5).
BOLT = [(0.58, 0.10), (0.27, 0.55), (0.47, 0.55), (0.40, 0.90), (0.73, 0.43), (0.53, 0.43), (0.64, 0.10)]


def gradient(size: tuple[int, int], a=INDIGO, b=VIOLET, angle_deg: float = 135) -> Image.Image:
    """Linear gradient from a to b along angle (0 = left→right)."""
    w, h = size
    small = (max(2, w // 8), max(2, h // 8))
    img = Image.new("RGB", small)
    px = img.load()
    rad = math.radians(angle_deg)
    dx, dy = math.cos(rad), math.sin(rad)
    corners = [0 * dx + 0 * dy, small[0] * dx, small[1] * dy, small[0] * dx + small[1] * dy]
    lo, hi = min(corners), max(corners)
    for y in range(small[1]):
        for x in range(small[0]):
            t = ((x * dx + y * dy) - lo) / (hi - lo)
            px[x, y] = tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))
    return img.resize(size, Image.BICUBIC)


def mark(size: int, scale: float, bolt=CORAL, ring=WHITE, ring_alpha=255) -> Image.Image:
    """The FitFlow mark (bolt inside an open 'flow' ring) on transparency.

    scale is the ring's outer diameter as a fraction of size.
    """
    S = size * SS
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = S / 2
    r = S * scale / 2
    width = r * 0.16
    box = [c - r + width / 2, c - r + width / 2, c + r - width / 2, c + r - width / 2]
    # Open ring: a gap at the top-right suggests motion ("flow").
    d.arc(box, start=-35, end=265, fill=(*ring, ring_alpha), width=round(width))
    # Rounded ring ends. PIL strokes an arc inward from its bounding box, so the
    # stroke's centre line sits one full width inside the outer radius.
    for ang in (-35, 265):
        a = math.radians(ang)
        rr = r - width
        x, y = c + rr * math.cos(a), c + rr * math.sin(a)
        d.ellipse([x - width / 2, y - width / 2, x + width / 2, y + width / 2], fill=(*ring, ring_alpha))
    bolt_size = r * 1.42
    pts = [(c + (px - 0.5) * bolt_size, c + (py - 0.5) * bolt_size) for px, py in BOLT]
    d.polygon(pts, fill=(*bolt, 255))
    return img.resize((size, size), Image.LANCZOS)


def full_icon(size: int, rounded: bool = False) -> Image.Image:
    """Square, full-bleed icon (Play 512, App Store 1024, legacy launcher)."""
    base = gradient((size, size)).convert("RGBA")
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([size * 0.18, size * 0.18, size * 0.82, size * 0.82], fill=(255, 255, 255, 28))
    base.alpha_composite(glow.filter(ImageFilter.GaussianBlur(size * 0.06)))
    base.alpha_composite(mark(size, 0.64))
    if rounded:
        mask = Image.new("L", (size * SS, size * SS), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, size * SS, size * SS], radius=size * SS * 0.22, fill=255)
        base.putalpha(mask.resize((size, size), Image.LANCZOS))
    return base


def font(size: int, weight: str = "bold") -> ImageFont.FreeTypeFont:
    candidates = {
        "bold": ["/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf",
                 "/System/Library/Fonts/SFNSRounded.ttf",
                 "/System/Library/Fonts/Supplemental/Arial Bold.ttf"],
        "regular": ["/System/Library/Fonts/SFNS.ttf",
                    "/System/Library/Fonts/Supplemental/Arial.ttf"],
    }[weight]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size)


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt, max_width: int) -> list[str]:
    words, lines, line = text.split(), [], ""
    for w in words:
        test = f"{line} {w}".strip()
        if draw.textlength(test, font=fnt) <= max_width:
            line = test
        else:
            lines.append(line)
            line = w
    if line:
        lines.append(line)
    return lines


def rounded(img: Image.Image, radius: int) -> Image.Image:
    img = img.convert("RGBA")
    mask = Image.new("L", (img.width * 2, img.height * 2), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.width * 2, img.height * 2], radius=radius * 2, fill=255)
    img.putalpha(mask.resize(img.size, Image.LANCZOS))
    return img


def shadow(size: tuple[int, int], radius: int, blur: int, opacity: int = 90) -> Image.Image:
    w, h = size
    pad = blur * 3
    s = Image.new("RGBA", (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    ImageDraw.Draw(s).rounded_rectangle([pad, pad, pad + w, pad + h], radius=radius, fill=(10, 8, 40, opacity))
    return s.filter(ImageFilter.GaussianBlur(blur))
