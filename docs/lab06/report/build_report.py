"""Build the Lab 06 report (Word) from the repository's evidence and assets.

Run: store-assets/_tools/.venv/bin/python docs/lab06/report/build_report.py
Output: docs/lab06/report/IT23230774_Lab06.docx (PDF is exported from Word).
"""
from __future__ import annotations

import re
from pathlib import Path

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor
from PIL import Image

REPO = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
IMG = OUT / "img"
IMG.mkdir(exist_ok=True)
SA = REPO / "store-assets"
RAW = REPO / "frontend/mobile/build/screenshots"
EVID = (REPO / "docs/lab06/evidence/release-evidence-1.1.0+2.txt").read_text()

INDIGO = RGBColor(0x43, 0x38, 0xCA)
GITHUB = "https://github.com/CHANUKA-01/fitflow-redesign"


# ---------- image preparation ----------

def grid(name: str, files: list[Path], cols: int, cell_h: int, gap: int = 24) -> Path:
    ims = [Image.open(f).convert("RGB") for f in files]
    ims = [i.resize((round(i.width * cell_h / i.height), cell_h), Image.LANCZOS) for i in ims]
    rows = (len(ims) + cols - 1) // cols
    cw = max(i.width for i in ims)
    sheet = Image.new("RGB", (cols * cw + (cols - 1) * gap, rows * cell_h + (rows - 1) * gap), "white")
    for k, im in enumerate(ims):
        sheet.paste(im, ((k % cols) * (cw + gap) + (cw - im.width) // 2, (k // cols) * (cell_h + gap)))
    path = IMG / f"{name}.jpg"
    sheet.save(path, quality=85)
    return path


def prepare_images() -> dict[str, Path]:
    phone = sorted((SA / "android/screenshots/phone").glob("*.png"))
    t7 = sorted((SA / "android/screenshots/tablet-7in").glob("*.png"))
    t10 = sorted((SA / "android/screenshots/tablet-10in").glob("*.png"))
    iph = sorted((SA / "ios/screenshots/iphone-6.9in").glob("*.png"))
    ipad = sorted((SA / "ios/screenshots/ipad-13in").glob("*.png"))
    icons = [SA / "icons/preview/ff_icon_rounded-preview_1024.png"]
    # Adaptive and monochrome previews composited for display.
    bg = Image.open(SA / "icons/source/adaptive-background.png").convert("RGBA")
    bg.alpha_composite(Image.open(SA / "icons/source/adaptive-foreground.png"))
    bg.save(IMG / "adaptive.png")
    mono = Image.new("RGBA", (1024, 1024), (45, 45, 55, 255))
    mono.alpha_composite(Image.open(SA / "icons/source/adaptive-monochrome.png"))
    mono.save(IMG / "mono.png")
    return {
        "icons": grid("icons", icons + [IMG / "adaptive.png", IMG / "mono.png"], 3, 360),
        # Contact sheet of raw emulator captures saved during Activity 2 (the build folder is
        # cleaned by the release script, so the raw PNGs are not kept there).
        "raw_app": IMG / "raw_app_sheet.png",
        "phone": grid("phone", phone, 4, 900),
        "t7l": grid("t7l", [f for f in t7 if "landscape" in f.name][:4], 2, 500),
        "t10p": grid("t10p", [f for f in t10 if "portrait" in f.name][:4], 4, 900),
        "ios": grid("ios", iph[:4] + ipad[:2], 6, 900),
        "feature": SA / "android/feature-graphic/ff_android_feature-graphic_1024x500.png",
        "banner": SA / "promo/banners/ff_promo_banner_1200x628.png",
    }


# ---------- docx helpers ----------

def shade(cell, hex_fill: str) -> None:
    tcPr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), hex_fill)
    tcPr.append(shd)


def add_runs(p, text: str, size: float | None = None) -> None:
    """Supports **bold** and `code` inline markup."""
    for part in re.split(r"(\*\*[^*]+\*\*|`[^`]+`)", text):
        if not part:
            continue
        if part.startswith("**"):
            r = p.add_run(part[2:-2])
            r.bold = True
        elif part.startswith("`"):
            r = p.add_run(part[1:-1])
            r.font.name = "Menlo"
            r.font.size = Pt(8.5)
        else:
            r = p.add_run(part)
        if size and not part.startswith("`"):
            r.font.size = Pt(size)


class Report:
    def __init__(self) -> None:
        self.d = Document()
        sec = self.d.sections[0]
        sec.page_height, sec.page_width = Cm(29.7), Cm(21.0)
        for side in ("left_margin", "right_margin"):
            setattr(sec, side, Cm(2.2))
        sec.top_margin = sec.bottom_margin = Cm(2.0)
        st = self.d.styles["Normal"]
        st.font.name = "Calibri"
        st.font.size = Pt(10.5)
        for lvl, size in ((1, 17), (2, 13), (3, 11.5)):
            h = self.d.styles[f"Heading {lvl}"]
            h.font.color.rgb = INDIGO if lvl < 3 else RGBColor(0x22, 0x22, 0x44)
            h.font.size = Pt(size)
            h.font.name = "Calibri"

    def h(self, text: str, level: int = 1) -> None:
        self.d.add_heading(text, level)

    def p(self, text: str, size: float | None = None, italic: bool = False, align=None):
        para = self.d.add_paragraph()
        add_runs(para, text, size)
        if italic:
            for r in para.runs:
                r.italic = True
        if align:
            para.alignment = align
        para.paragraph_format.space_after = Pt(4)
        return para

    def bullets(self, items: list[str]) -> None:
        for it in items:
            para = self.d.add_paragraph(style="List Bullet")
            add_runs(para, it)
            para.paragraph_format.space_after = Pt(1)

    def table(self, header: list[str], rows: list[list[str]], widths: list[float] | None = None,
              size: float = 9) -> None:
        t = self.d.add_table(rows=1, cols=len(header))
        t.style = "Table Grid"
        t.alignment = WD_TABLE_ALIGNMENT.CENTER
        for i, txt in enumerate(header):
            c = t.rows[0].cells[i]
            c.text = ""
            r = c.paragraphs[0].add_run(txt)
            r.bold = True
            r.font.size = Pt(size)
            r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
            shade(c, "4338CA")
        for row in rows:
            cells = t.add_row().cells
            for i, txt in enumerate(row):
                cells[i].text = ""
                add_runs(cells[i].paragraphs[0], str(txt), size)
        if widths:
            for row in t.rows:
                for i, w in enumerate(widths):
                    row.cells[i].width = Cm(w)
        self.d.add_paragraph().paragraph_format.space_after = Pt(2)

    def code(self, text: str) -> None:
        t = self.d.add_table(rows=1, cols=1)
        c = t.rows[0].cells[0]
        shade(c, "F1F1F7")
        c.text = ""
        para = c.paragraphs[0]
        r = para.add_run(text.rstrip())
        r.font.name = "Menlo"
        r.font.size = Pt(7.5)
        self.d.add_paragraph().paragraph_format.space_after = Pt(2)

    def img(self, path: Path, width_cm: float, caption: str | None = None) -> None:
        self.d.add_picture(str(path), width=Cm(width_cm))
        self.d.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER
        if caption:
            self.p(caption, 8.5, italic=True, align=WD_ALIGN_PARAGRAPH.CENTER)

    def page_break(self) -> None:
        self.d.add_paragraph().add_run().add_break(WD_BREAK.PAGE)


# ---------- content ----------

def build() -> Path:
    im = prepare_images()
    R = Report()
    d = R.d

    # Cover
    for _ in range(3):
        d.add_paragraph()
    for text, size, bold in (("Sri Lanka Institute of Information Technology", 24, True),
                             ("Human Computer Interaction (IT3060)", 16, False),
                             ("Lab Exercise 06", 14, True),
                             ("FitFlow — Release Preparation and Internal Testing", 13, False)):
        para = d.add_paragraph()
        para.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = para.add_run(text)
        r.font.size = Pt(size)
        r.bold = bold
    d.add_paragraph()
    R.img(SA / "icons/preview/ff_icon_rounded-preview_1024.png", 4.2)
    d.add_paragraph()
    for line in ("Details", "Campus: Malabe Campus", "Name: Jayawardhana O K T C", "Student ID: IT23230774",
                 "Year: 3rd Year, 2nd Semester", "Group: WE 1.1", "Date: 04/10/2026"):
        para = d.add_paragraph()
        para.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = para.add_run(line)
        r.font.size = Pt(12)
        if line == "Details":
            r.underline = True
        para.paragraph_format.space_after = Pt(1)
    R.page_break()

    # Contents
    R.h("Contents", 1)
    for line in ["Overview", "Activity 1 – Generate Signed APK/AAB",
                 "Activity 2 – Prepare App Icons, Screenshots and Store Assets",
                 "Activity 3 – Configure Google Play Console",
                 "Activity 4 – Configure App Store Connect and TestFlight",
                 "Activity 5 – Prepare a Privacy Policy and Release Notes",
                 "Activity 6 – Perform Internal Testing Deployment", "Appendix – Build and test commands"]:
        R.p(line)
    R.p(f"**GitHub repository:** {GITHUB}")
    R.p("All documents referenced in this report are in the repository under `docs/lab06/`, the store "
        "assets under `store-assets/` and the app under `frontend/mobile/`.", 9.5)

    R.h("Overview", 1)
    R.p("Lab 05 selected Flutter for the FitFlow mobile client. For this lab the Flutter app was built "
        "(\"Focus Flow\" design from Lab 03), signed for release, and prepared for both stores. Every screen "
        "implements a requirement from earlier labs (R01–R16, NFR1–NFR5, usability issues U01–U14).")
    R.table(["Item", "Value"], [
        ["App", "FitFlow: Workouts & Nutrition — package / bundle ID `io.fitflow.app`"],
        ["Version", "1.1.0 (build / versionCode 2)"],
        ["Framework", "Flutter 3.47.6, Dart 3.13.5; Android 7.0+ (API 24–36), iOS 15+"],
        ["Features", "Daily AI-style plan on Home, explained planner, one-tap set logging, on-device meal photo "
                     "review, nutrition, private circles, progress, privacy controls"],
        ["Store accounts", "Not available (Google Play US$25, Apple US$99) — Activities 3 and 4 are fully "
                           "prepared configurations; the signed builds and all assets are real"],
    ], [3.5, 13])
    R.img(im["raw_app"], 16.5, "Figure 1 – FitFlow 1.1.0 running on the Pixel 9a emulator (signed build, demo data): "
                               "welcome, home, plan, logger, meal review, nutrition, circles, progress, privacy.")
    R.page_break()

    # Activity 1
    R.h("Activity 1 – Generate Signed APK/AAB", 1)
    R.h("1.1 Build details", 2)
    R.table(["Item", "Value"], [
        ["Application ID", "io.fitflow.app"],
        ["Version name / code", "1.1.0 / 2 (baseline 1.0.0 / 1)"],
        ["Min / target / compile SDK", "24 (Android 7.0) / 36 (Android 16) / 36"],
        ["ABIs", "arm64-v8a, armeabi-v7a, x86_64"],
        ["Signing key", "Upload key `fitflow-upload`, RSA 4096, SHA384withRSA, PKCS12, valid to 2056"],
        ["Optimisation", "R8 minify + resource shrinking; Dart obfuscation with symbols split out"],
    ], [5, 11.5])
    R.h("1.2 Release configuration (android/app/build.gradle.kts)", 2)
    R.code('''signingConfigs {
    if (releaseStoreFile != null) {
        create("release") {
            storeFile = file(releaseStoreFile)          // from key.properties or FITFLOW_* env vars
            storePassword = signingValue("storePassword", "FITFLOW_KEYSTORE_PASSWORD")
            keyAlias = signingValue("keyAlias", "FITFLOW_KEY_ALIAS")
            keyPassword = signingValue("keyPassword", "FITFLOW_KEY_PASSWORD")
            storeType = "pkcs12"
        }
    }
}
buildTypes {
    release {
        signingConfig = signingConfigs.findByName("release")   // no fallback to the debug key
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}''')
    R.bullets([
        "The template signed release builds with the **debug key**; that was removed. A Gradle task-graph check "
        "stops any release build with a clear error if the upload key is missing, while debug builds still work.",
        "Android 11+ `<queries>` added so the privacy-policy and support links open on modern phones.",
    ])
    R.h("1.3 Keystore and signing", 2)
    R.code('''keytool -genkeypair -v -storetype PKCS12 \\
  -keystore ~/.fitflow-signing/fitflow-upload.jks -alias fitflow-upload \\
  -keyalg RSA -keysize 4096 -validity 10950 \\
  -dname "CN=FitFlow Upload Key, OU=IT3060 WE 1.1, O=FitFlow, L=Malabe, ST=Western, C=LK"''')
    R.table(["Secret", "Location", "In git?"], [
        ["Keystore file", "~/.fitflow-signing/fitflow-upload.jks (outside repo, mode 600)", "No"],
        ["Passwords + alias", "~/.fitflow-signing/key.properties; android/key.properties is a symlink", "No (git-ignored)"],
        ["CI copies", "GitHub Actions secrets (keystore base64 + passwords)", "No"],
    ], [3.5, 10, 3])
    R.bullets([
        "**Play App Signing:** Google holds the app signing key; the team holds only the upload key, which can be "
        "reset through Play Console if lost.",
        "**Backup:** two encrypted offline copies (USB + password manager); password only in the password manager; "
        "access limited to release owner and one deputy; restore test each semester.",
        "**Incident found and fixed:** the project is on an iCloud-synced Desktop, so `key.properties` (passwords) "
        "was being uploaded to iCloud. It was moved outside the synced folder.",
        "Upload certificate SHA-256: `93:B8:CF:64:31:72:92:77:8C:DA:A9:3D:ED:CB:96:90:67:EB:08:FA:3C:78:4D:4E:93:5D:29:8B:38:BA:57:51`",
    ])
    R.h("1.4 Build commands", 2)
    R.code('''cd frontend/mobile
scripts/release_android.sh            # clean, analyse, test, build AAB + APKs, verify, write evidence
# equivalent steps:
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info''')
    R.h("1.5 Verification", 2)
    R.table(["Check", "Tool", "Result"], [
        ["AAB signature", "jarsigner -verify", "jar verified — CN=FitFlow Upload Key"],
        ["APK signature", "apksigner verify", "Verifies (APK Signature Scheme v2), RSA 4096"],
        ["Signer = keystore", "SHA-256 compare", "Match (93b8cf64…5751)"],
        ["Code shrinking", "R8 mapping.txt", "Present — code obfuscated"],
        ["Play download size", "bundletool get-size", "≈ 8.0 MB (arm64) vs 48.6 MB AAB upload file"],
        ["Permissions", "aapt2 dump badging", "None shown to the user (no INTERNET, CAMERA or storage)"],
        ["Install test", "bundletool install-apks", "Installed and run on Pixel 9a emulator (Android 16)"],
        ["Start-up (NFR3)", "am start -W", "3.8–7.5 s on emulator; control app 2.5–5.5 s → emulator not valid; "
                                          "physical device pending"],
    ], [3.5, 3.8, 9.2])
    R.p("Excerpt of the generated evidence log (`docs/lab06/evidence/release-evidence-1.1.0+2.txt`):", 9.5)
    excerpt = "\n".join(EVID.splitlines()[:40])
    R.code(excerpt)
    R.page_break()

    # Activity 2
    R.h("Activity 2 – Prepare App Icons, Screenshots and Store Assets", 1)
    R.p("All assets are generated by code (Python/Pillow) and screenshots are captured from the real app by an "
        "automated Flutter integration test, so they can be regenerated after any change. A validator checks "
        "every file against Google Play and App Store rules: **72 of 72 checks passed**.")
    R.h("2.1 Icon and branding", 2)
    R.img(im["icons"], 12, "Figure 2 – App Store/Play icon, Android adaptive icon, Android 13 themed (monochrome) icon.")
    R.table(["Asset", "Size / format", "Rule"], [
        ["Play hi-res icon", "512×512 PNG", "Full square, Google applies mask"],
        ["App Store icon", "1024×1024 PNG, no alpha", "Apple rejects transparency"],
        ["Adaptive icon", "108 dp layers, all densities", "Mark inside 66 dp safe zone"],
        ["Themed icon", "Monochrome layer", "Android 13+ tints it"],
        ["iOS AppIcon set", "20–1024 pt @1x–@3x", "Generated by flutter_launcher_icons"],
        ["Splash", "Brand indigo, Android 12+ and iOS", "No white flash at start"],
    ], [4, 5, 7.5])
    R.h("2.2 Feature graphic and banners", 2)
    R.img(im["feature"], 12, "Figure 3 – Google Play feature graphic (1024×500).")
    R.img(im["banner"], 10, "Figure 4 – Promotional banner (1200×628).")
    R.h("2.3 Screenshots", 2)
    R.table(["Store slot", "Size", "Count"], [
        ["Play – phone", "1080×1920", "8"],
        ["Play – 7-inch tablet", "1200×1920 portrait + 1920×1200 landscape", "8 + 8"],
        ["Play – 10-inch tablet", "1600×2560 portrait + 2560×1600 landscape", "8 + 8"],
        ["App Store – iPhone 6.9\"", "1320×2868", "8"],
        ["App Store – iPad 13\"", "2064×2752", "8"],
    ], [5, 8, 3.5])
    R.img(im["phone"], 15, "Figure 5 – Google Play phone screenshots 01–08 (captioned, in upload order).")
    R.img(im["t7l"], 13, "Figure 6 – 7-inch tablet, landscape.")
    R.img(im["t10p"], 15, "Figure 7 – 10-inch tablet, portrait.")
    R.img(im["ios"], 16, "Figure 8 – App Store: iPhone 6.9\" (first four) and iPad 13\".")
    R.table(["#", "Screen", "Caption", "Requirement"], [
        ["01", "Home", "Today's workout, one tap away", "R01, R14, U04"],
        ["02", "Plan", "Know why every exercise is there", "R03–R05, R15"],
        ["03", "Logger", "Log a set with a single tap", "R06, R07, NFR1"],
        ["04", "Meal review", "Snap your plate. Check. Save.", "R08, R09, U08"],
        ["05", "Nutrition", "Calories and macros at a glance", "R08"],
        ["06", "Circles", "Share with your circle, not the world", "R11, U01"],
        ["07", "Progress", "Progress in one clear sentence", "R10, R12, R13"],
        ["08", "Privacy", "Your data, your call", "NFR5"],
    ], [1, 2.6, 7.5, 5.4])
    R.h("2.4 Video, listing text and folder structure", 2)
    R.bullets([
        "**App Store app preview:** 886×1920, H.264, 30 fps, silent stereo AAC, 23 s of real app footage recorded "
        "on the iPhone simulator with a clean 9:41 status bar (Apple requires real footage, 15–30 s).",
        "**Play promo video:** 1080×1920, 27 s — uploaded to YouTube (unlisted) and linked in the listing.",
        "**Listing text:** title 29/30, Play short description 78/80, App Store subtitle 24/30, keywords 98/100, "
        "promotional text 144/170, description ≈2 360/4000.",
        "**Honest metadata:** the planner is rule-based in this prototype, so the listing says \"smart planner\" not "
        "\"AI\" (Apple 2.3 / Play misleading claims). An unverified WCAG claim was removed.",
    ])
    R.code('''store-assets/
├─ android/  icon/ feature-graphic/ screenshots/{phone, tablet-7in, tablet-10in}
├─ ios/      icon/ screenshots/{iphone-6.9in, ipad-13in} previews/
├─ promo/    banners/ video/
├─ listing/  google-play/ app-store/
└─ _tools/   generators + validate_assets.py
Naming: ff_<platform>_<device>[-<orientation>]_<NN>_<screen>_<W>x<H>.png
        e.g. ff_android_phone_01_home_1080x1920.png''')
    R.h("2.5 Problems found and fixed", 2)
    R.table(["Problem", "Fix"], [
        ["Circle audience label truncated (\"Visible to 5 mem…\") — undid the U01 privacy fix", "Label given its own space, wraps"],
        ["Tablet layouts stretched across 2560 px", "Content capped to a centred 720 dp column"],
        ["Raw phone screenshot 2.24:1 — Play rejects > 2:1", "Framed onto 9:16 canvas with caption"],
        ["iOS build: codesign rejected files tagged by iCloud", "Build output moved outside synced Desktop"],
    ], [9, 7.5])
    R.page_break()

    # Activity 3
    R.h("Activity 3 – Configure Google Play Console", 1)
    R.p("**Status:** fully prepared; not submitted because no Google Play developer account was available. "
        "Full configuration: `docs/lab06/03-google-play-console.md`.", 10)
    R.table(["Section", "Configuration"], [
        ["App", "FitFlow: Workouts & Nutrition · en-GB · App · Free"],
        ["Category", "Health & Fitness; tags Workout, Fitness tracking, Nutrition"],
        ["Store listing", "Title, short and full description, 512 icon, feature graphic, 8 phone + 16 + 16 tablet screenshots, YouTube promo"],
        ["Privacy policy", "https://chanuka-01.github.io/fitflow-redesign/privacy-policy/"],
        ["Content rating (IARC)", "No violence/sex/gambling/drugs; users interact = Yes (circles, with report/delete) → expected PEGI 3 / Everyone"],
        ["Target audience", "18+ (16–17 allowed); not designed for children"],
        ["Ads / Advertising ID", "No ads; Advertising ID not used"],
        ["Data safety", "No data collected or shared (all on device, no INTERNET permission); in-app deletion available. "
                        "Planned answers prepared for the backend release"],
        ["Health apps declaration", "Activity & fitness tracking; nutrition; no medical/regulated features"],
        ["Play App Signing", "Google-generated app signing key; upload certificate SHA-256 93:B8:CF…:57:51"],
        ["Testing tracks", "Internal (team, ≤100) → Closed (Google Group) → Production. Personal accounts need 12 testers × 14 days of closed testing"],
        ["Release", "Internal: upload app-release.aab (1.1.0, code 2) + mapping.txt; notes from Activity 5"],
        ["Countries", "Sri Lanka first; then India, UK, Australia, Singapore"],
        ["Device exclusions", "None needed — minSdk 24 excludes old Android; camera not required"],
    ], [4, 12.5])
    R.h("3.1 Pre-launch report", 2)
    R.p("Play runs every testing-track upload on real devices. Expected: no crashes (none seen in 7 device "
        "configurations), possible accessibility suggestions (contrast audit is open), no security warnings (no "
        "cleartext traffic, no exported components except the launcher). Errors block promotion; warnings go to "
        "the bug log.")
    R.h("3.2 Store listing experiments (A/B tests)", 2)
    R.table(["#", "Hypothesis", "Variant", "Metric"], [
        ["E1", "Leading with the explained plan converts better", "Screenshot order 02-01-03", "Retained installers (1 day)"],
        ["E2", "Privacy-first short description attracts users who stay", "\"Private fitness planner: workouts that explain themselves, data stays on your phone.\"", "Retained installers"],
        ["E3", "Food recognition in the feature graphic lifts nutrition searches", "Meal-review phone in centre", "First-time installers"],
    ], [1, 6, 5.5, 4])
    R.p("50/50 split, at least 7 days, apply only at 90 % confidence; E1 first.", 9.5)
    R.page_break()

    # Activity 4
    R.h("Activity 4 – Configure App Store Connect and TestFlight", 1)
    R.p("**Status:** configuration prepared and the iOS app built and run on the iPhone 18 Pro Max and iPad Pro "
        "13-inch simulators (iOS 27, Xcode 27); not uploaded because no Apple Developer Program membership was "
        "available. Full configuration: `docs/lab06/04-app-store-connect-testflight.md`.", 10)
    R.table(["Section", "Configuration"], [
        ["App record", "iOS · FitFlow: Workouts & Nutrition · English (U.K.) · bundle io.fitflow.app · SKU FITFLOW-IOS-001"],
        ["Subtitle / category", "\"Workouts planned for you\" · Health & Fitness (secondary Food & Drink)"],
        ["Keywords (98/100)", "workout,planner,gym,fitness,strength,nutrition,calorie,meal,tracker,dumbbell,exercise,habit,streak"],
        ["Age rating", "4+ questionnaire; user-generated content = Yes with report/delete"],
        ["Privacy nutrition label", "\"Data Not Collected\" for 1.1.0 (no network access). Planned label prepared for backend release "
                                    "(Fitness, Name/Email, User content, Diagnostics — none used for tracking)"],
        ["Screenshots / preview", "8 × iPhone 6.9\" (1320×2868), 8 × iPad 13\" (2064×2752), 23 s app preview"],
        ["Export compliance", "ITSAppUsesNonExemptEncryption = NO added to Info.plist"],
        ["Upload", "flutter build ipa → Xcode Organizer or xcrun altool"],
    ], [4, 12.5])
    R.h("4.1 TestFlight", 2)
    R.table(["Group", "Type", "Members", "Review"], [
        ["FitFlow Team", "Internal", "≤100 App Store Connect users", "None"],
        ["FitFlow Beta – Campus", "External", "20–30 SLIIT students who train", "Beta App Review (first build)"],
        ["FitFlow Beta – Public link", "External", "Link capped at 100", "Beta App Review"],
    ], [4.5, 2.5, 5.5, 4])
    R.bullets([
        "Builds expire after **90 days**: new build at least every 60 days or after any critical fix; superseded "
        "builds expired manually; build number +1 per upload.",
        "\"What to test\": onboarding → start workout → log 3 sets → snap a meal and correct an item → post to private "
        "circle and check the audience label → send feedback with screenshot.",
    ])
    R.h("4.2 Apple review compliance (health)", 2)
    R.table(["Guideline", "FitFlow"], [
        ["1.4.1 Physical harm", "Reasons shown for every plan; conservative volume; professional-advice disclaimer"],
        ["1.2 User-generated content", "Report + delete on posts; private by default; contact in listing (block-user logged as gap)"],
        ["2.3 Accurate metadata", "Real screenshots; \"smart planner\", not \"AI\""],
        ["HealthKit / 5.1.3", "Not used in 1.1.0; rules documented if added (no ads, no iCloud storage)"],
        ["5.1.1 Data", "Privacy policy in app and listing; explicit consent; in-app deletion"],
        ["Camera purpose strings", "Explain on-device analysis and no upload"],
    ], [4.5, 12])
    R.page_break()

    # Activity 5
    R.h("Activity 5 – Prepare a Privacy Policy and Release Notes", 1)
    R.p("Full texts: `docs/lab06/05-privacy-policy.md` and `docs/lab06/05-release-notes.md`. The policy is linked in "
        "the app (onboarding consent step and Settings → Privacy policy) and in both store listings at "
        "**https://chanuka-01.github.io/fitflow-redesign/privacy-policy/** — publishing it with GitHub Pages is the "
        "remaining step.", 10)
    R.h("5.1 Privacy policy (summary of sections)", 2)
    R.table(["Section", "Content"], [
        ["Summary", "Everything stays on the phone; no accounts, ads or tracking; photos analysed on device then deleted"],
        ["Data used", "Profile, health/fitness (injuries, workouts), nutrition, meal photos, posts, consent record; no contacts, location, ad ID"],
        ["Health data & consent", "Special-category data (GDPR Art. 9; Sri Lanka PDPA No. 9 of 2022) — explicit consent at onboarding, withdrawable in Settings"],
        ["AI processing", "Rule-based on-device planner with reasons; on-device food recognition with confidence; suggestions only, no Art. 22 decisions"],
        ["Social features", "Private circle by default; audience shown on every post; delete/report; local-only in 1.1.0"],
        ["Storage & security", "App-private storage, device encryption; removed on uninstall or delete"],
        ["Sharing", "None; future providers (e.g. Firebase Crashlytics) listed before they are added"],
        ["Rights", "Access/portability (Export), correction, erasure (Delete all), withdraw consent, complaint to authority"],
        ["Children", "16+; not directed at children; no under-13 data"],
        ["HIPAA", "Not a covered entity, so HIPAA does not apply; HIPAA-style safeguards followed"],
        ["Disclaimer, changes, contact", "Not a medical device; versioned changes with in-app notice; contact support@fitflow.example (placeholder)"],
    ], [4, 12.5])
    R.h("5.2 Release notes – Google Play (449/500 characters)", 2)
    play = re.findall(r"```\n(.*?)```", (REPO / "docs/lab06/05-release-notes.md").read_text(), re.S)[0]
    R.code(play)
    R.h("5.3 Update history and known issues", 2)
    R.table(["Version", "Build", "Date", "Summary"], [
        ["1.1.0", "2", "2026-10-04", "Focus Flow redesign"],
        ["1.0.0", "1", "—", "Template baseline, never distributed"],
    ], [2.5, 2, 3, 9])
    R.bullets(["Food recognition uses a demonstration model — results must be checked.",
               "Circles are stored on the device only.",
               "Start-up target (2 s) still to be measured on a physical device."])
    R.page_break()

    # Activity 6
    R.h("Activity 6 – Perform Internal Testing Deployment", 1)
    R.p("Only observed results are reported; items not yet done are marked Pending. Full record: "
        "`docs/lab06/06-internal-testing.md`.", 10)
    R.h("6.1 Deployment", 2)
    R.table(["Channel", "Status"], [
        ["Google Play Internal Testing", "Prepared (Activity 3) — needs Play account"],
        ["Apple TestFlight", "Prepared (Activity 4) — needs Apple Developer account"],
        ["Signed build direct install", "Done — AAB → bundletool install-apks on Pixel 9a emulator"],
        ["Firebase App Distribution", "Planned free alternative using the signed universal APK"],
    ], [6, 10.5])
    R.h("6.2 Results", 2)
    R.table(["Test", "Result"], [
        ["flutter analyze", "No issues"],
        ["Unit/widget tests", "5/5 passed (injury rules, equipment, reasons, low-energy volume, onboarding consent)"],
        ["Integration test (9 screens)", "Passed on 7 configurations: phone, 7\"/10\" tablets portrait + landscape, iPhone 6.9\", iPad 13\""],
        ["Manual walkthrough T01–T09", "All passed (T08 after fixing B01)"],
        ["Crashes", "None in any run (logcat checked)"],
        ["Start-up (NFR3)", "Emulator not valid (control app as slow); physical device Pending"],
        ["Battery", "Pending — physical device needed"],
        ["Crashlytics", "Not integrated yet — needs INTERNET permission, so planned with privacy-policy update"],
    ], [5, 11.5])
    R.h("6.3 Bug log", 2)
    R.table(["ID", "Severity", "Description", "Fix", "Status"], [
        ["B01", "Major", "Audience label truncated (U01 regression)", "Own space, wraps", "Fixed"],
        ["B02", "Minor", "Chip checkmark over lock icon", "showCheckmark: false", "Fixed"],
        ["B03", "Major", "Tablet content stretched", "720 dp column", "Fixed"],
        ["B04", "Major", "Links fail on Android 11+", "Manifest <queries>", "Fixed"],
        ["B05", "Critical", "iCloud duplicate files broke Android build", "Build out of synced folder", "Fixed"],
        ["B06", "Critical", "iOS codesign rejected iCloud-tagged files", "Same as B05", "Fixed"],
        ["B07", "Major", "Signing passwords in iCloud-synced folder", "Moved, symlinked", "Fixed"],
        ["B08", "Minor", "Screenshot captured stale frame", "Settle + precache", "Fixed"],
        ["B09", "Minor", "Emulator slept mid-test", "Stay-awake in script", "Fixed"],
    ], [1.2, 1.8, 6, 4.5, 1.8], 8.5)
    R.h("6.4 Tester feedback (to be completed)", 2)
    R.table(["Tester", "Device / OS", "Tasks completed", "Rating 1–5", "Comment"],
            [["", "", "", "", ""] for _ in range(4)], [2.5, 3, 3, 2, 6])
    R.h("6.5 Approval record", 2)
    R.p("Criteria: no open Critical/Major bugs ✔ · tests pass ✔ · release build verified ✔ · physical-device "
        "start-up ≤ 2 s ☐ · tester feedback reviewed ☐", 9.5)
    R.table(["Role", "Name", "Decision", "Signature", "Date"], [
        ["Developer", "Jayawardhana O K T C (IT23230774)", "", "", ""],
        ["Reviewer / team lead", "", "", "", ""],
        ["Lecturer", "", "", "", ""],
    ], [3, 5, 2.5, 3, 2.5])
    R.page_break()

    # Appendix
    R.h("Appendix – Build and test commands", 1)
    R.code('''# app
cd frontend/mobile
flutter pub get
flutter analyze && flutter test
flutter run                                   # debug on emulator/simulator

# signed release + verification evidence
scripts/release_android.sh

# store screenshots (all devices) and preview recordings
RECORD=1 scripts/capture_screenshots.sh

# store assets (from repository root)
PY=store-assets/_tools/.venv/bin/python
$PY store-assets/_tools/make_icons.py
$PY store-assets/_tools/frame_screenshots.py
$PY store-assets/_tools/make_promo.py
store-assets/_tools/make_videos.sh
$PY store-assets/_tools/validate_assets.py''')
    R.p(f"GitHub repository: {GITHUB}")

    out = OUT / "IT23230774_Lab06.docx"
    d.save(out)
    return out


if __name__ == "__main__":
    print(build())
