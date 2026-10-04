"""Feature graphic (Google Play, 1024x500) and promotional banners.

Uses the raw phone captures, so run capture_screenshots.sh android-phone first.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from brand import CORAL, DEEP, INDIGO, VIOLET, WHITE, font, full_icon, gradient, rounded, shadow, wrap

REPO = Path(__file__).resolve().parents[2]
RAW = REPO / "frontend/mobile/build/screenshots/android-phone"
OUT = REPO / "store-assets"


def bg(size):
    img = gradient(size, INDIGO, DEEP, angle_deg=160).convert("RGBA")
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    w, h = size
    ImageDraw.Draw(glow).ellipse([w * 0.5, -h * 0.4, w * 1.2, h * 0.9], fill=(*VIOLET, 170))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(min(size) * 0.18)))
    return img


def phone(name: str, height: int) -> Image.Image:
    raw = Image.open(RAW / f"{name}.png").convert("RGB")
    w = round(raw.width * height / raw.height)
    shot = raw.resize((w, height), Image.LANCZOS)
    bezel = max(4, height // 70)
    dev = Image.new("RGB", (w + bezel * 2, height + bezel * 2), (12, 12, 24))
    dev.paste(shot, (bezel, bezel))
    return rounded(dev, height // 16)


def place_phones(canvas: Image.Image, names, cx: int, y0: int, height: int, step: int):
    """Fan of phones centred on cx: side phones smaller and behind, centre phone in front."""
    mid = len(names) // 2
    order = sorted(range(len(names)), key=lambda i: -abs(i - mid))  # outermost first
    for i in order:
        p = phone(names[i], height - abs(i - mid) * height // 10)
        x = cx + (i - mid) * step - p.width // 2
        y = y0 + (height - p.height) // 2
        s = shadow(p.size, p.height // 16, max(6, height // 30), 120)
        canvas.alpha_composite(s, (x - (s.width - p.width) // 2, y - (s.height - p.height) // 2 + height // 60))
        canvas.alpha_composite(p, (x, y))


def headline(canvas, x, y, max_w, size, title, sub):
    d = ImageDraw.Draw(canvas)
    icon = full_icon(round(size * 1.6), rounded=True)
    canvas.alpha_composite(icon, (x, y))
    d.text((x + icon.width + size * 0.4, y + icon.height / 2), "FitFlow", font=font(round(size * 1.05)),
           fill=WHITE, anchor="lm")
    y += icon.height + size * 0.6
    tf = font(size)
    for line in wrap(d, title, tf, max_w):
        d.text((x, y), line, font=tf, fill=WHITE)
        y += size * 1.2
    y += size * 0.2
    d.rounded_rectangle([x, y, x + size * 1.2, y + size * 0.14], radius=size, fill=CORAL)
    y += size * 0.45
    sf = font(round(size * 0.52), "regular")
    for line in wrap(d, sub, sf, max_w):
        d.text((x, y), line, font=sf, fill=(214, 214, 255))
        y += size * 0.7


def save(img: Image.Image, rel: str):
    path = OUT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(path, optimize=True)
    print(f"{rel:62s} {img.size[0]}x{img.size[1]}")


def main():
    order = ["04_meal_review", "01_home", "06_circles"]  # home in the centre, in front

    # Google Play feature graphic: 1024x500, no alpha. Key content kept away from
    # the edges because Play may overlay a play button or crop on some surfaces.
    fg = bg((1024, 500))
    headline(fg, 56, 78, 340, 40, "One clear workout a day", "Plans that explain themselves. Meals snapped on-device. Private circles.")
    place_phones(fg, order, 760, 36, 440, 150)
    save(fg, "android/feature-graphic/ff_android_feature-graphic_1024x500.png")

    # Social / website banner (Open Graph 1.91:1).
    ban = bg((1200, 628))
    headline(ban, 70, 120, 400, 46, "One clear workout a day", "Planned for you, explained to you. Now with nutrition and private circles.")
    place_phones(ban, order, 880, 44, 540, 180)
    save(ban, "promo/banners/ff_promo_banner_1200x628.png")

    # Square post.
    sq = bg((1080, 1080))
    d = ImageDraw.Draw(sq)
    tf = font(64)
    d.text((540, 120), "Train smarter with FitFlow", font=tf, fill=WHITE, anchor="mm")
    d.text((540, 200), "Smart workouts · Nutrition · Private circles", font=font(34, "regular"), fill=(214, 214, 255), anchor="mm")
    place_phones(sq, order, 540, 270, 760, 300)
    save(sq, "promo/banners/ff_promo_square_1080x1080.png")


if __name__ == "__main__":
    main()
