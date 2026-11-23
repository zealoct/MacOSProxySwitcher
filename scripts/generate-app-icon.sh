#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
icon_source="$project_root/artwork/AppIcon.svg"
icon_set="$project_root/MPS/MPS/Resources/Assets.xcassets/AppIcon.appiconset"

if ! command -v rsvg-convert >/dev/null 2>&1; then
    echo "Install librsvg (brew install librsvg) to regenerate the app icon." >&2
    exit 1
fi

mkdir -p "$icon_set"
manifest="$(mktemp "$icon_set/Contents.json.XXXXXX")"
trap 'rm -f "$manifest"' EXIT
printf '{\n  "images" : [\n' > "$manifest"
separator=""
for size in 16 32 128 256 512; do
    for scale in 1 2; do
        pixels=$((size * scale))
        filename="icon_${size}x${size}"
        if [ "$scale" -eq 2 ]; then filename="${filename}@2x"; fi
        filename="${filename}.png"
        rsvg-convert --width "$pixels" --height "$pixels" \
            --output "$icon_set/$filename" "$icon_source"
        printf '%s    { "filename" : "%s", "idiom" : "mac", "scale" : "%sx", "size" : "%sx%s" }' \
            "$separator" "$filename" "$scale" "$size" "$size" >> "$manifest"
        separator=$',\n'
    done
done
printf '\n  ],\n  "info" : { "author" : "xcode", "version" : 1 }\n}\n' >> "$manifest"
mv "$manifest" "$icon_set/Contents.json"
echo "Generated all 10 macOS app icon representations."
