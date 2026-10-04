# FitFlow store assets

Everything needed to fill in the Google Play and App Store listings for FitFlow 1.1.0. All images
are generated from code in [`_tools/`](_tools/), so they can be rebuilt after any UI or brand change
instead of being hand-edited.

## Folder structure

```
store-assets/
├─ android/                       Google Play Console
│  ├─ icon/                       512×512 hi-res icon
│  ├─ feature-graphic/            1024×500 feature graphic
│  └─ screenshots/
│     ├─ phone/                   1080×1920 (9:16)
│     ├─ tablet-7in/              1200×1920 portrait, 1920×1200 landscape
│     └─ tablet-10in/             1600×2560 portrait, 2560×1600 landscape
├─ ios/                           App Store Connect
│  ├─ icon/                       1024×1024 App Store icon (no alpha)
│  ├─ screenshots/
│  │  ├─ iphone-6.9in/            1320×2868
│  │  └─ ipad-13in/               2064×2752
│  └─ previews/                   App preview video
├─ promo/
│  ├─ banners/                    Social / website banners
│  └─ video/                      Promo video (Play: upload to YouTube, paste URL)
├─ listing/
│  ├─ google-play/                title, short + full description, category
│  └─ app-store/                  name, subtitle, promotional text, keywords, description
├─ icons/                         Icon masters used to generate in-app launcher icons
└─ _tools/                        Generators and validator (Python + Pillow)
```

## Naming convention

```
ff_<platform>_<device>[-<orientation>]_<NN>_<screen>_<W>x<H>.png
```

| Part | Values |
|---|---|
| `ff` | FitFlow prefix, so files stay identifiable when dragged out of the folder |
| `platform` | `android`, `ios`, `promo` |
| `device` | `phone`, `tablet7`, `tablet10`, `iphone69`, `ipad13` |
| `orientation` | `portrait`, `landscape` (tablets only; phones are portrait) |
| `NN_screen` | Upload order and screen: `01_home` … `08_privacy` |
| `WxH` | Exact pixel size, so a wrong-size file is visible before upload |

Upload in `NN` order. The first three screenshots are the ones most users see in search results, so
they lead with the redesign's main promises: the one-tap home plan, the explained plan and one-tap
logging.

## Screenshot story

| # | Screen | Caption | Requirement shown |
|---|---|---|---|
| 01 | Home | Today's workout, one tap away | R01, R14, U04 |
| 02 | Plan | Know why every exercise is there | R03–R05, R15 |
| 03 | Logger | Log a set with a single tap | R06, R07, NFR1 |
| 04 | Meal review | Snap your plate. Check. Save. | R08, R09, U08, ADR-003 |
| 05 | Nutrition | Calories and macros at a glance | R08 |
| 06 | Circles | Share with your circle, not the world | R11, U01 |
| 07 | Progress | Progress in one clear sentence | R10, R12, R13 |
| 08 | Privacy | Your data, your call | NFR5, GDPR rights |

The screenshots show real app screens captured by an automated test
([`integration_test/screenshots_test.dart`](../frontend/mobile/integration_test/screenshots_test.dart))
with fictional demo data. The meal photo is an original illustration, so no third-party image rights are
involved.

## Regenerating

From the repository root:

```bash
python3 -m venv store-assets/_tools/.venv
store-assets/_tools/.venv/bin/pip install -r store-assets/_tools/requirements.txt
PY=store-assets/_tools/.venv/bin/python

$PY store-assets/_tools/make_icons.py              # icon masters + store icons
(cd frontend/mobile && dart run flutter_launcher_icons)   # in-app launcher icons
(cd frontend/mobile && scripts/capture_screenshots.sh)    # raw captures, all devices
$PY store-assets/_tools/frame_screenshots.py       # captioned store screenshots
$PY store-assets/_tools/make_promo.py              # feature graphic + banners
$PY store-assets/_tools/validate_assets.py         # check everything, write report
```

The validator writes [`docs/lab06/evidence/asset-validation.md`](../docs/lab06/evidence/asset-validation.md)
and exits non-zero if any asset breaks a store rule.
