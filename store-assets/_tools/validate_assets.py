"""Check every store asset against Google Play and App Store requirements and
write docs/lab06/evidence/asset-validation.md. Exit code 1 if anything fails.

Rules encoded here are the published listing requirements as of 2026; each
check names the rule it applies so a failure is self-explanatory.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT.parent / "docs/lab06/evidence/asset-validation.md"
MB = 1024 * 1024

results: list[tuple[str, str, bool, str]] = []  # (group, item, ok, detail)


def check(group: str, item: str, ok: bool, detail: str) -> None:
    results.append((group, item, ok, detail))


def img_info(p: Path):
    with Image.open(p) as im:
        return im.size, im.mode, im.format


def has_alpha(mode: str) -> bool:
    return mode in ("RGBA", "LA", "PA") or mode.endswith("A")


def exact_image(group, rel, size, allow_alpha, max_bytes, formats=("PNG",)):
    p = ROOT / rel
    if not p.exists():
        check(group, rel, False, "missing")
        return
    (w, h), mode, fmt = img_info(p)
    problems = []
    if (w, h) != size:
        problems.append(f"{w}x{h}, needs {size[0]}x{size[1]}")
    if fmt not in formats:
        problems.append(f"format {fmt}")
    if not allow_alpha and has_alpha(mode):
        problems.append("has alpha channel")
    if p.stat().st_size > max_bytes:
        problems.append(f"{p.stat().st_size / MB:.1f} MB > {max_bytes / MB:.0f} MB")
    check(group, rel, not problems, "; ".join(problems) or f"{w}x{h} {fmt} {mode}, {p.stat().st_size // 1024} KB")


def play_screenshots(group, folder, minimum=2, maximum=8, min_side=320, max_side=3840):
    files = sorted((ROOT / folder).glob("*.png"))
    by_orient: dict[str, list[Path]] = {}
    for f in files:
        key = "landscape" if "landscape" in f.name else "portrait"
        by_orient.setdefault(key, []).append(f)
    check(group, f"{folder}/ count", minimum <= len(files) and all(len(v) <= maximum for v in by_orient.values()),
          f"{len(files)} files ({', '.join(f'{k}: {len(v)}' for k, v in by_orient.items()) or 'none'}); "
          f"Play allows {minimum}-{maximum} per device type")
    for f in files:
        (w, h), mode, fmt = img_info(f)
        problems = []
        if min(w, h) < min_side or max(w, h) > max_side:
            problems.append(f"side outside {min_side}-{max_side}px")
        if max(w, h) / min(w, h) > 2:
            problems.append("aspect ratio longer than 2:1")
        if has_alpha(mode):
            problems.append("alpha channel")
        if f.stat().st_size > 8 * MB:
            problems.append("over 8 MB")
        check(group, f.name, not problems, "; ".join(problems) or f"{w}x{h}, ratio {max(w, h) / min(w, h):.2f}")


def apple_screenshots(group, folder, sizes, maximum=10):
    files = sorted((ROOT / folder).glob("*.png"))
    check(group, f"{folder}/ count", 1 <= len(files) <= maximum, f"{len(files)} files; App Store allows 1-{maximum}")
    for f in files:
        (w, h), mode, _ = img_info(f)
        problems = []
        if (w, h) not in sizes:
            problems.append(f"{w}x{h} is not an accepted size {sorted(sizes)}")
        if has_alpha(mode):
            problems.append("alpha channel")
        check(group, f.name, not problems, "; ".join(problems) or f"{w}x{h} {mode}")


def text(group, rel, limit, extra=None):
    p = ROOT / rel
    if not p.exists():
        check(group, rel, False, "missing")
        return
    s = p.read_text().rstrip()
    problems = [] if len(s) <= limit else [f"{len(s)} chars > {limit}"]
    if extra:
        problems += extra(s)
    check(group, rel, not problems, "; ".join(problems) or f"{len(s)}/{limit} chars")


def keyword_rules(s: str) -> list[str]:
    out = []
    if ", " in s:
        out.append("spaces after commas waste characters")
    if "fitflow" in s.lower():
        out.append("repeats the app name (already indexed)")
    words = s.split(",")
    if len(words) != len(set(words)):
        out.append("duplicate keywords")
    return out


def no_claims(s: str) -> list[str]:
    """Unverifiable or medical marketing claims both stores reject."""
    banned = ["#1", "best app", "number one", "guaranteed", "lose weight fast", "cures ", "clinically proven"]
    return [f"contains '{b}'" for b in banned if b in s.lower()]


def main() -> int:
    g = "Google Play"
    exact_image(g, "android/icon/ff_android_icon_512.png", (512, 512), True, 1 * MB)
    exact_image(g, "android/feature-graphic/ff_android_feature-graphic_1024x500.png", (1024, 500), False, 15 * MB,
                ("PNG", "JPEG"))
    play_screenshots(g + " · phone", "android/screenshots/phone")
    play_screenshots(g + " · 7-inch tablet", "android/screenshots/tablet-7in", maximum=8)
    play_screenshots(g + " · 10-inch tablet", "android/screenshots/tablet-10in", min_side=1080, maximum=8)
    text(g, "listing/google-play/title.txt", 30)
    text(g, "listing/google-play/short-description.txt", 80, no_claims)
    text(g, "listing/google-play/full-description.txt", 4000, no_claims)

    a = "App Store"
    exact_image(a, "ios/icon/ff_ios_appstore-icon_1024.png", (1024, 1024), False, 8 * MB)
    apple_screenshots(a + " · iPhone 6.9-inch", "ios/screenshots/iphone-6.9in",
                      {(1320, 2868), (2868, 1320), (1290, 2796), (2796, 1290)})
    apple_screenshots(a + " · iPad 13-inch", "ios/screenshots/ipad-13in",
                      {(2064, 2752), (2752, 2064), (2048, 2732), (2732, 2048)})
    text(a, "listing/app-store/name.txt", 30)
    text(a, "listing/app-store/subtitle.txt", 30)
    text(a, "listing/app-store/promotional-text.txt", 170, no_claims)
    text(a, "listing/app-store/keywords.txt", 100, keyword_rules)
    text(a, "listing/app-store/description.txt", 4000, no_claims)

    failed = [r for r in results if not r[2]]
    lines = ["# Store asset validation", "",
             "Generated by `store-assets/_tools/validate_assets.py`. "
             f"**{len(results) - len(failed)} of {len(results)} checks passed.**", ""]
    group = None
    for grp, item, ok, detail in results:
        if grp != group:
            lines += ["", f"## {grp}", "", "| Asset | Result | Detail |", "|---|---|---|"]
            group = grp
        lines.append(f"| `{item}` | {'✅ pass' if ok else '❌ FAIL'} | {detail} |")
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text("\n".join(lines) + "\n")

    for grp, item, ok, detail in results:
        if not ok:
            print(f"FAIL  {grp}: {item} - {detail}")
    print(f"{len(results) - len(failed)}/{len(results)} checks passed -> {REPORT.relative_to(ROOT.parent)}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
