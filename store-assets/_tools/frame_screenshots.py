"""Turn raw captures (frontend/mobile/build/screenshots/<target>/NN_name.png)
into upload-ready store screenshots with a caption, at exact store sizes.

Naming:  ff_<platform>_<device>[-<orientation>]_<NN>_<screen>_<W>x<H>.png
Run:     store-assets/_tools/.venv/bin/python store-assets/_tools/frame_screenshots.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

from brand import CORAL, DEEP, INDIGO, VIOLET, WHITE, font, gradient, rounded, shadow, wrap

REPO = Path(__file__).resolve().parents[2]
RAW = REPO / "frontend/mobile/build/screenshots"
OUT = REPO / "store-assets"

# Store order. 00_welcome is captured for the report but not uploaded.
CAPTIONS = {
    "01_home": ("Today's workout, one tap away", "Planned around your time, energy and kit"),
    "02_plan": ("Know why every exercise is there", "The planner explains itself and runs on your phone"),
    "03_logger": ("Log a set with a single tap", "Last session's weights, already filled in"),
    "04_meal_review": ("Snap your plate. Check. Save.", "Recognised on your device. Photos are never uploaded"),
    "05_nutrition": ("Calories and macros at a glance", "Made for rice and curry, not just salads"),
    "06_circles": ("Share with your circle, not the world", "Private by default. Every post says who can see it"),
    "07_progress": ("Progress in one clear sentence", "Missed a day? Your streak can recover"),
    "08_privacy": ("Your data, your call", "Export or delete everything from Settings"),
}

# target dir -> (output folder, filename stem, canvas size)
TARGETS = {
    "android-phone": ("android/screenshots/phone", "ff_android_phone", (1080, 1920)),
    "android-tablet7-portrait": ("android/screenshots/tablet-7in", "ff_android_tablet7-portrait", (1200, 1920)),
    "android-tablet7-landscape": ("android/screenshots/tablet-7in", "ff_android_tablet7-landscape", (1920, 1200)),
    "android-tablet10-portrait": ("android/screenshots/tablet-10in", "ff_android_tablet10-portrait", (1600, 2560)),
    "android-tablet10-landscape": ("android/screenshots/tablet-10in", "ff_android_tablet10-landscape", (2560, 1600)),
    "ios-iphone69": ("ios/screenshots/iphone-6.9in", "ff_ios_iphone69", (1320, 2868)),
    "ios-ipad13": ("ios/screenshots/ipad-13in", "ff_ios_ipad13", (2064, 2752)),
}


def background(size: tuple[int, int]) -> Image.Image:
    bg = gradient(size, INDIGO, DEEP, angle_deg=100).convert("RGBA")
    w, h = size
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([w * 0.45, -h * 0.15, w * 1.3, h * 0.45], fill=(*VIOLET, 150))
    from PIL import ImageFilter
    bg.alpha_composite(glow.filter(ImageFilter.GaussianBlur(min(size) * 0.12)))
    return bg


def frame(raw: Image.Image, size: tuple[int, int], title: str, sub: str) -> Image.Image:
    w, h = size
    canvas = background(size)
    d = ImageDraw.Draw(canvas)
    landscape = w > h
    unit = min(w, h)

    title_f = font(round(unit * (0.058 if landscape else 0.072)))
    sub_f = font(round(unit * (0.030 if landscape else 0.036)), "regular")

    if landscape:
        text_box = (round(w * 0.06), round(w * 0.36))  # left column
        shot_area = (round(w * 0.40), round(h * 0.07), round(w * 0.95), h + round(h * 0.06))
    else:
        text_box = (round(w * 0.08), round(w * 0.92))
        shot_area = (round(w * 0.10), round(h * 0.215), round(w * 0.90), h + round(h * 0.04))

    # Caption.
    max_w = text_box[1] - text_box[0]
    lines = wrap(d, title, title_f, max_w)
    sublines = wrap(d, sub, sub_f, max_w)
    lh, sh = title_f.size * 1.18, sub_f.size * 1.35
    block = len(lines) * lh + unit * 0.02 + len(sublines) * sh
    y = (h - block) / 2 if landscape else h * 0.055
    # Accent bar.
    d.rounded_rectangle([text_box[0], y - unit * 0.03, text_box[0] + unit * 0.07, y - unit * 0.018],
                        radius=unit, fill=CORAL)
    for line in lines:
        d.text((text_box[0], y), line, font=title_f, fill=WHITE)
        y += lh
    y += unit * 0.02
    for line in sublines:
        d.text((text_box[0], y), line, font=sub_f, fill=(214, 214, 255))
        y += sh

    # Screenshot: scaled to the area width, rounded, shadowed, bleeding off the bottom.
    ax0, ay0, ax1, ay1 = shot_area
    scale = min((ax1 - ax0) / raw.width, (ay1 - ay0) / raw.height) if landscape else (ax1 - ax0) / raw.width
    sw, shh = round(raw.width * scale), round(raw.height * scale)
    shot = raw.convert("RGB").resize((sw, shh), Image.LANCZOS)
    radius = round(unit * 0.045)
    bezel = round(unit * 0.012)
    device = Image.new("RGB", (sw + bezel * 2, shh + bezel * 2), (12, 12, 24))
    device.paste(shot, (bezel, bezel))
    device = rounded(device, radius + bezel)
    inner_mask = rounded(Image.new("RGB", (sw, shh)), radius).getchannel("A")
    device.paste(shot, (bezel, bezel), inner_mask)

    x = ax0 + ((ax1 - ax0) - device.width) // 2
    y = ay0 if not landscape else ay0 + ((ay1 - ay0) - device.height) // 2
    s = shadow(device.size, radius, round(unit * 0.025))
    canvas.alpha_composite(s, (x - s.width // 2 + device.width // 2, y - s.height // 2 + device.height // 2 + round(unit * 0.012)))
    canvas.alpha_composite(device, (x, y))
    return canvas.convert("RGB")  # stores reject alpha in screenshots


def main() -> None:
    made = 0
    for target, (folder, stem, size) in TARGETS.items():
        src = RAW / target
        if not src.exists():
            print(f"skip {target}: no raw captures in {src.relative_to(REPO)}")
            continue
        dest = OUT / folder
        dest.mkdir(parents=True, exist_ok=True)
        for old in dest.glob(f"{stem}_*.png"):
            old.unlink()
        for key, (title, sub) in CAPTIONS.items():
            raw_path = src / f"{key}.png"
            if not raw_path.exists():
                print(f"  missing {raw_path.name} for {target}")
                continue
            img = frame(Image.open(raw_path), size, title, sub)
            name = f"{stem}_{key}_{size[0]}x{size[1]}.png"
            img.save(dest / name, optimize=True)
            made += 1
        print(f"{target:28s} -> {folder}")
    print(f"{made} screenshots written")


if __name__ == "__main__":
    main()
