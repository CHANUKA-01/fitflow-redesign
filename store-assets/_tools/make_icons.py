"""Generate FitFlow icon masters.

Outputs:
  store-assets/icons/source/      1024 px masters consumed by flutter_launcher_icons
  store-assets/android/icon/      Play Console hi-res icon (512x512, 32-bit PNG)
  store-assets/ios/icon/          App Store icon (1024x1024, no alpha)

Run:  store-assets/_tools/.venv/bin/python store-assets/_tools/make_icons.py
"""
from pathlib import Path

from PIL import Image

from brand import full_icon, gradient, mark

ROOT = Path(__file__).resolve().parents[1]


def save(img: Image.Image, rel: str) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, optimize=True)
    print(f"{rel:60s} {img.size[0]}x{img.size[1]} {img.mode}")


def main() -> None:
    # Adaptive icon layers (Android 8+). 108 dp canvas; launchers may crop to a
    # 66 dp safe zone, so the mark's ring sits inside the central ~58 %.
    save(gradient((1024, 1024)), "icons/source/adaptive-background.png")
    save(mark(1024, 0.56), "icons/source/adaptive-foreground.png")
    # Android 13+ themed icon: single-colour silhouette, system tints it.
    save(mark(1024, 0.56, bolt=(255, 255, 255), ring=(255, 255, 255)), "icons/source/adaptive-monochrome.png")
    # Full-bleed master for iOS and pre-Android-8 launchers (iOS forbids alpha).
    save(full_icon(1024).convert("RGB"), "icons/source/icon-1024.png")

    save(full_icon(512).convert("RGB"), "android/icon/ff_android_icon_512.png")
    save(full_icon(1024).convert("RGB"), "ios/icon/ff_ios_appstore-icon_1024.png")
    # Rounded preview used in the report and promo material only (never uploaded).
    save(full_icon(1024, rounded=True), "icons/preview/ff_icon_rounded-preview_1024.png")


if __name__ == "__main__":
    main()
