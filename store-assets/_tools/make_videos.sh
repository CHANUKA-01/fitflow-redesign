#!/usr/bin/env bash
# Turn raw screen recordings (frontend/mobile/build/recordings/) into store videos:
#   ios/previews/ff_ios_iphone69_app-preview_886x1920.mp4   App Store app preview
#   promo/video/ff_promo_android-phone_1080x1920.mp4        Play promo (upload to YouTube)
#
# App previews must show real app footage, be 15-30 s, <=30 fps, and carry a
# stereo audio track (silence is allowed). Footage before the end of the
# integration test's black "Test starting..." screen is cut automatically; the
# rest is sped up only if it would run past 28 s.
set -euo pipefail
cd "$(dirname "$0")/../.."
REC=frontend/mobile/build/recordings
TARGET_SECONDS=28

make() { # $1 input, $2 output, $3 width, $4 height
  [[ -f "$1" ]] || { echo "skip: $1 not found"; return; }
  local total start dur speed
  total=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$1")
  # End of the last black segment = first frame of the real app flow.
  start=$(ffmpeg -hide_banner -i "$1" -vf "blackdetect=d=0.5:pix_th=0.12" -an -f null - 2>&1 \
    | grep -oE 'black_end:[0-9.]+' | tail -1 | cut -d: -f2)
  start=${start:-0}
  dur=$(python3 -c "print($total - $start)")
  speed=$(python3 -c "print(max(1.0, $dur / $TARGET_SECONDS))")
  mkdir -p "$(dirname "$2")"
  ffmpeg -y -loglevel error -ss "$start" -i "$1" \
    -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
    -filter_complex "[0:v]setpts=PTS/${speed},fps=30,scale=$3:$4:force_original_aspect_ratio=decrease,pad=$3:$4:(ow-iw)/2:(oh-ih)/2:color=0x4338CA,format=yuv420p[v]" \
    -map "[v]" -map 1:a -c:v libx264 -profile:v high -preset slow -crf 20 -c:a aac -b:a 128k \
    -shortest -t "$TARGET_SECONDS" -movflags +faststart "$2"
  printf '%-60s %ss (source %.1fs from %.1fs, x%.2f)\n' "$2" \
    "$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$2" | cut -c1-5)" "$dur" "$start" "$speed"
}

make "$REC/ios-iphone69.mov" store-assets/ios/previews/ff_ios_iphone69_app-preview_886x1920.mp4 886 1920
make "$REC/android-phone.mp4" store-assets/promo/video/ff_promo_android-phone_1080x1920.mp4 1080 1920
